
boolean inMenu = true; // To check if we're currently showing the menu
int menuOption = 0; // 0 for 'Start', 1 for 'Close'
boolean inTutorial = false; // To check if we're showing the tutorial
int BulletPattern = 0;  // Determines which bullet pattern should be used





/* Temporary exists to make use of the possible Calculations provided by Processing, giving
 each object its own PVector dosent want to work and they would share their PVectors*/
PVector PlayerPosition, NewPlayerPosition, TEST, Temporary1, Temporary2;

/*
This array keeps all the non position information of the player character and other important variables
 Score, Lifes, Current Pattern, Invulnerability Timer, Game Time, Graze
 0      1        2                  3                    4        5
 Game Time increments by one each frame, its used to create enemies at certain points in the level.
 */
int[] GameStats = new int[6];

/*
 This keeps track of important counters, each pattern function manipulates this array on their own.
 The first value is used to determine which counter, this tells the used function if they have to set stuff to their start value
 */
int[] PatternCounter = new int[16];

/*
"Simple" Bullets, array with floats, for now X Y and Velocity
 Despite being an array of floats, not all values may be treated as such,
 for details see the functions working with this array
 
 The Bullets are made up out of a X and Y coordinate
 
 a flag to see if it was "grazed", meaning the player narowly
 dodged the projectile, which gives a bonus to the score, this can only happen once per bullet.
 
 The used image for the bullet is saved as a single value, which is used as the offset in the
 "Sprites" array to get the image for the bullet. This float is converted to an Int for this.
 
 The fourth  float is the Size of the bullet, this does not affect the bullets image but the
 calculations for collision. The Size should be small enough, to allow the players hitbox to
 clip the edges of the projectile, this is mostly for gameplay reasons.
 
 The fifth value is used similarly to the fourth one, but instead of saving the offset for
 the Sprites array, it determines which Function is used. The function uses a switch to
 determine the calculations for the Bullets new position. A switch is used instead of a
 function pointer, because java dosent provide function pointers.
 
 8 slots for parameters, which are used for functions, the exact use and amount of paramters used
 depends on each function. As an Example: the linear move function will use the first 2 Parameters
 to change the X and Y coordinate by the values of the first and second parameter.
 
 The Array size of the SimpleBullets is calculated as such (Amount * 14), this is because each bullet uses 14
 values.
 
 
 Quick Overview
 [X , Y , Image , Graze , Size , Function , P1 , P2 , P3 , P4 , P5 , P6 , P7 , P8]
 
 */
//28000 is for 2000 bullets, more can be given if needed by increasing the array size
float[] SimpleBullets_Array_Storage = new float[28000];






/*
This Arrays saves the positions, which can be safely overwriten in the SimpleBullets_Array_Storage
 and keep track of the total amount of free space.
 SimpleBullets_Array_Free[0] gives the total amount of free spaces, 0 means nothing is free
 SimpleBullets_Array_Free[ SimpleBullets_Array_Free[0] ] gives the position in SimpleBullets_Array_Storage[] where a new bullet can be added with no issues.
 
 New position are added from left to right
 Example:
 SimpleBullets_Array_Storage[ SimpleBullets_Array_Storage[0] + 1] = INT POSITION
 After this SimpleBullets_Array_Storage[0] gets incremented by one
 
 Positions are read right to left
 
 This avoids leaving gaps in the array when reading and allows very quick access to new positions without iterating trough arrays
 Example:
 SimpleBullets_Array_Storage[ SimpleBullets_Array_Storage[0] ] = Position
 The counter has 1 subtracted from it
 SimpleBullets_Array_Storage[0] has 1 subtracted
 
 The old position dosent need to be overwriten, because no function should read position beyond the value given by SimpleBullets_Array_Storage[0]
 The old position is only accessed, if a new free Position gets added, in which case it gets overwritten by the new free position.
 
 The Size should be the amount of bullets + 1
 */
int[] SimpleBullets_Array_Free = new int[2001];







