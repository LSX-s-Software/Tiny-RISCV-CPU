// ALU

`include "defines.v"

module ALU(
    input [`WORD_LEN-1:0]   a,
    input [`WORD_LEN-1:0]   b,
    input [3:0]             ALUCtrl,

    output reg [`WORD_LEN-1:0] ALUOut,
    output zeroFlag
);
    always @(*)
    case(ALUCtrl)
        `ALU_CTRL_MOVEA: 	ALUOut <= a;
        `ALU_CTRL_ADD:		ALUOut <= a + b;

        `ALU_CTRL_OR: 		ALUOut <= a | b;
        `ALU_CTRL_XOR: 		ALUOut <= a ^ b;
        `ALU_CTRL_AND:      ALUOut <= a & b;

        `ALU_CTRL_SLL:      ALUOut <= a << (b & 5'b11111);
        `ALU_CTRL_SRL:      ALUOut <= a >> (b & 5'b11111);
        `ALU_CTRL_SRA:      ALUOut <= $signed(a) >>> (b & 5'b11111);

        `ALU_CTRL_SUB:      ALUOut <= a - b;
        `ALU_CTRL_SLT:      ALUOut <= $signed(a) < $signed(b) ? 1 : 0;
        `ALU_CTRL_SLTU:     ALUOut <= a < b ? 1 : 0;

        `ALU_CTRL_LUI:		ALUOut <= b; //a = 0, b = immout
        `ALU_CTRL_AUIPC:	ALUOut <= a + $signed(b); //a = pc, b = immout

        //`ALU_CTRL_ZERO
        default: 			ALUOut <= `WORD_LEN'b0;
    endcase

    assign zeroFlag = (ALUOut == `WORD_LEN'b0);
endmodule
