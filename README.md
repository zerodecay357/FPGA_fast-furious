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
