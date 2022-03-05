// RISC-V CPU (RV32I ISA)

`include "defines.v"

module CPU (
    input clk, rst,

    output [`ADDR_SIZE-1:0] pc
);
    // PC
    wire [`ADDR_SIZE-1:0] newPC, newSeqAddr, newJumpAddr;
    wire [`WORD_LEN-1:0] immOut, immSL1, readData1;
    wire [1:0] jumpType;
    wire branchCtrl;
    PC programCounter(clk, rst, 1'b1, newPC, pc);
    addrAdder adder1(pc, {{{`WORD_LEN-3}{1'b0}}, 3'b100}, newSeqAddr);
    wire [`ADDR_SIZE-1:0] addrAdderSrc1 = {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, immOut};
    wire [`ADDR_SIZE-1:0] addrAdderSrc2 = jumpType == `JUMP_TYPE_JALR ? {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, readData1} : pc;  // rs1 or PC
    addrAdder adder2(addrAdderSrc1, addrAdderSrc2 ,newJumpAddr);
    PCSrcMux pcSrcMux(newSeqAddr, newJumpAddr, branchCtrl, newPC);

    // Instruction Memory
    wire [`INSTR_SIZE-1:0] instr;
    IMem imem(pc, instr);

    // Control Unit
    wire ALUSrcA, ALUSrcB, branch, memWrite, regWrite;
    wire [`WORD_LEN-1:0] aluOut;
    wire [4:0] immCtrl;
    wire [3:0] ALUCtrl;
    wire [2:0] branchType;
    wire [1:0] memtoReg;
    wire zeroFlag;

    ControlUnit cu(instr, immCtrl, ALUCtrl, ALUSrcA, ALUSrcB, branch, branchType, jumpType, memWrite, memtoReg, regWrite);
    PCSrcController pcSrcController(branch, branchType, jumpType != `JUMP_TYPE_NONE, aluOut[0], zeroFlag, branchCtrl);

    // Immdiate
    ImmGen immGen(instr, immCtrl, immOut);

    // Register File
    wire [`REG_IDX_WIDTH-1:0] readAddr1 = instr[19:15];
    wire [`REG_IDX_WIDTH-1:0] readAddr2 = instr[24:20];
    wire [`REG_IDX_WIDTH-1:0] writeAddr = instr[11:7];
    wire [`WORD_LEN-1:0] readData2, regWriteData;

    RegFile regfile(clk, readAddr1, readAddr2, readData1, readData2, regWrite, writeAddr, regWriteData);

    // ALU
    wire [`WORD_LEN-1:0] aluInputA, aluInputB;
    ALUSrcAMux aluSrcAMux(readData1, pc, ALUSrcA, aluInputA);
    ALUSrcBMux aluSrcBMux(readData2, immOut, ALUSrcB, aluInputB);
    ALU alu(aluInputA, aluInputB, ALUCtrl, aluOut, zeroFlag);

    // Data Memory
    wire [`WORD_LEN-1:0] memReadData;
    DMem dmem(clk, memWrite, {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, aluOut}, readData2, memReadData);
    MemtoRegMux memtoRegMux(aluOut, memReadData, newSeqAddr, memtoReg, regWriteData);
endmodule