// Saving all the sprites in an array for easier access
PImage Sprite;
PImage[] SimpleBullets_Array_Sprites = new PImage[512];






// 0    1    2    3     movement 4 focus 5 shoot 6 bomb    BOmbs and Shooting are unused but are still left behind, because rewriting all the associated stuff would take too long
// UP DOWN LEFT RIGHT |
boolean[] KeyInput = new boolean[7];





/*
Different timers
 */
int DoOnce = 1;
int Clock120 = 0; // A timer that goes from 0 - 120 increments by 1 every frame
int Clock20 = 0;

// This function deals with the collission stuff, returns true if the player is hit and not immune
public boolean Collision_Detection (float SB_Storage[], int BulletSize, int Position) {

  Temporary1.x = SB_Storage[Position*BulletSize];
  Temporary1.y = SB_Storage[Position*BulletSize + 1];

  if ( PlayerPosition.dist(Temporary1) < (SB_Storage[Position*BulletSize + 4] + 14) && SB_Storage[Position*BulletSize + 3] != 0) {
    GameStats[0] = GameStats[0] + 100; // 100 points given
    GameStats[5]++;
    SB_Storage[Position*BulletSize + 3] = 0; // prevents being given points multiple times by the same bullet
  }


  if ( PlayerPosition.dist(Temporary1) < (SB_Storage[Position*BulletSize + 4]) && GameStats[3] <= 0) {
    GameStats[3] = 70;  // Immunity timeer
    GameStats[1]--;    // Lowering Life
    return true;
  }

  return false;
}




/*
This Function goes trough the array SB_Storage, which is the used array for bullet storage, and stores free
 positions in SB_Free. The free position are saved as an offset for the array SB_Storage. If the first bullet is free, it saves 0
 if the 10th bullet is free, it saves 10 * Bulletsize. The Bulletsize determines how large each bullet is, with a size of 5, each bullet uses
 5 values in the array of SB_Storage.
 
 This Function should be run in Setup after the appropiate Arrays are made. The Remove function and Add Function should be able
 to adjust the SB_Free array on their own after this function ran once.
 */
public void SimpleBullets_GetFree(float SB_Storage[], int SB_Free[], int TotalBullets, int BulletSize) {

  //Iterate the Storage array and add free positions to the quick access array
  for (int i = 0; i < TotalBullets; i = i + 1) {

    if (SB_Storage[0+i*BulletSize] == 0) {                  // If the X position is 0, assume the bullet is removed, otherwise dont do anything with it

      SB_Free[SB_Free[0]+1] = i * BulletSize;                 // Add the Free position in the closesest free spot read left to right in the array | Bullet size is calculated here as well
      SB_Free[0] = SB_Free[0] + 1;                           // Increment the counter for free positions
    }
  }
}






public void SimpleBullets_Create(float SB_Storage[], int SB_Free[], int BulletSize, float X, float Y, float ImageFloat, float Graze, float Size, float FunctionFloat, float P1, float P2, float P3, float P4, float P5, float P6, float P7, float P8) {

  // 0 Means that no new bullet can be added to the array
  if (SB_Free[0] == 0) {
    // println("No Space for new Bullet");
    return;
  }

  int FreePosition = SB_Free[SB_Free[0]];     // SB_Free[0] gives the position is SB_Free with the
  SB_Free[0] = SB_Free[0] - 1;                // Decrease the counter at the start

  /*
   This chunk adds the parameters of the Bullet to the Array that stores bullets
   This Bullet is made up out of 14 Parts
   
   In theory, this function allows smaller Bullets by setting a lower BulletSize, which is defined in SimpleBullets_GetFree(),  and overwriting some of the
   P Values. This is Possible but should be done with care to avoid problems.
   
   */
  SB_Storage[0+FreePosition] = X;
  SB_Storage[1+FreePosition] = Y;
  SB_Storage[2+FreePosition] = ImageFloat;
  SB_Storage[3+FreePosition] = Graze;
  SB_Storage[4+FreePosition] = Size;
  SB_Storage[5+FreePosition] = FunctionFloat;
  SB_Storage[6+FreePosition] = P1;
  SB_Storage[7+FreePosition] = P2;
  SB_Storage[8+FreePosition] = P3;
  SB_Storage[9+FreePosition] = P4;
  SB_Storage[10+FreePosition] = P5;
  SB_Storage[11+FreePosition] = P6;
  SB_Storage[12+FreePosition] = P7;
  SB_Storage[13+FreePosition] = P8;
  // println("Bullet Added");
}

