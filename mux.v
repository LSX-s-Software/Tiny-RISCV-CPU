// MUX

`include "defines.v"

module PCSrcMux (
    input [`ADDR_SIZE-1:0] seqAddr, // sequence address (current PC + 4)
    input [`ADDR_SIZE-1:0] jmpAddr, // jump address (calculated by address adder)
    input PCSrc,

    output [`ADDR_SIZE-1:0] out
);
    assign out = (PCSrc == 0) ? seqAddr : jmpAddr;
endmodule

module ALUSrcAMux (
    input [`WORD_LEN-1:0] reg1Data, // data from the register file
    input [`ADDR_SIZE-1:0] pc,   // data from PC
    input ALUSrcA,

    output [`WORD_LEN-1:0] out
);
    assign out = (ALUSrcA == 0) ? reg1Data : {{{`WORD_LEN-`ADDR_SIZE}{1'b0}}, pc};
endmodule

module ALUSrcBMux (
    input [`WORD_LEN-1:0] reg2Data, // data from the register file
    input [`WORD_LEN-1:0] immData,  // data from the immediate generator
    input ALUSrcB,

    output [`WORD_LEN-1:0] out
);
    assign out = (ALUSrcB == 0) ? reg2Data : immData;
endmodule

module MemtoRegMux (
    input [`WORD_LEN-1:0] ALUResult, // result of the ALU
    input [`WORD_LEN-1:0] memData,   // data from the memory
    input [`ADDR_SIZE-1:0] newSeqAddr, // PC + 4
    input [1:0] MemtoReg,

    output reg [`WORD_LEN-1:0] out
);
    always @(*) begin
        case (MemtoReg)
            2'b00: out <= ALUResult;
            2'b01: out <= memData;
            2'b10: out <= newSeqAddr;
        endcase
    end
endmodule