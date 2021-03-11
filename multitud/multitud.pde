Crowd crowd;
Wall wall;

int auxId = 0;

//**Constantes de simulacion**
float a_i = 25.0;
float b_i = 0.08;
int k = 750;
int k_achatada = 3000;
float v_i_inicial = 5.0;
float t_i = 0.5;
float radioPerson = 10;
float r_vecindad = radioPerson*6;
PVector frontalDirection = new PVector(1,0);

//Constantes propias
int NumeroPersonas = 100;
float velocidadMax = 2;
float forceMax = 0.5;
float xInitialValue = 40;
float yInitialValue = 0;
//Distancia inicial entre personas.
float xMinimalDistance = 80;
float aux = NumeroPersonas*2;


//Se define el tamaño de la ventana, y las lineas principales.
void setup() {
  size(700, 500);
  crowd = new Crowd();
  wall = new Wall();
  wall.addLine(0,0,600,226);
  wall.addLine(600,274,0,500);
}

//Se dibujan las personas, utilizando un mecanismo que verifica que exista una
//distancia minima de separacion.
void draw() {
  background(50);
  line(0, 0, 600, 226);
  line(600, 274, 0, 500);
  if(NumeroPersonas > 0){
    NumeroPersonas-=1;
    float lastPersonPosX = crowd.getLastPersonPosX();
    if(lastPersonPosX > xMinimalDistance){ 
      float yValue = 0;
      while(yValue < 100 || yValue > 400){
        yValue = randomGaussian()*250;        
      }
      yInitialValue = yValue;
      crowd.addPerson(new Person(xInitialValue,yInitialValue)); 
    }else{
      NumeroPersonas+=1;
    }
    }else{
      NumeroPersonas = -1;
    }
  ArrayList<PVector> wallValues = wall.getValues();
  crowd.run(wallValues); 
}

//Clase wall (pared)
class Wall {
  ArrayList<PVector> values;
  
  //Constructor de la clase pared
  Wall(){
    values = new ArrayList<PVector>();
  }
  
  //Metodo que agrega las posiciones (x,y) de una recta limitada por dos puntos.
  void addLine(float x1, float y1, float x2, float y2){
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
 
  ArrayList<PVector> getValues(){
    return values;
  }
}


//Clase crowd (multitud)
class Crowd {
  ArrayList<Person> crowds;
  
  //Constructor de la clase crowd
  Crowd() {
    crowds = new ArrayList<Person>();
  }
  
  //Metodo que ejecuta la funcion run de un grupo de personas.
  void run(ArrayList<PVector> wallValues) {
    for (Person p : crowds) {
     p.run(crowds,wallValues);
   }
  }

  void addPerson(Person p) {
    crowds.add(p);
  }
  
  //Metodo que obtiene la posicion x, de la ultima persona entrante al crowd.
  float getLastPersonPosX(){
    int crowdSize = crowds.size();
    if(crowdSize == 0){
      return xMinimalDistance+1;
    }else{
      Person p = crowds.get(crowdSize-1);
      return p.getPosition().x;
    }
  }
}

//Clase person (persona)
class Person {
  int id;
  PVector position;
  PVector velocity;
  PVector acceleration;
  PVector desiredDirection;
  float r;
  float maxforce;
  float maxspeed;
  
  //Metodo constructor de la clase person.
  Person(float x, float y) {
    acceleration = new PVector(0, 0);
    desiredDirection = new PVector(0,0);
    velocity = new PVector(0,0);
    position = new PVector(x, y);
    r = radioPerson;
    maxspeed = velocidadMax;
    maxforce = forceMax;
    id = auxId;
    auxId += 1;
  }
  
  PVector getPosition(){
    return position;
  }
  
  //Metodo que actualiza
  void run(ArrayList<Person> crowds,ArrayList<PVector> wallValues) {
    processForces(crowds,wallValues);
    update();  
    render();
    borders();
  }
  
  //Metodo utilizado para aplicar las fuerzas.
  void applyForce(PVector force) {
    acceleration.add(force);
  }  
  
  //Metodo que procesa las fuerzas entrantes.
  void processForces(ArrayList<Person> crowds, ArrayList<PVector> wallValues) {
    PVector own = ownForces(position);
    //Fuerzas de multitud
    PVector sep = crowdForces(crowds);
    //Fuerzas de pared
    PVector wall = wallForces(wallValues);
    applyForce(wall);
    applyForce(sep);
    applyForce(own);
  }
  
