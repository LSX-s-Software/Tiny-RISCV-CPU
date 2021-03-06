`define DEBUG
`define PIPELINING
`define FPGA

// ISA related

`define ADDR_SIZE	    32 // width of an address
`define INSTR_SIZE      32 // length of an instruction

`define WORD_LEN	    32 // data width of a register
`define REG_COUNT	    32 // number of registers
`define REG_IDX_WIDTH   5  // width of a register index

`define IMEM_SIZE			1024
`define IMEM_SIZE_WIDTH		10
`define DMEM_SIZE			1024
`define DMEM_SIZE_WIDTH		10

//RV32I
`define OP_LUI		7'b0110111
`define OP_AUIPC	7'b0010111
`define OP_JAL		7'b1101111
`define OP_JALR		7'b1100111
`define OP_BRANCH	7'b1100011
`define OP_LOAD		7'b0000011
`define OP_STORE	7'b0100011
`define OP_I_TYPE	7'b0010011
`define OP_R_TYPE	7'b0110011

`define FUNCT3_BEQ	3'b000
`define FUNCT3_BNE	3'b001
`define FUNCT3_BLT	3'b100
`define FUNCT3_BGE	3'b101
`define FUNCT3_BLTU	3'b110
`define FUNCT3_BGEU	3'b111

`define FUNCT3_BYTE	3'b000
`define FUNCT3_HALF	3'b001
`define FUNCT3_WORD	3'b010
`define FUNCT3_BYTE_UNSIGNED	3'b100
`define FUNCT3_HALF_UNSIGNED	3'b101

`define FUNCT3_ADDI	3'b000
`define FUNCT3_SLTI	3'b010
`define FUNCT3_SLTIU	3'b011
`define FUNCT3_XORI	3'b100
`define FUNCT3_ORI	3'b110
`define FUNCT3_ANDI	3'b111

`define FUNCT3_SL	3'b001
`define FUNCT3_SR	3'b101

`define FUNCT7_SLLI	7'b0000000
`define FUNCT7_SRLI	7'b0000000
`define FUNCT7_SRAI	7'b0100000

`define FUNCT3_ADD	3'b000
`define FUNCT3_SLL	3'b001
`define FUNCT3_SLT	3'b010
`define FUNCT3_SLTU	3'b011
`define FUNCT3_XOR	3'b100
`define FUNCT3_OR	3'b110
`define FUNCT3_AND	3'b111

`define FUNCT7_ADD	7'b0000000
`define FUNCT7_SUB	7'b0100000

`define FUNCT7_SRL	7'b0000000
`define FUNCT7_SRA	7'b0100000

//ALU CTRL
`define	ALU_CTRL_MOVEA	4'b0000

`define	ALU_CTRL_ADD	4'b0001
`define	ALU_CTRL_SUB	4'b1001

`define	ALU_CTRL_OR		4'b0011
`define	ALU_CTRL_XOR	4'b0100
`define	ALU_CTRL_AND	4'b0101

`define	ALU_CTRL_SLL	4'b0110
`define	ALU_CTRL_SRL	4'b0111
`define	ALU_CTRL_SRA	4'b1000

`define	ALU_CTRL_SLT	4'b1011
`define	ALU_CTRL_SLTU	4'b1100

`define	ALU_CTRL_LUI	4'b1101
`define	ALU_CTRL_AUIPC	4'b1110

`define	ALU_CTRL_ZERO	4'b1111

//IMM CTRL itype, stype, btype, utype, jtype
`define IMM_CTRL_ITYPE	5'b10000
`define IMM_CTRL_STYPE	5'b01000
`define IMM_CTRL_BTYPE	5'b00100
`define IMM_CTRL_UTYPE	5'b00010
`define IMM_CTRL_JTYPE	5'b00001

// Jump type
`define JUMP_TYPE_NONE	2'b00
`define JUMP_TYPE_JAL	2'b01
`define JUMP_TYPE_JALR	2'b10