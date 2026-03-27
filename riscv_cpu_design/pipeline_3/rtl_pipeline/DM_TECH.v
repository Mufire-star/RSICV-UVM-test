`timescale 1ns / 1ps

module DM_TECH #(
    parameter DEPTH = 1024
) (
    input  wire        clk,
    input  wire        re,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wd,
    output wire [31:0] rd
);
    // Technology-memory placeholder.
    // Replace this module with the real TSMC SRAM wrapper used for synthesis and STA.
    assign rd = 32'h0;

endmodule
