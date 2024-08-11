import std.stdio;
import raylib;
import std.file;
import std.conv;
import std.datetime; // Import for time handling
import std.format;
import core.stdc.stdlib;
import std.string;
import std.conv;
import std.process;

const float tileWidthFraction = 1.0 / 6.0; // Width as a fraction of screen width
const float tileHeightFraction = 1.0 / 5.0; // Height as a fraction of screen height
const int gapSize = 10; // Size of the gap between tiles
const int rows = 3; // Number of rows
const int cols = 4; // Number of columns
const float scaleFactor = 1.1; // Scale factor for the selected tile
const float scaleSpeed = 0.1; // Speed of scaling

void drawTile(Color tileColor, string tileText, Texture2D tileImage, int x, int y, int width, int height, bool isSelected) {
    // Draw the tile background
    DrawRectangle(x, y, width, height, tileColor);
    
    // Draw the tile image if it exists
    if (tileImage.id != 0) {
        // Define a scaling factor for the texture size
        float textureScaleFactor = isSelected ? 0.19 : 0.14;
        int textureWidth = cast(int)(tileImage.width * textureScaleFactor);
        int textureHeight = cast(int)(tileImage.height * textureScaleFactor);
        
        // Calculate the position to center the texture within the tile
        int textureX = x + (width - textureWidth) / 2;
        int textureY = y + (height - textureHeight) / 2;

        // Draw the texture at the calculated position with the new dimensions
        DrawTexturePro(tileImage, 
                       Rectangle(0, 0, cast(float)tileImage.width, cast(float)tileImage.height), 
                       Rectangle(textureX, textureY, textureWidth, textureHeight), 
                       Vector2(0, 0), 
                       0.0, 
                       Colors.WHITE);
    }
    
    // Draw the tile text at the left bottom corner
    DrawText(cast(char*)tileText, x + 10, y + height - 30, 20, Colors.BLACK); // Adjusted y position
}

string getCurrentTime() {
    auto now = Clock.currTime(); // Get the current time
    return format("%02d:%02d", now.hour, now.minute); // Format as HH:MM:SS
}

void drawBoxArts(int selectedBoxArtIndex, Texture2D[] boxArtTextures, string[] names, string[] commands) {
    int screenWidth = GetScreenWidth();
    int screenHeight = GetScreenHeight();
    
    int boxArtHeight = cast(int)(screenHeight * (1.0 / 2.0)); // 1/2 of screen height
    int boxArtWidth = cast(int)(screenWidth * (1.0 / 5.0)); // 1/5 of screen width
    int selectedBoxArtHeight = cast(int)(boxArtHeight * 1.03); // 20% bigger than normal box art
    int selectedBoxArtWidth = cast(int)(boxArtWidth * 1.03); // 20% bigger than normal box art
    int padding = 20; // Padding between box arts
    int startX = 0; // Start from the left corner
    int startY = (screenHeight - boxArtHeight) / 2; // Center verticall
    for (int i = 0; i < boxArtTextures.length; i++) {
        int x = startX;
        int y = startY;
        
        // Draw the white rectangle for the box art and label
        if (i == selectedBoxArtIndex) {
            DrawRectangle(x - 10, y - 10, selectedBoxArtWidth + 20, selectedBoxArtHeight + 50, Colors.WHITE); // Upscale the rectangle for the selected box art
        } else {
            DrawRectangle(x, y, boxArtWidth, boxArtHeight + 30, Colors.WHITE); // Normal size for other box arts
        }
        
        // Draw the box art
        if (i == selectedBoxArtIndex) {
            DrawTexturePro(boxArtTextures[i], 
                           Rectangle(0, 0, cast(float)boxArtTextures[i].width, cast(float)boxArtTextures[i].height), 
                           Rectangle(x, y, selectedBoxArtWidth, selectedBoxArtHeight), 
                           Vector2(0, 0), 
                           0.0, 
                           Colors.WHITE);
        } else {
            DrawTexturePro(boxArtTextures[i], 
                           Rectangle(0, 0, cast(float)boxArtTextures[i].width, cast(float)boxArtTextures[i].height), 
                           Rectangle(x, y, boxArtWidth, boxArtHeight), 
                           Vector2(0, 0), 
                           0.0, 
                           Colors.WHITE);
        }
        if (i == selectedBoxArtIndex && IsKeyPressed(KeyboardKey.KEY_ENTER)) {
            spawnShell(commands[i], null, Config.detached);
            
        }
        if (i == selectedBoxArtIndex && IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN)) {
            spawnShell(commands[i], null, Config.detached);
        }

        // Draw the text under the box art
        if (i == selectedBoxArtIndex) {
            DrawText(names[i].toStringz, x + (selectedBoxArtWidth - MeasureText(names[i].toStringz, 20)) / 2, y + selectedBoxArtHeight + 5, 20, Colors.BLACK);
        } else {
            DrawText(names[i].toStringz, x + (boxArtWidth - MeasureText(names[i].toStringz, 18)) / 2, y + boxArtHeight + 5, 18, Colors.BLACK);
        }
        
        // Move to the next position
        startX += boxArtWidth + padding;
    }
}

