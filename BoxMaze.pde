
// <copyright file="BoxMaze.pde">
// Copyright (c) 2015 All Right Reserved, http://boxmazegame.com/
//
// </copyright>
// <author>Andrew Albers</author>
// <email>andrew.albers@gmail.com</email>
// <date>2015-08-22</date>
// <summary>Contains Processing code for Box Maze Game</summary>

interface JavaScript {
  void playBlast();
  void playBlastCrate();
  void playSwish();
  void playMusic();
}

void bindJavascript(Javascript js) {
  javascript = js;
}

Javascript javascript;

static int ACT_ID_CHANGED = 0;
static int MOVING = 1;
static int WINNING = 2;
static int NUMBLOCKS = 85;
boolean action_id_changed = false;
boolean background_created = false;

boolean game_is_beginning = true;
boolean main_menu_on = true;

static int GOAL_INDEX = 0;
static int PLAYER_INDEX = 1;

static int NONE = -3;
static int OUT_OF_BOUNDS = -2;
static int BLK_EMPTY = -1;
static int BLK_GOAL = 0;
static int BLK_PLAYER = 1;
static int BLK_MOVER = 2;
static int BLK_TNT = 3;
static int BLK_WOOD = 4;
static int BLK_METAL = 5;

static int DIR_NONE = 0;
static int DIR_RIGHT = 1;
static int DIR_LEFT = 2;
static int DIR_DOWN = 3;
static int DIR_UP = 4;

static int SQUARESIZE = 50;
static int SCREEN_W = 1000;
static int SCREEN_H = 650;

static int INDEX_X = 0;
static int INDEX_Y = 1;
static int INDEX_TYPE = 2;
static int INDEX_BODY = 0;
static int INDEX_MOUTH = 1;
static int INDEX_EYES = 2;
static int INDEX_TIMER = 3;

PImage backgroundImg;
PImage playerImg;
PImage metalCrateImg;
PImage crateImg;
PImage tntImg;
PImage moverImg;
PImage explodeImg;
PImage exitImg;
PImage bodyFrame;
PImage eyeFrame;
PImage mouthFrame;

PImage mainMenu;
PImage winMenu;

PGraphics pg;
static float HOVERCO = 3;

float timeNow = 0.0;
float timeLast = 0.0;
int frameNow = 0;
int frameLast = 0;
int frameChange = 0;
float millisPerFrame = 30;

int lastMusicUpdate = -30000;

int actionId = NONE;
float playerSpeed = 0.0;
int moveDir = DIR_NONE;
float playerAcc = 0.25;
int gameState = ACT_ID_CHANGED; // 0 = rest, 1 = moving, 2 = colliding
int playerFrame = 0; // which frame
int destX = 0;
int destY = 0;

int[] numBlockTypes = {1, 1, 10, 15, 30};
float[][] blocks = new float[NUMBLOCKS][3]; //x, y, type, body state, mouth state, eye state
int[][] blockState = new int[NUMBLOCKS][4]; //body, mouth, eyes, timer 
int[][] gameMap = new int[SCREEN_W/SQUARESIZE][SCREEN_H/SQUARESIZE]; //2D array of open vs. blocked squares

void setup(){
  size(1000,650);
  pg = createGraphics(width, height); //create graphics buffer
  background(0,0,0);
  initializeGameMap();
  playerImg = loadImage("version03.png"); //load image files
  crateImg = loadImage("crate.png");
  tntImg = loadImage("tntcrate.png");
  explodeImg = loadImage("crateexplode.png");
  metalCrateImg = loadImage("metalcrate.png");
  moverImg = loadImage("movermovewhite.png");
  exitImg = loadImage("exit.png");
  mainMenu = loadImage("main_menu.png");
  winMenu = loadImage("win_menu.png");
  smooth();
}

void draw() {
  updateTime();
  updateRenderStates();
  updateGame();
  updateMusic();
  render();
}

