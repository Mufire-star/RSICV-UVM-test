module alu(
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [3:0]  op,
    output reg  [15:0] y,
    output reg         zero,
    output reg         sign,
    output reg         carry,
    output reg         overflow
);

    // op encoding
    localparam OP_ADD  = 4'd0;
    localparam OP_SUB  = 4'd1;
    localparam OP_AND  = 4'd2;
    localparam OP_OR   = 4'd3;
    localparam OP_XOR  = 4'd4;
    localparam OP_SLL  = 4'd5;
    localparam OP_SRL  = 4'd6;

    always @(*) begin
        reg [16:0] tmp17;
        reg [15:0] res;
        reg c;
        reg ov;
        tmp17 = 17'd0;
        res = 16'd0;
        c = 1'b0;
        ov = 1'b0;
        case (op)
            OP_ADD: begin
                tmp17 = {1'b0, a} + {1'b0, b};
                res = tmp17[15:0];
                c = tmp17[16];
                // overflow for signed add
                ov = (~a[15] & ~b[15] & res[15]) | (a[15] & b[15] & ~res[15]);
            end
            OP_SUB: begin
                tmp17 = {1'b0, a} - {1'b0, b};
                res = tmp17[15:0];
                c = tmp17[16];
                // overflow for signed sub
                ov = (a[15] & ~b[15] & ~res[15]) | (~a[15] & b[15] & res[15]);
            end
            OP_AND: begin
                res = a & b;
                c = 1'b0; ov = 1'b0;
            end
            OP_OR: begin
                res = a | b;
                c = 1'b0; ov = 1'b0;
            end
            OP_XOR: begin
                res = a ^ b;
                c = 1'b0; ov = 1'b0;
            end
            OP_SLL: begin
                res = a << b[3:0];
                c = 1'b0; ov = 1'b0;
            end
            OP_SRL: begin
                res = a >> b[3:0];
                c = 1'b0; ov = 1'b0;
            end
            default: begin
                res = 16'h0000;
                c = 1'b0; ov = 1'b0;
            end
        endcase

        y = res;
        zero = (res == 16'h0000);
        sign = res[15];
        carry = c;
        overflow = ov;
    end

endmodule
