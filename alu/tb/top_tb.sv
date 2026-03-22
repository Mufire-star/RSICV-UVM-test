`timescale 1ns/1ps
module top_tb;
  reg clk;
  reg [15:0] a,b;
  reg [3:0] op;
  wire [15:0] y;
  wire zero, sign, carry, overflow;

  // Instantiate DUT and driver
  dut u_dut(.a(a), .b(b), .op(op), .y(y), .zero(zero), .sign(sign), .carry(carry), .overflow(overflow));
  driver u_drv(.clk(clk), .a(a), .b(b), .op(op), .y(y));

  initial clk = 0; always #5 clk = ~clk;

  // Wave dump: always generate VCD; if FSDB support is available, generate FSDB too
  initial begin
`ifdef FSDB
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars();
    $fsdbDumpon;
`endif
    $dumpfile("wave.vcd");
    $dumpvars(0, top_tb);
  end

  reg [15:0] expected;
  reg [16:0] tmp17;
  integer i;
  initial begin
    $display("ALU test start");
    for (i=0; i<256; i=i+1) begin
      a = $urandom;
      b = $urandom;
      op = i % 7; // cycle through 0..6 ops
      #10;
      case (op)
        0: begin tmp17 = {1'b0,a} + {1'b0,b}; expected = tmp17[15:0]; end
        1: begin tmp17 = {1'b0,a} - {1'b0,b}; expected = tmp17[15:0]; end
        2: expected = a & b;
        3: expected = a | b;
        4: expected = a ^ b;
        5: expected = a << b[3:0];
        6: expected = a >> b[3:0];
        default: expected = 16'hxxxx;
      endcase
      #1;
      if (y !== expected) begin
        $display("FAIL op=%0d a=%h b=%h y=%h exp=%h", op, a, b, y, expected);
        $finish;
      end
    end
    $display("PASS: all tests");
    $finish;
  end
endmodule
