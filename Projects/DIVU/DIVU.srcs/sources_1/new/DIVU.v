`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2026 03:32:32 PM
// Design Name: 
// Module Name: DIVU
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

module DIVU( 
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
    reg[31:0] reg_r;
    reg reg_busy;
    reg reg_sign;

    wire [32:0] sub_add = reg_sign ?
        ({reg_r, reg_q[31]} + {1'b0, divisor}): 
        ({reg_r, reg_q[31]} - {1'b0, divisor});
        
    assign q = reg_q;
    assign r = reg_sign ? reg_r + divisor : reg_r;
    assign busy = reg_busy;
    
    always @(posedge clock) begin
        if (reset) begin
            count <= 5'b0;
            reg_busy <= 0;
            reg_sign <= 0;
        end else begin
            if (start) begin
                count <= 5'b0;
                reg_q <= dividend;
                reg_r <= 32'b0;
                reg_busy <= 1;
                reg_sign <= 0;
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