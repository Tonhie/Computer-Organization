`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2025 11:20:01 AM
// Design Name: 
// Module Name: alu
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


module alu(
    input [31:0] a,
    input [31:0] b,
    input [3:0] aluc,
    output reg [31:0] r,
    output reg zero,
    output reg carry,
    output reg negative,
    output reg overflow
    );
    wire [32:0] add_result = {1'b0, a} + {1'b0, b};
    wire [32:0] sub_result = {1'b0, a} - {1'b0, b};
    wire [31:0] and_result = a & b;
    wire [31:0] or_result = a | b;
    wire [31:0] xor_result = a ^ b;
    wire [31:0] nor_result = ~(a | b);
    wire [31:0] lui_result = {b[15:0], 16'b0};
    wire [32:0] sra_result = $signed({b, 1'b0}) >>> a;
    wire [32:0] sll_result = {1'b0, b} << a;
    wire [32:0] srl_result = {b, 1'b0} >> a; 
          
    wire signed_compare, unsigned_compare;
    assign signed_compare = $signed(a) < $signed(b);
    assign unsigned_compare = a < b;
    
    always @(*) begin
        casex(aluc)
            4'b0000: {carry, r} = add_result;
            4'b0010: begin
                r = add_result[31:0];
                overflow = (r[31] ^ a[31]) & (r[31] ^ b[31]);
                zero = (r == 32'b0);
                negative = r[31];
            end
            4'b0001: {carry, r} = sub_result;
            4'b0011: begin
                r = sub_result[31:0];
                overflow = (r[31] ^ a[31]) & (r[31] ^ ~b[31]);
            end
            4'b0100: r = and_result;
            4'b0101: r = or_result;
            4'b0110: r = xor_result;
            4'b0111: r = nor_result;
            4'b100x: r = lui_result;
            4'b1011: r = {31'b0, signed_compare};
            4'b1010: begin
                r = {31'b0, unsigned_compare};
                carry = sub_result[32];
            end
            4'b1100: {r, carry} = sra_result;
            4'b111x: {carry, r} = sll_result;
            4'b1101: {r, carry} = srl_result;
        endcase
        zero = (aluc == 4'b1011 || aluc == 4'b1010) ? (sub_result[32:0] == 33'b0) : (r == 32'b0);
        negative = (aluc == 4'b1011) ? signed_compare : r[31];
    end
endmodule
