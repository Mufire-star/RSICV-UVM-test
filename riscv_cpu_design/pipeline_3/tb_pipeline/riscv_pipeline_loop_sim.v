`timescale 1ns / 1ps

module riscv_pipeline_loop_sim;
    reg clk;
    reg rst;
    integer cycle_count;
    localparam integer PROG_WORDS = 9;

    riscv_pipeline dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        $readmemh("../hex_pipeline/pipeline_loop.hex", dut.U_IM.memory, 0, PROG_WORDS - 1);
        clk = 1'b0;
        rst = 1'b1;
        cycle_count = 0;

        $dumpfile("riscv_pipeline_loop.vcd");
        $dumpvars(0, riscv_pipeline_loop_sim);

        repeat (2) @(posedge clk);
        rst = 1'b0;
    end

    initial begin
        #1000;
        $fatal(1, "loop test timeout");
    end

    always #2.5 clk = ~clk;

    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;

        if (!rst && dut.U_RF.regs[4] == 32'd5 && dut.U_DM.memory[0] == 32'd5) begin
            if (dut.U_RF.regs[1] !== 32'd5) $fatal(1, "loop test x1 mismatch");
            if (dut.U_RF.regs[2] !== 32'd0) $fatal(1, "loop test x2 mismatch");
            if (dut.U_RF.regs[3] !== 32'd1) $fatal(1, "loop test x3 mismatch");
            if (dut.U_RF.regs[4] !== 32'd5) $fatal(1, "loop test x4 mismatch");
            if (dut.U_DM.memory[0] !== 32'd5) $fatal(1, "loop test dmem[0] mismatch");

            $display("PIPELINE LOOP TEST PASS");
            $finish;
        end
    end

endmodule
