Crowd crowd;

int auxId = 0;

float a_i = 25.0;
float b_i = 0.08;
int k = 750;
int k_achatada = 3000;
float v_i_inicial = 5.0;
float t_i = 0.5;
float r_vecindad = 15;

int NumeroPersonas = 30;
float velocidadMax = 1;
float forceMax = 5;
float radioPerson = 10;
int massPerson = 1;

void setup() {
  size(700, 500);
  crowd = new Crowd();
  for (int i = 0; i < NumeroPersonas; i++) {
    crowd.addPerson(new Person(random(width),random(height)));
  }
}

//Se dibuja la pelota y los pajaros
void draw() {
  background(50);
  line(0, 0, 600, 226);
  line(600, 274, 0, 500);
  crowd.run();
}


class Wall {
  ArrayList<PVector> values;
  Wall(int x1, int y1, int x2, int y2){
    
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
    crowds.add(p);}
}

class Person {
  int id;
  PVector position;
  PVector velocity;
  PVector acceleration;
  PVector desiredDirection;
  float r;
  float m;
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
    m = massPerson;
    maxspeed = velocidadMax;
    maxforce = forceMax;
    id = auxId;
    auxId = auxId +1;
  }
  
  void run(ArrayList<Person> crowds) {
    //1
    processForces(crowds);
    update();  
    //2
    borders();
    render();
  }
  
  ///////////////////////////////////1
  //ACA SE APLICAN LAS FUERZAS
  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }  
  
  //ACA SE CREAN LAS FUERZAS DE LAS PERSONAS.
  void processForces(ArrayList<Person> crowds) {
    
    //Fuerza propia
    PVector own = ownForce();
    
    //Fuerzas de multitud
    PVector sep = crowdForces(crowds);   // Separation
    
    //Fuerzas de pared
    //PVector wall = wallForce()
    // Arbitrarily weight these forces
    // Add the force vectors to acceleration
    
    PVector total = PVector.add(own,sep);
    applyForce(total);
  }
  
  PVector ownForce(){
    PVector forces = new PVector(0, 0, 0);
    PVector auxOF_1 = PVector.mult(desiredDirection,v_i_inicial);
    PVector auxOF_2 = PVector.sub(auxOF_1,velocity);
    PVector ownForce = PVector.div(auxOF_2,t_i); 
    forces.add(ownForce);
    forces.normalize();
    return forces;
  }
  

//FALTA CALCULAR:
//Direccion unitaria perpendicular de la fuerza de friccion.
  PVector crowdForces (ArrayList<Person> crowds) {
    PVector forces = new PVector(0, 0, 0); 
    for (Person other : crowds) {
      if(id != other.id){
        //Calculo de distancia y radio combinado.
        float d_ij = abs(PVector.dist(position, other.position));
        float r_ij = r + other.r;
        
        if(d_ij > r_vecindad) {
          //Fuerza de repulsion.
          PVector diff = PVector.sub(position, other.position);
          PVector n_ij = PVector.div(diff,d_ij);
          float auxRF = a_i*exp(-(d_ij - r_ij)/b_i);
          PVector repulsionForce = PVector.mult(n_ij,auxRF);
          forces.add(repulsionForce);
          
          if(d_ij <= r_ij){
            //**Fuerzas de contacto**  
            
            //Fuerza corporal
            float auxCF = 2*k*(r_ij-d_ij);
            PVector contactForce = PVector.mult(n_ij,auxCF);
            forces.add(contactForce);        
            
            //Fuerza de friccion
            
            //Falta esteee ripi
            PVector tangDirection = new PVector(1,1,1);
                        
            PVector auxRelTang = PVector.sub(other.velocity,velocity);
            float relTangVelocity = PVector.dot(tangDirection,auxRelTang);
            float auxFF = k_achatada*(r_ij-d_ij)*relTangVelocity;
            PVector frictionForce = PVector.mult(tangDirection,auxFF);
            forces.add(frictionForce);   
          }
        }
      }
    }
    forces.mult(maxspeed);
    forces.limit(maxforce);
    return forces;
  }
  
  ///////////////////////////////////
  
  
  void update() {
    velocity.add(acceleration);
    velocity.limit(maxspeed);
    position.add(velocity);
    acceleration.mult(0);
  } 
  
  ///////////////////////////////////2
  void borders() {
    if (position.x < -r) 
    {
      position.x = width+r;
    }
    if (position.y < -r) position.y = height+r;
    if (position.x > width+r) position.x = -r;
    if (position.y > height+r) position.y = -r;
  }  

  void render() {
    circle(position.x, position.y, radioPerson);
  }   
}
