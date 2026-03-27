`timescale 1ns / 1ps

`include "global_def.v"

module IM #(
    parameter DEPTH = `IMEM_DEPTH
) (
    input  wire        clk,
    input  wire [31:0] addr,
    output wire [31:0] ins
);
    localparam ADDR_W = $clog2(DEPTH);
`ifdef PIPELINE_TECH_MEM
    IM_TECH #(
        .DEPTH(DEPTH)
    ) U_IM_TECH (
        .addr(addr),
        .ins (ins)
    );
`else
    reg [31:0] memory [0:DEPTH-1];
    reg [31:0] ins_q;
    wire [ADDR_W-1:0] word_addr = addr[ADDR_W+1:2];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            memory[i] = `NOP_INSTR;
        end
        ins_q = `NOP_INSTR;
    end

    // Model a macro-style instruction memory with registered read data.
    always @(posedge clk) begin
        ins_q <= memory[word_addr];
    end

    assign ins = ins_q;
`endif

endmodule