void updateTime() {
  timeLast = timeNow;
  timeNow = millis();
  frameLast = frameNow;
  frameNow = int(timeNow/millisPerFrame);
  frameChange = frameNow - frameLast;
}

void keyPressed()
{
  if(actionId == NONE && gameState != WINNING && main_menu_on == false)
  {
    if(keyCode == RIGHT){  moveDir = DIR_RIGHT; initializeAction(PLAYER_INDEX); }
    else if(keyCode == LEFT) {  moveDir = DIR_LEFT; initializeAction(PLAYER_INDEX); }
    else if(keyCode == DOWN) {  moveDir = DIR_DOWN; initializeAction(PLAYER_INDEX); }
    else if(keyCode == UP)   {  moveDir = DIR_UP; initializeAction(PLAYER_INDEX); }
    else changeBlocks();
  }
  if(key == 'r' || key == 'R')  {initializeGameMap();  }
  if(key == ' ' || key == 'h' || key == 'H') {toggleMainMenu();}
}

void toggleMainMenu() {
  if (main_menu_on) {
    main_menu_on = false;
  } else {
    main_menu_on = true;
  }
}

void toggleGameBeginning() {
  if (game_is_beginning){
    game_is_beginning = false;
  }
}

void changeBlocks()
{
  if(key == 'm')  {
    if(numBlockTypes[BLK_MOVER] > 0){  numBlockTypes[BLK_MOVER] -= 1;  }
  }
  else if(key == 'M') {
    if(isBlocksAvailable()) { numBlockTypes[BLK_MOVER] += 1;  }
  }
  else if(key == 'w') {
    if(numBlockTypes[BLK_WOOD] > 0) { numBlockTypes[BLK_WOOD] -= 1;  }
  }
  else if(key == 'W') {
    if(isBlocksAvailable()) { numBlockTypes[BLK_WOOD] += 1;  }
  }
  else if(key == 't') {
    if(numBlockTypes[BLK_TNT] > 0) { numBlockTypes[BLK_TNT] -= 1;  }
  }
  else if(key == 'T') {
    if(isBlocksAvailable()) {numBlockTypes[BLK_TNT] += 1;  }
  }
}

void updateMusic()
{
  if (javascript != null && timeNow - lastMusicUpdate >= 28450)
  {
    lastMusicUpdate = timeNow;
    javascript.playMusic();
  }
}

boolean isBlocksAvailable()
{
  int total = 0;
  for(int i = 0; i < BLK_METAL; i++) //assumes that BLK_METAL is beyond the last index of the numBlockTypes array
  {  total += numBlockTypes[i];  }
  if(total >= 75) {return false;}
  else {return true;}
}

//updates player position and state
void updateGame(){
  if(gameState != WINNING)
  {
    if(actionId != NONE)                    // if a block is still acting, do next step of action
    {
      doAction();
    }
    else                                    // otherwise, set direction and playerSpeed to NONE
    {
      moveDir = DIR_NONE;
      playerSpeed = 0.0;
    }
  }
  else
  {
    moveDir = DIR_NONE;
    playerSpeed = 0.0;
    actionId = NONE;
  }
}

void updateRenderStates()
{
  if(action_id_changed)
  {
    if(gameState == WINNING)                          //if player just won, set body to winning state and return flag to false
    {  blockState[PLAYER_INDEX][INDEX_BODY] = 5;
       blockState[PLAYER_INDEX][INDEX_MOUTH] = int(random(5,8));
       action_id_changed = false;          
    }
    else if(actionId == PLAYER_INDEX)
    {
      blockState[actionId][INDEX_EYES] = moveDir;
      blockState[actionId][INDEX_MOUTH] = 0;
      blockState[actionId][INDEX_BODY] = moveDir;
    }
  }
  if(actionId != PLAYER_INDEX && actionId != NONE)
  {  blockState[actionId][INDEX_EYES] = int(random(2,5)); 
     blockState[actionId][INDEX_MOUTH] = 4; 
     blockState[actionId][INDEX_BODY] = moveDir; 
     blockState[actionId][INDEX_TIMER] = 10;
  }
}

