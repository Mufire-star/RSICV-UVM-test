module dut(
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [3:0]  op,
    output wire [15:0] y,
    output wire        zero,
    output wire        sign,
    output wire        carry,
    output wire        overflow
);

    alu u_alu(
        .a(a), .b(b), .op(op),
        .y(y), .zero(zero), .sign(sign), .carry(carry), .overflow(overflow)
    );

endmodule
