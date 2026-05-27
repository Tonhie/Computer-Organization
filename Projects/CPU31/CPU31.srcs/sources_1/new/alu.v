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
    output zero,
    output reg carry,
    output reg negative,
    output reg overflow
    );
    wire [32:0] add_result = {1'b0, a} + {1'b0, b};
    wire [32:0] sub_result = {1'b0, a} - {1'b0, b};
    wire [31:0] lui_result = {b[15:0], 16'b0};
    wire [4:0]  shift_amt  = a[4:0];

    wire signed_compare, unsigned_compare;
    assign signed_compare   = $signed(a) < $signed(b);
    assign unsigned_compare = a < b;
    assign zero = ((a - b) == 0);

    always @(*) begin
        carry    = 1'b0;
        negative = 1'b0;
        overflow = 1'b0;
        r        = 32'b0;

        case (aluc)
            4'b0000: begin {carry, r} = add_result;negative = r[31]; end
            4'b0010: begin
                r = add_result[31:0];
                overflow = (a[31] & b[31] & ~r[31]) | (~a[31] & ~b[31] & r[31]);
                negative = r[31];
            end
            4'b0001: begin {carry, r} = sub_result;negative = r[31]; end
            4'b0011: begin
                r = sub_result[31:0];
                carry = sub_result[32];
                overflow = (a[31] ^ b[31]) & (a[31] ^ r[31]);
                negative = r[31];
            end
            4'b0100: begin r = a & b;          negative = r[31]; end
            4'b0101: begin r = a | b;          negative = r[31]; end
            4'b0110: begin r = a ^ b;          negative = r[31]; end
            4'b0111: begin r = ~(a | b);       negative = r[31]; end
            4'b1000: begin r = lui_result;     negative = r[31]; end
            4'b1011: begin r = {31'b0, signed_compare};  negative = signed_compare;   end
            4'b1010: begin r = {31'b0, unsigned_compare}; carry = sub_result[32];negative = unsigned_compare; end
            4'b1100: begin r = ($signed(b)) >>> a;negative = r[31]; end
            4'b1101: begin r = b >> a;         negative = r[31]; end
            4'b1110: begin r = b << a;         negative = r[31]; end
            4'b1111: begin r = b << a;         negative = r[31]; end
            default: begin r = 32'b0; carry = 1'b0; negative = 1'b0; overflow = 1'b0; end
        endcase
    end
endmodule
