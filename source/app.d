import std.stdio;
import raylib;
import std.file;
import std.conv;
import std.datetime; // Import for time handling
import std.format;
import core.stdc.stdlib;

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

void drawBoxArts(Texture2D[] boxArtTextures, int selectedBoxArtIndex) {
    int screenWidth = GetScreenWidth();
    int screenHeight = GetScreenHeight();
    
    // Calculate box art dimensions based on screen size
    int boxArtWidth = cast(int)(screenWidth * (1.0 / 5.0)); // 1/5 of screen width
    int boxArtHeight = cast(int)(screenHeight * (1.0 / 2.0)); // 1/2 of screen height
    
    int padding = 20; // Padding between box arts
    int startX = 0; // Start from the left corner
    int startY = (screenHeight - boxArtHeight) / 2; // Center vertically

    for (int i = 0; i < boxArtTextures.length; i++) {
        int x = startX + i * (boxArtWidth + padding);
        int y = startY; // Y position for the box arts

        // Draw the white rectangle for the box art and label
        DrawRectangle(x, y, boxArtWidth, boxArtHeight + 30, Colors.WHITE); // Height increased for label space

        // Draw the box art
        DrawTexturePro(boxArtTextures[i], 
                       Rectangle(0, 0, cast(float)boxArtTextures[i].width, cast(float)boxArtTextures[i].height), 
                       Rectangle(x, y, boxArtWidth, boxArtHeight), 
                       Vector2(0, 0), 
                       0.0, 
                       Colors.WHITE);
        
        // Draw the text below the box art
        string labelText = "Box Art " ~ (i + 1).to!string; // Customize this text as needed
        DrawText(cast(char*)labelText, x + (boxArtWidth - MeasureText(cast(char*)labelText, 20)) / 2, y + boxArtHeight + 5, 20, Colors.BLACK);

        // If this box art is selected, upscale it
        if (i == selectedBoxArtIndex) {
            DrawRectangle(x - 10, y - 10, boxArtWidth + 20, boxArtHeight + 50, Colors.LIGHTGRAY); // Highlight selected box art
            DrawTexturePro(boxArtTextures[i], 
                           Rectangle(0, 0, cast(float)boxArtTextures[i].width, cast(float)boxArtTextures[i].height), 
                           Rectangle(x - 10, y - 10, boxArtWidth + 20, boxArtHeight + 20), 
                           Vector2(0, 0), 
                           0.0, 
                           Colors.WHITE);
        }
    }
}

void main() {
    // Initialize the window
    InitWindow(GetScreenWidth(), GetScreenHeight(), "NCPUI");
    SetTargetFPS(60);
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

    // Variables for scaling
    float currentScale = 1.0; // Current scale of the tile
    float targetScale = 1.0; // Target scale of the tile

    // Load box art textures
    Texture2D[] boxArtTextures = [
        LoadTexture("res/boxart.png"),
        LoadTexture("res/boxart.png"),
        LoadTexture("res/boxart.png")
    ];

    // Main game loop
    Texture2D mapTexture = LoadTexture("res/background.png");
    bool showBoxArts = false; // Flag to show box arts screen
    while (!WindowShouldClose()) {
        // Handle keyboard input for tile selection
        if (!showBoxArts) {
            if (IsKeyPressed(KeyboardKey.KEY_W) && selectedRow > 0) {
                selectedRow--;
                PlaySound(tileChangeSound); // Play sound when changing tile
                isSoundPlaying = true; // Set sound playing flag
                soundTimer = soundDuration; // Reset the timer
            }
            if (IsKeyPressed(KeyboardKey.KEY_S) && selectedRow < rows - 1) {
                selectedRow++;
                PlaySound(tileChangeSound); // Play sound when changing tile
                isSoundPlaying = true; // Set sound playing flag
                soundTimer = soundDuration; // Reset the timer
            }
            if (IsKeyPressed(KeyboardKey.KEY_A)) {
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
            if (IsKeyPressed(KeyboardKey.KEY_D)) {
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
            if (IsKeyPressed(KeyboardKey.KEY_ENTER) && selectedRow == 0 && selectedCol == 0) {
				isSoundPlaying = true;
				soundTimer = soundDuration;
				PlaySound(selectSound);
                showBoxArts = true; // Show the box arts screen
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
            DrawText(cast(char*)currentTime, screenWidth - padding - MeasureText(cast(char*)currentTime, 20), padding, 20, Colors.BLACK);

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
            if (IsKeyPressed(KeyboardKey.KEY_A) && selectedBoxArtIndex > 0) {
                selectedBoxArtIndex--; // Move left
				PlaySound(tileChangeSound);
				isSoundPlaying = true;
				soundTimer = soundDuration;
            }
            if (IsKeyPressed(KeyboardKey.KEY_D) && selectedBoxArtIndex < boxArtTextures.length - 1) {
                selectedBoxArtIndex++; // Move right
				PlaySound(tileChangeSound);
				isSoundPlaying = true;
				soundTimer = soundDuration;
            }

            // Draw the clock in the top right corner
            string currentTime = getCurrentTime()~"         "~getenv("USER").to!string;
            int padding = 20; // Padding from the edges
            DrawText(cast(char*)currentTime, GetScreenWidth() - padding - MeasureText(cast(char*)currentTime, 20), padding, 20, Colors.BLACK);
            drawBoxArts(boxArtTextures, selectedBoxArtIndex); // Draw the box arts and text
            EndDrawing();

            // Check for ESC key to go back
            if (IsKeyPressed(KeyboardKey.KEY_N)) {
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
    for (int i = 0; i < boxArtTextures.length; i++) {
        UnloadTexture(boxArtTextures[i]); // Unload each box art texture
    }
    UnloadTexture(mapTexture);
    UnloadSound(tileChangeSound); // Unload the sound
	UnloadSound(changePageSound);
    CloseWindow();
}