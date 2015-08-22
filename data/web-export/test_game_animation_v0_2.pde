//changing to add animation/art styles

static int RESTING = 0;
static int MOVING = 1;
static int WINNING = 2;
static float MAXSPEED = 0.95;

static int DIR_NONE = 0;
static int DIR_RIGHT = 1;
static int DIR_LEFT = 2;
static int DIR_DOWN = 3;
static int DIR_UP = 4;

static int SQUARESIZE = 50;
static int SCREEN_W = 800;
static int SCREEN_H = 800;

PImage playerImg;
PImage boxImg;
PImage crateImg;
PImage exitImg;
PGraphics pg;
static float HOVERCO = 3;
int eyeState = 1;
int mouthState = 1;

float timeNow = 0.0;
float timeLast = 0.0;
int frameNow = 0;
int frameLast = 0;
int frameChange = 0;
float millisPerFrame = 80;

float playerX = 0;
float playerY = 0;
float playerXWas = 0;
float playerYWas = 0;
float playerSpeed = 0.0;
int playerDir = DIR_NONE;
float playerAcc = 0.25;
int playerState = RESTING; // 0 = rest, 1 = moving, 2 = colliding
int playerFrame = 0; // which frame
int destX = 0;
int destY = 0;

int[][] map = new int[SCREEN_W/SQUARESIZE][SCREEN_H/SQUARESIZE]; //2D array of open vs. blocked squares

void setup(){
  size(800,800);
  pg = createGraphics(width, height); //create graphics buffer
  background(0,0,0);
  initializeMap();
  playerImg = loadImage("version03.png"); //load image files
  crateImg = loadImage("crate.png");
  boxImg = loadImage("box.png");
  exitImg = loadImage("exit.png");
  smooth();
}

void draw() {
  updateTime();
  updatePlayer();
  render();
}

void updateTime() {
  timeLast = timeNow;
  timeNow = millis();
  frameLast = frameNow;
  frameNow = int(timeNow/millisPerFrame);
  frameChange = frameNow - frameLast;
}

void getInput(){
  if(keyPressed == true) // && playerMoving == false)
  {
      if(keyCode == RIGHT){  playerState = MOVING; playerDir = DIR_RIGHT; setDest(); }
      if(keyCode == LEFT) {  playerState = MOVING; playerDir = DIR_LEFT; setDest(); }
      if(keyCode == DOWN) {  playerState = MOVING; playerDir = DIR_DOWN; setDest(); }
      if(keyCode == UP)   {  playerState = MOVING; playerDir = DIR_UP; setDest(); }
  }
}

//updates player position and state
void updatePlayer(){
  if(playerState == MOVING){
    movePlayer();
    if(playerBlocked())
    {
      if(playerSpeed == MAXSPEED) {  
        //playerState = COLLIDING;
        playerState = RESTING; //it will eventually be colliding, once we've worked out our animation system.
        playerDir = DIR_NONE; 
      }
      else
      {  playerState = RESTING;
         playerDir = DIR_NONE;  } //if we don't need to do a collision animation, just set dir to 0
      playerSpeed = 0.0;
    }
  }
  else {
    getInput();
  }
}

boolean playerBlocked()
{
  if(playerDir == DIR_RIGHT) 
  {  if(playerX >= destX)  {  playerX = destX; return true;  }  }
  else if(playerDir == DIR_LEFT)
  {  if(playerX <= destX) {  playerX = destX; return true;  }  }
  else if(playerDir == DIR_DOWN)
  {  if(playerY >= destY) {  playerY = destY; return true;  }  }
  else if(playerDir == DIR_UP)
  {  if(playerY <= destY) {  playerY = destY; return true;  }  }
  return false;
}


//changes speed and position of character according to acceleration, max speed
void movePlayer()
{
  playerXWas = playerX;
  playerYWas = playerY;
  playerSpeed += playerAcc;
  if(playerDir == DIR_RIGHT) { playerX += playerSpeed; }
  else if(playerDir == DIR_LEFT) { playerX -= playerSpeed; }
  else if(playerDir == DIR_DOWN) { playerY += playerSpeed; }
  else if(playerDir == DIR_UP) { playerY -= playerSpeed; }
}