/*
The SimpleBullets_Update()  Goes trough the SB_Storage array and checks each entry for a active bullet. It jumps based on
 the size of the Bullet int BulletSize, this speeds up the process, as it only checks if the X coordinate is == 0. If it is,
 the bullet is assumed as "removed". If a Bullets X coordinate != 0, then a function is run. Which function is defined in the
 switch case, which function is run is saved in +5 position of the Bullet in the SB_Storage array. The Function will generally
 calculate a new position, do other stuff, draw the bullet and remove the Bullet, if certain conditiones defined in the Function
 are met. For Deleting Bullets, the X coordinate is set to 0 and the position of the Bullet in the SB_Storage array is noted down
 in SB_Free array at position SB_Free[ SB_Free[0+1] ] and the counter at SB_Free[0] is incremented by one.
 
 */


public void SimpleBullets_Update(float SB_Storage[], int SB_Free[], int BulletSize, int BulletAmount) {



  for (int i = 0; i < BulletAmount; i = i +1) {

    if (SB_Storage[i*BulletSize] != 0) {          // X == 0 is used as a check to see if a bullet was removed or not




      /*
   This Switch handles the possible Functions for bullet calculations. The Function to use is determined
       by the value saved in the position for functions.
       
       +0  +1    +2      +3      +4      +5      +6    +7   +8  +9  +10  +11  +12  +13
       [X , Y , Image , Graze , Size , Function , P1 , P2 , P3 , P4 , P5 , P6 , P7 , P8]
       
       Function, Image are saved as Float but should be converted to int, these arrays do not accept different data types
       */

      switch(int(SB_Storage[i * BulletSize + 5])) {


        /* FUNCTION 1*/
        /* This Function Moves the Projectile in a linear fashion, where P1 is for the change in X and P2 is for the change in Y*/
        /* FUNCTION 1*/


      case 1:
        SB_Storage[i*BulletSize] = SB_Storage[i*BulletSize] + SB_Storage[i*BulletSize + 6];    // new X
        SB_Storage[i*BulletSize + 1] = SB_Storage[i*BulletSize + 1] + SB_Storage[i*BulletSize + 7];  // new Y

        // Checks if the bullet is out of bounds and deletes it it is, it gets removed.  X coordinate > 846 / < 96  Y Coordinate > 932 / < 32
        if ((SB_Storage[i*BulletSize] < 48 || SB_Storage[i*BulletSize] > 648 || SB_Storage[i*BulletSize + 1] < 32 || SB_Storage[i*BulletSize + 1] > 732) && SB_Storage[i*BulletSize] != 0) {

          SB_Storage[i*BulletSize] = 0;

          SB_Free[SB_Free[0]+1] = i*BulletSize;

          SB_Free[0] += 1;
          break; // Early Break, wont draw the projectile if the bullet gets destroyed
        }

        image( SimpleBullets_Array_Sprites[ int(SB_Storage[i * BulletSize + 2]) ], SB_Storage[i*BulletSize], SB_Storage[i*BulletSize+1]);

        if (Collision_Detection(SB_Storage, BulletSize, i)) {
         
        }


        break;



        /*FUNCTION 2
         This Function changes the position of the Bullet by P1 for X and P2 for Y
         P1 and P2 are changed by P3 and P4 respectively
         2
         FUNCTION 2*/
      case 2:

        SB_Storage[i*BulletSize] = SB_Storage[i*BulletSize] + SB_Storage[i*BulletSize + 6];
        SB_Storage[i*BulletSize + 1] = SB_Storage[i*BulletSize + 1] + SB_Storage[i*BulletSize + 7];

        SB_Storage[i*BulletSize + 6] = SB_Storage[i*BulletSize + 6] + SB_Storage[i*BulletSize + 8];
        SB_Storage[i*BulletSize + 7] = SB_Storage[i*BulletSize + 7] + SB_Storage[i*BulletSize + 9];


        // Checks if the bullet is out of bounds and deletes it it is it gets removed.  X coordinate > 846 / < 96  Y Coordinate > 932 / < 32
        if ((SB_Storage[i*BulletSize] < 48 || SB_Storage[i*BulletSize] > 648 || SB_Storage[i*BulletSize + 1] < 32 || SB_Storage[i*BulletSize + 1] > 732) && SB_Storage[i*BulletSize] != 0) {

          SB_Storage[i*BulletSize] = 0;
          SB_Free[SB_Free[0]+1] = i*BulletSize;
          SB_Free[0] += 1;
          break;// Early Break, wont draw the projectile if the bullet gets destroyed
        }

        image( SimpleBullets_Array_Sprites[ int(SB_Storage[i * BulletSize + 2]) ], SB_Storage[i*BulletSize], SB_Storage[i*BulletSize+1]);  // Draws the Bullet on the X Y coordinates of the bullet


        if (Collision_Detection(SB_Storage, BulletSize, i)) {
          
        }

        break;



        /* FUNCTION 3*/









        /*
   Runs if the Function isnt known in the switch case,
         gives position of the bullets start and provides the value requested
         */
      default:
        println("Unknown Function Identifier");
        print("At Position ");
        print(i*BulletSize+5);
        print(" ID : ");
        println(SB_Storage[i * BulletSize + 5]);
        SB_Free[SB_Free[0]+1] = i*BulletSize;
        SB_Free[0] += 1;
        SB_Storage[i*BulletSize] = 0;  // Set x to 0 to remove the bullet
        break;
      }
    }
  }
}











