`timescale 1ns / 1ps

`include "instruction_def.v"
`include "ctrl_signal_def.v"

module Decoder (
    input  wire [31:0] ins,
    output reg         reg_write,
    output reg         mem_write,
    output reg         mem_read,
    output reg         use_imm,
    output reg  [1:0]  wb_sel,
    output reg  [2:0]  imm_sel,
    output reg  [1:0]  branch_type,
    output reg  [1:0]  jump_type,
    output reg  [3:0]  alu_op,
    output reg         rs1_used,
    output reg         rs2_used,
    output reg         illegal
);
    wire [6:0] opcode = ins[6:0];
    wire [2:0] funct3 = ins[14:12];
    wire [6:0] funct7 = ins[31:25];

    always @(*) begin
        reg_write   = 1'b0;
        mem_write   = 1'b0;
        mem_read    = 1'b0;
        use_imm     = 1'b0;
        wb_sel      = `WB_ALU;
        imm_sel     = `IMM_I;
        branch_type = `BR_NONE;
        jump_type   = `JMP_NONE;
        alu_op      = `ALU_ADD;
        rs1_used    = 1'b0;
        rs2_used    = 1'b0;
        illegal     = 1'b0;

        case (opcode)
            `OPCODE_OP: begin
                reg_write = 1'b1;
                rs1_used  = 1'b1;
                rs2_used  = 1'b1;
                case (funct3)
                    `FUNCT3_ADD_SUB: begin
                        if (funct7 == `FUNCT7_ADD) begin
                            alu_op = `ALU_ADD;
                        end else if (funct7 == `FUNCT7_SUB) begin
                            alu_op = `ALU_SUB;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    `FUNCT3_AND: begin
                        if (funct7 == `FUNCT7_ADD) begin
                            alu_op = `ALU_AND;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    `FUNCT3_OR: begin
                        if (funct7 == `FUNCT7_ADD) begin
                            alu_op = `ALU_OR;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    `FUNCT3_SLL: begin
                        if (funct7 == `FUNCT7_ADD) begin
                            alu_op = `ALU_SLL;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    `FUNCT3_XOR: begin
                        if (funct7 == `FUNCT7_ADD) begin
                            alu_op = `ALU_XOR;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    `FUNCT3_SRL: begin
                        if (funct7 == `FUNCT7_SRL) begin
                            alu_op = `ALU_SRL;
                        end else if (funct7 == `FUNCT7_SRA) begin
                            alu_op = `ALU_SRA;
                        end else begin
                            illegal = 1'b1;
                        end
                    end
                    default: illegal = 1'b1;
                endcase
            end

            `OPCODE_OP_IMM: begin
                reg_write = 1'b1;
                use_imm   = 1'b1;
                imm_sel   = `IMM_I;
                rs1_used  = 1'b1;
                case (funct3)
                    `FUNCT3_ADD_SUB: alu_op = `ALU_ADD;
                    `FUNCT3_OR:      alu_op = `ALU_OR;
                    default:         illegal = 1'b1;
                endcase
            end

            `OPCODE_LOAD: begin
                rs1_used  = 1'b1;
                use_imm   = 1'b1;
                mem_read  = 1'b1;
                reg_write = 1'b1;
                imm_sel   = `IMM_I;
                wb_sel    = `WB_MEM;
                alu_op    = `ALU_ADD;
                if (funct3 != `FUNCT3_LW_SW) begin
                    illegal = 1'b1;
                end
            end

            `OPCODE_STORE: begin
                rs1_used  = 1'b1;
                rs2_used  = 1'b1;
                use_imm   = 1'b1;
                mem_write = 1'b1;
                imm_sel   = `IMM_S;
                alu_op    = `ALU_ADD;
                if (funct3 != `FUNCT3_LW_SW) begin
                    illegal = 1'b1;
                end
            end

            `OPCODE_BRANCH: begin
                rs1_used = 1'b1;
                rs2_used = 1'b1;
                imm_sel  = `IMM_B;
                case (funct3)
                    `FUNCT3_BEQ: branch_type = `BR_EQ;
                    `FUNCT3_BNE: branch_type = `BR_NE;
                    default:     illegal = 1'b1;
                endcase
            end

            `OPCODE_JAL: begin
                reg_write = 1'b1;
                wb_sel    = `WB_PC4;
                imm_sel   = `IMM_J;
                jump_type = `JMP_JAL;
            end

            `OPCODE_JALR: begin
                if (funct3 == `FUNCT3_JALR) begin
                    reg_write = 1'b1;
                    wb_sel    = `WB_PC4;
                    imm_sel   = `IMM_I;
                    jump_type = `JMP_JALR;
                    use_imm   = 1'b1;
                    rs1_used  = 1'b1;
                end else begin
                    illegal = 1'b1;
                end
            end

            default: illegal = 1'b1;
        endcase

        if (illegal) begin
            reg_write   = 1'b0;
            mem_write   = 1'b0;
            mem_read    = 1'b0;
            use_imm     = 1'b0;
            wb_sel      = `WB_ALU;
            branch_type = `BR_NONE;
            jump_type   = `JMP_NONE;
            alu_op      = `ALU_ADD;
        end
    end

endmodule
