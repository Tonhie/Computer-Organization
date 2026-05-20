`timescale 1ns / 1ps

// Behavioral instruction memory (ROM)
module imem (
    input [10:0] a,
    output [31:0] spo
);
    reg [31:0] mem [0:2047];

    initial begin
        $readmemh("../../../imem.hex", mem);
    end

    assign spo = mem[a];
endmodule

// Behavioral data memory (RAM)
module dmem (
    input [10:0] a,
    input [31:0] d,
    input clk,
    input we,
    output [31:0] spo
);
    reg [31:0] mem [0:2047];

    initial begin
        $readmemh("../../../dmem.hex", mem);
    end

    assign spo = mem[a];

    always @(posedge clk) begin
        if (we)
            mem[a] <= d;
    end
endmodule

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
        .inst(inst),
        .pc(pc),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_write(mem_write),
        .mem_rdata(mem_rdata)
    );

    imem rom (
        .a(pc[12:2]),
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
