`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2026 01:40:38 PM
// Design Name: 
// Module Name: MULTU
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

module MULTU (
    input  clk,
    input  reset,
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] z
);
    reg [63:0] pipe1 [31:0];
    reg [63:0] pipe2 [15:0];
    reg [63:0] pipe3 [7:0];
    reg [63:0] pipe4 [3:0];
    reg [63:0] pipe5 [1:0];
    reg [63:0] pipe6;

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) pipe1[i] <= 64'b0;
            for (i = 0; i < 16; i = i + 1) pipe2[i] <= 64'b0;
            for (i = 0; i < 8;  i = i + 1) pipe3[i] <= 64'b0;
            for (i = 0; i < 4;  i = i + 1) pipe4[i] <= 64'b0;
            for (i = 0; i < 2;  i = i + 1) pipe5[i] <= 64'b0;
            pipe6 <= 64'b0;
        end else begin
            for (i = 0; i < 32; i = i + 1) pipe1[i] <= b[i] ? (a << i) : 64'b0;
            for (i = 0; i < 16; i = i + 1) pipe2[i] <= pipe1[2*i] + pipe1[2*i+1];
            for (i = 0; i < 8; i = i + 1) pipe3[i] <= pipe2[2*i] + pipe2[2*i+1];
            for (i = 0; i < 4; i = i + 1) pipe4[i] <= pipe3[2*i] + pipe3[2*i+1];
            for (i = 0; i < 2; i = i + 1) pipe5[i] <= pipe4[2*i] + pipe4[2*i+1];
            pipe6 <= pipe5[0] + pipe5[1];
        end
    end

    assign z = pipe6;

endmodule