//calls correct action function based on the type of the action block
void doAction()
{
  int type = int(blocks[actionId][INDEX_TYPE]);
  if(type == BLK_MOVER || type == BLK_PLAYER)  {  doMoveAction();  }
  else if(type == BLK_TNT)  { doExplodeAction();  }
}

void doMoveAction()
{
  movePlayer();
  int blockerId = playerBlocked();
  if(blockerId != NONE)
  {
    if(blockerId == OUT_OF_BOUNDS || blockerId == BLK_EMPTY) 
    {  finalizeAction();  }                        // finalize but do not set a new action Id if not stopped by a block
    else           
    { changeActionId(blockerId); }                   // otherwise, set actionId to blocker
  }
}

void doExplodeAction()
{
  explode(actionId, 4);
  finalizeAction();
}

void explode(int id, int startFrame)
{
  if (javascript != null) {
    javascript.playBlast();
  }
  uproot(id);
  int targetId;
  for(int i = int(blocks[id][INDEX_X]) - 1; i <= int(blocks[id][INDEX_X]) + 1; i++)
  {
    for(int j = int(blocks[id][INDEX_Y]) - 1; j <= int(blocks[id][INDEX_Y]) + 1; j++)
    {
      targetId = getIdAtXY(i,j);
      if(targetId != id && targetId != OUT_OF_BOUNDS && targetId != BLK_EMPTY)
      {
        if(blocks[targetId][INDEX_TYPE] == BLK_TNT)
        {  
          explode(targetId, startFrame + 1);
        }
        else if(blocks[targetId][INDEX_TYPE] == BLK_WOOD)
        {
          if (javascript != null) {
            javascript.playBlastCrate();
           }
          uproot(targetId);
          destroy(targetId, startFrame + 2);
        }
      }
    }
  }
  destroy(id,startFrame);
}

void destroy(int id, int startFrame)
{
  blockState[id][INDEX_TIMER] = startFrame;
}

void eraseBlock(int id)
{
  blocks[id][INDEX_TYPE] = BLK_EMPTY;
  blockState[id][INDEX_TIMER] = -1;
}

void changeActionId(int id)
{
  finalizeAction();  //finalize last action block's action, call downroot for moving blocks
  initializeAction(id);
}

/* Uproots moving blocks and sets actionId to new action block if type has an action to perform */
void initializeAction(int id)
{
  actionId = id;                                                                  // start by assuming we are changing actionId to new action block
  if(blocks[id][INDEX_TYPE] == BLK_MOVER || blocks[id][INDEX_TYPE] == BLK_PLAYER) // if block type is a mover, uproot it and set new destination.
  {  
     uproot(actionId);
     setDest();
     if(javascript != null){
       javascript.playSwish();
     }
   }
  else if(blocks[id][INDEX_TYPE] == BLK_TNT)
  { }
  else
  {  actionId = NONE;  }                                                          // if block type is not any of those, set actionId to NONE.
  action_id_changed = true;                                                  // set flag to indicate a change
}

/* Downroots moving blocks and sets actionId = NONE */
void finalizeAction()
{
  if(actionId != NONE)
  {
    if(blocks[actionId][INDEX_TYPE] == BLK_MOVER || blocks[actionId][INDEX_TYPE] == BLK_PLAYER)
    {  downroot(actionId);  }
    actionId = NONE;
  }
}

/*returns id of blocking block if action block has passed its destination and sets action block to last legal position
  TODO: make this a simpler function. Not sure how yet, but I'm pretty sure it's possible. */