/*
Goes trough an array and prints the value seperated by a line,
 meant to test if values are properly edited inside an array or if
 parts of an array is unused.
 */
public void PrintArr(float List[], int Length) {

  for (int i = 0; i<Length; i=i+1) {
    println("------");
    println(i);
    println(List[i]);
  }
}



/*

 BULLET PATTERNS START
 BULLET PATTERNS START
 BULLET PATTERNS START
 BULLET PATTERNS START
 BULLET PATTERNS START
 BULLET PATTERNS START
 BULLET PATTERNS START
 BULLET PATTERNS START
 BULLET PATTERNS START
 BULLET PATTERNS START
 
 */




public void PatternA(int[] GameStats, int[] Counter) {

  if (Counter[0] != 1) {
    Counter[0] = 1;
    Counter[1] = 0;
    Counter[3] = 0;
    Counter[4] = 0;
  }

  Counter[1]++;


  /*
   
   Pattern Part A
   Counter 1 is used for the delay
   */
 
  if (Counter[1]==8 && Counter[3] == 0) {

    Temporary1.x = PlayerPosition.x-48;
    Temporary1.y = (PlayerPosition.y)-(Counter[2]*50+32);
    Temporary1.setMag(1.5);
    SimpleBullets_Create(SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 14, 48, Counter[2]*50+32 /* X Y */, 4 /* Image */, 1/*Graze, set to 1*/, 6/*Size,adjust for sprite*/, 2  /*Function*/,
      Temporary1.x /*P1*/, Temporary1.y/*P2*/, 0/*P3*/, 0/*P4*/, 12/*P5*/, 13/*P6*/, 14/*P7*/, 1/*P8*/);
      
    Temporary1.x = PlayerPosition.x-648;
    Temporary1.y = (PlayerPosition.y)-(732-Counter[2]*50);
    Temporary1.setMag(1.5);
    SimpleBullets_Create(SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 14, 648, 732-Counter[2]*50 /* X Y */, 4 /* Image */, 1/*Graze, set to 1*/, 6/*Size,adjust for sprite*/, 2  /*Function*/,
      Temporary1.x /*P1*/, Temporary1.y/*P2*/, 0/*P3*/, 0/*P4*/, 12/*P5*/, 13/*P6*/, 14/*P7*/, 1/*P8*/);

    Counter[2]++; // Increment the counter to determine bullet spawn
    Counter[1] = 0; // Reset Delay
  } else if (Counter[1]==4 && Counter[3] == 1) {

    Temporary1.x = 348 - (48 + Counter[2]*50);
    Temporary1.y = (382)-732;
    Temporary1.setMag(1.5);
    SimpleBullets_Create(SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 14, 48 + Counter[2]*50, 732 /* X Y */, 5 /* Image */, 1/*Graze, set to 1*/, 6/*Size,adjust for sprite*/, 2  /*Function*/,
      Temporary1.x /*P1*/, Temporary1.y/*P2*/, 0/*P3*/, 0/*P4*/, 12/*P5*/, 13/*P6*/, 14/*P7*/, 1/*P8*/);

    Temporary1.x = 348 - (648 - Counter[2]*50);
    Temporary1.y = (382)-32;
    Temporary1.setMag(1.5);
    SimpleBullets_Create(SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 14, 648 - Counter[2]*50, 32 /* X Y */, 5 /* Image */, 1/*Graze, set to 1*/, 6/*Size,adjust for sprite*/, 2  /*Function*/,
      Temporary1.x /*P1*/, Temporary1.y/*P2*/, 0/*P3*/, 0/*P4*/, 12/*P5*/, 13/*P6*/, 14/*P7*/, 1/*P8*/);
      
    Counter[2]++;
    Counter[1] = 0;
  }


  if (Counter[2]==15 && Counter[3] != 2) {
    Counter[2] = 0;
    Counter[3] = (Counter[3]==0) ? 1 : 0;
    Counter[4]++; 
    
    if(Counter[4]==3){
    Counter[3] = 2;
    Counter[4] = 0;
    }
  }
  
  if(Counter[3] == 2 && Counter[1] == 60){
  
  
    for(int i = 0; i<10;i++){
    
    Temporary1.x = 348 - 648;
    Temporary1.y = (382)-70*i;
    Temporary1.setMag(1.8);
    SimpleBullets_Create(SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 14, 648, 70*i /* X Y */, 5 /* Image */, 1/*Graze, set to 1*/, 6/*Size,adjust for sprite*/, 2  /*Function*/,
      Temporary1.x /*P1*/, Temporary1.y/*P2*/, 0/*P3*/, 0/*P4*/, 12/*P5*/, 13/*P6*/, 14/*P7*/, 1/*P8*/);
      
     Temporary1.x = 348 - 48;
    Temporary1.y = (382)-70*i;
    Temporary1.setMag(1.8);
    SimpleBullets_Create(SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 14, 48, 70*i /* X Y */, 5 /* Image */, 1/*Graze, set to 1*/, 6/*Size,adjust for sprite*/, 2  /*Function*/,
      Temporary1.x /*P1*/, Temporary1.y/*P2*/, 0/*P3*/, 0/*P4*/, 12/*P5*/, 13/*P6*/, 14/*P7*/, 1/*P8*/);      
      
        Temporary1.x = 348 - (48 + i*60);
    Temporary1.y = (382)-732;
    Temporary1.setMag(1.8);
    SimpleBullets_Create(SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 14, 48 + i*60, 732 /* X Y */, 5 /* Image */, 1/*Graze, set to 1*/, 6/*Size,adjust for sprite*/, 2  /*Function*/,
      Temporary1.x /*P1*/, Temporary1.y/*P2*/, 0/*P3*/, 0/*P4*/, 12/*P5*/, 13/*P6*/, 14/*P7*/, 1/*P8*/); 

            Temporary1.x = 348 - (48 + i*60);
    Temporary1.y = (382)-32;
    Temporary1.setMag(1.8);
    SimpleBullets_Create(SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 14, 48 + i*60, 32 /* X Y */, 5 /* Image */, 1/*Graze, set to 1*/, 6/*Size,adjust for sprite*/, 2  /*Function*/,
      Temporary1.x /*P1*/, Temporary1.y/*P2*/, 0/*P3*/, 0/*P4*/, 12/*P5*/, 13/*P6*/, 14/*P7*/, 1/*P8*/);   
  
    }
    
    
  Counter[3] = 0;
  Counter[1] = -180;
  }
  
  
}







