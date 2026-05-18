`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2026 06:15:24 PM
// Design Name: 
// Module Name: DIV_tb
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

module DIV_tb;
    reg  [31:0] dividend, divisor;
    reg  start, clock, reset;
    wire [31:0] q, r;
    wire busy;

    DIV uut (
        .dividend(dividend), .divisor(divisor),
        .start(start), .clock(clock),
        .reset(reset), .q(q), .r(r), .busy(busy)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    // 将有符号值显示为十进制
    task do_div;
        input signed [31:0] a, b;
        begin
            dividend = a; divisor = b;
            @(posedge clock); #1;
            start = 1;
            @(posedge clock); #1;
            start = 0;
            wait(!busy);
            @(posedge clock); #1;
            $display("DIV: (%0d) / (%0d) = q=%0d, r=%0d  (expect q=%0d, r=%0d)",
                $signed(a), $signed(b),
                $signed(q), $signed(r),
                $signed(a) / $signed(b),
                $signed(a) % $signed(b));
        end
    endtask

    initial begin
        reset = 1; start = 0; dividend = 0; divisor = 1;
        @(posedge clock); #1;
        reset = 0;

        do_div( 100,   7);    //  + / +
        do_div(-100,   7);    //  - / +
        do_div( 100,  -7);    //  + / -
        do_div(-100,  -7);    //  - / -
        do_div(   1,   1);
        do_div(-1,     1);
        do_div(32'h8000_0000, 1);   // 最小负数 / 1

        $finish;
    end
endmodule