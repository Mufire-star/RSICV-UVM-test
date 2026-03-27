`timescale 1ps/1ps
`include "../rtl_pipeline/includes/ctrl_signal_def.v"

module alu_ref(
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  ALUOp,
    output reg  [31:0] y,
    output wire        zero
);
    reg [32:0] tmp33;
    always @(*) begin
        case (ALUOp)
            `ALU_ADD: begin tmp33 = {1'b0,A} + {1'b0,B}; y = tmp33[31:0]; end
            `ALU_SUB: begin tmp33 = {1'b0,A} - {1'b0,B}; y = tmp33[31:0]; end
            `ALU_AND: y = A & B;
            `ALU_OR : y = A | B;
            `ALU_XOR: y = A ^ B;
            `ALU_SLL: y = A << B[4:0];
            `ALU_SRL: y = A >> B[4:0];
            `ALU_SRA: y = $signed(A) >>> B[4:0];
            default: y = 32'hxxxx;
        endcase
    end

    assign zero = (y == 32'h0);
endmodule
