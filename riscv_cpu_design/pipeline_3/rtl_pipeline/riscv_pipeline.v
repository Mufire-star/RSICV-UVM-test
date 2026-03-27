`timescale 1ns / 1ps

`include "ctrl_signal_def.v"
`include "global_def.v"

module riscv_pipeline (
    input wire clk,
    input wire rst
);
    wire [31:0] pc_q;
    wire [31:0] pc_plus4_if;
    wire [31:0] fetched_ins;
    wire [31:0] pc_next;

    wire        if_id_valid;
    wire [31:0] if_id_pc;
    wire [31:0] if_id_pc4;
    wire [31:0] if_id_ins;

    wire [4:0] rs1 = if_id_ins[19:15];
    wire [4:0] rs2 = if_id_ins[24:20];
    wire [4:0] rd  = if_id_ins[11:7];

    wire        dec_reg_write;
    wire        dec_mem_write;
    wire        dec_mem_read;
    wire        dec_use_imm;
    wire [1:0]  dec_wb_sel;
    wire [2:0]  dec_imm_sel;
    wire [1:0]  dec_branch_type;
    wire [1:0]  dec_jump_type;
    wire [3:0]  dec_alu_op;
    wire        dec_rs1_used;
    wire        dec_rs2_used;
    wire        dec_illegal;

    wire [31:0] rs1_data_raw;
    wire [31:0] rs2_data_raw;
    wire [31:0] imm_value;
    wire [31:0] operand_a;
    wire [31:0] operand_b_raw;
    wire [31:0] alu_src_b;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [31:0] dmem_rdata;
    wire [31:0] wb_data;
    wire [31:0] if_pc4_in;

    reg         wb_valid;
    reg         wb_reg_write;
    reg  [1:0]  wb_sel_q;
    reg  [4:0]  wb_rd_q;
    reg  [31:0] wb_pc4_q;
    reg  [31:0] wb_alu_result_q;
    reg         im_req_valid_q;
    reg  [31:0] im_req_pc_q;

    wire        rs1_forward_hit;
    wire        rs2_forward_hit;
    wire        branch_eq;
    wire        branch_taken;
    wire        jump_taken;
    wire        redirect_valid;
    wire [31:0] redirect_pc;
    wire        stage_valid;
    wire        rf_we;
    wire        dmem_re;
    wire        dmem_we;

    assign pc_plus4_if = pc_q + 32'd4;
    assign stage_valid = if_id_valid && ~dec_illegal;
    assign rf_we = wb_valid && wb_reg_write;

    assign rs1_forward_hit = wb_valid && wb_reg_write && (wb_rd_q != 5'd0) && (wb_rd_q == rs1);
    assign rs2_forward_hit = wb_valid && wb_reg_write && (wb_rd_q != 5'd0) && (wb_rd_q == rs2);
    assign operand_a = rs1_forward_hit ? wb_data : rs1_data_raw;
    assign operand_b_raw = rs2_forward_hit ? wb_data : rs2_data_raw;
    assign branch_eq = (operand_a == operand_b_raw);
    assign alu_src_b = dec_use_imm ? imm_value : operand_b_raw;
    assign if_pc4_in = im_req_pc_q + 32'd4;

    assign wb_data = (wb_sel_q == `WB_MEM) ? dmem_rdata :
                     (wb_sel_q == `WB_PC4) ? wb_pc4_q :
                     wb_alu_result_q;

    PC U_PC (
        .clk    (clk),
        .rst    (rst),
        .en     (1'b1),
        .pc_next(pc_next),
        .pc_q   (pc_q)
    );

    IM U_IM (
        .clk (clk),
        .addr(pc_q),
        .ins (fetched_ins)
    );

    IF_ID U_IF_ID (
        .clk      (clk),
        .rst      (rst),
        .en       (1'b1),
        .clear    (redirect_valid),
        .valid_in (im_req_valid_q),
        .pc_in    (im_req_pc_q),
        .pc4_in   (if_pc4_in),
        .ins_in   (fetched_ins),
        .valid_out(if_id_valid),
        .pc_out   (if_id_pc),
        .pc4_out  (if_id_pc4),
        .ins_out  (if_id_ins)
    );

    Decoder U_DECODER (
        .ins        (if_id_ins),
        .reg_write  (dec_reg_write),
        .mem_write  (dec_mem_write),
        .mem_read   (dec_mem_read),
        .use_imm    (dec_use_imm),
        .wb_sel     (dec_wb_sel),
        .imm_sel    (dec_imm_sel),
        .branch_type(dec_branch_type),
        .jump_type  (dec_jump_type),
        .alu_op     (dec_alu_op),
        .rs1_used   (dec_rs1_used),
        .rs2_used   (dec_rs2_used),
        .illegal    (dec_illegal)
    );

    ImmGen U_IMMGEN (
        .ins    (if_id_ins),
        .imm_sel(dec_imm_sel),
        .imm    (imm_value)
    );

    RF U_RF (
        .clk(clk),
        .we (rf_we),
        .rr1(rs1),
        .rr2(rs2),
        .wr (wb_rd_q),
        .wd (wb_data),
        .rd1(rs1_data_raw),
        .rd2(rs2_data_raw)
    );

    ALU U_ALU (
        .A        (operand_a),
        .B        (alu_src_b),
        .ALUOp    (dec_alu_op),
        .zero     (alu_zero),
        .ALUResult(alu_result)
    );

    DM U_DM (
        .clk (clk),
        .re  (dmem_re),
        .we  (dmem_we),
        .addr(alu_result),
        .wd  (operand_b_raw),
        .rd  (dmem_rdata)
    );

    assign branch_taken = stage_valid &&
                          (((dec_branch_type == `BR_EQ) && branch_eq) ||
                           ((dec_branch_type == `BR_NE) && ~branch_eq));
    assign jump_taken = stage_valid && (dec_jump_type != `JMP_NONE);
    assign redirect_valid = branch_taken || jump_taken;
    assign redirect_pc = (dec_jump_type == `JMP_JALR) ? ((operand_a + imm_value) & 32'hffff_fffe) :
                         (if_id_pc + imm_value);
    assign dmem_re = stage_valid && dec_mem_read;
    assign dmem_we = stage_valid && dec_mem_write;
    assign pc_next = redirect_valid ? redirect_pc : pc_plus4_if;

    always @(posedge clk) begin
        if (rst) begin
            im_req_valid_q <= 1'b0;
            im_req_pc_q    <= `RESET_PC;
            wb_valid      <= 1'b0;
            wb_reg_write  <= 1'b0;
            wb_sel_q      <= `WB_ALU;
            wb_rd_q       <= 5'd0;
            wb_pc4_q      <= 32'h0;
            wb_alu_result_q <= 32'h0;
        end else begin
            im_req_valid_q <= ~redirect_valid;
            im_req_pc_q    <= pc_q;
            wb_valid      <= stage_valid;
            wb_reg_write  <= stage_valid && dec_reg_write;
            wb_sel_q      <= dec_wb_sel;
            wb_rd_q       <= rd;
            wb_pc4_q      <= if_id_pc4;
            wb_alu_result_q <= alu_result;
        end
    end

endmodule
