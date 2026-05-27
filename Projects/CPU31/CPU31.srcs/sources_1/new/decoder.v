module decoder (
    input [31:0] inst,
    output reg is_R_type,
    output reg is_I_type,
    output reg is_J_type,
    output [5:0] op,
    output [4:0] rs,
    output [4:0] rt,
    output [4:0] rd,
    output [4:0] shamt,
    output [5:0] func,
    output [15:0] immediate,
    output reg [3:0] aluc,
    output reg is_signed,
    output reg need_jump,
    output [25:0] index,
    output reg reg_write,
    output reg mem_to_reg,
    output reg mem_write,
    output reg alu_src_b,
    output reg alu_src_a,
    output reg branch,
    output reg branch_eq,
    output reg link,
    output reg jump_reg
);

    assign op = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign shamt = inst[10:6];
    assign func = inst[5:0];
    assign immediate = inst[15:0];
    assign index = inst[25:0];

    always @(*) begin
        is_R_type = 0;
        is_I_type = 0;
        is_J_type = 0;
        aluc = 4'b0000;
        is_signed = 0;
        need_jump = 0;
        reg_write = 0;
        mem_to_reg = 0;
        mem_write = 0;
        alu_src_b = 0;
        alu_src_a = 0;
        branch = 0;
        branch_eq = 0;
        link = 0;
        jump_reg = 0;

        case (op)
            6'b000000: begin
                is_R_type = 1;
                casex (func)
                    // add
                    6'b100000: begin
                        aluc = 4'b0010;
                        is_signed = 1;
                        reg_write = 1;
                    end
                    // addu
                    6'b100001: begin
                        aluc = 4'b0000;
                        reg_write = 1;
                    end
                    // sub
                    6'b100010: begin
                        aluc = 4'b0011;
                        is_signed = 1;
                        reg_write = 1;
                    end
                    // subu
                    6'b100011: begin
                        aluc = 4'b0001;
                        reg_write = 1;
                    end
                    // and
                    6'b100100: begin
                        aluc = 4'b0100;
                        reg_write = 1;
                    end
                    // or
                    6'b100101: begin
                        aluc = 4'b0101;
                        reg_write = 1;
                    end
                    // xor
                    6'b100110: begin
                        aluc = 4'b0110;
                        reg_write = 1;
                    end
                    // nor
                    6'b100111: begin
                        aluc = 4'b0111;
                        reg_write = 1;
                    end
                    // slt
                    6'b101010: begin
                        aluc = 4'b1011;
                        is_signed = 1;
                        reg_write = 1;
                    end
                    // sltu
                    6'b101011: begin
                        aluc = 4'b1010;
                        reg_write = 1;
                    end
                    // sll
                    6'b000000: begin
                        aluc = 4'b1110;
                        alu_src_a = 1;
                        reg_write = 1;
                    end
                    // srl
                    6'b000010: begin
                        aluc = 4'b1101;
                        alu_src_a = 1;
                        reg_write = 1;
                    end
                    // sra
                    6'b000011: begin
                        aluc = 4'b1100;
                        alu_src_a = 1;
                        reg_write = 1;
                    end
                    // sllv
                    6'b000100: begin
                        aluc = 4'b1110;
                        reg_write = 1;
                    end
                    // srlv
                    6'b000110: begin
                        aluc = 4'b1101;
                        reg_write = 1;
                    end
                    // srav
                    6'b000111: begin
                        aluc = 4'b1100;
                        reg_write = 1;
                    end
                    // jr
                    6'b001000: begin
                        need_jump = 1;
                        jump_reg = 1;
                    end
                endcase
            end

            // addi
            6'b001000: begin
                is_I_type = 1;
                aluc = 4'b0010;
                is_signed = 1;
                alu_src_b = 1;
                reg_write = 1;
            end
            // addiu
            6'b001001: begin
                is_I_type = 1;
                aluc = 4'b0000;
                alu_src_b = 1;
                reg_write = 1;
            end
            // andi
            6'b001100: begin
                is_I_type = 1;
                aluc = 4'b0100;
                alu_src_b = 1;
                reg_write = 1;
            end
            // ori
            6'b001101: begin
                is_I_type = 1;
                aluc = 4'b0101;
                alu_src_b = 1;
                reg_write = 1;
            end
            // xori
            6'b001110: begin
                is_I_type = 1;
                aluc = 4'b0110;
                alu_src_b = 1;
                reg_write = 1;
            end
            // lw
            6'b100011: begin
                is_I_type = 1;
                aluc = 4'b0010;
                alu_src_b = 1;
                reg_write = 1;
                mem_to_reg = 1;
            end
            // sw
            6'b101011: begin
                is_I_type = 1;
                aluc = 4'b0010;
                alu_src_b = 1;
                mem_write = 1;
            end
            // beq
            6'b000100: begin
                is_I_type = 1;
                aluc = 4'b0001;
                branch = 1;
                branch_eq = 1;
            end
            // bne
            6'b000101: begin
                is_I_type = 1;
                aluc = 4'b0001;
                branch = 1;
                branch_eq = 0;
            end
            // slti
            6'b001010: begin
                is_I_type = 1;
                aluc = 4'b1011;
                is_signed = 1;
                alu_src_b = 1;
                reg_write = 1;
            end
            // sltiu
            6'b001011: begin
                is_I_type = 1;
                aluc = 4'b1010;
                alu_src_b = 1;
                reg_write = 1;
            end
            // lui
            6'b001111: begin
                is_I_type = 1;
                aluc = 4'b1000;
                alu_src_b = 1;
                reg_write = 1;
            end

            // j
            6'b000010: begin
                is_J_type = 1;
                need_jump = 1;
            end
            // jal
            6'b000011: begin
                is_J_type = 1;
                need_jump = 1;
                link = 1;
                reg_write = 1;
            end
        endcase
    end

endmodule
