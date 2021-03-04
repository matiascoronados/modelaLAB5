Flock flock;
Ball pelota = new Ball(180, 180, 50);
int cantidadPajaros = 200;

//Se define tamaño de ventana y posicion inicial de los pajaros
void setup() {
  size(640, 360);
  flock = new Flock();
  
  // Add an initial set of boids into the system
  for (int i = 0; i < cantidadPajaros; i++) {
    flock.addBoid(new Boid(width/2,height/2));
  }
}


//Se dibuja la pelota y los pajaros
void draw() {
  background(50);
  for (Boid boids : flock.boids) {
    boids.checkCollision(pelota);    
  }
  //Se actualizan las posiciones de los pajaros
  flock.run();
  
  //Se dibuja la pelota en pantalla
  pelota.display();
  pelota.checkBoundaryCollision();  
}

// Agregar pajaros con un click
void mousePressed() {
  flock.addBoid(new Boid(mouseX,mouseY));
}



//Clase pelota
class Ball {
  PVector position;
  PVector velocity;
  float radius, m;
  
  //Constructor de la clase pelota
  Ball(float x, float y, float r_) {
    position = new PVector(x, y);
    velocity = PVector.random2D();
    velocity.mult(3);
    radius = r_;
    m = radius*.1;
  }
  
  //Actualizacion de la pelota  **Futura implementacion con pelota en movimiento**
  void update() {
    position.add(velocity);
  }
  
  void display() {
    noStroke();
    fill(204);
    ellipse(position.x, position.y, radius*2, radius*2);
  }
  
   //Metodo para que la pelota no colisione con la pared **Futura implementacion con pelota en movimiento**
   void checkBoundaryCollision() {
    if (position.x > width-radius) {
      position.x = width-radius;
      velocity.x *= -1;
    } else if (position.x < radius) {
      position.x = radius;
      velocity.x *= -1;
    } else if (position.y > height-radius) {
      position.y = height-radius;
      velocity.y *= -1;
    } else if (position.y < radius) {
      position.y = radius;
      velocity.y *= -1;
    }
  }
 }




// The Flock (a list of Boid objects)
class Flock {
  ArrayList<Boid> boids; // An ArrayList for all the boids

  Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList
  }

  void run() {
    for (Boid b : boids) {
      b.run(boids);  // Passing the entire list of boids to each boid individually
    }
  }

  void addBoid(Boid b) {
    boids.add(b);
  }

}




// The Boid class
class Boid {

  PVector position;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed

    Boid(float x, float y) {
      acceleration = new PVector(0, 0);
  
      // This is a new PVector method not yet implemented in JS
      // velocity = PVector.random2D();
  
      // Leaving the code temporarily this way so that this example runs in JS
      float angle = random(TWO_PI);
      velocity = new PVector(cos(angle), sin(angle));
  
      position = new PVector(x, y);
      r = 2.0;
      maxspeed = 1;
      maxforce = 0.03;
  }

  void run(ArrayList<Boid> boids) {
    flock(boids);
    update();
    borders();
    render();
  }

  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids) {
    PVector sep = separate(boids);   // Separation
    PVector ali = align(boids);      // Alignment
    PVector coh = cohesion(boids);   // Cohesion
    // Arbitrarily weight these forces
    sep.mult(1.5);
    ali.mult(1.0);
    coh.mult(1.0);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
  }

  // Method to update position
  void update() {
    // Update velocity
    velocity.add(acceleration);
    // Limit speed
    velocity.limit(maxspeed);
    position.add(velocity);
    // Reset accelertion to 0 each cycle
    acceleration.mult(0);
  }

  // A method that calculates and applies a steering force towards a target
  // STEER = DESIRED MINUS VELOCITY
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position);  // A vector pointing from the position to the target
    // Scale to maximum speed
    desired.normalize();
    desired.mult(maxspeed);

    // Above two lines of code below could be condensed with new PVector setMag() method
    // Not using this method until Processing.js catches up
    // desired.setMag(maxspeed);

    // Steering = Desired minus Velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    return steer;
  }

  void render() {
    // Draw a triangle rotated in the direction of velocity
    float theta = velocity.heading2D() + radians(90);
    // heading2D() above is now heading() but leaving old syntax until Processing.js catches up
    
    fill(200, 100);
    stroke(255);
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    beginShape(TRIANGLES);
    vertex(0, -r*2);
    vertex(-r, r*2);
    vertex(r, r*2);
    endShape();
    popMatrix();
  }

  // Wraparound
  void borders() {
    if (position.x < -r) position.x = width+r;
    if (position.y < -r) position.y = height+r;
    if (position.x > width+r) position.x = -r;
    if (position.y > height+r) position.y = -r;
  }

  // Separation
  // Method checks for nearby boids and steers away
  PVector separate (ArrayList<Boid> boids) {
    float desiredseparation = 25.0f;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    // For every boid in the system, check if it's too close
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(d);        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    // Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // steer.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < neighbordist)) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div((float)count);
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // sum.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } 
    else {
      return new PVector(0, 0);
    }
  }

  // Cohesion
  // For the average position (i.e. center) of all nearby boids, calculate steering vector towards that position
  PVector cohesion (ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all positions
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < neighbordist)) {
        sum.add(other.position); // Add position
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);  // Steer towards the position
    } 
    else {
      return new PVector(0, 0);
    }
  }
  ////////////////////////////////////////////////////////////////////////////////////////
  //Metodo que verifica si esta por colisionar con la pelota para cambiar la trayectoria//
  ////////////////////////////////////////////////////////////////////////////////////////
  void checkCollision(Ball other) {
    //Vector de distancia
    PVector distanceVect = PVector.sub(other.position, position);

    //Magnitud del vector de distancia
    float distanceVectMag = distanceVect.mag();
    float minDistance = other.radius + 10;
    
    
    //Si el pajaro esta por colosionar
    if (distanceVectMag < minDistance) {
      //Para que direccion tiene que ir si toca la pelota.
      float distanceCorrection = (minDistance-distanceVectMag)/2.0;
      PVector d = distanceVect.copy();
      PVector correctionVector = d.normalize().mult(distanceCorrection);
   
      
      position.add(correctionVector); 
      position.sub(correctionVector);
      

      //Obtiene el angulo de la trayectoria de los pajaros
      float theta  = velocity.heading2D() + radians(45);
      
      float sine = sin(theta);
      float cosine = cos(theta);

      
      PVector bTemp = new PVector();
      
      

       
      bTemp.x  = cosine * distanceVect.x + sine * distanceVect.y;
      bTemp.y  = cosine * distanceVect.y - sine * distanceVect.x;

      
      PVector vTemp = new PVector();

      vTemp.x  = cosine * velocity.x + sine * velocity.y;
      vTemp.y  = cosine * velocity.y - sine * velocity.x;
     

      PVector vFinal = new PVector();
      //Rotacion final
      float valor = 100;
      vFinal.x = valor + ((other.m) * vTemp.x + 2 * other.m * vTemp.x) / ( other.m);
      vFinal.y = valor + vTemp.y;
      
      bTemp.x += vFinal.x;

      // rotacion de los direcciones de los pajaros
      PVector bFinal = new PVector();

      bFinal.x = cosine * bTemp.x - sine * bTemp.y;
      bFinal.y = cosine * bTemp.y + sine * bTemp.x;

      // Se actualizan las velocidades de los pajaros
      velocity.x = cosine * vFinal.x - sine * vFinal.y;
      velocity.y = cosine * vFinal.y + sine * vFinal.x;
    }
  
  }
}
  
  
