`timescale 1ns / 1ps


module Display_sprite #(
        parameter pixel_counter_width = 10,
        parameter OFFSET_BG_X = 200,
        parameter OFFSET_BG_Y = 150
    )
    (
        input clk,
        input btnc_raw,
        input btnr_raw,
        input btnl_raw,

        output HS, VS,
        output [11:0] vgaRGB
    );

    localparam bg1_width = 160;
    localparam bg1_height = 240;

    localparam main_car_width = 14;
    localparam main_car_height = 16;


    wire pixel_clock;
    wire [3:0] vgaRed, vgaGreen, vgaBlue;
    wire [pixel_counter_width-1:0] hor_pix, ver_pix;
    reg [11:0] output_color;
    reg [11:0] next_color;
    reg [15:0] bg_rom_addr;
    wire [11:0] bg_color;
    reg [7:0] car_rom_addr;
    wire [11:0] car_color;



    reg bg_on, car_on;
    wire [pixel_counter_width-1:0] car_x, car_y;


    wire frame_completed;
    assign frame_completed = (hor_pix == 799) && (ver_pix == 479);

    reg [7:0] frame_counter = 0;
    reg scroll_high;
     wire stop;

    localparam SCROLL_SPEED = 3;

    always @(posedge clk) begin
    if(stop)begin
        scroll_high <= 1'b0;


    end
        else if (frame_completed) begin
            if (frame_counter == SCROLL_SPEED - 1) begin
                frame_counter <= 0;
                scroll_high <= 1'b1;
            end
            else begin
                frame_counter <= frame_counter + 1;
                scroll_high <= 1'b0;
            end
        end
        else begin
            scroll_high <= 1'b0;
        end
    end

    reg [7:0] scroll_shifter = 0;

    always @(posedge clk) begin
        if (scroll_high) begin
            if (scroll_shifter == bg1_height - 1)
                scroll_shifter <= 0;
            else
                scroll_shifter <= scroll_shifter + 1;
        end
    end

    // ========== END SCROLLING LOGIC ==========


    //Main display driver
    VGA_driver #(
        .WIDTH(pixel_counter_width)
    )   display_driver (
        .clk(clk),
        .vgaRed(vgaRed), .vgaGreen(vgaGreen), .vgaBlue(vgaBlue),
        .HS(HS),
        .VS(VS),
        .vgaRGB(vgaRGB),
        .pixel_clock(pixel_clock),
        .hor_pix(hor_pix),
        .ver_pix(ver_pix)
    );

    bg_rom bg1_rom (
        .clka(clk),
        .addra(bg_rom_addr),
        .douta(bg_color),
        .ena(1'b1)
    );

    main_car_rom car1_rom (
        .clka(clk),
        .addra(car_rom_addr),
        .douta(car_color),
        .ena(1'b1)
    );

    reg [pixel_counter_width-1:0] car_position_dynamic = 270;

    assign car_x = car_position_dynamic;
    assign car_y = 300;

    wire move_right_signal;
    wire move_left_signal;
    wire reset_car_signal;

    Controller car_fsm (
        .clk(clk),
        .rst(btnc_raw),
        .btnr_raw(btnr_raw),
        .btnl_raw(btnl_raw),
        .btnc_raw(btnc_raw),
        .car_pos_x(car_position_dynamic),

        .move_right(move_right_signal),
        .move_left(move_left_signal),
        .reset_car_pos(reset_car_signal),
        .stop(stop)
    );

    reg [7:0] movement_frame_counter = 0;
    localparam MOVEMENT_FRAME_THRESHOLD = 3;

    always @(posedge clk) begin
        if (frame_completed) begin
            if (movement_frame_counter == MOVEMENT_FRAME_THRESHOLD - 1) begin
                movement_frame_counter <= 0;

                // Perform movement only on this frame tick
                if (reset_car_signal) begin
                    car_position_dynamic <= 270;
                end
                else if (move_right_signal) begin
                    if (car_position_dynamic + main_car_width < 318) begin
                        car_position_dynamic <= car_position_dynamic + 1;
                    end
                end
                else if (move_left_signal) begin
                    if (car_position_dynamic > 244) begin
                        car_position_dynamic <= car_position_dynamic - 1;
                    end
                end

            end else begin
                movement_frame_counter <= movement_frame_counter + 1;
            end
        end
    end
    // ========== END CAR MOVEMENT ==========


    always @(posedge clk) begin : CAR_LOCATION
        if (hor_pix >= car_x && hor_pix < (car_x + main_car_width) &&
            ver_pix >= car_y && ver_pix < (car_y + main_car_height)) begin
            car_rom_addr <= (hor_pix - car_x) + (ver_pix - car_y) * main_car_width;
            car_on <= 1;
        end
        else begin
            car_on <= 0;
        end
    end

    integer bg_row_signed;
    reg [pixel_counter_width-1:0] bg_row;

    always @(posedge clk) begin : BG_LOCATION
        if (hor_pix >= OFFSET_BG_X && hor_pix < (OFFSET_BG_X + bg1_width) &&
            ver_pix >= OFFSET_BG_Y && ver_pix < (OFFSET_BG_Y + bg1_height)) begin

            
            bg_row_signed = (ver_pix - OFFSET_BG_Y) - scroll_shifter;

           
            if (bg_row_signed < 0) begin
                bg_row = bg_row_signed + bg1_height;
            end
        
            else if (bg_row_signed >= bg1_height) begin
                bg_row = bg_row_signed - bg1_height;
            end
          
            else begin
                bg_row = bg_row_signed;
            end

            bg_rom_addr <= (hor_pix - OFFSET_BG_X) + bg_row * bg1_width;
            bg_on <= 1;
        end
        else begin
            bg_on <= 0;
        end
    end
    // ========== END BACKGROUND INDEXING ==========


    always @(posedge pixel_clock) begin : MUX_VGA_OUTPUT
        if (car_on) begin
            if (car_color != 12'b101000001010) begin
                next_color <= car_color;
            end
            else begin
                next_color <= bg_color;
            end
        end
        else if (bg_on) begin
            next_color <= bg_color;
        end
        else
            next_color <= 0;
    end

    always @(posedge pixel_clock) begin
        output_color <= next_color;
    end

    assign vgaRed = output_color[11:8];
    assign vgaGreen = output_color[7:4];
    assign vgaBlue = output_color[3:0];


endmodule


module Controller(
    input clk,
    input rst,
    input btnr_raw,
    input btnl_raw,
    input btnc_raw,
    input [9:0] car_pos_x,
    output reg move_right,
    output reg move_left,
    output reg reset_car_pos,
    output reg stop
);
    wire btnr, btnc, btnl;

    debouncer debouncer_r (
        .clk(clk),
        .btn_in(btnr_raw),
        .stable_out(btnr)
    );

    debouncer debouncer_c (
        .clk(clk),
        .btn_in(btnc_raw),
        .stable_out(btnc)
    );

    debouncer debouncer_l (
        .clk(clk),
        .btn_in(btnl_raw),
        .stable_out(btnl)
    );

    localparam START     = 3'b000;
    localparam RIGHT_CAR = 3'b001;
    localparam LEFT_CAR  = 3'b010;
    localparam COLLIDE   = 3'b011;
    localparam IDLE      = 3'b100;

    reg [2:0] current_state = START;
    reg [2:0] next_state;

    always @(posedge clk) begin
        if (rst)
            current_state <= START;
        else
            current_state <= next_state;
    end

    always @(*) begin
        // Default assignments to prevent latches
        move_right    = 1'b0;
        move_left     = 1'b0;
        reset_car_pos = 1'b0;
        stop          = 1'b0;
        next_state    = current_state;

        case(current_state)
            START: begin
                reset_car_pos = 1'b1;
                next_state = IDLE;
            end

            IDLE: begin
                if (btnc == 1'b1) begin
                    next_state = START;
                end
                else if (btnr == 1'b1 && btnl == 1'b0) begin
                    next_state = RIGHT_CAR;
                end
                else if (btnr == 1'b0 && btnl == 1'b1) begin
                    next_state = LEFT_CAR;
                end
                else begin
                    next_state = IDLE;
                end
            end

            RIGHT_CAR: begin
                move_right = 1'b1;

                if (btnc == 1'b1) begin
                    next_state = START;
                end
                else if (car_pos_x + 14 >= 318) begin
                    next_state = COLLIDE;
                end
                else if (btnr == 1'b0) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = RIGHT_CAR;
                end
            end

            LEFT_CAR: begin
                move_left = 1'b1;

                if (btnc == 1'b1) begin
                    next_state = START;
                end
                else if (car_pos_x <= 244) begin
                    next_state = COLLIDE;
                end
                else if (btnl == 1'b0) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = LEFT_CAR;
                end
            end

            COLLIDE: begin
                stop=1'b1;

                if (btnc == 1'b1) begin
                    next_state = START;
                end
                else begin
                    next_state = COLLIDE;
                end
            end

            default: begin
                next_state = START;
            end

        endcase
    end

endmodule


module debouncer(
    input clk,
    input btn_in,
    output reg stable_out
);
    reg [19:0] counter;
    reg btn_in_sync1, btn_in_sync2;

    initial begin
        counter = 0;
        stable_out = 0;
        btn_in_sync1 = 0;
        btn_in_sync2 = 0;
    end

    // Two-stage synchronizer for metastability prevention
    always @(posedge clk) begin
        btn_in_sync1 <= btn_in;
        btn_in_sync2 <= btn_in_sync1;
    end

    // Debounce logic with ~10ms delay at 100MHz
    always @(posedge clk) begin
        if (stable_out == btn_in_sync2) begin
            counter <= 0;
        end else begin
            if (counter >= 20'd1000000) begin
                stable_out <= btn_in_sync2;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule