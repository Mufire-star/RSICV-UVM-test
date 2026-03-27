`timescale 1ns / 1ps

`include "ctrl_signal_def.v"

module ALU (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  ALUOp,
    output wire        zero,
    output reg  [31:0] ALUResult
);
    wire        sub_sel;
    wire [31:0] adder_b;
    wire [32:0] adder_sum;
    wire [31:0] logic_and_result;
    wire [31:0] logic_or_result;
    wire [31:0] logic_xor_result;
    wire [31:0] shift_left_result;
    wire [31:0] shift_right_result;
    wire [31:0] shift_arith_right_result;

    assign sub_sel = (ALUOp == `ALU_SUB);
    assign adder_b = B ^ {32{sub_sel}};
    assign adder_sum = {1'b0, A} + {1'b0, adder_b} + sub_sel;
    assign logic_and_result = A & B;
    assign logic_or_result = A | B;
    assign logic_xor_result = A ^ B;
    assign shift_left_result = A << B[4:0];
    assign shift_right_result = A >> B[4:0];
    assign shift_arith_right_result = $signed(A) >>> B[4:0];

    always @(*) begin
        case (ALUOp)
            `ALU_ADD: ALUResult = adder_sum[31:0];
            `ALU_SUB: ALUResult = adder_sum[31:0];
            `ALU_AND: ALUResult = logic_and_result;
            `ALU_OR : ALUResult = logic_or_result;
            `ALU_XOR: ALUResult = logic_xor_result;
            `ALU_SLL: ALUResult = shift_left_result;
            `ALU_SRL: ALUResult = shift_right_result;
            `ALU_SRA: ALUResult = shift_arith_right_result;
            default : ALUResult = 32'h0;
        endcase
    end

    assign zero = (ALUResult == 32'h0);

endmodule
