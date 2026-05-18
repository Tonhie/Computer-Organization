`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2026 06:14:24 PM
// Design Name: 
// Module Name: DIVU_tb
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

module DIVU_tb;
    reg [31:0] dividend, divisor;
    reg start, clock, reset;
    wire [31:0] q, r;
    wire busy;

    DIVU uut (
        .dividend(dividend), .divisor(divisor),
        .start(start), .clock(clock),
        .reset(reset), .q(q), .r(r), .busy(busy)
    );

    // 时钟：10ns 周期
    initial clock = 0;
    always #5 clock = ~clock;

    // 等待运算完成的任务
    task do_div;
        input [31:0] a, b;
        begin
            dividend = a; divisor = b;
            @(posedge clock); #1;
            start = 1;
            @(posedge clock); #1;
            start = 0;
            wait(!busy);
            @(posedge clock); #1;
            $display("DIVU: %0d / %0d = q=%0d, r=%0d  (expect q=%0d, r=%0d)",
                a, b, q, r, a/b, a%b);
        end
    endtask

    initial begin
        reset = 1; start = 0; dividend = 0; divisor = 1;
        @(posedge clock); #1;
        reset = 0;

        do_div(100,      7);
        do_div(0,        1);
        do_div(1,        1);
        do_div(32'hFFFF_FFFF, 32'hFFFF_FFFF);   // 最大值 / 最大值
        do_div(32'hFFFF_FFFF, 3);
        do_div(1000000,  999);

        $finish;
    end
endmodule