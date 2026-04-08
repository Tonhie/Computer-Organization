`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2026 03:49:05 PM
// Design Name: 
// Module Name: MULT_tb
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

module MULT_tb;

    reg                clk;
    reg                reset;
    reg  signed [31:0] a;
    reg  signed [31:0] b;
    wire signed [63:0] z;

    MULT uut (
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
        repeat (2) @(posedge clk);
        @(posedge clk) begin a = $signed($random); b = $signed($random); end
        @(posedge clk) begin a = $signed($random); b = $signed($random); end
        @(posedge clk) begin a = $signed($random); b = $signed($random); end
        @(posedge clk) begin a = $signed($random); b = $signed($random); end
        @(posedge clk) begin a = $signed($random); b = $signed($random); end

        @(posedge clk) begin a =  32'sh7FFFFFFF; b =  32'sh7FFFFFFF; end
        @(posedge clk) begin a = -32'sh80000000; b = -32'sh80000000; end
        @(posedge clk) begin a =  32'sh7FFFFFFF; b = -32'sh80000000; end

        repeat (20) @(posedge clk);
    end
    
endmodule