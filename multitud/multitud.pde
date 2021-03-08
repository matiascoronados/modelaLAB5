Crowd crowd;
Wall wall;

int auxId = 0;

//Constantes de simulacion
float a_i = 25.0;
float b_i = 0.08;
int k = 750;
int k_achatada = 3000;
float v_i_inicial = 5.0;
float t_i = 0.5;
float r_vecindad = 30;

int NumeroPersonas = 20;
float velocidadMax = 1;
float forceMax = 5;
float radioPerson = 10;

int aux = NumeroPersonas*2;
void setup() {
  size(700, 500);
  crowd = new Crowd();
  //for (int i = 0; i < NumeroPersonas; i++) {
    //crowd.addPerson(new Person(40,random(100,400)));
  //}
  wall = new Wall();
  //Se agregan las dos lineas principales.
  wall.addHorizontalValues(0,0,600,226);
  wall.addHorizontalValues(600,274,0,500);
  
  //Se agregan las lineas de la ventana.
  //wall.addHorizontalValues(0,0,700,0);
  //wall.addVerticalValues(0,0,0,500);
  //wall.addHorizontalValues(0,500,700,500);
  //wall.addVerticalValues(700,0,700,500);
}

void draw() {
  background(50);
  line(0, 0, 600, 226);
  line(600, 274, 0, 500);
  
  //Para que las personas no se crean al mismo tiempo
  if(aux%2 == 0){
    if(aux !=0){
      crowd.addPerson(new Person(40,random(100,400)));
    }
  }
  if(aux > 0){
    aux-=1;
  }
  
  crowd.run();
  
  
}


class Wall {
  ArrayList<PVector> values;
  
  Wall(){
    values = new ArrayList<PVector>();
  }
  
  void addHorizontalValues(float x1, float y1, float x2, float y2){
    float aux1 = (y2 - y1);
    float aux2 = (x2 - x1);
    float pendiente = aux1/aux2;
    float initialValue = 0;
    float finalValue = 0;
    
    if(x1 > x2){
      initialValue = x2;
      finalValue = x1;
    }else{
      initialValue = x1;
      finalValue = x2;     
    }
    
    for(int i = (int)initialValue ; i <= finalValue; i++){
      float valorY = pendiente*(i-x1)+y1;
      float valorX = i;
      PVector coordenadas = new PVector(valorX,valorY);
      values.add(coordenadas);
    }    
  }
 
   void addVerticalValues(float x1, float y1, float x2, float y2){
    float aux1 = (y2 - y1);
    float aux2 = (x2 - x1);
    float pendiente = aux1/aux2;
    float initialValue = y1;
    float finalValue = y2;
   
    for(int i = (int)initialValue ; i <= finalValue; i++){
      float valorY = i;
      float valorX = (i - y1)/pendiente+x1;
      PVector coordenadas = new PVector(valorX,valorY);
      values.add(coordenadas);
    }    
  }
 
  ArrayList<PVector> getValues(){
    return values;
  }
}


// The Crowd (a list of Person objects)
class Crowd {
  ArrayList<Person> crowds;
  Crowd() {
    crowds = new ArrayList<Person>();
  }
  
  void run() {
    for (Person p : crowds) {
     p.run(crowds);}
  }

  void addPerson(Person p) {
    crowds.add(p);
  }
}

class Person {
  int id;
  PVector position;
  PVector velocity;
  PVector acceleration;
  PVector desiredDirection;
  float r;
  float maxforce;    // Maximum forcesing force
  float maxspeed;    // Maximum speed
  
  Person(float x, float y) {
    acceleration = new PVector(0, 0);
    desiredDirection = new PVector(1,0);
    // Leaving the code temporarily this way so that this example runs in JS
    float angle = random(TWO_PI);
    velocity = new PVector(cos(angle), sin(angle));
    position = new PVector(x, y);
    r = radioPerson;
    maxspeed = velocidadMax;
    maxforce = forceMax;
    id = auxId;
    auxId = auxId +1;
  }
  
  void run(ArrayList<Person> crowds) {
    processForces(crowds);
    update();  
    render();
    borders();
  }
  
  void applyForce(PVector force) {
    acceleration.add(force);
  }  
  
  void processForces(ArrayList<Person> crowds) {
    //Fuerza propia
    PVector own = ownForces(position);
    //Fuerzas de multitud
    PVector sep = crowdForces(crowds);
    //Fuerzas de pared
    PVector wall = wallForces();
    PVector aux = PVector.add(wall,sep);
    PVector total = PVector.add(own,aux);
    applyForce(total);
  }
  
