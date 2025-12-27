`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IITD
// Engineer: Shivanshu Aryan
// 
// Create Date: 23.10.2025 06:57:49
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench;

reg clk;
wire HS, VS;
wire [11:0] vgaRGB;

initial clk = 0; 


always #5 clk = ~clk; 


Display_sprite Disp(
.clk(clk),
.HS(HS),
.VS(VS),
.vgaRGB(vgaRGB)
);

initial begin

#20_000_000;//480*640*40ns

end






    
    
    
endmodule
