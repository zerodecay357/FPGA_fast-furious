`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Delhi
// Engineer: Shivanshu Aryan
//
// Create Date: 30.10.2025 04:08:45
// Design Name:
// Module Name: shift_reg
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
//
//////////////////////////////////////////////////////////////////////////////////

module shift_reg #(
    parameter [7:0] SEED = 8'b10101111
)
(
    input clk,
    input reset, 
    input spawn, 
    output reg [6:0] random
);

    reg [7:0] lfsr_reg;

    wire feedback;
    assign feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[2];

    // Free-running LFSR
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr_reg <= SEED;
        end
        else begin
            lfsr_reg <= {lfsr_reg[6:0], feedback};
        end
    end

    // Output Snapshot Logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            random <= SEED[6:0]; 
        end
        else if (spawn) begin
            random <= lfsr_reg[6:0];
        end
    end

endmodule