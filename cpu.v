// RISC-V CPU (RV32I ISA)

`include "defines.v"

module xgriscv_pipeline (
    input clk, rst,

    output [`ADDR_SIZE-1:0] pc
);
    // PC
    wire [`ADDR_SIZE-1:0] newPC, newSeqAddr, newJumpAddr;
    wire [`WORD_LEN-1:0] immSL1;
    wire branchCtrl;
    PC programCounter(clk, rst, 1'b1, newPC, pc);
    addr_adder1 adder1(pc, newSeqAddr);
    addr_adder2 adder2(pc, immSL1 ,newJumpAddr);
    PCSrcMux pcSrcMux(newSeqAddr, newJumpAddr, branchCtrl, newPC);

    // Instruction Memory
    wire [`INSTR_SIZE-1:0] instr;
    IMem U_imem(pc, instr);

    // Control Unit
    wire ALUSrcA, ALUSrcB, branch, jump, memWrite, memtoReg, regWrite;
    wire [4:0] immCtrl;
    wire [3:0] ALUCtrl;
    wire [2:0] branchType;
    wire zeroFlag, ltFlag, gtFlag;

    ControlUnit cu(instr, immCtrl, ALUCtrl, ALUSrcA, ALUSrcB, branch, branchType, jump, memWrite, memtoReg, regWrite);
    PCSrcController pcSrcController(branch, branchType, jump, zeroFlag, ltFlag, gtFlag, branchCtrl);

    // Immdiate
    wire [`WORD_LEN-1:0] immOut;
    ImmGen immGen(instr, immCtrl, immOut);
    SL1 sl1(immOut, immSL1);

    // Register File
    wire [`REG_IDX_WIDTH-1:0] readAddr1 = instr[19:15];
    wire [`REG_IDX_WIDTH-1:0] readAddr2 = instr[24:20];
    wire [`REG_IDX_WIDTH-1:0] writeAddr = instr[11:7];
    wire [`WORD_LEN-1:0] readData1, readData2, regWriteData;

    RegFile regfile(clk, readAddr1, readAddr2, readData1, readData2, regWrite, writeAddr, regWriteData, pc);

    // ALU
    wire [`WORD_LEN-1:0] aluInputA, aluInputB, aluOut;
    ALUSrcAMux aluSrcAMux(readData1, pc, ALUSrcA, aluInputA);
    ALUSrcBMux aluSrcBMux(readData2, immOut, ALUSrcB, aluInputB);
    ALU alu(aluInputA, aluInputB, ALUCtrl, aluOut, zeroFlag, ltFlag, gtFlag);

    // Data Memory
    wire [`WORD_LEN-1:0] memReadData;
    DMem dmem(clk, memWrite, {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, aluOut[`WORD_LEN-1:0]}, readData2, pc, memReadData);
    MemtoRegMux memtoRegMux(aluOut, memReadData, memtoReg, regWriteData);
endmodule