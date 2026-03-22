module driver(
    input wire clk,
    input wire [15:0] a,
    input wire [15:0] b,
    input wire [3:0]  op,
    input wire [15:0] y
);
    always @(posedge clk) begin
        $display("DRV: a=%h b=%h op=%0d y=%h", a, b, op, y);
    end
endmodule
