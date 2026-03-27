`timescale 1ns / 1ps

`include "ctrl_signal_def.v"

module ImmGen (
    input  wire [31:0] ins,
    input  wire [2:0]  imm_sel,
    output reg  [31:0] imm
);

    always @(*) begin
        case (imm_sel)
            `IMM_I: imm = {{20{ins[31]}}, ins[31:20]};
            `IMM_S: imm = {{20{ins[31]}}, ins[31:25], ins[11:7]};
            `IMM_B: imm = {{19{ins[31]}}, ins[31], ins[7], ins[30:25], ins[11:8], 1'b0};
            `IMM_J: imm = {{11{ins[31]}}, ins[31], ins[19:12], ins[20], ins[30:21], 1'b0};
            default: imm = 32'h0;
        endcase
    end

endmodule