int playerBlocked()
{ 
  if(moveDir == DIR_RIGHT)
  {  
    if(blocks[actionId][INDEX_X] >= destX)       // if action block has passed its destination
    { 
      blocks[actionId][INDEX_X] = destX;         // set action block to last legal position
      if(destX + 1 > gameMap.length - 1)
      {  return OUT_OF_BOUNDS;  }                // if blocking block is out of range, return OUT_OF_BOUNDS code
      else
      {  return gameMap[destX + 1][destY];  }    // else return id of blocking block
    }  
  }
  else if(moveDir == DIR_LEFT)
  {  
    if(blocks[actionId][INDEX_X] <= destX) 
    {  
      blocks[actionId][INDEX_X] = destX;
      if(destX - 1 < 0)
      {  return OUT_OF_BOUNDS;  }
      else
      {  return gameMap[destX - 1][destY];  }  
    }  
  }
  else if(moveDir == DIR_DOWN)
  {  
    if(blocks[actionId][INDEX_Y] >= destY) 
    {
      blocks[actionId][INDEX_Y] = destY;
      if(destY + 1 > gameMap[destX].length - 1)
      {  return OUT_OF_BOUNDS;  }
      else
      {  return gameMap[destX][destY + 1];  }
    }
  }
  else if(moveDir == DIR_UP)
  {
    if(blocks[actionId][INDEX_Y] <= destY) 
    {  
      blocks[actionId][INDEX_Y] = destY;
      if(destY - 1 < 0)
      {  return OUT_OF_BOUNDS;  }
      else
      {  return gameMap[destX][destY - 1];  }  
    }  
  }
  return NONE;                                     //return NONE if action block is not blocked
}

int getIdAtXY(int x, int y)
{
  if(x >= 0 && y >= 0 && x < gameMap.length && y < gameMap[x].length)
  {
    return gameMap[x][y];
  }
  else
  {
    return OUT_OF_BOUNDS;
  }
}

/* Changes speed and position of character according to acceleration */
void movePlayer()
{
  playerSpeed += playerAcc;
  if(moveDir == DIR_RIGHT) { blocks[actionId][INDEX_X] += playerSpeed; }
  else if(moveDir == DIR_LEFT) { blocks[actionId][INDEX_X] -= playerSpeed; }
  else if(moveDir == DIR_DOWN) { blocks[actionId][INDEX_Y] += playerSpeed; }
  else if(moveDir == DIR_UP) { blocks[actionId][INDEX_Y] -= playerSpeed; }
}

/* Remove footprint on gameMap for block at index */
void uproot(int index)
{
  if(int(blocks[GOAL_INDEX][INDEX_X]) == int(blocks[index][INDEX_X]) && int(blocks[GOAL_INDEX][INDEX_Y]) == int(blocks[index][INDEX_Y]))
  {
    gameMap[int(blocks[index][INDEX_X])][int(blocks[index][INDEX_Y])] = BLK_GOAL;          // if action block is on goal, replace goal
  }
  else
  {
    gameMap[int(blocks[index][INDEX_X])][int(blocks[index][INDEX_Y])] = BLK_EMPTY;         // otherwise, set footprint to empty
  }
}

/* Place footprint on gameMap for block at index */
void downroot(int index)
{
  if(index != PLAYER_INDEX || gameMap[int(blocks[index][INDEX_X])][int(blocks[index][INDEX_Y])] != BLK_GOAL)
  {
    gameMap[int(blocks[index][INDEX_X])][int(blocks[index][INDEX_Y])] = index;
  }
  else
  {
    setWinCondition();
  }
}

void setWinCondition()
{
  gameState = WINNING;
}

