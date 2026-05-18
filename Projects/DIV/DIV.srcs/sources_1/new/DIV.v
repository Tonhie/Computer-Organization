`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2026 03:32:13 PM
// Design Name: 
// Module Name: DIV
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

module DIV( 
    input [31:0]dividend, 
    input [31:0]divisor,    
    input start,    
    input clock, 
    input reset, 
    output [31:0]q,    
    output [31:0]r,    
    output busy 
);
    reg[4:0] count;
    reg[31:0] reg_q;
    reg reg_q_sign;
    reg[31:0] reg_r;
    reg reg_r_sign;
    reg reg_busy;
    reg reg_sign;
    wire [31:0] abs_dividend = dividend[31] ? ~dividend + 1 : dividend;
    wire [31:0] abs_divisor = divisor[31] ? ~divisor + 1 : divisor;

    wire [32:0] sub_add = reg_sign ?
        ({reg_r, reg_q[31]} + {1'b0, abs_divisor}): 
        ({reg_r, reg_q[31]} - {1'b0, abs_divisor});

    wire [31:0] true_r_mag = reg_sign ? (reg_r + abs_divisor) : reg_r;
    assign q = reg_q_sign ? (~reg_q + 1'b1) : reg_q;
    assign r = reg_r_sign ? (~true_r_mag + 1'b1) : true_r_mag;
    assign busy = reg_busy;

    always @(posedge clock) begin
        if (reset) begin
            count <= 6'b0;
            reg_busy <= 0;
        end else begin
            if (start) begin
                count <= 0;
                reg_q <= abs_dividend;
                reg_r <= 0;
                reg_q_sign  <= dividend[31] ^ divisor[31];
                reg_r_sign  <= dividend[31];
                reg_sign <= 0;
                reg_busy <= 1;
            end else if (busy) begin
                reg_r <= sub_add[31:0];
                reg_sign <= sub_add[32];
                reg_q <= {reg_q[30:0], ~sub_add[32]};
                count <= count + 1;
                if (count == 5'd31) reg_busy <= 0;
            end
        end
    end

endmodule