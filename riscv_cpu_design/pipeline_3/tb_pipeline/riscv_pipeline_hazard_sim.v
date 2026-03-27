`timescale 1ns / 1ps

module riscv_pipeline_hazard_sim;
    reg clk;
    reg rst;
    integer cycle_count;
    localparam integer PROG_WORDS = 27;

    riscv_pipeline dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        $readmemh("../hex_pipeline/code_hazard.hex", dut.U_IM.memory, 0, PROG_WORDS - 1);
        clk = 1'b0;
        rst = 1'b1;
        cycle_count = 0;

        $dumpfile("riscv_pipeline_hazard.vcd");
        $dumpvars(0, riscv_pipeline_hazard_sim);

        repeat (2) @(posedge clk);
        rst = 1'b0;
    end

    initial begin
        #1400;
        $fatal(1, "hazard test timeout");
    end

    always #2.5 clk = ~clk;

    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;

        if (!rst && cycle_count > 50) begin
            if (dut.U_RF.regs[1]  !== 32'd1)         $fatal(1, "hazard test x1 mismatch");
            if (dut.U_RF.regs[2]  !== 32'd2)         $fatal(1, "hazard test x2 mismatch");
            if (dut.U_RF.regs[3]  !== 32'd3)         $fatal(1, "hazard test x3 mismatch");
            if (dut.U_RF.regs[4]  !== 32'd5)         $fatal(1, "hazard test x4 mismatch");
            if (dut.U_RF.regs[5]  !== 32'd4)         $fatal(1, "hazard test x5 mismatch");
            if (dut.U_RF.regs[6]  !== 32'd7)         $fatal(1, "hazard test x6 mismatch");
            if (dut.U_RF.regs[7]  !== 32'd5)         $fatal(1, "hazard test x7 mismatch");
            if (dut.U_RF.regs[8]  !== 32'd10)        $fatal(1, "hazard test x8 mismatch");
            if (dut.U_RF.regs[9]  !== 32'd2)         $fatal(1, "hazard test x9 mismatch");
            if (dut.U_RF.regs[10] !== 32'd2)         $fatal(1, "hazard test x10 mismatch");
            if (dut.U_RF.regs[11] !== 32'd0)         $fatal(1, "hazard test x11 should be flushed");
            if (dut.U_RF.regs[12] !== 32'd40)        $fatal(1, "hazard test x12 mismatch");
            if (dut.U_RF.regs[13] !== 32'd60)        $fatal(1, "hazard test x13 mismatch");
            if (dut.U_RF.regs[14] !== 32'd0)         $fatal(1, "hazard test x14 should be flushed");
            if (dut.U_RF.regs[15] !== 32'd80)        $fatal(1, "hazard test x15 mismatch");
            if (dut.U_RF.regs[16] !== 32'd72)        $fatal(1, "hazard test x16 mismatch");
            if (dut.U_RF.regs[17] !== 32'd0)         $fatal(1, "hazard test x17 should be flushed");
            if (dut.U_RF.regs[18] !== 32'd0)         $fatal(1, "hazard test x18 should be flushed");
            if (dut.U_RF.regs[19] !== 32'hffff_ffff) $fatal(1, "hazard test x19 mismatch");
            if (dut.U_RF.regs[20] !== 32'hffff_ffff) $fatal(1, "hazard test x20 mismatch");
            if (dut.U_RF.regs[21] !== 32'd0)         $fatal(1, "hazard test x21 should be flushed");
            if (dut.U_RF.regs[0]  !== 32'd0)         $fatal(1, "hazard test x0 mismatch");
            if (dut.U_DM.memory[0] !== 32'd2)              $fatal(1, "hazard test dmem[0] mismatch");
            if (dut.U_DM.memory[1] !== 32'hffff_ffff)      $fatal(1, "hazard test dmem[1] mismatch");

            $display("PIPELINE HAZARD TEST PASS");
            $finish;
        end
    end

endmodule
