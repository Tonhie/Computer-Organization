`timescale 1ns / 1ps

// Top-level datapath
module sccomp_dataflow(
    input clk_in,
    input reset,
    output [31:0] inst,
    output [31:0] pc
);
    wire [31:0] mem_addr, mem_wdata;
    wire mem_write;
    wire [31:0] mem_rdata;

    cpu sccpu(
        .clk_in(clk_in),
        .reset(reset),
        .instr(inst),
        .pc(pc),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_write(mem_write),
        .mem_rdata(mem_rdata)
    );

    wire [31:0] imem_addr;
    assign imem_addr = pc - 32'h00400000;

    imem rom (
        .a(imem_addr[12:2]),
        .spo(inst)
    );

    dmem ram (
        .a(mem_addr[12:2]),
        .d(mem_wdata),
        .clk(clk_in),
        .we(mem_write),
        .spo(mem_rdata)
    );

endmodule