  PVector ownForces(PVector position){
    PVector direction = desiredDirection;
    
    //Direccion deseada dependiendo de la posicion de la persona
    if(position.y < 226){
      direction = new PVector(600,239);
    }
    if(position.y > 274){
      direction = new PVector(600,-261);
    }
    if( 226 <= position.y && position.y <= 274){
      direction = desiredDirection;
    }
    PVector forces = new PVector(0, 0, 0);
    PVector auxOF_1 = PVector.mult(direction,v_i_inicial);
    PVector auxOF_2 = PVector.sub(auxOF_1,velocity);
    PVector ownForce = PVector.div(auxOF_2,t_i); 
    forces.add(ownForce);
    forces.normalize();
    return forces;
  }
  

//FALTA CALCULAR:
//Direccion unitaria perpendicular de la fuerza de friccion. (LISTOO)
  PVector crowdForces (ArrayList<Person> crowds) {
    PVector forces = new PVector(0, 0, 0); 
    for (Person other : crowds) {
      if(id != other.id){
        //Calculo de distancia y radio combinado.
        float d_ij = abs(PVector.dist(position, other.position));
        float r_ij = r + other.r;
        if(d_ij <= r_vecindad) {
          //Fuerza de repulsion.
          PVector repulsionForce = getRepulsionForce(position, other.position,r_ij);
          forces.add(repulsionForce);      
          if(d_ij <= r_ij){
            //**Fuerzas de contacto**  
            //Fuerza corporal
            PVector contactForce = getContactForce(position,other.position,r_ij);
            forces.add(contactForce);        
            //Fuerza de friccion
            PVector frictionForce = getFrictionForce(position,velocity,other.position,other.velocity,r_ij);
            forces.add(frictionForce);   
          }
        }
      }
    }
    forces.mult(maxspeed);
    forces.limit(maxforce);
    forces.normalize();
    return forces;
  }
  
  
  PVector wallForces () {
    PVector forces = new PVector(0, 0, 0); 
    ArrayList<PVector> wallValues = wall.getValues();
    for (PVector wallPos : wallValues) {
        float d_ij = PVector.dist(position, wallPos);
        if(d_ij <= r_vecindad) {
          //Fuerza de repulsion.
          PVector repulsionForce = getRepulsionForce(position,wallPos,r);
          forces.add(repulsionForce);        
          if(d_ij <= r){
            //**Fuerzas de contacto**   
            //Fuerza corporal
            PVector contactForce = getContactForce(position,wallPos,r);
            forces.add(contactForce);        
            //Fuerza de friccion
            //Se realizan unas modificaciones para adecuar la ecuacion de friccion con personas a friccion con paredes.
            PVector velocityAux = PVector.mult(velocity,-1);
            PVector velocityNull = new PVector(0,0);
            PVector frictionForce = getFrictionForce(position,velocityAux,wallPos,velocityNull,r);
            forces.add(frictionForce);   
          }
        }
      }
    forces.mult(maxspeed);
    forces.limit(maxforce);
    forces.normalize();
    return forces;
  }
  
  
  PVector getRepulsionForce(PVector posA, PVector posB,float r_ij){
    float d_ij = PVector.dist(posA, posB);
    PVector diff = PVector.sub(posA, posB);
    PVector n_ij = PVector.div(diff,d_ij);
    float exponent = (-1*(d_ij - r_ij)/b_i);
    float auxRF = pow(a_i,exponent);
    PVector repulsionForce = PVector.mult(n_ij,auxRF);  
    return repulsionForce;
  }
  
  PVector getContactForce(PVector posA, PVector posB,float r_ij){
    float d_ij = PVector.dist(posA, posB);
    PVector diff = PVector.sub(posA, posB);
    PVector n_ij = PVector.div(diff,d_ij);    
    float auxCF = 2*k*(r_ij-d_ij);
    PVector contactForce = PVector.mult(n_ij,auxCF); 
    return contactForce;
  }
  
  PVector getFrictionForce(PVector posA,PVector velocityA, PVector posB, PVector velocityB,float r_ij){
    float d_ij = PVector.dist(posA, posB);
    PVector diff = PVector.sub(posA, posB);
    PVector n_ij = PVector.div(diff,d_ij);
    
    //Se agrega la direccion unitaria perpendicular
    PVector tangDirection = new PVector(-1*n_ij.y,n_ij.x);
    PVector auxRelTang = PVector.sub(velocityB,velocityA);
    
    float relTangVelocity = PVector.dot(auxRelTang,tangDirection);
    
    float auxFF = k_achatada*(r_ij-d_ij)*relTangVelocity;
    PVector frictionForce = PVector.mult(tangDirection,auxFF); 
    return frictionForce;
  }
  

  void update() {
    velocity.add(acceleration);
    velocity.limit(maxspeed);
    position.add(velocity);
    acceleration.mult(0);
  } 
  
  void render() {
    //El tercer parametro de circle() es el diametro, por eso multiplice por 2 el radios
    circle(position.x, position.y, 2*radioPerson);
  }
  
  //Metodo que verifica si esta en el borde, para que vuelva a aparecer por el otro extremo.
  void borders() {
    if (position.x < -r) 
    {
      position.x = width+r;
    }
    if (position.y < -r) position.y = height+r;
    if (position.x > width+r) position.x = -r;
    if (position.y > height+r) position.y = -r;
  }
}
