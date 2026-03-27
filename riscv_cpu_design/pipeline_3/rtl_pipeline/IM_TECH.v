`timescale 1ns / 1ps

module IM_TECH #(
    parameter DEPTH = 1024
) (
    input  wire [31:0] addr,
    output wire [31:0] ins
);
    // Technology-memory placeholder.
    // Replace this module with the real TSMC ROM/SRAM wrapper used for synthesis and STA.
    assign ins = 32'h0000_0013;

endmodule
