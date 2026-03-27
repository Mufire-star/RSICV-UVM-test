`timescale 1ns / 1ps

`include "global_def.v"

module DM #(
    parameter DEPTH = `DMEM_DEPTH
) (
    input  wire        clk,
    input  wire        re,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wd,
    output wire [31:0] rd
);
    localparam ADDR_W = $clog2(DEPTH);
`ifdef PIPELINE_TECH_MEM
    DM_TECH #(
        .DEPTH(DEPTH)
    ) U_DM_TECH (
        .clk (clk),
        .re  (re),
        .we  (we),
        .addr(addr),
        .wd  (wd),
        .rd  (rd)
    );
`else
    reg [31:0] memory [0:DEPTH-1];
    reg [31:0] rd_q;
    wire [ADDR_W-1:0] word_addr = addr[ADDR_W+1:2];
    wire               mem_en = re | we;
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            memory[i] = 32'h0;
        end
        rd_q = 32'h0;
    end

    always @(posedge clk) begin
        // Model a single-port SRAM-style interface: writes commit on the clock
        // edge, and reads return through a registered output one cycle later.
        if (mem_en && we) begin
            memory[word_addr] <= wd;
        end
        if (mem_en && re && !we) begin
            rd_q <= memory[word_addr];
        end
    end

    assign rd = rd_q;
`endif

endmodule