void setDest()
{ 
  destX = int(blocks[actionId][INDEX_X]);
  destY = int(blocks[actionId][INDEX_Y]);
  
  int yDif = 0;
  int xDif = 0;
  int nextBlockType;
  if(moveDir == DIR_RIGHT) { xDif = 1; }
  else if(moveDir == DIR_LEFT) { xDif = -1; }
  else if(moveDir == DIR_DOWN) { yDif = 1; }
  else if(moveDir == DIR_UP) { yDif = -1; }
  
  nextBlockType = getBlockType(destX + xDif, destY + yDif);
  while(nextBlockType == BLK_EMPTY || nextBlockType == BLK_GOAL && getBlockType(destX - xDif,destY - yDif) != BLK_GOAL) 
  {
    if(getBlockType(destX, destY) == BLK_GOAL && actionId == PLAYER_INDEX)
    {
      break;
    }
    else
    {
      destX += xDif; 
      destY += yDif;
      nextBlockType = getBlockType(destX + xDif, destY + yDif); 
    }
  }
}

int getBlockType(int posX, int posY)
{
  if(posX < SCREEN_W/SQUARESIZE && posX >= 0 && posY < SCREEN_H/SQUARESIZE && posY >= 0)
  {
    if(gameMap[posX][posY] == BLK_EMPTY)
    {
      return BLK_EMPTY;
    }
    else
    {
      return int(blocks[gameMap[posX][posY]][INDEX_TYPE]); //return the block type of the block with the index at that location
    }
  }
  else
  {
    return OUT_OF_BOUNDS; //return invalid if block is outside of range
  }
}

//randomly generate 0's and 1's to represent open and closed spaces, place character.
void initializeGameMap() {
  gameState = ACT_ID_CHANGED;
  actionId = NONE;
  
  //initialize all squares to BLK_EMPTY
  for(int i = 0; i < (SCREEN_W/SQUARESIZE); i++){ 
    for(int j = 0; j < SCREEN_H/SQUARESIZE; j++){
      gameMap[i][j] = BLK_EMPTY;
    }
  }
  
  int type;
  //populate all blocks randomly except first two, reserved for goal and player positions
  for(int k = 0; k < NUMBLOCKS; k++)
  {
    if(k == PLAYER_INDEX) {  type = BLK_PLAYER;  }
    else if(k == GOAL_INDEX) { type = BLK_GOAL;  }
    else if(k < numBlockTypes[BLK_MOVER] + 2) { type = BLK_MOVER;  }
    else if(k < numBlockTypes[BLK_MOVER] + numBlockTypes[BLK_WOOD] + 2) { type = BLK_WOOD; }
    else if(k < numBlockTypes[BLK_MOVER] + numBlockTypes[BLK_WOOD] + numBlockTypes[BLK_TNT] + 2) { type = BLK_TNT;  }
    else {  type = BLK_METAL;  }
    placeBlock(k, type);
  }
}

void placeBlock(int index, int type)
{
  boolean isPlaced = false;
  while(isPlaced != true)
  {
    int placeX = int(random(SCREEN_W/SQUARESIZE));
    int placeY = int(random(SCREEN_H/SQUARESIZE));
    
    if(gameMap[placeX][placeY] == BLK_EMPTY)
    {
      gameMap[placeX][placeY] = index; //set gameMap[x][y] to the index of the block information in blocks[]
      blocks[index][INDEX_X] = placeX; //update blocks array with location and type of block placed
      blocks[index][INDEX_Y] = placeY;
      blocks[index][INDEX_TYPE] = type;
      blockState[index][INDEX_TIMER] = -1; 
      isPlaced = true;
    }
  }
}