void main() {
    // Initialize the window
    InitWindow(GetScreenWidth(), GetScreenHeight(), "NCPUI");
    SetTargetFPS(20);
    ToggleFullscreen();
    InitAudioDevice();
    
    Texture2D[] menuIcons = [LoadTexture("res/gameslogo.png"), LoadTexture("res/gameslogo.png"), LoadTexture("res/gameslogo.png"), 
        LoadTexture("res/gameslogo.png"), LoadTexture("res/gameslogo.png"), LoadTexture("res/gameslogo.png"), LoadTexture("res/gameslogo.png"), 
        LoadTexture("res/gameslogo.png"), LoadTexture("res/gameslogo.png"), LoadTexture("res/gameslogo.png"), LoadTexture("res/gameslogo.png"), 
        LoadTexture("res/gameslogo.png")];
    
    // Load sound
    Sound tileChangeSound = LoadSound("res/move.wav"); // Load the sound file
	Sound changePageSound = LoadSound("res/slide.wav");
	Sound selectSound = LoadSound("res/select.wav");
	Sound backSound = LoadSound("res/back.wav");
    float soundDuration = 0.34; // Duration to play the sound
    float soundTimer = 0.0; // Timer to track sound playback
    bool isSoundPlaying = false; // Flag to check if sound is currently playing
    SetGamepadMappings("030000005e040000ea020000050d0000,Xbox Controller,a:b0,b:b1,x:b2,y:b3,back:b6,guide:b8,start:b7,leftstick:b9,rightstick:b10,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:a4,righttrigger:a5; \\\\
        030000004c050000c405000011010000,PS4 Controller,a:b1,b:b2,x:b0,y:b3,back:b8,guide:b12,start:b9,leftstick:b10,rightstick:b11,leftshoulder:b4,rightshoulder:b5,dpup:b11,dpdown:b14,dpleft:b7,dpright:b15,leftx:a0,lefty:a1,rightx:a2,righty:a5,lefttrigger:a3,righttrigger:a4;");
    // Variables to track the selected tile
    int selectedRow = 0;
    int selectedCol = 0;
    int selectedBoxArtIndex = 0; // New variable to track selected box art index
    string[] menuPointsPage1 = ["Games", "Firefox", "Power off", "Terminal", "Reboot", "Exit", "Settings", "Test",
	 "Test", "Test", "test", "test"];
    string[] menuPointsPage2 = ["Page 2 - Item 1", "Page 2 - Item 2", "Page 2 - Item 3", "Page 2 - Item 4", 
	"Page 2 - Item 5", "Page 2 - Item 6", "Page 2 - Item 7", "Page 2 - Item 8", "Page 2 - Item 9", "Page 2 - Item 10",
	"Page 2 - Item 11", "Page 2 - Item 12"];
    
    // Current page variable
    bool isPage1 = true;
    // Load the box art textures from the gameslist.txt file
    string gameData = readText("games/listgames.txt");
    string[] entries = split(gameData, "[entry]");
    Texture2D[] boxArtTextures = new Texture2D[entries.length - 1]; // Allocate space for the textures
    string[] names = new string[entries.length - 1];
    string[] commands = new string[entries.length - 1];
    for (int i = 1; i < entries.length; i++) { // Start from 1 to skip the first empty entry
        string[] lines = split(entries[i], "\n");
        string image = "";
        string name = "";
        string execut = "";
        foreach (line; lines) {
            if (startsWith(line, "[icon]")) {
                image = line["[icon]".length .. $ - "[/icon]".length];
            } else if (startsWith(line, "[name]")) {
                name = line["[name]".length .. $ - "[/name]".length];
            } else if (startsWith(line, "[executable]")) {
                execut = line["[executable]".length .. $ - "[/executable]".length];
            }
        }
        commands[i -1] = execut;
        names[i - 1] = name;
        boxArtTextures[i - 1] = LoadTexture(image.toStringz);
    }
    
    // Variables for scaling
    float currentScale = 1.0; // Current scale of the tile
    float targetScale = 1.0; // Target scale of the tile
    // Main game loop
    Texture2D mapTexture = LoadTexture("res/background.png");
    bool showBoxArts = false; // Flag to show box arts screen
    while (!WindowShouldClose()) {
        // Handle keyboard input for tile selection
        if (!showBoxArts) {
            if (IsKeyPressed(KeyboardKey.KEY_W)&& selectedRow > 0 || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_UP) && selectedRow > 0) {
                selectedRow--;
                PlaySound(tileChangeSound); // Play sound when changing tile
                isSoundPlaying = true; // Set sound playing flag
                soundTimer = soundDuration; // Reset the timer
            }
            if (IsKeyPressed(KeyboardKey.KEY_S)&& selectedRow < rows -1 || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_DOWN) && selectedRow < rows - 1) {
                selectedRow++;
                PlaySound(tileChangeSound); // Play sound when changing tile
                isSoundPlaying = true; // Set sound playing flag
                soundTimer = soundDuration; // Reset the timer
            }
            if (IsKeyPressed(KeyboardKey.KEY_A) || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_LEFT)) {
                if (selectedCol > 0) {
                    selectedCol--;
                    PlaySound(tileChangeSound); // Play sound when changing tile
                    isSoundPlaying = true; // Set sound playing flag
                    soundTimer = soundDuration; // Reset the timer
                } else {
                    // If on the first column and on the second page, switch back to the first page
                    if (!isPage1) {
                        isPage1 = true; // Switch to the first page
                        selectedCol = 3; // Reset column to the first item
						PlaySound(changePageSound); // Play sound when changing page
                        isSoundPlaying = true; // Set sound playing flag
                        soundTimer = soundDuration; // Reset the timer
                    } else {
						isPage1 = false;
						selectedCol = 3;
						PlaySound(changePageSound);
						isSoundPlaying = true;
						soundTimer = soundDuration;
					}
                }
            }
            if (IsKeyPressed(KeyboardKey.KEY_D) || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) {
				if (selectedCol < cols - 1) {
					selectedCol++;
					PlaySound(tileChangeSound); // Play sound when changing tile
					isSoundPlaying = true; // Set sound playing flag
					soundTimer = soundDuration; // Reset the timer
				} else {
					// Switch to the second page if at the end of the row
					isPage1 = !isPage1;
					selectedCol = 0; // Reset column to the first item
					PlaySound(changePageSound); // Play sound when changing page
					isSoundPlaying = true; // Set sound playing flag
					soundTimer = soundDuration; // Reset the timer
				}
			}

            // Check for Enter key press on the "Games" tile
            if (IsKeyPressed(KeyboardKey.KEY_ENTER)&& selectedRow == 0 && selectedCol == 0  || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN) && selectedRow == 0 && selectedCol == 0) {
				isSoundPlaying = true;
				soundTimer = soundDuration;
				PlaySound(selectSound);
                showBoxArts = true; // Show the box arts screen
            }
            if (IsKeyPressed(KeyboardKey.KEY_ENTER)&& selectedRow == 1 && selectedCol == 0  || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN) && selectedRow == 1 && selectedCol == 0) {
				isSoundPlaying = true;
				soundTimer = soundDuration;
				PlaySound(selectSound);
                executeShell("setsid xvkbd & setsid firefox");
                
            }
            if (IsKeyPressed(KeyboardKey.KEY_ENTER)&& selectedRow == 2 && selectedCol == 0  || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN) && selectedRow == 2 && selectedCol == 0) {
				isSoundPlaying = true;
				soundTimer = soundDuration;
				PlaySound(selectSound);
                executeShell("loginctl poweroff");
                
            }
            if (IsKeyPressed(KeyboardKey.KEY_ENTER)&& selectedRow == 0 && selectedCol == 1  || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN) && selectedRow == 0 && selectedCol == 1) {
				isSoundPlaying = true;
				soundTimer = soundDuration;
				PlaySound(selectSound);
                executeShell("loginctl reboot");
                
            }
            
            // Update sound timer
            if (isSoundPlaying) {
                soundTimer -= GetFrameTime(); // Decrease timer by the time since last frame
                if (soundTimer <= 0.0) {
                    isSoundPlaying = false; // Reset sound playing flag
                }
            }

            // Update target scale based on selected tile
            targetScale = 1.0; // Reset target scale
            for (int row = 0; row < rows; row++) {
                for (int col = 0; col < cols; col++) {
                    if (row == selectedRow && col == selectedCol) {
                        targetScale = scaleFactor; // Set target scale for the selected tile
                    }
                }
            }

            // Interpolate current scale towards target scale
            currentScale += (targetScale - currentScale) * scaleSpeed;

            // Start drawing
            BeginDrawing();
            ClearBackground(Colors.RAYWHITE);
            DrawTexturePro(
                mapTexture,
                Rectangle(0, 0, cast(float)mapTexture.width, cast(float)mapTexture.height),
                Rectangle(0, 0, cast(float)GetScreenWidth(), cast(float)GetScreenHeight()),
                Vector2(0, 0),
                0.0,
                Colors.WHITE
            );

            // Calculate tile dimensions based on screen size
            int screenWidth = GetScreenWidth();
            int screenHeight = GetScreenHeight();
            int tileWidth = cast(int)(screenWidth * tileWidthFraction);
            int tileHeight = cast(int)(screenHeight * tileHeightFraction);

            // Calculate total grid dimensions
            int gridWidth = cols * tileWidth + (cols - 1) * gapSize;
            int gridHeight = rows * tileHeight + (rows - 1) * gapSize;

            // Calculate starting position to center the grid
            int startX = (screenWidth - gridWidth) / 2;
            int startY = (screenHeight - gridHeight) / 2 + 20; // Add gap for title

            // Draw the page titles
            Color page1Color = isPage1 ? Colors.BLACK : Colors.LIGHTGRAY; // Black if selected, light gray if not
            Color page2Color = isPage1 ? Colors.LIGHTGRAY : Colors.BLACK; // Light gray if not selected, black if selected
            DrawText(cast(char*)"Page 1", (screenWidth - MeasureText(cast(char*)"Page 1", 20)) / 2 - 50, startY - 30, 20, page1Color); // Draw Page 1 title
            DrawText(cast(char*)"Page 2", (screenWidth - MeasureText(cast(char*)"Page 2", 20)) / 2 + 50, startY - 30, 20, page2Color); // Draw Page 2 title

            // Draw the grid of tiles
            string[] currentMenuPoints = isPage1 ? menuPointsPage1 : menuPointsPage2; // Select the current menu points
            for (int row = 0; row < rows; row++) {
                for (int col = 0; col < cols; col++) {
                    int x = startX + col * (tileWidth + gapSize);
                    int y = startY + row * (tileHeight + gapSize);
                    
                    // Determine the dimensions and position of the tile
                    int currentTileWidth = tileWidth;
                    int currentTileHeight = tileHeight;
                    int currentX = x;
                    int currentY = y;

                    // If the tile is selected, scale it
                    if (row == selectedRow && col == selectedCol) {
                        currentTileWidth = cast(int)(tileWidth * currentScale);
                        currentTileHeight = cast(int)(tileHeight * currentScale);
                        currentX = x - (currentTileWidth - tileWidth) / 2; // Center the enlarged tile
                        currentY = y - (currentTileHeight - tileHeight) / 2; // Center the enlarged tile
                    }

                    Color tileColor = (row == selectedRow && col == selectedCol) ? Colors.DARKGREEN : Color(43, 122, 63, 255); // Change color if selected
                    drawTile(tileColor, currentMenuPoints[col * rows + row], menuIcons[col * rows + row], currentX, currentY, currentTileWidth, currentTileHeight, row == selectedRow && col == selectedCol);
                }
            }

            // Draw the clock in the top right corner
            string currentTime = getCurrentTime()~"         "~getenv("USER").to!string;
            int padding = 20; // Padding from the edges
            DrawText(currentTime.toStringz, screenWidth - padding - MeasureText(currentTime.toStringz, 20), padding, 20, Colors.LIGHTGRAY);

            // End drawing
            EndDrawing();
        } else {
            // Drawing the box arts screen
            BeginDrawing();
            ClearBackground(Colors.RAYWHITE);
            DrawText(cast(char*)"Press N to go back", 10, 10, 20, Colors.BLACK); // Instruction to go back
			DrawTexturePro(
                mapTexture,
                Rectangle(0, 0, cast(float)mapTexture.width, cast(float)mapTexture.height),
                Rectangle(0, 0, cast(float)GetScreenWidth(), cast(float)GetScreenHeight()),
                Vector2(0, 0),
                0.0,
                Colors.WHITE
            );

            // Handle box art selection
            if (IsKeyPressed(KeyboardKey.KEY_A)  || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_LEFT)) {
                selectedBoxArtIndex--; // Move left
				PlaySound(tileChangeSound);
				isSoundPlaying = true;
				soundTimer = soundDuration;
            }
            if (IsKeyPressed(KeyboardKey.KEY_D) || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT)) {
                selectedBoxArtIndex++; // Move right
				PlaySound(tileChangeSound);
				isSoundPlaying = true;
				soundTimer = soundDuration;
            }

            // Draw the clock in the top right corner
            string currentTime = getCurrentTime()~"         "~getenv("USER").to!string;
            int padding = 20; // Padding from the edges
            DrawText(currentTime.toStringz, GetScreenWidth() - padding - MeasureText(currentTime.toStringz, 20), padding, 20, Colors.LIGHTGRAY);
            drawBoxArts(selectedBoxArtIndex, boxArtTextures, names, commands); // Draw the box arts and text
            EndDrawing();

            // Check for ESC key to go back
            if (IsKeyPressed(KeyboardKey.KEY_N)  || IsGamepadButtonPressed(0, GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT) ) {
				isSoundPlaying = true;
				PlaySound(backSound);
				soundTimer = soundDuration;
                showBoxArts = false; // Hide the box arts screen
            }
        }
    }

    // Unload resources
    for (int i = 0; i < menuIcons.length; i++) {
        UnloadTexture(menuIcons[i]);
    }
    closeApp: UnloadTexture(mapTexture);
    UnloadSound(tileChangeSound); // Unload the sound
	UnloadSound(changePageSound);
    CloseWindow();
}