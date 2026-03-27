`ifndef PIPELINE_INSTRUCTION_DEF_V
`define PIPELINE_INSTRUCTION_DEF_V

`define OPCODE_OP      7'b0110011
`define OPCODE_OP_IMM  7'b0010011
`define OPCODE_LOAD    7'b0000011
`define OPCODE_STORE   7'b0100011
`define OPCODE_BRANCH  7'b1100011
`define OPCODE_JAL     7'b1101111
`define OPCODE_JALR    7'b1100111

`define FUNCT3_ADD_SUB 3'b000
`define FUNCT3_SLL     3'b001
`define FUNCT3_XOR     3'b100
`define FUNCT3_SRL     3'b101
`define FUNCT3_OR      3'b110
`define FUNCT3_AND     3'b111
`define FUNCT3_LW_SW   3'b010
`define FUNCT3_BEQ     3'b000
`define FUNCT3_BNE     3'b001
`define FUNCT3_JALR    3'b000

`define FUNCT7_ADD     7'b0000000
`define FUNCT7_SUB     7'b0100000
`define FUNCT7_SRL     7'b0000000
`define FUNCT7_SRA     7'b0100000

`endif
