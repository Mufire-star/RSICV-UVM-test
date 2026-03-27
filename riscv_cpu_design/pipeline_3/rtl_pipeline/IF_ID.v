`timescale 1ns / 1ps

`include "global_def.v"

module IF_ID (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    input  wire        clear,
    input  wire        valid_in,
    input  wire [31:0] pc_in,
    input  wire [31:0] pc4_in,
    input  wire [31:0] ins_in,
    output reg         valid_out,
    output reg  [31:0] pc_out,
    output reg  [31:0] pc4_out,
    output reg  [31:0] ins_out
);

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            pc_out    <= `RESET_PC;
            pc4_out   <= `RESET_PC + 32'd4;
            ins_out   <= `NOP_INSTR;
        end else if (clear) begin
            valid_out <= 1'b0;
            pc_out    <= 32'h0;
            pc4_out   <= 32'h0;
            ins_out   <= `NOP_INSTR;
        end else if (en) begin
            valid_out <= valid_in;
            pc_out    <= pc_in;
            pc4_out   <= pc4_in;
            ins_out   <= ins_in;
        end
    end

endmodule
