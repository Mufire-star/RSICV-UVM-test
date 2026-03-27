module dut(
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  op,
    output wire [31:0] y,
    output wire        zero
);

    ALU u_alu(
        .A(a), .B(b), .ALUOp(op),
        .ALUResult(y), .zero(zero)
    );

endmodule
