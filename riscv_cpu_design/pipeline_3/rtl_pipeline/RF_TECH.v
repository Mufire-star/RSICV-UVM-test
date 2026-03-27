`timescale 1ns / 1ps

module RF_TECH (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  rr1,
    input  wire [4:0]  rr2,
    input  wire [4:0]  wr,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    // Technology register-file placeholder.
    // Replace this module with the real 2R1W register-file wrapper used for synthesis and STA.
    assign rd1 = 32'h0;
    assign rd2 = 32'h0;

endmodule
