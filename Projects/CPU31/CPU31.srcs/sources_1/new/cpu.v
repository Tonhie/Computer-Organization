`timescale 1ns / 1ps

module cpu(
    input clk_in,
    input reset,
    output [31:0] pc,
    input [31:0] inst,
    output [31:0] mem_addr,
    output [31:0] mem_wdata,
    output mem_write,
    input [31:0] mem_rdata
);

    // �?�? PC register �?�?
    wire [31:0] pc_next;
    pcreg pc_reg (
        .clk(clk_in),
        .rst(reset),
        .ena(1'b1),
        .data_in(pc_next),
        .data_out(pc)
    );

    // �?�? Decoder �?�?
    wire        is_R_type, is_I_type, is_J_type;
    wire [5:0]  op;
    wire [4:0]  rs, rt, rd, shamt;
    wire [5:0]  func;
    wire [15:0] immediate;
    wire [3:0]  aluc;
    wire        is_signed;
    wire        need_jump;
    wire [25:0] index;
    wire        reg_write, mem_to_reg;
    wire        alu_src_b, alu_src_a;
    wire        branch, branch_eq, link, jump_reg;

    decoder cpu_decoder (
        .inst(inst),
        .is_R_type(is_R_type),
        .is_I_type(is_I_type),
        .is_J_type(is_J_type),
        .op(op),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .shamt(shamt),
        .func(func),
        .immediate(immediate),
        .aluc(aluc),
        .is_signed(is_signed),
        .need_jump(need_jump),
        .index(index),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .mem_write(mem_write),
        .alu_src_b(alu_src_b),
        .alu_src_a(alu_src_a),
        .branch(branch),
        .branch_eq(branch_eq),
        .link(link),
        .jump_reg(jump_reg)
    );

    // �?�? Register file �?�?
    wire [31:0] rdata1, rdata2;
    wire [4:0]  waddr;
    wire [31:0] wdata;

    regfiles cpu_ref (
        .clk(clk_in),
        .rst(reset),
        .we(reg_write),
        .raddr1(rs),
        .raddr2(rt),
        .waddr(waddr),
        .wdata(wdata),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    // �?�? ALU �?�?
    wire [31:0] alu_a, alu_b;
    wire [31:0] alu_r;
    wire        alu_zero, alu_carry, alu_negative, alu_overflow;

    alu cpu_alu (
        .a(alu_a),
        .b(alu_b),
        .aluc(aluc),
        .r(alu_r),
        .zero(alu_zero),
        .carry(alu_carry),
        .negative(alu_negative),
        .overflow(alu_overflow)
    );

    // �?�? Immediate extension �?�?
    wire [31:0] imm_ext;
    assign imm_ext = ((op == 6'b001100) || (op == 6'b001101) || (op == 6'b001110))
        ? {16'b0, immediate}
        : {{16{immediate[15]}}, immediate};

    // Data memory interface
    assign mem_addr = alu_r;
    assign mem_wdata = rdata2;

    // �?�? ALU input muxes �?�?
    assign alu_a = alu_src_a ? {27'b0, shamt} : rdata1;
    assign alu_b = alu_src_b ? imm_ext : rdata2;

    // �?�? Writeback muxes �?�?
    wire [31:0] pc_plus_4 = pc + 32'd4;
    assign waddr = link ? 5'd31 : (is_R_type ? rd : rt);
    assign wdata = link ? pc_plus_4 : (mem_to_reg ? mem_rdata : alu_r);

    // �?�? Next PC logic �?�?
    wire [31:0] branch_offset = {{14{immediate[15]}}, immediate, 2'b00};
    wire [31:0] branch_target = pc_plus_4 + branch_offset;
    wire [31:0] jump_target = {pc_plus_4[31:28], index, 2'b00};
    wire        branch_taken = branch & (branch_eq ? alu_zero : ~alu_zero);

    assign pc_next = jump_reg ? rdata1
                   : (need_jump ? jump_target
                   : (branch_taken ? branch_target
                   : pc_plus_4));

endmodule
