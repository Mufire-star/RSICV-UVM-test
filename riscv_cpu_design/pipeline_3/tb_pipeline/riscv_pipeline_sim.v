`timescale 1ns / 1ps

module riscv_pipeline_sim;
    reg clk;
    reg rst;
    integer cycle_count;
    localparam integer PROG_WORDS = 26;

    riscv_pipeline dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        $readmemh("../hex_pipeline/pipeline_basic.hex", dut.U_IM.memory, 0, PROG_WORDS - 1);
        clk = 1'b0;
        rst = 1'b1;
        cycle_count = 0;

        $dumpfile("riscv_pipeline.vcd");
        $dumpvars(0, riscv_pipeline_sim);

        repeat (2) @(posedge clk);
        rst = 1'b0;
    end

    always #2.5 clk = ~clk;

    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;

        if (!rst && cycle_count > 40) begin
            if (dut.U_RF.regs[1]  !== 32'd8)  $fatal(1, "x1 mismatch");
            if (dut.U_RF.regs[2]  !== 32'd12) $fatal(1, "x2 mismatch");
            if (dut.U_RF.regs[3]  !== 32'd20) $fatal(1, "x3 mismatch");
            if (dut.U_RF.regs[4]  !== 32'd4)  $fatal(1, "x4 mismatch");
            if (dut.U_RF.regs[5]  !== 32'd8)  $fatal(1, "x5 mismatch");
            if (dut.U_RF.regs[6]  !== 32'd12) $fatal(1, "x6 mismatch");
            if (dut.U_RF.regs[7]  !== 32'd15) $fatal(1, "x7 mismatch");
            if (dut.U_RF.regs[8]  !== 32'd32) $fatal(1, "x8 mismatch");
            if (dut.U_RF.regs[9]  !== 32'd2)  $fatal(1, "x9 mismatch");
            if (dut.U_RF.regs[10] !== 32'd3)  $fatal(1, "x10 mismatch");
            if (dut.U_RF.regs[11] !== 32'd20) $fatal(1, "x11 mismatch");
            if (dut.U_RF.regs[12] !== 32'd0)  $fatal(1, "x12 should remain zero after beq flush");
            if (dut.U_RF.regs[13] !== 32'd0)  $fatal(1, "x13 should remain zero after bne flush");
            if (dut.U_RF.regs[14] !== 32'd68) $fatal(1, "x14 mismatch");
            if (dut.U_RF.regs[15] !== 32'd0)  $fatal(1, "x15 should remain zero after jal flush");
            if (dut.U_RF.regs[16] !== 32'd88) $fatal(1, "x16 mismatch");
            if (dut.U_RF.regs[17] !== 32'd80) $fatal(1, "x17 mismatch");
            if (dut.U_RF.regs[18] !== 32'd0)  $fatal(1, "x18 should remain zero after jalr flush");
            if (dut.U_RF.regs[19] !== 32'd0)  $fatal(1, "x19 should remain zero after jalr flush");
            if (dut.U_RF.regs[20] !== 32'd6)  $fatal(1, "x20 mismatch");
            if (dut.U_RF.regs[21] !== 32'd6)  $fatal(1, "x21 mismatch");
            if (dut.U_DM.memory[0] !== 32'd20) $fatal(1, "dmem[0] mismatch");
            if (dut.U_DM.memory[1] !== 32'd6)  $fatal(1, "dmem[1] mismatch");

            $display("PIPELINE TEST PASS");
            $finish;
        end
    end

endmodule
