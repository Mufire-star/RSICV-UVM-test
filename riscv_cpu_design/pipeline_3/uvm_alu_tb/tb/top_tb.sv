`timescale 1ps/1ps
`include "../rtl_pipeline/includes/ctrl_signal_def.v"
module top_tb;
  reg clk;
  reg [31:0] a,b;
  reg [3:0] op;
  wire [31:0] y;
  wire zero;

  // Instantiate DUT and driver
  dut u_dut(.a(a), .b(b), .op(op), .y(y), .zero(zero));
  // behavioral reference ALU (acts as e203 ALU substitute)
  wire [31:0] y_ref;
  wire        zero_ref;
  alu_ref ref_dut(.A(a), .B(b), .ALUOp(op), .y(y_ref), .zero(zero_ref));
  driver u_drv(.clk(clk), .a(a), .b(b), .op(op), .y(y));

  initial clk = 0; always #2.5ns clk = ~clk;

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

  reg [31:0] expected;
  reg [32:0] tmp33;
  reg [3:0] optab [0:7];
  integer NUM_TESTS = 10000;
  integer CORNER = 12;
  reg [31:0] corners [0:11];
  integer pass_count;
  integer fail_count;
  integer zero_fail_count;
  integer seed;
  integer i;
  initial begin
    // initialize op code table to match ALU encodings
    optab[0] = `ALU_ADD;
    optab[1] = `ALU_SUB;
    optab[2] = `ALU_AND;
    optab[3] = `ALU_OR;
    optab[4] = `ALU_SLL;
    optab[5] = `ALU_SRL;
    optab[6] = `ALU_XOR;
    optab[7] = `ALU_SRA;
  end
  initial begin
    // prepare corner cases
    corners[0]  = 32'h00000000;
    corners[1]  = 32'hFFFFFFFF;
    corners[2]  = 32'h7FFFFFFF;
    corners[3]  = 32'h80000000;
    corners[4]  = 32'h00000001;
    corners[5]  = 32'h00000002;
    corners[6]  = 32'hFFFFFFFE;
    corners[7]  = 32'hFFFF0000;
    corners[8]  = 32'h00FF00FF;
    corners[9]  = 32'hAAAAAAAA;
    corners[10] = 32'h55555555;
    corners[11] = 32'h0000FFFF;

    pass_count = 0;
    fail_count = 0;
    zero_fail_count = 0;

    // seed PRNG and print seed for reproducibility
    seed = $urandom;
    $display("RANDOM SEED: %0d", seed);
    // reseed simulator PRNG if supported (assign return to seed)
    seed = $urandom(seed);

    $display("ALU random test start, total tests=%0d", NUM_TESTS);
    for (i=0; i<NUM_TESTS; i=i+1) begin
      // drive inputs synchronously on clock edge so they change once per cycle
      @(posedge clk);
      if (i < CORNER) begin
        a = corners[i % CORNER];
        b = corners[(i+3) % CORNER];
      end else begin
        a = $urandom;
        b = $urandom;
      end
      op = optab[$urandom_range(0,7)]; // random op among defined encodings

      // small settle time for combinational ALU
      #1ns;

      case (op)
        `ALU_ADD: begin tmp33 = {1'b0,a} + {1'b0,b}; expected = tmp33[31:0]; end
        `ALU_SUB: begin tmp33 = {1'b0,a} - {1'b0,b}; expected = tmp33[31:0]; end
        `ALU_AND: expected = a & b;
        `ALU_OR : expected = a | b;
        `ALU_XOR: expected = a ^ b;
        `ALU_SLL: expected = a << b[4:0];
        `ALU_SRL: expected = a >> b[4:0];
        `ALU_SRA: expected = $signed(a) >>> b[4:0];
        default: expected = 32'hxxxx;
      endcase

      // compare data output
      if (y !== expected) begin
        if (fail_count < 20) $display("FAIL op=%0d a=%h b=%h y=%h exp=%h (i=%0d)", op, a, b, y, expected, i);
        fail_count = fail_count + 1;
      end else begin
        pass_count = pass_count + 1;
      end
      // check zero flag
      if (zero !== (expected == 32'h0)) begin
        if (zero_fail_count < 20) $display("ZERO FAIL op=%0d a=%h b=%h zero=%b exp_zero=%b (i=%0d)", op, a, b, zero, (expected==32'h0), i);
        zero_fail_count = zero_fail_count + 1;
      end
    end

    $display("ALU test finished. total=%0d pass=%0d fail=%0d zero_fail=%0d", NUM_TESTS, pass_count, fail_count, zero_fail_count);
    $finish;
  end
endmodule
