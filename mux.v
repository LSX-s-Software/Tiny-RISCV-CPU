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

module ALUSrcMux (
    input [`WORD_LEN-1:0] reg2Data, // data from the register file
    input [`WORD_LEN-1:0] immData,  // data from the immediate generator
    input ALUSrc,

    output [`WORD_LEN-1:0] out
);
    assign out = (ALUSrc == 0) ? reg2Data : immData;
endmodule

module MemtoRegMux (
    input [`WORD_LEN-1:0] ALUResult, // result of the ALU
    input [`WORD_LEN-1:0] memData,   // data from the memory
    input MemtoReg,

    output [`WORD_LEN-1:0] out
);
    assign out = (MemtoReg == 0) ? ALUResult : memData;
endmodule