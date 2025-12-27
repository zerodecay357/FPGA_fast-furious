# FPGA Car Game Documentation

This documentation details the design, implementation, and execution of the **FPGA Car Game**, a racing arcade simulator developed for the **COL215: Digital Logic and System Design** course. The system is implemented on a **Xilinx Artix-7 (Basys3)** board and involves VGA interfacing, custom Finite State Machines (FSM), and real-time hardware control.

---

## 🛠️ System Architecture & Design Decisions

The project is structured into three main parts: basic VGA display, interactive control logic, and autonomous rival car movement.

### Core Design Decisions

* 
**Finite State Machine (FSM)**: A robust FSM manages game states including start, movement (left/right), collision, and idle. This centralizes the control logic for easier debugging and hardware efficiency.


* 
**Hit Box Logic**: A rectangular **14x16 pixel hit box** is used for the car. This design choice simplifies collision detection by checking for overlaps between simple bounding boxes rather than complex pixel-perfect shapes.


* 
**Movement Granularity**: Car movement occurs at a **per-pixel level** when buttons are held, chosen to provide visual smoothness on the VGA monitor.


* 
**Vertical Speed Control**: The rival car's vertical coordinate updates every **15 frames**, a threshold selected to ensure movement is visible and smooth without being excessively fast for the player.


* 
**Randomness**: To ensure a unique gameplay experience, the rival car's spawning position is randomized using an **8-bit Linear Feedback Shift Register (LFSR)**. The LFSR is seeded with a unique group-specific value (XOR of team Kerberos IDs).



---

## 📖 Finite State Machine (FSM) Implementation

The FSM is the "brain" of the car game, implemented in Verilog using a dual-block structure: a **State Register (sequential)** for state updates and a **Combinational Block** for next-state logic.

### Primary States

1. 
**START**: The initial state where the car is drawn at a fixed position (270, 300).


2. 
**LEFT_CAR / RIGHT_CAR**: Triggered when BTNL or BTNR is pressed, updating the car's horizontal position.


3. 
**IDLE**: The state when no movement buttons are pressed and the car is within road boundaries.


4. 
**COLLIDE**: Entered if the car crosses road boundaries ( or ) or overlaps with the rival car.



### FSM Transition Logic

The FSM continuously monitors input signals (buttons) and internal signals (collision flags) to transition between states.

---

## 💻 Implementation Details (Code Blocks)

The project consists of several critical Verilog modules:

### 1. VGA Driver & Image Rendering

* 
**VGA_driver.v**: Generates `HSYNC` and `VSYNC` signals for 640x480 resolution.


* 
**bg_rom & main_car_rom**: Single-port ROMs that store pixel data for the background and cars.


* 
**Transparency MUX**: Logic that checks for "pink" background pixels (12'b101000001010) in the car sprite and replaces them with background ROM data for a transparent effect.



### 2. Collision Detection Block

Collision is checked combinatorially by comparing the hit boxes:

```verilog
// Pseudocode for Collision Logic
collision = (car_x < 244) || (car_x + 14 > 318) || 
            (hitbox_overlap(main_car, rival_car)); // Part III addition

```

*cite: 63, 64, 65, 140, 362*

### 3. LFSR Random Generator

* 
**Mechanism**: Uses 8 D-flip-flops with bitwise XOR feedback from the 4th, 5th, 6th, and 8th flops.


* 
**Application**: The output determines the `rival_x_pos` between pixels 44 and 104.



---

## 🚀 How to Run the Project

### Prerequisites

* 
**Xilinx Vivado** (for synthesis and implementation).


* 
**Basys3 Development Board**.


* 
**VGA Monitor** and cable.



### Execution Steps

1. 
**Project Setup**: Create a new project in Vivado targeting the **Artix-7 xc7a35tcpg236-1** chip.


2. 
**Add Sources**: Add the Verilog modules (`Display_sprite.v`, `VGA_driver.v`, FSM logic) and `.coe` files for the ROMs.


3. 
**Constraints**: Update the `.xdc` file with the correct pin mappings for the VGA port and push buttons (BTNL, BTNR, BTNC).


4. 
**Synthesis & Implementation**: Run the synthesis and implementation tools to generate the bitstream.


5. 
**Program FPGA**: Connect the Basys3 board and load the generated **.bit file**.


6. **Controls**:
* 
**BTNL/BTNR**: Move car left/right.


* 
**BTNC**: Reset the game after a collision.





---

## 📝 Performance & Utilization

The final design is highly efficient, utilizing approximately:

* 
**Slice LUTs**: ~1.20%.


* 
**Block RAM**: ~29.00% (used primarily for background and car ROMs).


* 
**DSP Slices**: 2.22%.



*Cite: 88, 167*

Would you like a sample Verilog template for the 8-bit LFSR used in the rival car implementation?
