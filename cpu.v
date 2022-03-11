// RISC-V CPU (RV32I ISA)

`include "defines.v"

`ifdef PIPELINING
//-----------------------------------------------------------------------------
// Pipelined Version
module CPU (
    input clk, rst
);
    //-------------------------------------------------------------------------
    // IF
    wire [`ADDR_SIZE-1:0] pc_IF, pc_ID, pc_EX, pc_MEM, pc_WB;
    wire [`ADDR_SIZE-1:0] newPC, newSeqAddr;
    wire [`ADDR_SIZE-1:0] newJumpAddr;
    wire [`INSTR_SIZE-1:0] instr_IF, instr_ID;
    wire branchCtrl;

    addrAdder adder1(pc_IF, {{{`WORD_LEN-3}{1'b0}}, 3'b100}, newSeqAddr);
    PCSrcMux pcSrcMux(newSeqAddr, newJumpAddr, branchCtrl, newPC);
    PC programCounter(clk, rst, 1'b1, newPC, pc_IF);
    IMem imem(pc_IF, instr_IF);
    //-------------------------------------------------------------------------
    // IF/ID
    IFIDPipeReg ifidPipeReg(
        .clk(clk),
        .reset(rst),
        .IFIDFlush(branchCtrl),
        .PCIn(pc_IF),
        .instrIn(instr_IF),
        .PCOut(pc_ID),
        .instrOut(instr_ID)
    );
    //-------------------------------------------------------------------------
    // ID
    wire [`WORD_LEN-1:0] readData1_ID, readData1_EX;
    wire [`WORD_LEN-1:0] readData2_ID, readData2_EX, readData2_MEM;
    wire [`WORD_LEN-1:0] regWriteData_WB;
    wire ALUSrcA_ID, ALUSrcA_EX;
    wire ALUSrcB_ID, ALUSrcB_EX;
    wire memWrite_ID, memWrite_EX, memWrite_MEM;
    wire regWrite_ID, regWrite_EX, regWrite_MEM, regWrite_WB;
    wire [`WORD_LEN-1:0] imm_ID, imm_EX;
    wire [4:0] immCtrl;
    wire [3:0] ALUCtrl_ID, ALUCtrl_EX;
    wire [2:0] funct3_ID, funct3_EX, funct3_MEM;
    wire [1:0] memtoReg_ID, memtoReg_EX, memtoReg_MEM, memtoReg_WB;
    wire isBranchOp;
    wire [1:0] jumpType;

    wire [`REG_IDX_WIDTH-1:0] readAddr1_ID = instr_ID[19:15];
    wire [`REG_IDX_WIDTH-1:0] readAddr2_ID = instr_ID[24:20];
    wire [`REG_IDX_WIDTH-1:0] readAddr1_EX, readAddr2_EX, readAddr2_MEM;
    wire [`REG_IDX_WIDTH-1:0] writeAddr_ID = instr_ID[11:7];
    wire [`REG_IDX_WIDTH-1:0] writeAddr_EX, writeAddr_MEM, writeAddr_WB;

    ControlUnit cu(instr_ID, immCtrl, ALUCtrl_ID, ALUSrcA_ID, ALUSrcB_ID, isBranchOp, funct3_ID, jumpType, memWrite_ID, memtoReg_ID, regWrite_ID);
    RegFile regfile(clk, readAddr1_ID, readAddr2_ID, readData1_ID, readData2_ID, regWrite_WB, writeAddr_WB, regWriteData_WB);
    ImmGen immGen(instr_ID, immCtrl, imm_ID);

    wire [`ADDR_SIZE-1:0] addrAdderSrc1 = {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, imm_ID};
    wire [`ADDR_SIZE-1:0] addrAdderSrc2 = jumpType == `JUMP_TYPE_JALR ? {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, readData1_ID} : pc_ID;  // rs1 or PC
    addrAdder adder2(addrAdderSrc1, addrAdderSrc2, newJumpAddr);
    PCSrcController pcSrcController(
        .isBranchOp(isBranchOp),
        .branchType(funct3_ID),
        .isJumpOp(jumpType != `JUMP_TYPE_NONE),
        .rs1(readData1_ID),
        .rs2(readData2_ID),
        .branchCtrl(branchCtrl)
    );
    //-------------------------------------------------------------------------
    // ID/EX
    IDEXPipeReg idexPipeReg(
        .clk(clk),
        .reset(rst),
        .IDEXFlush(1'b0),
        .ALUCtrlIn(ALUCtrl_ID),
        .ALUCtrlOut(ALUCtrl_EX),
        .readAddr1In(readAddr1_ID),
        .readAddr2In(readAddr2_ID),
        .readAddr1Out(readAddr1_EX),
        .readAddr2Out(readAddr2_EX),
        .ALUSrcAIn(ALUSrcA_ID),
        .ALUSrcBIn(ALUSrcB_ID),
        .ALUSrcAOut(ALUSrcA_EX),
        .ALUSrcBOut(ALUSrcB_EX),
        .funct3In(funct3_ID),
        .funct3Out(funct3_EX),
        .memWriteIn(memWrite_ID),
        .memWriteOut(memWrite_EX),
        .writeAddrIn(writeAddr_ID),
        .writeAddrOut(writeAddr_EX),
        .memtoRegIn(memtoReg_ID),
        .memtoRegOut(memtoReg_EX),
        .regWriteIn(regWrite_ID),
        .regWriteOut(regWrite_EX),
        .readData1In(readData1_ID),
        .readData2In(readData2_ID),
        .readData1Out(readData1_EX),
        .readData2Out(readData2_EX),
        .PCIn(pc_ID),
        .PCOut(pc_EX),
        .immdiateIn(imm_ID),
        .immdiateOut(imm_EX)
    );
    //-------------------------------------------------------------------------
    // EX
    wire zeroFlag_EX, zeroFlag_MEM;
    wire [`WORD_LEN-1:0] aluSrcAMuxOut, aluSrcBMuxOut;
    wire [`WORD_LEN-1:0] aluInputA, aluInputB; // read ALU input
    wire [1:0] forwardA, forwardB;
    wire forwardMEM;
    wire [`WORD_LEN-1:0] aluOut_EX, aluOut_MEM, aluOut_WB;

    ALUSrcAMux aluSrcAMux(readData1_EX, pc_EX, ALUSrcA_EX, aluSrcAMuxOut);
    ALUSrcBMux aluSrcBMux(readData2_EX, imm_EX, ALUSrcB_EX, aluSrcBMuxOut);
    ForwardingUnit forwardingUnit(
        .regWrite_MEM(regWrite_MEM),
        .regWrite_WB(regWrite_WB),
        .memWrite_MEM(memWrite_MEM),
        .readAddr1_EX(readAddr1_EX),
        .readAddr2_EX(readAddr2_EX),
        .readAddr2_MEM(readAddr2_MEM),
        .writeAddr_MEM(writeAddr_MEM),
        .writeAddr_WB(writeAddr_WB),
        .forwardA(forwardA),
        .forwardB(forwardB),
        .forwardMEM(forwardMEM)
    );
    ALUForwardMux forwardMux1(aluSrcAMuxOut, aluOut_MEM , regWriteData_WB, forwardA, aluInputA);
    ALUForwardMux forwardMux2(aluSrcBMuxOut, aluOut_MEM , regWriteData_WB, forwardB, aluInputB);
    ALU alu(aluInputA, aluInputB, ALUCtrl_EX, aluOut_EX, zeroFlag_EX);
    //-------------------------------------------------------------------------
    // EX/MEM
    EXMEMPipeReg exmemPipeReg(
        .clk(clk),
        .reset(rst),
        .zeroFlagIn(zeroFlag_EX),
        .zeroFlagOut(zeroFlag_MEM),
        .funct3In(funct3_EX),
        .funct3Out(funct3_MEM),
        .memWriteIn(memWrite_EX),
        .memWriteOut(memWrite_MEM),
        .readAddr2In(readAddr2_EX),
        .readAddr2Out(readAddr2_MEM),
        .writeAddrIn(writeAddr_EX),
        .writeAddrOut(writeAddr_MEM),
        .memtoRegIn(memtoReg_EX),
        .memtoRegOut(memtoReg_MEM),
        .regWriteIn(regWrite_EX),
        .regWriteOut(regWrite_MEM),
        .ALUResultIn(aluOut_EX),
        .ALUResultOut(aluOut_MEM),
        .readData2In(readData2_EX),
        .readData2Out(readData2_MEM),
        .PCIn(pc_EX),
        .PCOut(pc_MEM)
    );
    //-------------------------------------------------------------------------
    // MEM
    wire [`WORD_LEN-1:0] memReadData_MEM, memReadData_WB, memWriteData;
    wire [`ADDR_SIZE-1:0] memWriteAddr = {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, aluOut_MEM};

    MEMForwardMux forwardMux3(readData2_MEM, regWriteData_WB, forwardMEM, memWriteData);
    DMem dmem(clk, memWrite_MEM, memWriteAddr, funct3_MEM, memWriteData, memReadData_MEM);
    //-------------------------------------------------------------------------
    // MEM/WB
    MEMWBPipeReg memwbReg(
        .clk(clk),
        .reset(rst),
        .writeAddrIn(writeAddr_MEM),
        .writeAddrOut(writeAddr_WB),
        .memtoRegIn(memtoReg_MEM),
        .memtoRegOut(memtoReg_WB),
        .regWriteIn(regWrite_MEM),
        .regWriteOut(regWrite_WB),
        .ALUResultIn(aluOut_MEM),
        .ALUResultOut(aluOut_WB),
        .memReadDataIn(memReadData_MEM),
        .memReadDataOut(memReadData_WB),
        .PCIn(pc_MEM),
        .PCOut(pc_WB)
    );
    //-------------------------------------------------------------------------
    // WB
    MemtoRegMux memtoRegMux(aluOut_WB, memReadData_WB, (pc_WB + 3'b100), memtoReg_WB, regWriteData_WB);
endmodule
//-----------------------------------------------------------------------------
`else
//-----------------------------------------------------------------------------
// Single Cycle Version
module CPU (
    input clk, rst,
    output [`ADDR_SIZE-1:0] pc
);
    // PC
    wire [`ADDR_SIZE-1:0] newPC, newSeqAddr, newJumpAddr;
    wire [`WORD_LEN-1:0] immOut, readData1;
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
    wire ALUSrcA, ALUSrcB, isBranchOp, memWrite, regWrite;
    wire [`WORD_LEN-1:0] aluOut;
    wire [4:0] immCtrl;
    wire [3:0] ALUCtrl;
    wire [2:0] funct3;
    wire [1:0] memtoReg;
    wire zeroFlag;

    ControlUnit cu(instr, immCtrl, ALUCtrl, ALUSrcA, ALUSrcB, isBranchOp, funct3, jumpType, memWrite, memtoReg, regWrite);
    PCSrcController pcSrcController(isBranchOp, funct3, jumpType != `JUMP_TYPE_NONE, aluOut[0], zeroFlag, branchCtrl);

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
    DMem dmem(clk, memWrite, {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, aluOut}, funct3, readData2, memReadData);
    MemtoRegMux memtoRegMux(aluOut, memReadData, newSeqAddr, memtoReg, regWriteData);
endmodule
//-----------------------------------------------------------------------------
`endif