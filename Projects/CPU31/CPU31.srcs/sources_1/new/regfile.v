`timescale 1ns / 1ps

module pcreg #(
    parameter INIT = 32'h00000000
)(
    input clk,
    input rst,
    input ena,
    input [31:0] data_in,
    output reg [31:0] data_out
    );
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= INIT;
        end else begin
            if(ena) begin
                data_out <= data_in;
            end
        end
    end
endmodule

module regfiles(
    input clk,
    input rst,
    input we,
    input [4:0] raddr1,
    input [4:0] raddr2,
    input [4:0] waddr,
    input [31:0] wdata,
    output [31:0] rdata1,
    output [31:0] rdata2
);
    wire [31:0] array_reg [0:31]; 

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : reg_gen
            if (i == 0) begin
                assign array_reg[0] = 32'h0;
            end else if (i == 28) begin
                // $gp — MARS initializes this to 0x10008000
                pcreg #(.INIT(32'h10008000)) reg_inst (
                    .clk(clk),
                    .rst(rst),
                    .ena(we && (waddr == i)),
                    .data_in(wdata),
                    .data_out(array_reg[i])
                );
            end else if (i == 29) begin
                // $sp — MARS initializes this to 0x7fffeffc
                pcreg #(.INIT(32'h7fffeffc)) reg_inst (
                    .clk(clk),
                    .rst(rst),
                    .ena(we && (waddr == i)),
                    .data_in(wdata),
                    .data_out(array_reg[i])
                );
            end else begin
                pcreg reg_inst (
                    .clk(clk),
                    .rst(rst),
                    .ena(we && (waddr == i)),
                    .data_in(wdata),
                    .data_out(array_reg[i])
                );
            end
        end
    endgenerate

    assign rdata1 = array_reg[raddr1];
    assign rdata2 = array_reg[raddr2];

endmodule