/*

 BULLET PATTERNS END
 BULLET PATTERNS END
 BULLET PATTERNS END
 BULLET PATTERNS END
 BULLET PATTERNS END
 BULLET PATTERNS END
 BULLET PATTERNS END
 BULLET PATTERNS END
 BULLET PATTERNS END
 
 */





// Input Reading: sets the bool to true
void keyPressed() {


  // Inputs for menus
  if (inMenu) {
    if (keyCode == UP || keyCode == DOWN) {
      menuOption = (menuOption == 0) ? 1 : 0; // Toggle option, switches between the two options each time you press up/down
    } else if (keyCode == ENTER) {
      if (menuOption == 0) {
        inMenu = false; // Exit menu
        inTutorial = true; // Enter tutorial
      } else if (menuOption == 1) {
        exit(); // Close the game
      }
    }
  } else if (inTutorial) {
    if (keyCode == ENTER) {
      inTutorial = false; // Start the game after tutorial
    }
  }

  // Inputs for playing the Game
  else {

    if (keyCode == UP) {
      KeyInput[0] = true;
    }

    if (keyCode == DOWN) {
      KeyInput[1] = true;
    }

    if (keyCode == LEFT) {
      KeyInput[2] = true;
    }

    if (keyCode == RIGHT) {
      KeyInput[3] = true;
    }

    if (keyCode == SHIFT) {
      KeyInput[4] = true;
    }

    if (key == 'y') {
      KeyInput[5] = true;
    }

    if (key == 'x') {
      KeyInput[6] = true;
    }
  }
}


