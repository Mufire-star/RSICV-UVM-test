`timescale 1ns / 1ps

module RF (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  rr1,
    input  wire [4:0]  rr2,
    input  wire [4:0]  wr,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
`ifdef PIPELINE_TECH_RF
    RF_TECH U_RF_TECH (
        .clk(clk),
        .we (we),
        .rr1(rr1),
        .rr2(rr2),
        .wr (wr),
        .wd (wd),
        .rd1(rd1),
        .rd2(rd2)
    );
`else
    reg [31:0] regs [0:31];
    wire        rf_we = we && (wr != 5'd0);
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] = 32'h0;
        end
    end

    always @(posedge clk) begin
        // 2R1W register-file style behavior: synchronous write, combinational
        // read, and x0 is hardwired to zero.
        if (rf_we) begin
            regs[wr] <= wd;
        end
        regs[0] <= 32'h0;
    end

    assign rd1 = (rr1 == 5'd0) ? 32'h0 : regs[rr1];
    assign rd2 = (rr2 == 5'd0) ? 32'h0 : regs[rr2];
`endif

endmodule