void setDest()
{ 
  destX = int(playerX);
  destY = int(playerY);
  if(playerDir == DIR_RIGHT) {
    while(destX + 1 < SCREEN_W/SQUARESIZE && map[destX+1][destY] < 1 && map[destX][destY] != -1) {  destX++;  }
  } //right
  else if(playerDir == DIR_LEFT) {
    while(destX > 0 && map[destX-1][destY] < 1 && map[destX][destY] != -1) {  destX--;  }
  } //left
  else if(playerDir == DIR_DOWN) {
    while(destY + 1 < SCREEN_H/SQUARESIZE && map[destX][destY+1] < 1 && map[destX][destY] != -1) {  destY++;  } 
  } //down
  else if(playerDir == DIR_UP) {
    while(destY > 0 && map[destX][destY-1] < 1 && map[destX][destY] != -1) {  destY--;  } 
  } //down
}

//randomly generate 0's and 1's to represent open and closed spaces, place character.
void initializeMap() {
  for(int i = 0; i < (SCREEN_W/SQUARESIZE); i++){
    for(int j = 0; j < SCREEN_H/SQUARESIZE; j++){
      map[i][j] = int(random(0,1.33));
      if(map[i][j] == 1)
      {  map[i][j] = int(random(1,3));  }
    }
  }
  map[int(random(SCREEN_W/SQUARESIZE))][int(random(SCREEN_H/SQUARESIZE))] = -1;
  playerX = 10; //initialize player on an open space.
  playerY = 5;
  map[10][5] = 0;
}

void drawMap(){
  pg.fill(0,0,0);
  for(int i = 0; i < (SCREEN_W/SQUARESIZE); i++){
    for(int j = 0; j < SCREEN_H/SQUARESIZE; j++){
      if(map[i][j] == 1) {
        pg.image(crateImg, i*SQUARESIZE, j*SQUARESIZE, SQUARESIZE, SQUARESIZE);
      }
      else if(map[i][j] == 2) {
        pg.image(crateImg, i*SQUARESIZE, j*SQUARESIZE, SQUARESIZE, SQUARESIZE);
      }
      else if(map[i][j] == -1) {
        PImage exitFrame = exitImg.get((int(HOVERCO * sin(frameNow*0.4)) + 2) * 50, 0, 50, 50); 
        pg.image(exitFrame, i*SQUARESIZE, j*SQUARESIZE, SQUARESIZE, SQUARESIZE);
      }
    }
  }
}

void drawPlayer(){
  int hoverOffset = int(HOVERCO * sin(frameNow*0.4)); 
  PImage bodyFrame = playerImg.get(playerDir * 50, 0, 50, 50);
  if(playerState == MOVING) {eyeState = playerDir; }
  else if(eyeState == 0) {eyeState = int(random(5));   }
  else if(random(30) < 1) {eyeState = 0;  }
  if(mouthState == 0) { mouthState = int(random(5));  }
  else if(random(20) < 1) { mouthState = int(random(5));  }
  PImage eyeFrame = playerImg.get(eyeState * 50, 100, 50, 50);
  PImage mouthFrame = playerImg.get(mouthState * 50, 50, 50, 50);
  pg.image(bodyFrame, playerX*SQUARESIZE, playerY*SQUARESIZE + hoverOffset, SQUARESIZE, SQUARESIZE);
  pg.image(eyeFrame, playerX*SQUARESIZE, playerY*SQUARESIZE + hoverOffset, SQUARESIZE, SQUARESIZE);
  pg.image(mouthFrame, playerX*SQUARESIZE, playerY*SQUARESIZE + hoverOffset, SQUARESIZE, SQUARESIZE);

}

void render(){
  if(frameChange > 0){
    pg.beginDraw();
    pg.background(44,35,74,150);
    drawMap();
    drawPlayer();
    pg.endDraw();
    image(pg,0,0);
  }
}

