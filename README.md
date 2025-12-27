# **FPGA Car Game Documentation**

This documentation covers the design, implementation, and execution of the **FPGA Car Racing Game**, a hardware-based arcade simulator developed for the **COL215: Digital Logic and System Design** course. The project is implemented on a **Xilinx Artix-7 (Basys3)** FPGA using VGA graphics, custom FSMs, and real-time hardware control logic.

---

## **🛠️ System Architecture & Design Decisions**

The project is organized into three main subsystems: **VGA Display & Rendering**, **Interactive Control Logic**, and **Autonomous Rival Car & Random Movement**.

### **Core Design Decisions**

| Design Element | Decision | Reason |
| --- | --- | --- |
| **FSM Control** | Centralized Finite State Machine 

 | Clean debugging & deterministic logic 

 |
| **Hit Box Logic** | 14x16 rectangular bounds 

 | Fast collision detection (bounding box) 

 |
| **Movement Granularity** | 1 pixel per update 

 | Smooth visual tracking on VGA 

 |
| **Vertical Speed** | Update rival car every 15 frames 

 | Balance visibility & difficulty 

 |
| **Randomness** | 8-bit LFSR 

 | Unique gameplay per team 

 |

---

## **📖 Finite State Machine (FSM)**

The FSM is the "brain" of the game, implemented in Verilog using a **sequential state register** and **combinational next-state logic**. It dictates gameplay flow based on push-button input and collision conditions.

### **Primary FSM States**

**START**: Initial state where the car is at a fixed position.


**LEFT_CAR / RIGHT_CAR**: Car moves horizontally based on `BTNL` or `BTNR` button input.


**IDLE**: State when no buttons are pressed and the car is within lane boundaries.


**COLLIDE**: Triggered if the car hits road boundaries or overlaps with the rival car.


**RESET**: Returns the game to the `START` state via the `BTNC` button.



---

## **💻 Implementation Details (Code Blocks)**

The project is composed of multiple modules that interact in real-time to generate video output and gameplay.

### **1. VGA Driver & Image Rendering**


**VGA_driver.v**: Generates `HSYNC` and `VSYNC` signals for 640x480 resolution.


**ROMs**: Single-port ROMs (`bg_rom`, `main_car_rom`, `rival_car_rom`) store pixel data for the background and cars.

 
**Transparency MUX**: Uses a "pink key" (color `12'b101000001010`) to replace car sprite backgrounds with actual game background pixels.



```verilog
// Transparency Example (MUX)
assign pixel_out = (car_pixel == 12'b101000001010) 
                   ? bg_pixel 
                   : car_pixel;

```

### **2. Collision Detection Block**

Collision is checked combinatorially by comparing hit boxes and road boundaries.

```verilog
// Collision Logic (Pseudocode)
collision = (car_x < 244) || (car_x + 14 > 318) || 
            ((car_x < rival_x + 14) && 
             (car_x + 14 > rival_x) && 
             (car_y < rival_y + 16) && 
             (car_y + 16 > rival_y));

```

### **3. 8-bit LFSR Random Generator**

To ensure varied gameplay, an 8-bit Linear Feedback Shift Register (LFSR) determines the rival car's spawning position.

```verilog
// 8-bit LFSR Implementation
module LFSR (
    input  wire clk,
    input  wire reset,
    output reg [7:0] out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            out <= 8'hA5; // Seed: XOR of team Kerberos IDs
        else
            out <= {out[6:0], out[7] ^ out[5] ^ out[4] ^ out[3]};
    end
endmodule

```

---

## **🚀 How to Run the Project**

### **Prerequisites**

**Xilinx Vivado**: For synthesis, implementation, and bitstream generation.


**Basys3 Development Board**: Target hardware (Artix-7 xc7a35tcpg236-1).


**VGA Monitor & Cable**: To view the game output.



### **Execution Steps**

1. **Project Setup**: Create a new Vivado project targeting the **Artix-7 xc7a35tcpg236-1** chip.


2. **Add Sources**: Include Verilog modules (`Display_sprite.v`, `VGA_driver.v`, etc.) and `.coe` files for ROM initialization.


3. **Constraints**: Map `BTNL`, `BTNR`, and `BTNC` buttons and VGA pins in the `.xdc` file.


4. **Bitstream**: Run **Synthesis → Implementation → Generate Bitstream**.


5. **Program**: Connect the Basys3 board and load the **.bit file** via Hardware Manager.



### **Controls**

| Button | Function |
| --- | --- |
| **BTNL** | Move car left |
| **BTNR** | Move car right |
| **BTNC** | Reset game after collision |

---

## **📊 FPGA Resource Usage Summary**

The design is optimized for hardware efficiency on the Artix-7:

| Resource | Usage (%) | Notes |
| --- | --- | --- |
| **Slice LUTs** | ~1.15% | Minimal logic footprint 

 |
| **Block RAM** | ~28.00% | Primarily for background and sprite ROMs 

 |
| **DSP Slices** | 2.22% | Used for timing and update rate logic 

 |
| **Flip-Flops (FFs)** | 0.47% | FSM and LFSR registers 

 |

---

## **🎮 Outcome**

The final system successfully implements a real-time racing game with smooth VGA graphics, deterministic hardware FSM control, randomized enemy behavior, and hardware-level collision detection.
