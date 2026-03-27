`ifndef PIPELINE_CTRL_SIGNAL_DEF_V
`define PIPELINE_CTRL_SIGNAL_DEF_V

`define ALU_ADD 4'd0
`define ALU_SUB 4'd1
`define ALU_AND 4'd2
`define ALU_OR  4'd3
`define ALU_SLL 4'd4
`define ALU_SRL 4'd5
`define ALU_XOR 4'd6
`define ALU_SRA 4'd7

`define IMM_I 3'd0
`define IMM_S 3'd1
`define IMM_B 3'd2
`define IMM_J 3'd3

`define WB_ALU 2'd0
`define WB_MEM 2'd1
`define WB_PC4 2'd2

`define BR_NONE 2'd0
`define BR_EQ   2'd1
`define BR_NE   2'd2

`define JMP_NONE 2'd0
`define JMP_JAL  2'd1
`define JMP_JALR 2'd2

`endif
