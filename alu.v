// ALU

`include "defines.v"

module alu(
    input [`WORD_LEN-1:0]   a,
    input [`WORD_LEN-1:0]   b,
    input [3:0]             ALUOp,

    output reg [`WORD_LEN-1:0] ALUOut,
    output zeroFlag,
    output ltFlag,
    output geFlag,
);
    always @(*)
    case(ALUOp[3:0])
        `ALU_CTRL_MOVEA: 	aluout <= a;
        `ALU_CTRL_ADD: 		aluout <= $signed(a) + $signed(b);
        `ALU_CTRL_ADDU:		aluout <= a + b;

        `ALU_CTRL_OR: 		aluout <= a | b;
        `ALU_CTRL_XOR: 		aluout <= a ^ b;
        `ALU_CTRL_AND:      aluout <= a & b;

        `ALU_CTRL_SLL:      aluout <= a << b;
        `ALU_CTRL_SRL:      aluout <= a >> b;
        `ALU_CTRL_SRA:      aluout <= $signed(a) >>> b;

        `ALU_CTRL_SUB:      aluout <= $signed(a) - $signed(b);
        `ALU_CTRL_SUBU:     aluout <= a - b;
        `ALU_CTRL_SLT:      aluout <= $signed(a) < $signed(b) ? 1 : 0;
        `ALU_CTRL_SLTU:     aluout <= a < b ? 1 : 0;

        `ALU_CTRL_LUI:		aluout <= b; //a = 0, b = immout
        `ALU_CTRL_AUIPC:	aluout <= a + $signed(b); //a = pc, b = immout

        //`ALU_CTRL_ZERO
        default: 			aluout <= `WORD_LEN'b0;
    endcase

    assign zeroFlag = (aluout == `WORD_LEN'b0);
    assign ltFlag = aluout[`WORD_LEN-1];
    assign geFlag = ~aluout[`WORD_LEN-1];
endmodule