void drawGameMap(){
  pg.fill(0,0,0);
  int x;
  int y;
  int type;
  if(gameState != WINNING)
  {
    for(int i = 0; i < NUMBLOCKS; i++)
    {
      if(blocks[i][INDEX_TYPE] != BLK_PLAYER && i != actionId)
      {
        x = int(blocks[i][INDEX_X]);
        y = int(blocks[i][INDEX_Y]);
        type = int(blocks[i][INDEX_TYPE]);
        if(type == BLK_WOOD) {
          if(blockState[i][INDEX_TIMER] > 0)
          {
            if(blockState[i][INDEX_TIMER] < 5)
            {  
               PImage explodeFrame = explodeImg.get((4 - blockState[i][INDEX_TIMER]) * 250, 0, 250, 250);
               pg.image(explodeFrame, x*SQUARESIZE - 100, y*SQUARESIZE - 100, 250, 250);
            }
            else
            {  pg.image(crateImg, x*SQUARESIZE, y*SQUARESIZE, SQUARESIZE, SQUARESIZE);   }
            blockState[i][INDEX_TIMER] -= 1;
          }
          else if(blockState[i][INDEX_TIMER] == 0)
          {
            eraseBlock(i);
          }
          else
          {          
            pg.image(crateImg, x*SQUARESIZE, y*SQUARESIZE, SQUARESIZE, SQUARESIZE);    
          }
        }
        else if(type == BLK_METAL) {
          pg.image(metalCrateImg, x*SQUARESIZE, y*SQUARESIZE, SQUARESIZE, SQUARESIZE);
        }
        else if(type == BLK_TNT) {
          if(blockState[i][INDEX_TIMER] > 0)
          {
            if(blockState[i][INDEX_TIMER] < 5)
            {  
               PImage explodeFrame = explodeImg.get((4 - blockState[i][INDEX_TIMER]) * 250, 0, 250, 250);
               pg.image(explodeFrame, x*SQUARESIZE - 100, y*SQUARESIZE - 100, 250, 250);
            }
            else
            {  pg.image(tntImg, x*SQUARESIZE, y*SQUARESIZE, SQUARESIZE, SQUARESIZE);  }
            blockState[i][INDEX_TIMER] -= 1;
          }
          else if(blockState[i][INDEX_TIMER] == 0)
          {
            eraseBlock(i);
          }
          else
          {
            pg.image(tntImg, x*SQUARESIZE, y*SQUARESIZE, SQUARESIZE, SQUARESIZE);
          }
        }
        else if(type == BLK_MOVER) {
          drawMover(i);
        }
        else if(type == BLK_GOAL) {
          PImage exitFrame = exitImg.get((int(HOVERCO * sin(frameNow*0.4)) + 2) * 50, 0, 50, 50); 
          pg.image(exitFrame, x*SQUARESIZE, y*SQUARESIZE, SQUARESIZE, SQUARESIZE);
        }
      }
    }
  }
}

void drawMover(int index)
{
  if(blockState[index][INDEX_EYES] == 1)
  {
    blockState[index][INDEX_EYES] = 0;
  }
  else if(random(50) < 1)
  {
    blockState[index][INDEX_EYES] = 1;
  }
  if(gameState != MOVING)
  {
    blockState[index][INDEX_BODY] = 0;
  }
  
  if(blockState[index][INDEX_MOUTH] == 0) 
  {  
    blockState[index][INDEX_MOUTH] = int(random(1,3));  
  }
  else if(blockState[index][INDEX_MOUTH] == 1 || blockState[index][INDEX_MOUTH] == 4)
  {
    if(random(100) < 1) {  blockState[index][INDEX_MOUTH] = 0;  }
  }
  else if(blockState[index][INDEX_MOUTH] == 2)
  {
    if(random(20) < 1) { blockState[index][INDEX_MOUTH] = 3;  }
  }
  else if(blockState[index][INDEX_MOUTH] == 3)
  {
    if(random(20) < 1) { blockState[index][INDEX_MOUTH] = int(random(1,3));  }
  }
  if(blockState[index][INDEX_TIMER] > 0)
  {
    blockState[index][INDEX_BODY] = moveDir;
    blockState[index][INDEX_TIMER] -= 1;
  }
  
  renderBlock(index);
}

