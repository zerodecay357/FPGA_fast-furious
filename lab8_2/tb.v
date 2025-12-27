`timescale 1ns / 1ps

module Display_sprite_tb;

    reg clk;
    reg btnc_raw;
    reg btnr_raw;
    reg btnl_raw;

    wire HS;
    wire VS;
    wire [11:0] vgaRGB;

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

    wire [2:0] fsm_current_state = dut.car_fsm.current_state;
    wire       fsm_move_right    = dut.car_fsm.move_right;
    wire       fsm_move_left     = dut.car_fsm.move_left;
    wire       fsm_reset_car     = dut.car_fsm.reset_car_pos;
    wire       fsm_stop          = dut.car_fsm.stop;
    wire [9:0] car_x_pos         = dut.car_position_dynamic;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Start with buttons released
        btnc_raw = 0;
        btnr_raw = 0;
        btnl_raw = 0;

        // Wait for a few frames to pass
        #(200_000_000); // 200ms

        // --- Test 1: Press RIGHT button ---
        // Press and hold for 20ms (to beat 10ms debouncer)
        btnr_raw = 1;
        #(20_000_000); // 20ms
        
        // Hold for 100ms
        #(100_000_000);
        
        // Release button
        btnr_raw = 0;
        #(100_000_000); // Wait 100ms

        // --- Test 2: Press LEFT button ---
        // Press and hold for 20ms
        btnl_raw = 1;
        #(20_000_000);
        
        // Hold for 100ms
        #(100_000_000);
        
        // Release button
        btnl_raw = 0;
        #(100_000_000); // Wait 100ms

        // --- Test 3: Force LEFT collision ---
        $display("TEST 3: Forcing collision by holding LEFT");
        // Press and hold for 20ms (to beat debouncer)
        btnl_raw = 1;
        #(20_000_000);
        
        // Hold for 500ms to ensure car moves all the way left and hits boundary
        #(500_000_000); 
        $display("TEST 3: Collision should be active now (State: %h, Stop: %b)", fsm_current_state, fsm_stop);

        // Release button (FSM should stay in COLLIDE state)
        btnl_raw = 0;
        #(100_000_000); // Wait 100ms
        $display("TEST 3: Released LEFT, FSM should remain in COLLIDE (State: %h, Stop: %b)", fsm_current_state, fsm_stop);


        // --- Test 4: Press RESET button (after collision) ---
        $display("TEST 4: Pressing RESET to recover from collision");
        // Press and hold for 20ms
        btnc_raw = 1;
        #(20_000_000);
        
        // Release button
        btnc_raw = 0;
        #(100_000_000); // Wait 100ms
        $display("TEST 4: Released RESET, car should be reset (State: %h, CarX: %d)", fsm_current_state, car_x_pos);

        // End simulation
        $finish;
    end

endmodule
