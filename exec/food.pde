class Food {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float maxSpeed;
  float initMaxSpeed;
  float mass;
  float bodySize;
  float spoilTimer;
  int beingChasedBy;
  
  Food(float x, float y, float imass) {
    position = new PVector (x, y);
    velocity = new PVector (0, 0);
    acceleration = new PVector(0, 0);
    mass= imass;
    bodySize= 1+ mass/3;
    initMaxSpeed = bodySize-1; 
    maxSpeed = initMaxSpeed;
    spoilTimer = mass*2;
    beingChasedBy = -1;
  }

  void display() {
    noStroke();
    fill(100, 0, 0);
    //textSize(spoilTimer*2 +5);
    //text(spoilTimer,position.x,position.y);
    ellipse(position.x, position.y, bodySize, bodySize);
    //println(beingChasedBy);
  }

  void update() {
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);
    acceleration.mult(1);
  }

  void applyForce(PVector force) {
    PVector f = PVector.div(force, mass);
    acceleration.add(f);
  }

  void jitter() {
    PVector jitter;
    jitter= PVector.random2D();
    jitter.mult(4/bodySize);
    acceleration.add(jitter);
  }

  void checkEdges() {
    if (position.y > height * containerScale) {
      position.y = 0;
    }
  }

  void respawn() {
    if (position.x < 0){
      position.x = width * containerScale;
    } else if (position.x > width * containerScale){
      position.x= 0;
    }
    
    if (position.y < 0 || position.y > height * containerScale){
     position.y= random(width * containerScale);
    }
  }
}

void setupFoods(){
  for (int i = 0; i<foods.length; i++) {
    foods[i] = new Food(width * 2/2, 1, random(1,5));
  }
}
