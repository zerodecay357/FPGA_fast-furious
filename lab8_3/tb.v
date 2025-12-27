`timescale 1ns / 1ps

module Display_sprite_tb;

    reg clk;
    reg btnc_raw;
    reg btnr_raw;
    reg btnl_raw;

    wire HS;
    wire VS;
    wire [11:0] vgaRGB;

    // Instantiate the Device Under Test (DUT)
    Display_sprite #(
        .pixel_counter_width(10),
        .OFFSET_BG_X(200),
        .OFFSET_BG_Y(150)
    ) dut (
        .clk(clk),
        .btnc_raw(btnc_raw),
        .btnr_raw(btnr_raw),
        .btnl_raw(btnl_raw),
        .HS(HS),
        .VS(VS),
        .vgaRGB(vgaRGB)
    );

    // --- SPYING ON INTERNAL SIGNALS ---
    // FSM States
    wire [2:0] fsm_state      = dut.car_fsm.current_state;
    wire       fsm_stop       = dut.car_fsm.stop;
    
    // Positions
    wire [9:0] player_x       = dut.car_position_dynamic;
    wire [9:0] player_y       = dut.car_y; // Fixed at 300
    wire [9:0] rival_x        = dut.rival_x_pos;
    wire [9:0] rival_y        = dut.rival_y_pos;
    
    // Random Number Generator
    wire [6:0] random_val     = dut.rival_random;
    wire [7:0] lfsr_internal  = dut.lsfr.lfsr_reg; // Peek inside the LFSR
    
    // Background
    wire [7:0] bg_scroll      = dut.scroll_shifter;
    wire       collision      = dut.collision;

    // Clock Generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- SIMULATION SEQUENCE ---
    initial begin
        $display("==================================================");
        $display("SIMULATION START");
        $display("==================================================");

        // 1. Initialize
        btnc_raw = 1; // Reset pressed
        btnr_raw = 0;
        btnl_raw = 0;
        #1000;
        
        // Check Initial Random Seed visibility
        $display("[INIT] Random Value at Reset: %h (Should be SEED or valid)", random_val);
        
        btnc_raw = 0; // Release Reset
        #1000;
        
        $display("[START] Game running. Player Y: %d. Rival Y: %d", player_y, rival_y);


        // 2. Verify Background and Rival Movement
        // We wait for the rival to move a bit to prove the game is live
        wait (rival_y > 160); 
        $display("[MOVEMENT] Rival detected moving. Current Y: %d", rival_y);
        $display("[BG CHECK] Current BG Scroll Offset: %d", bg_scroll);


        // 3. Test Random Number Generation (Wait for Respawn)
        $display("--------------------------------------------------");
        $display("[RANDOM] Waiting for Rival to pass bottom of screen to trigger new Random #...");
        
        // Rival falls off screen around Y = 150 + 240 = 390. 
        // Wait until it resets to top (Y = 150).
        wait (rival_y == 150); 
        
        #1000; // Wait a tiny bit for latching
        $display("[RANDOM] Rival Respawned! New Random Value: %h", random_val);
        $display("[RANDOM] Rival New X Position: %d", rival_x);


        // 4. Setup Collision
        $display("--------------------------------------------------");
        $display("[COLLISION] waiting for Rival to approach Player (Y=280)...");
        
        // Wait until rival is just above the player
        wait (rival_y >= 280);
        
        // FORCE ALIGNMENT: To guarantee a crash for this test, 
        // we force the player X to match the rival X exactly.
        // This ensures we test the *Collision Logic*, not your driving skills.
        force dut.car_position_dynamic = rival_x;
        
        $display("[COLLISION] ALIGNING CARS! Player forced to X=%d to hit Rival at X=%d", rival_x, rival_x);

        // Wait for the hardware to detect the collision
        wait (collision == 1'b1);
        $display("[COLLISION] IMPACT DETECTED! Collision Wire is HIGH.");


        // 5. Verify Stop Logic and Background Freeze
        // Wait a few clock cycles for FSM to transition
        #(1000); 
        
        if (fsm_state == 3'b011) // COLLIDE state
            $display("[FSM] State correctly transitioned to COLLIDE (3'b011).");
        else
            $display("[FSM] ERROR: State is %b (Expected COLLIDE)", fsm_state);

        if (fsm_stop == 1'b1)
            $display("[STOP] Stop signal is ACTIVE.");
        else
            $display("[STOP] ERROR: Stop signal is inactive.");

        // Release the forced position (cleanup)
        release dut.car_position_dynamic;


        // 6. Check Background Freeze
        $display("--------------------------------------------------");
        $display("[FREEZE] Checking if background is frozen...");
        
        // Capture current scroll
        // We store the value in a variable
        begin : check_freeze
            reg [7:0] frozen_val;
            frozen_val = bg_scroll;
            
            $display("[FREEZE] Scroll value at crash: %d", frozen_val);
            
            // Wait for what WOULD be many frames of movement
            #(20_000_000); 
            
            $display("[FREEZE] Scroll value after wait: %d", bg_scroll);
            
            if (bg_scroll == frozen_val)
                $display("[PASS] Background did not move. FREEZE SUCCESSFUL.");
            else
                $display("[FAIL] Background moved! Logic error.");
        end

        $display("==================================================");
        $finish;
    end

endmodule