// marks the keys are no longer pressed by flipping the bool
void keyReleased() {


  if (keyCode == UP) {
    KeyInput[0] = false;
  }

  if (keyCode == DOWN) {
    KeyInput[1] = false;
  }

  if (keyCode == LEFT) {
    KeyInput[2] = false;
  }

  if (keyCode == RIGHT) {
    KeyInput[3] = false;
  }

  if (keyCode == SHIFT) {
    KeyInput[4] = false;
  }

  if (key == 'y') {
    KeyInput[5] = false;
  }

  if (key == 'x') {
    KeyInput[6] = false;
  }
}










void setup() {    // Fenster Größe
  size (1024, 768);
  PlayerPosition = new PVector(500, 500);
  NewPlayerPosition = new PVector(500, 500);

  Temporary1 = new PVector(0, 0);
  GameStats[5] = 0;
  GameStats[0] = 0;
  GameStats[1] = 3;
  imageMode(CENTER);
  /*
       Loads all the used images (sprites) into memory. They are kept in the same array for ease of access
   */
  Sprite = loadImage("Basic Red.png");
  SimpleBullets_Array_Sprites[0] = Sprite;
  SimpleBullets_Array_Sprites[1] = loadImage("Basic Blue.png");
  SimpleBullets_Array_Sprites[2] = loadImage("Basic Green.png");
  SimpleBullets_Array_Sprites[3] = loadImage("small red.png");
  SimpleBullets_Array_Sprites[4] = loadImage("small green.png");
  SimpleBullets_Array_Sprites[5] = loadImage("small blue.png");
  SimpleBullets_GetFree( SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 2000, 14);


  inMenu = true;
  inTutorial = false;

  SimpleBullets_Create(SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 14, 324, 366 /* X Y */, 4 /* Image */, 0/*Graze, set to 1*/, 0/*Size,adjust for sprite*/, 2  /*Function*/,
    0 /*P1*/, 0/*P2*/, 0/*P3*/, 0/*P4*/, 12/*P5*/, 13/*P6*/, 14/*P7*/, 1/*P8*/);

  //    PrintArr(SimpleBullets_Array_Storage,28000);
}


