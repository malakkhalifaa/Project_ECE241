# Pacman FPGA Implementation

A hardware implementation of the classic Pacman arcade game using Verilog HDL and FPGA technology. This project demonstrates real-time video generation, collision detection, PS/2 keyboard interfacing, and audio processing through dedicated hardware modules.

## Project Overview

This implementation runs entirely on an FPGA without the use of a general-purpose processor, leveraging parallel hardware execution for game logic, rendering, and peripheral communication. The system generates VGA video output at 160x120 resolution with 3-bit color depth, processes PS/2 keyboard input for player control, and supports audio output through an I2S audio codec interface.

<img width="1728" height="892" alt="image" src="https://github.com/user-attachments/assets/507d2d8c-d998-4860-9d60-19d19749c053" />

## Demo

Demonstration video showcasing gameplay, hardware connections, and system functionality:

[![Demo Video](https://img.youtube.com/vi/6VuTFfgRM2U/maxresdefault.jpg)](https://www.youtube.com/watch?v=6VuTFfgRM2U)

## Hardware Architecture

### Top-Level Module Structure

The design follows a hierarchical module architecture where the `top_level.v` module serves as the primary integration point for all subsystems:

```
top_level
├── pacman_logic
│   ├── PS2_Demo (keyboard interface)
│   ├── pacman_movement (FSM controller)
│   ├── connect_vga (collision detection)
│   └── count_down (timer logic)
├── pacman_pixel (VGA rendering engine)
├── pacmaze_screen (start screen renderer)
├── audio_demo (I2S audio controller)
├── count_down (global timer)
└── seg7_decoder (score display)
```

<img width="819" height="635" alt="image" src="https://github.com/user-attachments/assets/199834f7-4386-4c4a-bcc4-f36e945a8ce0" />


### Core Modules

#### Game Logic Controller (`pacman_logic.v`)

The game logic module orchestrates player input processing, movement state management, and collision detection. It implements a finite state machine that transitions between idle, movement, and collision states based on keyboard input and wall detection results.

- **Input Processing**: Decodes PS/2 keyboard scan codes into directional commands
- **State Management**: Maintains current game state (active, ended, paused)
- **Collision Detection Interface**: Communicates with VGA module for pixel-perfect collision detection
- **Score Tracking**: Increments score counter upon successful pellet collection

#### Movement Controller (`pacman_movement.v`)

Implements the Pacman character movement mechanics using a finite state machine. The module calculates movement vectors based on player input and maze geometry, performing multi-point collision checks to ensure the character cannot pass through walls.

**Collision Detection Algorithm:**
- Samples 5 points along the leading edge of the character sprite
- Converts 2D coordinates to 1D memory address: `address = (y × 160) + x`
- Checks maze data ROM for wall presence at each sample point
- Blocks movement if any sample point detects a collision

```verilog
// Multi-point collision checking example
assign maze_address = (pacman_y * 17'd160) + pacman_x;
assign up_pixel_0 = maze_address - 17'd482;
assign up_pixel_1 = maze_address - 17'd481;
// ... additional sample points
```

#### VGA Rendering System

The system employs dual VGA rendering paths for start screen and game screen, with multiplexing logic controlled by game state.

**Game Screen Renderer (`pacman_pixel.v`):**
- Real-time pixel generation synchronized to VGA timing
- Sprite rendering with position-based coordinate transformation
- Background maze rendering from ROM data
- Dynamic color generation based on game state (normal, collision animation)

**Start Screen Renderer (`pacmaze_screen.v`):**
- Loads background image from MIF (Memory Initialization File)
- Resolution: 160 × 120 pixels
- Color depth: 3 bits per pixel (8 colors)
- Background file: `titlefinal.mif`


#### PS/2 Keyboard Interface (`PS2_Demo.v`)

Implements bidirectional PS/2 communication protocol for keyboard input. The module handles clock stretching, data packet reception, and scan code translation.

- **Protocol Implementation**: Manages PS/2 clock and data lines with proper timing
- **Scan Code Decoding**: Converts raw scan codes to directional commands (WASD or arrow keys)
- **Debouncing**: Internal debounce logic prevents spurious input signals

#### Audio System (`audio_demo.v`)

Controls the I2S audio codec for sound generation. The module manages I2C configuration and audio sample streaming.

- **I2C Interface**: Configures audio codec registers via FPGA_I2C_SDAT and FPGA_I2C_SCLK
- **Audio Streaming**: Transmits audio samples through AUD_DACDAT at 48 kHz sample rate
- **Clock Generation**: Produces master audio clock (AUD_XCK) for codec synchronization

#### Timer and Display

**Countdown Timer (`count_down.v`):**
- Prescaled clock divider from 50 MHz system clock
- Decrements game timer displayed on HEX2 and HEX3 displays
- Generates timeout signal when timer reaches zero

**7-Segment Decoder (`seg7_decoder.v`):**
- Converts 4-bit binary score value to 7-segment display format
- Displays current score on HEX1 display
- Hexadecimal representation (0-9, A-F)

## Signal Interface

### Primary I/O Ports

**Clock and Reset:**
- `CLOCK_50`: 50 MHz system clock input
- `KEY[0]`: Active-low reset button
- `KEY[1]`: Reserved
- `KEY[2]`: Reserved  
- `KEY[3]`: Reserved

**Switches:**
- `SW[0]`: Audio control
- `SW[1]`: Game restart toggle
- `SW[2]`: Reserved
- `SW[3]`: Audio mode selection

**VGA Output:**
- `VGA_CLK`: 25 MHz pixel clock (50 MHz divided by 2)
- `VGA_HS`: Horizontal synchronization pulse
- `VGA_VS`: Vertical synchronization pulse
- `VGA_BLANK_N`: Active-low blanking signal
- `VGA_SYNC_N`: Active-low sync signal
- `VGA_R[7:0]`: Red color channel (8-bit)
- `VGA_G[7:0]`: Green color channel (8-bit)
- `VGA_B[7:0]`: Blue color channel (8-bit)

**PS/2 Interface:**
- `PS2_CLK`: Bidirectional keyboard clock line
- `PS2_DAT`: Bidirectional keyboard data line

**Audio Interface:**
- `AUD_XCK`: Master audio clock output
- `AUD_DACDAT`: Audio data output to codec
- `AUD_ADCDAT`: Audio data input from codec
- `AUD_BCLK`: Bit clock for I2S communication
- `AUD_DACLRCK`: Left/right channel clock for DAC
- `AUD_ADCLRCK`: Left/right channel clock for ADC
- `FPGA_I2C_SDAT`: I2C data line for codec configuration
- `FPGA_I2C_SCLK`: I2C clock line for codec configuration

**Display Outputs:**
- `HEX1[6:0]`: 7-segment display for score
- `HEX2[6:0]`: 7-segment display for timer tens place
- `HEX3[6:0]`: 7-segment display for timer ones place
- `HEX4[6:0]`: Keyboard status display
- `HEX5[6:0]`: Keyboard status display
- `LEDR[9:0]`: Status indicator LEDs

## Game Mechanics

### Movement System

The game implements grid-based movement with smooth pixel-level positioning. Player movement is constrained to orthogonal directions (up, down, left, right) with collision detection preventing wall traversal.

**Coordinate System:**
- X-axis: 9-bit value (0-159 pixels)
- Y-axis: 8-bit value (0-119 pixels)
- Origin: Top-left corner (0, 0)

### Collision Detection

Collision detection operates at the pixel level, checking multiple points along the character sprite perimeter before allowing movement. The maze data is stored in read-only memory, with each pixel represented by a single bit indicating wall presence.

**Collision Resolution:**
1. Calculate proposed movement coordinates
2. Sample 5 points along leading edge of sprite
3. Query maze ROM at each sample point
4. Block movement if wall detected at any point
5. Trigger collision animation state if blocked

### Scoring System

The scoring mechanism increments a 4-bit counter upon pellet collection, with the maximum score limited to 15 (hexadecimal F). Score is displayed on HEX1 in hexadecimal format.

### Game States

The system maintains several discrete states:

- **START_SCREEN**: Initial state displaying title screen
- **PLAYING**: Active gameplay state with timer running
- **COLLISION**: Temporary state during collision animation
- **GAME_OVER**: End state triggered by timer expiration or win condition

State transitions are controlled by:
- Timer expiration (`time_out` signal)
- Win condition detection (`game_ended` signal)
- Reset button press (`KEY[0]`)
- Restart switch toggle (`SW[1]`)

## Implementation Details

### Clock Domain Management

The system operates across multiple clock domains:

- **System Clock Domain (50 MHz)**: Main game logic, keyboard processing, audio control
- **VGA Clock Domain (25 MHz)**: Pixel generation and video timing
- **Audio Clock Domain (Variable)**: I2S sample rate clock (typically 48 kHz derived clock)

Clock domain crossings are handled through synchronizer flip-flops where necessary, particularly for user input signals that may arrive asynchronously.

### Memory Organization

**Maze Data Storage:**
- Total pixels: 160 × 120 = 19,200 pixels
- Memory width: 1 bit per pixel (wall/empty)
- Total memory required: 19,200 bits (2,400 bytes)
- Access pattern: Read-only during gameplay
- Addressing: Linear addressing scheme `address = (y × 160) + x`

**Background Image Storage:**
- Format: MIF (Memory Initialization File)
- Resolution: 160 × 120 pixels
- Color depth: 3 bits per pixel
- Total memory: 19,200 × 3 = 57,600 bits

### Performance Characteristics

- **Frame Rate**: 60 Hz (standard VGA refresh rate)
- **Pixel Clock**: 25 MHz
- **Collision Check Latency**: Single clock cycle per sample point
- **Input Response Time**: ~2-3 clock cycles from keyboard input to movement update

## Build and Deployment

### Prerequisites

- Intel Quartus Prime (or compatible FPGA development environment)
- Target FPGA: Intel/Altera Cyclone IV or compatible device
- VGA-compatible monitor
- PS/2 keyboard
- Audio codec (WM8731 or compatible)

### Compilation Steps

1. Create a new Quartus Prime project
2. Add all Verilog source files from `Final Submission Files/` directory
3. Specify target FPGA device in project settings
4. Assign pin locations according to target board pinout
5. Set timing constraints for 50 MHz system clock and 25 MHz VGA clock
6. Run synthesis and place-and-route
7. Generate programming file (.sof or .pof)

### Configuration Files

Required configuration files:
- Pin assignment file (.qsf)
- Timing constraint file (.sdc)
- Memory initialization files (.mif) for maze and background data

## Testing and Verification

### Functional Testing

Test cases cover the following scenarios:

1. **Input Verification**: Keyboard input correctly translates to movement commands
2. **Collision Detection**: Character correctly stops at wall boundaries
3. **Timer Functionality**: Countdown timer decrements at correct rate
4. **Score Tracking**: Score increments appropriately upon pellet collection
5. **State Transitions**: Game correctly transitions between states based on conditions
6. **VGA Output**: Video signals meet VGA timing specifications
7. **Audio Output**: Audio codec correctly configured and produces sound

### Timing Analysis

Static timing analysis confirms:
- All paths meet setup and hold time requirements
- Clock skew is within acceptable limits
- Cross-domain signals are properly synchronized

## Project Structure

```
Project_ECE241/
├── Final Submission Files/
│   ├── top_level.v              # Top-level integration module
│   ├── pacman_logic.v           # Main game logic controller
│   ├── pacman_movement.v        # Movement FSM and collision logic
│   ├── pacman_pixel.v           # VGA game screen renderer
│   ├── pacmaze_screen.v         # VGA start screen renderer
│   ├── connect_vga.v            # VGA interface and collision detection
│   ├── PS2_Demo.v               # PS/2 keyboard interface
│   ├── audio_demo.v             # I2S audio controller
│   ├── count_down.v             # Game timer module
│   ├── delay_counter.v          # Delay generation utility
│   ├── intel_sound.v            # Intel audio IP wrapper
│   └── seg7_decoder.v           # 7-segment display decoder
├── docs/
│   └── images/                  # Documentation images (placeholders)
└── README.md                    # This file
```

## Technical Specifications

| Parameter | Specification |
|-----------|--------------|
| Target FPGA | Intel/Altera Cyclone IV (or compatible) |
| System Clock | 50 MHz |
| VGA Resolution | 160 × 120 pixels |
| VGA Refresh Rate | 60 Hz |
| Color Depth | 3 bits per pixel (8 colors) |
| Pixel Clock | 25 MHz |
| Audio Sample Rate | 48 kHz |
| PS/2 Clock Frequency | ~10-16.7 kHz |
| Score Range | 0-15 (4-bit) |
| Timer Resolution | 1 second per count |

## Future Enhancements

Potential improvements for future iterations:

- Increased resolution support (320 × 240 or higher)
- Expanded color palette (8-bit or 24-bit color depth)
- Ghost AI implementation with pathfinding algorithms
- Power pellet mechanics with state changes
- Multiple maze layouts
- High score persistence using non-volatile memory
- Sound effects synchronized with game events
- Animated sprite frames for character movement

## References

- VGA Video Timing Standards
- PS/2 Keyboard Protocol Specification
- I2S Audio Interface Specification
- Intel/Altera FPGA Documentation

## License

This project is developed for educational purposes as part of ECE241 coursework.

---

