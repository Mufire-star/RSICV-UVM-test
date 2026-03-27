`timescale 1ns / 1ps

module riscv_pipeline_instr_sim;
    reg clk;
    reg rst;
    integer cycle_count;
    localparam integer PROG_WORDS = 29;

    riscv_pipeline dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        $readmemh("../hex_pipeline/code_instr.hex", dut.U_IM.memory, 0, PROG_WORDS - 1);
        clk = 1'b0;
        rst = 1'b1;
        cycle_count = 0;

        $dumpfile("riscv_pipeline_instr.vcd");
        $dumpvars(0, riscv_pipeline_instr_sim);

        repeat (2) @(posedge clk);
        rst = 1'b0;
    end

    initial begin
        #1200;
        $fatal(1, "instruction coverage test timeout");
    end

    always #2.5 clk = ~clk;

    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;

        if (!rst && cycle_count > 40) begin
            if (dut.U_RF.regs[1]  !== 32'd5)  $fatal(1, "instr test x1 mismatch");
            if (dut.U_RF.regs[2]  !== 32'd9)  $fatal(1, "instr test x2 mismatch");
            if (dut.U_RF.regs[3]  !== 32'd14) $fatal(1, "instr test x3 mismatch");
            if (dut.U_RF.regs[4]  !== 32'd4)  $fatal(1, "instr test x4 mismatch");
            if (dut.U_RF.regs[5]  !== 32'd1)  $fatal(1, "instr test x5 mismatch");
            if (dut.U_RF.regs[6]  !== 32'd13) $fatal(1, "instr test x6 mismatch");
            if (dut.U_RF.regs[7]  !== 32'd1)  $fatal(1, "instr test x7 mismatch");
            if (dut.U_RF.regs[8]  !== 32'd10) $fatal(1, "instr test x8 mismatch");
            if (dut.U_RF.regs[9]  !== 32'd4)  $fatal(1, "instr test x9 mismatch");
            if (dut.U_RF.regs[10] !== 32'h33) $fatal(1, "instr test x10 mismatch");
            if (dut.U_RF.regs[11] !== 32'd14) $fatal(1, "instr test x11 mismatch");
            if (dut.U_RF.regs[12] !== 32'd0)  $fatal(1, "instr test x12 should be flushed");
            if (dut.U_RF.regs[13] !== 32'd0)  $fatal(1, "instr test x13 should be flushed");
            if (dut.U_RF.regs[14] !== 32'd80) $fatal(1, "instr test x14 mismatch");
            if (dut.U_RF.regs[15] !== 32'd0)  $fatal(1, "instr test x15 should be flushed");
            if (dut.U_RF.regs[16] !== 32'd100) $fatal(1, "instr test x16 mismatch");
            if (dut.U_RF.regs[17] !== 32'd92) $fatal(1, "instr test x17 mismatch");
            if (dut.U_RF.regs[18] !== 32'd0)  $fatal(1, "instr test x18 should be flushed");
            if (dut.U_RF.regs[19] !== 32'd0)  $fatal(1, "instr test x19 should be flushed");
            if (dut.U_RF.regs[20] !== 32'd6)  $fatal(1, "instr test x20 mismatch");
            if (dut.U_RF.regs[21] !== 32'd6)  $fatal(1, "instr test x21 mismatch");
            if (dut.U_RF.regs[22] !== 32'd12) $fatal(1, "instr test x22 mismatch");
            if (dut.U_RF.regs[24] !== 32'hfffffff0) $fatal(1, "instr test x24 mismatch");
            if (dut.U_RF.regs[25] !== 32'hfffffff8) $fatal(1, "instr test x25 mismatch");
            if (dut.U_DM.memory[0] !== 32'd14) $fatal(1, "instr test dmem[0] mismatch");
            if (dut.U_DM.memory[1] !== 32'd6)  $fatal(1, "instr test dmem[1] mismatch");

            $display("PIPELINE INSTRUCTION TEST PASS");
            $finish;
        end
    end

endmodule