void drawMenu() {
  background(0);
  textSize(32);
  fill(255); // White text

  // Highlight the selected option
  if (menuOption == 0) fill(255, 0, 0); // Red for selected option
  text("Spiel starten", width / 2 - 100, height / 2 - 20);
  fill(255); // Reset to white for other options

  if (menuOption == 1) fill(255, 0, 0); // Red for selected option
  text("Spiel beenden", width / 2 - 100, height / 2 + 20);
}


void drawTutorial() {
  background(0);
  textSize(20);
  fill(255);
  text("Tutorial: Pfeiltasten, um sich zu bewegen \n Punkte sammelt man indem man überlebt und knapp ausweicht \n Werde nicht getroffen", width / 4, height / 2);

  textSize(16);
  text("Drücke Enter um das Spiel zu beginnen", width / 2 - 100, height - 50);
}





void draw() {


  if (inMenu) {
    drawMenu();
  } else if (inTutorial) {
    drawTutorial();
  } else // If you arent in the menus, the game actually starts
  {
    Clock120 = (Clock120+1)*int(Clock120<120);
    Clock20 = (Clock20+1)*int(Clock20<20);

    PatternA(GameStats, PatternCounter);

    // Background for now
    fill(55, 55, 55);
    rect(0, 0, 1280, 960);
    fill(150, 150, 150);

    // Area
    rect(48, 32, 600, 700);
    fill(55, 55, 150);

    // Guidance lines to find the center and such
    line(48, 32, 648, 732);
    line(648, 32, 48, 732);

    // Draws the Player
    circle(PlayerPosition.x, PlayerPosition.y, 14);
    fill(180, 20, 20);
    circle(PlayerPosition.x, PlayerPosition.y, 6*int(KeyInput[4])); // Only drawn when focus is active, small red circle in the center



    // Movement of Player
    // Checks if the Player is moving Diagonally, this is to keep the speed consistent

    // Calculates a vector based on the movement key inputs
    NewPlayerPosition.y = (((9-7*int(KeyInput[4])) *int(KeyInput[1]) -  (9-7*int(KeyInput[4])) *int(KeyInput[0])));
    NewPlayerPosition.x = (((9-7*int(KeyInput[4])) *int(KeyInput[3]) -  (9-7*int(KeyInput[4])) *int(KeyInput[2])));

    // Limits max speed for Diagonall Movement cases and sets the new position
    NewPlayerPosition.setMag(11-7*int(KeyInput[4]));
    PlayerPosition =   PlayerPosition.add(NewPlayerPosition);

    // Limits player to the Playable area
    if (PlayerPosition.x <= 96 || PlayerPosition.x >= 846) {
      PlayerPosition.x = 96 * int(PlayerPosition.x <= 96) + 846 * int(PlayerPosition.x >= 846 );
    }
    if (PlayerPosition.y <= 32 || PlayerPosition.y >= 932) {
      PlayerPosition.y = 32 * int(PlayerPosition.y <= 32) + 932 * int(PlayerPosition.y >= 932 );
    }

    textSize(50);
    fill(0, 150, 80);
    text("Score", 760, 50);
    text(GameStats[0], 760, 100);
    text("Graze", 760, 150);
    text(GameStats[5], 760, 200);
    text("Life", 760, 250);
    text(GameStats[1], 760, 300);
    SimpleBullets_Update(SimpleBullets_Array_Storage, SimpleBullets_Array_Free, 14, 2000);
    if (Clock20 == 0) {
      GameStats[0] += 5;
    }
    println(frameRate);
    GameStats[3]--;


    GameStats[4]++;  // Increment game time each frame, used to determine which pattern is used
  }
}
