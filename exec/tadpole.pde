/*-=-=-=-=-=-=-=-=-=-=-=- CLASS DEFINITION -=-=-=-=-=-=-=-=-=-=-=-*/
class Tadpole {

  PVector position;
  PVector velocity;
  PVector acceleration;
  PVector bodyCenter;
  float x, y, a, b, c, d, e, s;
  float mass;
  float bodySize;   
  float angle;
  float maxSpeed;
  float jitterSpeed;
  float huntManyRange;
  float huntOneRange;
  float maxSteer;
  float angleInit = random(TWO_PI);
  float desiredSep;
  float hunger;
  float maxHunger;
  float linger;
  float tailBodyRatio;
  float tailLength;
  float absoluteVelocity;
  float absoluteAcceleration;
  float growthFactorSize;
  float growthFactorMaxSpeed;
  float sepMult;
  float aliMult;
  float cohMult;
  float colMult;
  float maxTargetSize;
  
  int id;
  int lifeCycleStage = 0;
  int foodCount;
  int gender;
  int neighbordist;
  color bodyColor;
  int longCloseRatio;
  boolean targetAcquired;
  int[] metamorphosis = new int[3];
  Tadpole[] others; //class of others

  /*-=-=-=-=-=-=-=-=-=-=-=- CONSTRUCTOR -=-=-=-=-=-=-=-=-=-=-=-*/
  Tadpole (float x, float y, Tadpole[] oin, int i) {

    id = i;
    // Movements
    position= new PVector (x, y);
    velocity= new PVector (5*cos(angleInit), 5*sin(angleInit));
    acceleration= new PVector (0, 0);
    others = oin;
    a = random(360); //begin life at a random angle
    s = random(0.1); //this can be anywhere from 0 to 10; the lower the better, surivability wise; could pop both out into explore method

    // counters
    foodCount= 0;
    //foodCount= 0;
    hunger= 0;

    // Genome
    mass= 1;
    //longCloseRatio= 2;
    desiredSep= 200;
    linger= 2;
    tailBodyRatio= 1;
    growthFactorSize = 0.01;
    growthFactorMaxSpeed = 0.01;
    //make into array;
    metamorphosis[0] = 0;
    metamorphosis[1] = 10;
    metamorphosis[2] = 50;
    gender = round(random(0, 2));
    neighbordist = 50;
    //maxTargetSize = bodySize * 2;
    maxTargetSize = 5;

    if (gender == 0) {
      // red
      bodyColor = color(180, 50, 50);
      maxHunger= 2;
      aliMult = 0.05;
      sepMult = 1.2;
      colMult = 2.0; 
      maxSteer= 0.1;
      maxSpeed= 3.5;
      huntOneRange= 100;
      huntManyRange= 120;

    } else if (gender == 1) {
      // green
      bodyColor = color(50, 180, 50);
      maxHunger= 4;
      aliMult = 1.0;
      sepMult = 0.75;
      colMult = 1.0; 
      maxSteer= 0.08;
      maxSpeed= 3.3;
      huntOneRange= 80;
      huntManyRange= 160;

    } else {
      // blue
      bodyColor = color(50, 50, 220);
      maxHunger= 8;
      aliMult = 5.0;
      sepMult = 0.6;
      colMult = 0.5;
      maxSteer= 0.06;
      maxSpeed= 2.8;
      huntOneRange= 50;
      huntManyRange= 200;

    }
    
     // defaults
     maxSteer= 0.1;
     //maxSpeed = 2;
     huntOneRange= 100;
     huntManyRange= 150;
     //maxHunger = 10000000;

     //sepMult = 0.8; // 10 is kinda like gas molecules
     aliMult = 0.04;   // 10 is like a herd of sheep
     // how close they WANT to be
     cohMult = 0.03; // 10 they pull together, almost overlapping;
     // how forcefully they repel
     colMult = 1.0;  // 10, they bounce so violently the inner core is stuck

    // functional
    bodySize= mass*5;
    bodyCenter = new PVector(-bodySize/2, 0);
    // jitterSpeed= 0.1;
    tailLength = bodySize * -tailBodyRatio;
    
    if (spriteMode == true){
      maxHunger = 10000000;
      //maxSpeed= 0;
    }

  }

