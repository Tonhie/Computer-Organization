`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 02:07:54 PM
// Design Name: 
// Module Name: sccomp_dataflow
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


module sccomp_dataflow(
    input clk_in,
    input reset,
    input [31:0] inst,
    output [31:0] pc
);
    // dmem、imem
    cpu sccpu(
        .clk_in(clk_in),
        .reset(reset),
        .inst(inst),
        .pc(pc)
    );

endmodule