  //Metodo que calcula la fuerza de la propia persona.
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
      direction = frontalDirection;
    }
    PVector forces = new PVector(0, 0);
    PVector auxOF_1 = PVector.mult(direction,v_i_inicial);
    PVector auxOF_2 = PVector.sub(auxOF_1,velocity);
    PVector ownForce = PVector.div(auxOF_2,t_i); 
    forces.add(ownForce);
    forces.normalize();
    forces.mult(maxspeed);
    forces.sub(velocity);
    forces.limit(maxforce);    
    return forces;
  }
  
  //Metodo que calcula las fuerzas ejercidas por la multitud
  PVector crowdForces (ArrayList<Person> crowds) {
    PVector forces = new PVector(0, 0); 
    for (Person other : crowds) {
      if(id != other.id){
        //Calculo de distancia y radio combinado.
        float r_ij = r + other.r;
        float d_ij = abs(PVector.dist(position, other.position))-r_ij;
        if(d_ij <= r_vecindad) {
          //Fuerza de repulsion.
          PVector repulsionForce = getRepulsionForce(position, other.position,r_ij);
          repulsionForce.normalize();
          forces.add(repulsionForce);            
          if(d_ij <= r_ij){
            //**Fuerzas de contacto**  
            //Fuerza corporal
            PVector contactForce = getContactForce(position,other.position,r_ij);
            contactForce.normalize();
            forces.add(contactForce); 
            //Fuerza de friccion
            PVector frictionForce = getFrictionForce(position,velocity,other.position,other.velocity,r_ij);
            frictionForce.normalize();
            forces.add(frictionForce);   
          }
        }else{
          forces.add(new PVector(0,0));
        }
      }
    }
    forces.normalize();
    forces.mult(maxspeed);
    forces.sub(velocity);
    forces.limit(maxforce);
    return forces;
  }
  
  //Metodo que calcula las fuerzas ejercidas por la pared
  PVector wallForces (ArrayList<PVector> wallValues) {
    PVector forces = new PVector(0, 0); 
    for (PVector wallPos : wallValues) {
        float d_ij = PVector.dist(position, wallPos)-r;
        if(d_ij <= r_vecindad) {
          //Fuerza de repulsion.
          PVector repulsionForce = getRepulsionForce(position,wallPos,r);
          repulsionForce.normalize();
          forces.add(repulsionForce);        
          if(d_ij <= r){
            //**Fuerzas de contacto**   
            //Fuerza corporal
            PVector contactForce = getContactForce(position,wallPos,r);
            contactForce.normalize();
            forces.add(contactForce);        
            //Fuerza de friccion
            //Se realizan unas modificaciones para adecuar la ecuacion de friccion con personas a friccion con paredes.
            PVector velocityAux = PVector.mult(velocity,-1);
            PVector velocityNull = new PVector(0,0);
            PVector frictionForce = getFrictionForce(position,velocityAux,wallPos,velocityNull,r);
            frictionForce.normalize();
            forces.add(frictionForce);   
          }
        }
      }
    forces.normalize();      
    forces.mult(maxspeed);
    forces.sub(velocity);
    forces.limit(maxforce);
    return forces;
  }
  
  //Metodo que calcula la fuerza de repulsion
  PVector getRepulsionForce(PVector posA, PVector posB,float r_ij){
    float d_ij = PVector.dist(posA, posB)-r_ij;
    PVector diff = PVector.sub(posA, posB);
    PVector n_ij = PVector.div(diff,d_ij);
    float exponent = (-1*(d_ij - r_ij)/b_i);
    float auxRF = pow(a_i,exponent);
    PVector repulsionForce = PVector.mult(n_ij,auxRF);  
    return repulsionForce;
  }

  //Metodo que calcula la fuerza de contacto
  PVector getContactForce(PVector posA, PVector posB,float r_ij){
    float d_ij = PVector.dist(posA, posB)-r_ij;
    PVector diff = PVector.sub(posA, posB);
    PVector n_ij = PVector.div(diff,d_ij);    
    float auxCF = 2*k*(r_ij-d_ij);
    PVector contactForce = PVector.mult(n_ij,auxCF); 
    return contactForce;
  }

  //Metodo que calcula la fuerza de friccion
  PVector getFrictionForce(PVector posA,PVector velocityA, PVector posB, PVector velocityB,float r_ij){
    float d_ij = PVector.dist(posA, posB)-r_ij;
    PVector diff = PVector.sub(posA, posB);
    PVector n_ij = PVector.div(diff,d_ij);
    PVector tangDirection = new PVector(-1*n_ij.y,n_ij.x);
    PVector auxRelTang = PVector.sub(velocityB,velocityA);
    float relTangVelocity = PVector.dot(auxRelTang,tangDirection);
    float auxFF = k_achatada*(r_ij-d_ij)*relTangVelocity;
    PVector frictionForce = PVector.mult(tangDirection,auxFF); 
    return frictionForce;
  }
  
  //Metodo que actualiza los valores de velocidad y posicion, en base a la
  //aceleracion ganada.
  void update() {
    velocity.add(acceleration);
    velocity.limit(maxspeed);
    position.add(velocity);
    acceleration.mult(0);
  } 
  
  //Metodo que renderiza la figura de las personas.
  void render() {
    circle(position.x, position.y, 2*radioPerson);
  }
  
  //Metodo que verifica si esta en el borde, para que vuelva a aparecer por el otro extremo.
  void borders() {
    if (position.x < -r) position.x = width+r;
    if (position.y < -r) position.y = height+r;
    if (position.x > width+r) position.x = -r;
    if (position.y > height+r) position.y = -r;
  }
}
