`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2026 03:49:30 PM
// Design Name: 
// Module Name: MULTU_tb
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

module MULTU_tb;

    reg         clk;
    reg         reset;
    reg  [31:0] a;
    reg  [31:0] b;
    wire [63:0] z;
    MULTU uut (
        .clk  (clk),
        .reset(reset),
        .a    (a),
        .b    (b),
        .z    (z)
    );
    always #5 clk = ~clk;
    initial begin
        clk   = 0;
        reset = 1;
        a     = 0;
        b     = 0;
        #12 reset = 0;
        // 等待复位释放后的稳定周期
        repeat (2) @(posedge clk);
        // 给几组随机数
        @(posedge clk) begin a = $random; b = $random; end
        @(posedge clk) begin a = $random; b = $random; end
        @(posedge clk) begin a = $random; b = $random; end
        @(posedge clk) begin a = $random; b = $random; end
        @(posedge clk) begin a = $random; b = $random; end
        // 等待结果稳定
        repeat (20) @(posedge clk);
    end

endmodule