void drawPlayer(){
  if(gameState == WINNING)
  {
    if(blockState[PLAYER_INDEX][INDEX_EYES] == 0)
    {
      blockState[PLAYER_INDEX][INDEX_EYES] = int(random(6));
      if(random(2) < 1 || blockState[PLAYER_INDEX][INDEX_MOUTH] < 5) 
      {  blockState[PLAYER_INDEX][INDEX_MOUTH] = int(random(5,8));
         blockState[PLAYER_INDEX][INDEX_BODY] = int(random(5,8));  }
    }
    else if(random(30) < 1)
    {
      blockState[PLAYER_INDEX][INDEX_EYES] = 0;
      blockState[PLAYER_INDEX][INDEX_MOUTH] = 0;
      blockState[PLAYER_INDEX][INDEX_BODY] = 0;
    }
  }
  else
  {
    blockState[PLAYER_INDEX][INDEX_BODY] = moveDir;
    //eyes
    if(gameState == MOVING) {blockState[PLAYER_INDEX][INDEX_EYES] = moveDir; blockState[PLAYER_INDEX][INDEX_MOUTH] = 4;}
    else if(blockState[PLAYER_INDEX][INDEX_EYES] == 0) {blockState[PLAYER_INDEX][INDEX_EYES] = int(random(6));   }
    else if(random(50) < 1){blockState[PLAYER_INDEX][INDEX_EYES] = 0; }
    //mouth
    if(blockState[PLAYER_INDEX][INDEX_MOUTH] < 2) { blockState[PLAYER_INDEX][INDEX_MOUTH] = int(random(5));  }
    else if(random(50) < 1) { blockState[PLAYER_INDEX][INDEX_MOUTH] = 0; }
  }
  
  renderBlock(PLAYER_INDEX);
}

//paints block to screen for blocks of type BLK_PLAYER and BLK_MOVER
void renderBlock(int id)
{
  int hoverOffset = int((HOVERCO * sin(frameNow*0.25))/blocks[id][INDEX_TYPE]); 
  float x = blocks[id][INDEX_X] * SQUARESIZE;
  float y = blocks[id][INDEX_Y] * SQUARESIZE;
  if(id == PLAYER_INDEX) { y += hoverOffset;  }
  
  //choose correct .png file based on block type. (EVENTUALLY replace with one file and use offset)
  PImage thisImg = null;
  if(blocks[id][INDEX_TYPE] == BLK_PLAYER)
  {  thisImg = playerImg;  }
  else if(blocks[id][INDEX_TYPE] == BLK_MOVER)
  {  thisImg = moverImg;  }
  
  bodyFrame = thisImg.get(blockState[id][INDEX_BODY] * 50, 0, 50, 50);
  eyeFrame = thisImg.get(blockState[id][INDEX_EYES] * 50, 100, 50, 50);
  mouthFrame = thisImg.get(blockState[id][INDEX_MOUTH] * 50, 50, 50, 50);
  
  pg.image(bodyFrame, x, y, SQUARESIZE, SQUARESIZE);
  pg.image(eyeFrame, x, y, SQUARESIZE, SQUARESIZE);
  pg.image(mouthFrame, x, y, SQUARESIZE, SQUARESIZE);
}

void render(){
  if(main_menu_on && game_is_beginning == false){
    image(mainMenu, 200, 25, 600, 491);
  }
  else{
    if(frameChange > 0){
      pg.beginDraw();
      clearForNewFrame();
      drawGameMap();
      drawPlayer();
      pg.endDraw();
      image(pg,0,0);
    }
    if(background_created == false)
    {
      backgroundImg = pg; 
      background_created = true; 
      initializeGameMap();
    }
    if(game_is_beginning){
      toggleGameBeginning();
    }
  }
  if (gameState == WINNING){
    image(winMenu, 250, 200, 500, 250);
  }
}

//clears old frame (using background with low alpha) to 
void clearForNewFrame()
{
   if(gameState == WINNING)
    {
      pg.background(255,255,255,50); 
    }
    else
    {  pg.background(44,34,64,250);  }
}