  void display() {
    angle = velocity.heading();
    pushMatrix();
      translate(position.x, position.y);
      rotate(angle);
      lifeStage();
    popMatrix();
  }

  void run(ArrayList<Tadpole> tadpoles) {
   if (hunger < maxHunger) {
      swarm(tadpoles);
      update();
      checkEdgesAlive();
      display(); 
      if (spriteMode == false){
        wander();
      }
      huntMany();
      huntOne();
      eat();
    }
  }  
  
  void update() {
    if (lifeCycleStage == 2){
     
    } else {
      absoluteAcceleration = abs(acceleration.x + acceleration.y);

      velocity.add(acceleration);
      absoluteVelocity = abs(velocity.x + velocity.y);

      velocity.limit(maxSpeed);

      position.add(velocity);

      a += absoluteVelocity/2;

      if (abs(velocity.x) > 0.0) {
        velocity.x *= 0.99;
      } 

      if (abs(velocity.y) > 0.0) {
        velocity.y *= 0.99;
      } 
    }

  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }

  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position);
    desired.normalize();
    desired.mult(3);

    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxSteer);
    return steer;
  }

  void wander() {
    //s -- range from 0.1 to about 1, using random makes the paths more exploratory seeing
    acceleration= PVector.random2D();
    acceleration.mult(jitterSpeed);
  }

  void huntOne() {
    targetAcquired= false;
    PVector dir;
    PVector target;

    for (int i=0; i<foods.length; i++) {
      
      // if going after same target, pick new one
      target = new PVector(foods[i].position.x, foods[i].position.y);
      dir = PVector.sub(target, position);
      dir.normalize();

      if (canTargetFood(foods[i]) && targetAcquired==false/*&& foods[i].beingChased==false*/) { 
        targetAcquired = true;
        foods[i].beingChasedBy = id;
        acceleration = dir;

        if (debugOne == true) {
          strokeWeight(1);
          stroke(bodyColor);
          line(position.x, position.y, foods[i].position.x, foods[i].position.y);
        }
      }
    }
  }

  void huntMany() {
    PVector dir;
    PVector food;

    for (int i=0; i<foods.length; i++) {
      food = new PVector (foods[i].position.x, foods[i].position.y);
      dir = PVector.sub(food, position);
      dir.normalize();
      dir.mult(0.2);

      if (canTargetFood(foods[i])) {
        acceleration = dir;

         if (debugMany == true) {
           strokeWeight(0.2);
           stroke(0, 0, 0);
           line(position.x, position.y, foods[i].position.x, foods[i].position.y);
         }
      }
    }
  }

  boolean canTargetFood(Food food){
    return ( (foodIsSmallEnough(food) && foodIsWithinRange("long", food)) && food.position.y > 0 );
  }
  
  boolean foodIsSmallEnough(Food food){
    return food.bodySize < maxTargetSize;
  }
  
  boolean foodIsWithinRange(String rangeType, Food food){
    if (rangeType == "eat") {
      return dist(
        position.x, 
        position.y, 
        food.position.x, 
        food.position.y
       ) < bodySize / 2;

    } else if (rangeType == "close") {
      return dist(
        position.x, 
        position.y, 
        food.position.x, 
        food.position.y
       ) < huntOneRange / 2;
       
    } else if (rangeType == "long") {
      return dist(
        position.x, 
        position.y, 
        food.position.x, 
        food.position.y
      ) < huntManyRange / 2;

    } else {
       return false; 
    }

  }

  //boolean deadFromStarvation(){
  // }

  //void metabolize(){
  //}

  void lifeStage() {
    b = sin(a);
    c = cos(a/10);
    d = sin(a/10);

    if (foodCount > metamorphosis[2]) {
      lifeCycleStage = 2;
      stageThree();

    } else if (between(foodCount, metamorphosis[1], metamorphosis[2])) {
      lifeCycleStage = 1;
      stageTwo();
      
    } else if (between(foodCount, metamorphosis[0], metamorphosis[1])) { //
      lifeCycleStage = 0;
      stageOne();
    }
  }

  void stageThree() {
    jitterSpeed = 0.0;
    acceleration.x = 0;
    acceleration.y = 0;
    velocity.x = 0;
    velocity.y = 0;
 
    strokeWeight(bodySize/10);
    stroke(0, 0, 0);

    pushMatrix();
      rotate(-angle);
      line(0, 0, -10, 7);
      line(0, 0, 10, 7);
    popMatrix();
    fill(bodyColor);
    pushMatrix();
      rotate(radians(15));
      arc(0, 0, bodySize*3, bodySize*3, 0, radians(330), PIE);
    popMatrix();
    fill(100);
    ellipse(0, 0, 1, 1);


  }

  void stageTwo() {
    jitterSpeed = 0.08;
    noFill();  
    PVector startpoint = new PVector(round(bodyCenter.x -3), round(bodyCenter.y));
    float v = 3 + absoluteVelocity;
    PVector endpoint1 =   new PVector(-v * 3, -8*d);
    PVector endpoint2 =   new PVector(-v * 3, 8*d );

    // top curve    
    float m = 2;
    float n = 10;
    
    float flagAngle = PI/ 5;
    
    PVector tc1 = new PVector(-12, m *d);
    PVector tc2 = new PVector(-12, -n *c);
    strokeWeight(0.3);
    stroke(0, 0, 0);
    pushMatrix();
      translate(0, 2);
      rotate(flagAngle);
      bezier(
        startpoint.x, startpoint.y,
        tc1.x, tc1.y,
        tc2.x, tc2.y, 
        endpoint1.x, endpoint1.y
      );
      if (showBodyLines == true){
        stroke(102, 255, 0);
        strokeWeight(0.5);
        line(startpoint.x, startpoint.y, tc1.x, tc1.y);
        line(endpoint1.x, endpoint1.y, tc2.x, tc2.y);
      }
    popMatrix();

    // bottom curve
    PVector bc1 = new PVector(tc1.x, -m *d);
    PVector bc2 = new PVector(tc2.x, n *c);
      pushMatrix();
        translate(0, -2);
        rotate(-flagAngle);
        bezier(
          startpoint.x, startpoint.y,
          bc1.x, bc1.y,
          bc2.x, bc2.y, 
          endpoint2.x, endpoint2.y
        );
        if (showBodyLines == true){
          stroke(255, 102, 0);
          strokeWeight(0.5);
          line(startpoint.x, startpoint.y, bc1.x, bc1.y);
          line(endpoint2.x, endpoint2.y, bc2.x, bc2.y);
        }
      popMatrix();

    strokeWeight(0.2);  
    stroke(220, 220, 0);
    fill(bodyColor);
    ellipse(0, 0, bodySize*2, bodySize);
    
  }
  
  void stageOne() {
    jitterSpeed = 1.5;
    noStroke();
    fill(bodyColor);
    ellipse(0, 0, bodySize, bodySize);
    strokeWeight(bodySize/10);
    stroke(0, 0, 0);
    pushMatrix();
      translate(0, 0);
      rotate( ( (b + (PI/4)) /5 ) *absoluteVelocity );
      line(
        bodyCenter.x+3, 
        bodyCenter.y, 
        (tailLength - absoluteVelocity)/2, 
        absoluteVelocity
      );
    popMatrix(); 
  }
  
  void grow() {
    bodySize += growthFactorSize;
    maxSpeed += growthFactorMaxSpeed;
  }

  void eat() { 
    hunger+=0.01; 

    for (int i=0; i<foods.length; i++) {
      if (foodIsWithinRange("eat", foods[i])) {
        // handle elsewhere, some other way //
        //////////////////////////////////////
        foods[i].position.y = random(height * 2); 
        foods[i].position.x = random(width * 2-20) + 10;
        //////////////////////////////////////
        // maturity?
        foodCount++;
        // satiety (needs to be sufficiently high to mate)
        hunger -= foods[i].mass;
        grow();
      }
    }
  }

  /*-=-=-=-=-=-=-=-=-=-=-=- CONSTRAINT METHODS -=-=-=-=-=-=-=-=-=-=-=-*/
  // replace with force appliers, ideally

  void checkEdgesAlive() {

    if (position.x < 0) {
      position.x= width * containerScale-1;
    } else if (position.x > width * containerScale) {
      position.x= 1;
    }

    if (position.y < 0) {
      position.y=1;
      velocity.y*=-0.8; 
    } else if (position.y > height * containerScale) {
      position.y=height * containerScale-1; 
      velocity.y*=-0.8;
    }

  }

  /*-=-=-=-=-=-=-=-=-=-=-=- SWARM METHODS -=-=-=-=-=-=-=-=-=-=-=-*/
  PVector collide (ArrayList<Tadpole> tadpoles) {
    PVector steer= new PVector (0, 0);

    for (Tadpole other : tadpoles) {
      float d = PVector.dist(position, other.position);
      float m = bodySize/2 + other.bodySize/2;

      if (d < m) { 
        PVector diff= PVector.sub(position, other.position);
        diff.normalize();
        steer.add(diff);

        if (steer.mag() > 0) {
          steer.normalize();
          steer.mult(0.2);
          steer.sub(velocity);
        }
      }
    }

    return steer;
  }

  PVector seperate (ArrayList<Tadpole> tadpoles) {
    float desiredseperation = desiredSep;
    PVector steer = new PVector(0, 0);
    int count = 0;

    for (Tadpole other : tadpoles) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < desiredseperation)) {
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(d);
        steer.add(diff);
        count++;
      }
    }
    
    if (count > 0) {
      steer.div((float)count);
    }

    if (steer.mag() > 0) {  
      steer.normalize();
      steer.mult(1);
      steer.sub(velocity);
      steer.limit(maxSteer);
    }

    return steer;
  }

  PVector align (ArrayList<Tadpole>tadpoles) {
    // float neighbordist = 50;
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Tadpole other : tadpoles) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && d < neighbordist) {
        sum.add(other.velocity);
        count++;
      }
    }

    if (count > 0) {
      sum.div((float)count); 
      sum.normalize();
      sum.mult(1);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxSteer);
      return steer;
    } else {
      return new PVector(0, 0);
    }
  }     

  PVector cohesion(ArrayList<Tadpole> tadpoles) {
    // float neighbordist = 50;
    PVector sum = new PVector(0, 0); 
    int count = 0;

    for (Tadpole other : tadpoles) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < neighbordist)) {
        sum.add(other.position);
        count++;
      }
    }

    if (count > 0) {
      sum.div(count);
      return seek(sum);
    } else {
      return new PVector (0, 0);
    }
  }
  
  void swarm(ArrayList<Tadpole> tadpoles) {
    PVector sep = seperate(tadpoles);
    PVector ali = align(tadpoles);
    PVector coh = cohesion(tadpoles);
    PVector col = collide(tadpoles);

    sep.mult(sepMult);
    ali.mult(aliMult);
    coh.mult(cohMult);
    col.mult(colMult);

    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
    applyForce(col);
  }

  /*-=-=-=-=-=-=-=-=-=-=-=- HELPER METHODS -=-=-=-=-=-=-=-=-=-=-=*/
  boolean between(int v, int start, int end) {
    return (v >= start && v < end);
  }

  void vectorLine(PVector start, PVector end) {
    line(start.x, start.y, end.x, end.y);
  }

}
