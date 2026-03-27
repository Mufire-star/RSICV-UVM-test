`timescale 1ps/1ps
`include "../rtl_pipeline/includes/ctrl_signal_def.v"
module top_tb_e203;
  reg clk;
  reg [31:0] a = 32'h00000000, b = 32'h00000000;
  reg [3:0] op = 4'h0;
  reg rst_n;
  wire [31:0] y;
  wire zero;

  // Instantiate DUT and driver
  dut u_dut(.a(a), .b(b), .op(op), .y(y), .zero(zero));
  // using only e203 ALU datapath as reference (no separate behavioral model)
  // e203 ALU datapath instance
  wire [31:0] y_e203;
  // control signals for e203 datapath
  wire alu_req_alu_add  = (op == `ALU_ADD);
  wire alu_req_alu_sub  = (op == `ALU_SUB);
  wire alu_req_alu_xor  = (op == `ALU_XOR);
  wire alu_req_alu_sll  = (op == `ALU_SLL);
  wire alu_req_alu_srl  = (op == `ALU_SRL);
  wire alu_req_alu_sra  = (op == `ALU_SRA);
  wire alu_req_alu_or   = (op == `ALU_OR);
  wire alu_req_alu_and  = (op == `ALU_AND);
  driver u_drv(.clk(clk), .a(a), .b(b), .op(op), .y(y));

  // Start with clock stopped, assert reset for a short time, then start clock
  initial clk = 0;
  initial begin
    rst_n = 1'b0;
    #20ns; // keep reset asserted for 20 ns
    rst_n = 1'b1;
  end

  initial begin
    // start toggling clock only after a short delay (after reset will be released)
    #25ns;
    forever #2.5ns clk = ~clk;
  end

  // Wave dump: always generate VCD; if FSDB support is available, generate FSDB too
  initial begin
`ifdef FSDB
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars();
    $fsdbDumpon;
`endif
    $dumpfile("wave.vcd");
    $dumpvars(0, top_tb_e203);
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
  integer e203_fail_count;
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

  // Instantiate e203 ALU datapath as additional reference (module-scope)
  wire alu_req_alu = 1'b1;
  wire [31:0] alu_req_alu_op1 = a;
  wire [31:0] alu_req_alu_op2 = b;
  wire [31:0] alu_req_alu_res;

  e203_exu_alu_dpath e203_alu (
    .alu_req_alu(alu_req_alu),
    .alu_req_alu_add(alu_req_alu_add),
    .alu_req_alu_sub(alu_req_alu_sub),
    .alu_req_alu_xor(alu_req_alu_xor),
    .alu_req_alu_sll(alu_req_alu_sll),
    .alu_req_alu_srl(alu_req_alu_srl),
    .alu_req_alu_sra(alu_req_alu_sra),
    .alu_req_alu_slt(1'b0),
    .alu_req_alu_sltu(1'b0),
    .alu_req_alu_lui(1'b0),
    .alu_req_alu_or(alu_req_alu_or),
    .alu_req_alu_and(alu_req_alu_and),
    .alu_req_alu_op1(alu_req_alu_op1),
    .alu_req_alu_op2(alu_req_alu_op2),
    .alu_req_alu_res(alu_req_alu_res),
    // tie off other requesters and buffers
    .bjp_req_alu(1'b0),
    .bjp_req_alu_op1(32'b0),
    .bjp_req_alu_op2(32'b0),
    .bjp_req_alu_cmp_eq(1'b0),
    .bjp_req_alu_cmp_ne(1'b0),
    .bjp_req_alu_cmp_lt(1'b0),
    .bjp_req_alu_cmp_gt(1'b0),
    .bjp_req_alu_cmp_ltu(1'b0),
    .bjp_req_alu_cmp_gtu(1'b0),
    .bjp_req_alu_add(1'b0),
    // tie off muldiv shared-buffer / interface (core built with MULDIV enabled)
    .muldiv_req_alu(1'b0),
    .muldiv_req_alu_op1(35'b0),
    .muldiv_req_alu_op2(35'b0),
    .muldiv_req_alu_add(1'b0),
    .muldiv_req_alu_sub(1'b0),
    .muldiv_sbf_0_ena(1'b0),
    .muldiv_sbf_0_nxt(33'b0),
    .muldiv_sbf_0_r(),
    .muldiv_sbf_1_ena(1'b0),
    .muldiv_sbf_1_nxt(33'b0),
    .muldiv_sbf_1_r(),
    .agu_req_alu(1'b0),
    .agu_req_alu_op1(32'b0),
    .agu_req_alu_op2(32'b0),
    .agu_req_alu_swap(1'b0),
    .agu_req_alu_add(1'b0),
    .agu_req_alu_and(1'b0),
    .agu_req_alu_or(1'b0),
    .agu_req_alu_xor(1'b0),
    .agu_req_alu_max(1'b0),
    .agu_req_alu_min(1'b0),
    .agu_req_alu_maxu(1'b0),
    .agu_req_alu_minu(1'b0),
    .agu_req_alu_res(),
    .agu_sbf_0_ena(1'b0),
    .agu_sbf_0_nxt(32'b0),
    .agu_sbf_0_r(),
    .agu_sbf_1_ena(1'b0),
    .agu_sbf_1_nxt(32'b0),
    .agu_sbf_1_r(),
    .clk(clk),
    .rst_n(rst_n)
  );
  // expose e203 datapath result for waveform/debug
  assign y_e203 = alu_req_alu_res;
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
    e203_fail_count = 0;

    // seed PRNG and print seed for reproducibility
    seed = $urandom;
    $display("RANDOM SEED: %0d", seed);
    // reseed simulator PRNG if supported (assign return to seed)
    seed = $urandom(seed);

    // wait for reset release so DUT / E203 are initialized
    wait (rst_n == 1'b1);
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

      // concise debug: only print key signals when unknown detected
      if ($isunknown(a) || $isunknown(b) || $isunknown(op) || $isunknown(y) || $isunknown(alu_req_alu_res)) begin
        $display("X-DETECT iter=%0d time=%t a=%h b=%h op=%0d y=%h e203_y=%h zero=%b",
                 i, $time, a, b, op, y, alu_req_alu_res, zero);
      end

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

      // compare data output (DUT vs expected)
      if (y !== expected) begin
        if (fail_count < 20) $display("FAIL DUT op=%0d a=%h b=%h y=%h e203_y=%h exp=%h (i=%0d)", op, a, b, y, alu_req_alu_res, expected, i);
        fail_count = fail_count + 1;
      end else begin
        pass_count = pass_count + 1;
      end

      // compare e203 datapath result vs expected
      if (alu_req_alu_res !== expected) begin
        if (e203_fail_count < 20) $display("FAIL E203 op=%0d a=%h b=%h e203_y=%h exp=%h (i=%0d)", op, a, b, alu_req_alu_res, expected, i);
        e203_fail_count = e203_fail_count + 1;
      end
      // check zero flag
      if (zero !== (expected == 32'h0)) begin
        if (zero_fail_count < 20) $display("ZERO FAIL op=%0d a=%h b=%h zero=%b exp_zero=%b (i=%0d)", op, a, b, zero, (expected==32'h0), i);
        zero_fail_count = zero_fail_count + 1;
      end
    end

    $display("ALU test finished. total=%0d pass=%0d fail=%0d e203_fail=%0d zero_fail=%0d", NUM_TESTS, pass_count, fail_count, e203_fail_count, zero_fail_count);
    $finish;
  end
endmodule
