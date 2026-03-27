`timescale 1ns / 1ps

`include "global_def.v"

module PC (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    input  wire [31:0] pc_next,
    output reg  [31:0] pc_q
);

    always @(posedge clk) begin
        if (rst) begin
            pc_q <= `RESET_PC;
        end else if (en) begin
            pc_q <= pc_next;
        end
    end

endmodule
