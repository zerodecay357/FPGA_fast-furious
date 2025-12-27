# **FPGA Car Game Documentation**

This documentation covers the design, implementation, and execution of the **FPGA Car Racing Game**, a hardware-based arcade simulator developed for the **COL215: Digital Logic and System Design** course.  
The project is implemented on a **Xilinx Artix-7 (Basys3)** FPGA using VGA graphics, custom FSMs, and real-time hardware control logic.

---

## **🛠️ System Architecture & Design Decisions**

The project is organized into three main subsystems:

1. **VGA Display & Rendering**
2. **Interactive Control Logic**
3. **Autonomous Rival Car & Random Movement**

### **Core Design Decisions**

| Design Element | Decision | Reason |
|---------------|-----------|--------|
| FSM Control | Centralized finite state machine | Clean debugging & deterministic logic |
| Hit Box Logic | 14x16 rectangular bounds | Fast collision detection (bounding box) |
| Movement Granularity | 1 pixel per update | Smooth visual tracking on VGA |
| Vertical Speed | Update rival car every 15 frames | Balance visibility & difficulty |
| Randomness | 8-bit LFSR (XOR of Kerberos IDs as seed) | Unique gameplay per team |

---

## **📖 Finite State Machine (FSM)**

The FSM is implemented in Verilog using a **sequential state register** and **combinational next-state logic**.  
It dictates gameplay flow based on push-button input and collision conditions.

### **Primary FSM States**

| State | Description |
|-------|--------------|
| `START` | Initial static position of main car |
| `LEFT_CAR / RIGHT_CAR` | Car moves based on BTNL / BTNR button |
| `IDLE` | Car stays within lane boundaries |
| `COLLIDE` | Triggered if car overlaps rival or exits road |
| `RESET` | Game restarts via BTNC button |

### **FSM Transition Summary**

```text
START → LEFT_CAR / RIGHT_CAR / IDLE (button input)
LEFT_CAR / RIGHT_CAR → COLLIDE (if boundary or hit)
COLLIDE → RESET (on BTNC)
RESET → START
```
💻 Verilog Implementation Overview

The project is composed of multiple modules that interact in real-time to generate video output and gameplay.

1️⃣ VGA Driver & Sprite Rendering

Modules Used

VGA_driver.v (HSYNC/VSYNC generation for 640×480 @ 60Hz)

bg_rom.v, main_car_rom.v, rival_car_rom.v

Transparency MUX using a “pink key” color: 12'b101000001010

// Transparency Example (MUX)
assign pixel_out = (car_pixel == 12'b101000001010) 
                   ? bg_pixel 
                   : car_pixel;

2️⃣ Collision Detection Logic

Collision check uses bounding box overlap & lane boundaries.

// Collision Logic (Pseudocode)
collision = (car_x < 244) || (car_x + 14 > 318) ||
            ((car_x < rival_x + 14) &&
             (car_x + 14 > rival_x) &&
             (car_y < rival_y + 16) &&
             (car_y + 16 > rival_y));

3️⃣ 8-bit LFSR Random Generator

The LFSR provides pseudorandom spawn positions for the rival car.

// 8-bit LFSR Template
module LFSR (
    input  wire clk,
    input  wire reset,
    output reg [7:0] out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            out <= 8'hA5; // Team-specific XOR seed
        else
            out <= {out[6:0], out[7] ^ out[5] ^ out[4] ^ out[3]};
    end
endmodule

🚀 How to Run on Hardware
Prerequisites

Xilinx Vivado (Synthesis + Bitstream)

Basys3 Board (Artix-7 XC7A35T)

VGA Monitor & Cable

Execution Steps

Create a new Vivado project (Artix-7 target: xc7a35tcpg236-1)

Add Verilog source files:

VGA_driver.v

Display_sprite.v

FSM_controller.v

ROM .coe files

Set pin constraints in .xdc file:

BTNL, BTNR, BTNC buttons

VGA R/G/B + HSYNC + VSYNC

Synthesize → Implement → Generate Bitstream

Program the FPGA

Controls
Button	Function
BTNL	Move car left
BTNR	Move car right
BTNC	Reset after collision
📊 FPGA Resource Usage Summary
Resource	Usage	Notes
Slice LUTs	~1.15%	Minimal logic footprint
Block RAM	~28.00%	Used for background & sprite ROM
DSP Slices	2.22%	For timing / update rate logic
Flip-Flops (FFs)	0.47%	FSM + LFSR registers
🎮 Outcome

The final system successfully implements a real-time racing game with:

✔ Smooth VGA graphics
✔ Deterministic hardware FSM control
✔ Randomized enemy behavior
✔ Hardware-level collision detection
