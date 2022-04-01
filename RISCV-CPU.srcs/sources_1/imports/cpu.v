// RISC-V CPU (RV32I ISA)

`include "defines.v"

`ifdef PIPELINING
//-----------------------------------------------------------------------------
// Pipelined Version

// ModelSim top level module
module CPU (
    input clk, rst
);
    wire [`ADDR_SIZE-1:0] pc_IF;
    wire [`ADDR_SIZE-1:0] memAccessAddr;
    wire [`INSTR_SIZE-1:0] instr_IF;
    wire [`WORD_LEN-1:0] memWriteData, memReadData_MEM;
    wire [2:0] memAccessUnitSize;
    wire memRead_MEM, memWrite_MEM;

    IMem imem(pc_IF, instr_IF);

    DMem dmem(
        .clk(clk),
        .readEnable(memRead_MEM),
        .writeEnable(memWrite_MEM),
        .addr(memAccessAddr),
        .unitSize(memAccessUnitSize),
        .writeData(memWriteData),
        .readData(memReadData_MEM)
    );

    CPUCore cpuCore(
        .clk(clk),
        .rst(rst),
        .pc_IF(pc_IF),
        .instr_IF(instr_IF),
        .memRead_MEM(memRead_MEM),
        .memWrite_MEM(memWrite_MEM),
        .memAccessAddr(memAccessAddr),
        .memAccessUnitSize(memAccessUnitSize),
        .memWriteData(memWriteData),
        .memReadData_MEM(memReadData_MEM)
    );
endmodule

// CPU core (without memory)
module CPUCore (
    input  clk, rst,
    output [`ADDR_SIZE-1:0]   pc_IF,
    input  [`INSTR_SIZE-1:0]  instr_IF,
    output                    memRead_MEM, memWrite_MEM,
    output [`ADDR_SIZE-1:0]   memAccessAddr,
    output [2:0]              memAccessUnitSize,
    output [`WORD_LEN-1:0]    memWriteData,
    input  [`WORD_LEN-1:0]    memReadData_MEM
`ifdef FPGA
    , input [`REG_IDX_WIDTH-1:0] readAddr3,
    output [`WORD_LEN-1:0] readData3
`endif
);
    //-------------------------------------------------------------------------
    // IF
    wire [`ADDR_SIZE-1:0] pc_ID, pc_EX, pc_MEM, pc_WB;
    wire [`ADDR_SIZE-1:0] newPC, newSeqAddr;
    wire [`ADDR_SIZE-1:0] newJumpAddr;
    wire [`INSTR_SIZE-1:0] instr_ID;
    wire branchCtrl, PCEn, IFIDEn;

    addrAdder adder1(pc_IF, {{{`WORD_LEN-3}{1'b0}}, 3'b100}, newSeqAddr);
    PCSrcMux pcSrcMux(newSeqAddr, newJumpAddr, branchCtrl, newPC);
    PC programCounter(clk, rst, PCEn, newPC, pc_IF);
    //-------------------------------------------------------------------------
    // IF/ID
    IFIDPipeReg ifidPipeReg(
        .clk(clk),
        .reset(rst),
        .en(IFIDEn),
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
    wire [`WORD_LEN-1:0] regWriteData_MEM, regWriteData_WB;
    wire ALUSrcA_ID, ALUSrcA_EX;
    wire ALUSrcB_ID, ALUSrcB_EX;
    wire memRead_ID, memRead_EX;
    wire memWrite_ID, memWrite_EX;
    wire regWrite_ID, regWrite_EX, regWrite_MEM, regWrite_WB;
    wire [`WORD_LEN-1:0] imm_ID, imm_EX;
    wire [4:0] immCtrl;
    wire [3:0] ALUCtrl_ID, ALUCtrl_EX;
    wire [2:0] funct3_ID, funct3_EX, funct3_MEM;
    wire [1:0] memtoReg_ID, memtoReg_EX, memtoReg_MEM;
    wire isBranchOp;
    wire [1:0] jumpType;
    wire isJumpOp = jumpType != `JUMP_TYPE_NONE;
    wire IDEXFlush;

    wire [`REG_IDX_WIDTH-1:0] readAddr1_ID = instr_ID[19:15];
    wire [`REG_IDX_WIDTH-1:0] readAddr2_ID = instr_ID[24:20];
    wire [`REG_IDX_WIDTH-1:0] readAddr1_EX, readAddr2_EX, readAddr2_MEM;
    wire [`REG_IDX_WIDTH-1:0] writeAddr_ID = instr_ID[11:7];
    wire [`REG_IDX_WIDTH-1:0] writeAddr_EX, writeAddr_MEM, writeAddr_WB;

    ControlUnit cu(
        .instr(instr_ID),
        .immCtrl(immCtrl),
        .ALUCtrl(ALUCtrl_ID),
        .ALUSrcA(ALUSrcA_ID),
        .ALUSrcB(ALUSrcB_ID),
        .branch(isBranchOp),
        .funct3(funct3_ID),
        .jumpType(jumpType),
        .memRead(memRead_ID),
        .memWrite(memWrite_ID),
        .memtoReg(memtoReg_ID),
        .regWrite(regWrite_ID)
    );
    RegFile regfile(
        .clk(clk),
        .readAddr1(readAddr1_ID),
        .readAddr2(readAddr2_ID),
        .readData1(readData1_ID),
        .readData2(readData2_ID),
        .writeEnable(regWrite_WB),
        .writeAddr(writeAddr_WB),
        .writeData(regWriteData_WB)
`ifdef FPGA
        ,.readAddr3(readAddr3),
        .readData3(readData3)
`endif
    );
    ImmGen immGen(instr_ID, immCtrl, imm_ID);

    wire [`WORD_LEN-1:0] pcSrcControllerIn1, pcSrcControllerIn2;
    wire [`ADDR_SIZE-1:0] addrAdderSrc1 = {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, imm_ID};
    wire [`ADDR_SIZE-1:0] addrAdderSrc2 = jumpType == `JUMP_TYPE_JALR ? {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, pcSrcControllerIn1} : pc_ID;  // rs1 or PC
    wire forwardR1, forwardR2;

    addrAdder adder2(addrAdderSrc1, addrAdderSrc2, newJumpAddr);
    MEMIDForwardMux forwardMux4(readData1_ID, regWriteData_MEM, forwardR1, pcSrcControllerIn1);
    MEMIDForwardMux forwardMux5(readData2_ID, regWriteData_MEM, forwardR2, pcSrcControllerIn2);
    PCSrcController pcSrcController(
        .isBranchOp(isBranchOp),
        .branchType(funct3_ID),
        .isJumpOp(isJumpOp),
        .rs1(pcSrcControllerIn1),
        .rs2(pcSrcControllerIn2),
        .branchCtrl(branchCtrl)
    );

    HazardDetectionUnit hdu(
        .memRead_EX(memRead_EX),
        .memWrite_ID(memWrite_ID),
        .branchOrJump_ID(isBranchOp || isJumpOp),
        .regWrite_EX(regWrite_EX),
        .readAddr1_ID(readAddr1_ID),
        .readAddr2_ID(readAddr2_ID),
        .writeAddr_EX(writeAddr_EX),
        .PCEn(PCEn),
        .IFIDEn(IFIDEn),
        .IDEXFlush(IDEXFlush)
    );
    //-------------------------------------------------------------------------
    // ID/EX
    IDEXPipeReg idexPipeReg(
        .clk(clk),
        .reset(rst),
        .IDEXFlush(IDEXFlush),
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
        .memReadIn(memRead_ID),
        .memReadOut(memRead_EX),
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
    wire [`WORD_LEN-1:0] aluSrcAMuxOut, aluSrcBMuxOut;
    wire [`WORD_LEN-1:0] aluInputA, readData2ForwardedData_EX, aluInputB; // read ALU input
    wire [1:0] forwardA, forwardB;
    wire forwardMEM;
    wire [`WORD_LEN-1:0] aluOut_EX, aluOut_MEM;

    ALUSrcAMux aluSrcAMux(readData1_EX, pc_EX, ALUSrcA_EX, aluSrcAMuxOut);
    ForwardingUnit forwardingUnit(
        .regWrite_MEM(regWrite_MEM),
        .regWrite_WB(regWrite_WB),
        .memWrite_EX(memWrite_EX),
        .memWrite_MEM(memWrite_MEM),
        .readAddr1_ID(readAddr1_ID),
        .readAddr2_ID(readAddr2_ID),
        .readAddr1_EX(readAddr1_EX),
        .readAddr2_EX(readAddr2_EX),
        .readAddr2_MEM(readAddr2_MEM),
        .writeAddr_MEM(writeAddr_MEM),
        .writeAddr_WB(writeAddr_WB),
        .forwardA(forwardA),
        .forwardB(forwardB),
        .forwardMEM(forwardMEM),
        .forwardR1(forwardR1),
        .forwardR2(forwardR2)
    );
    ALUForwardMux forwardMux1(aluSrcAMuxOut, aluOut_MEM, regWriteData_WB, forwardA, aluInputA);
    ALUForwardMux forwardMux2(readData2_EX, aluOut_MEM, regWriteData_WB, forwardB, readData2ForwardedData_EX);
    ALUSrcBMux aluSrcBMux(readData2ForwardedData_EX, imm_EX, ALUSrcB_EX, aluInputB);
    ALU alu(aluInputA, aluInputB, ALUCtrl_EX, aluOut_EX);
    //-------------------------------------------------------------------------
    // EX/MEM
    EXMEMPipeReg exmemPipeReg(
        .clk(clk),
        .reset(rst),
        .funct3In(funct3_EX),
        .funct3Out(funct3_MEM),
        .memReadIn(memRead_EX),
        .memReadOut(memRead_MEM),
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
    assign memAccessAddr = {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, aluOut_MEM};
    assign memAccessUnitSize = funct3_MEM;

    WBMEMForwardMux forwardMux3(readData2_MEM, regWriteData_WB, forwardMEM, memWriteData);
    MemtoRegMux memtoRegMux(
        .ALUResult(aluOut_MEM),
        .memData(memReadData_MEM),
        .newSeqAddr(pc_MEM + 3'b100),
        .MemtoReg(memtoReg_MEM),
        .out(regWriteData_MEM)
    );
    //-------------------------------------------------------------------------
    // MEM/WB
    MEMWBPipeReg memwbReg(
        .clk(clk),
        .reset(rst),
        .writeAddrIn(writeAddr_MEM),
        .writeAddrOut(writeAddr_WB),
        .regWriteIn(regWrite_MEM),
        .regWriteOut(regWrite_WB),
        .regWriteDataIn(regWriteData_MEM),
        .regWriteDataOut(regWriteData_WB),
        .PCIn(pc_MEM),
        .PCOut(pc_WB)
    );
endmodule
//-----------------------------------------------------------------------------
`else
//-----------------------------------------------------------------------------
// Single Cycle Version
module CPU (
    input clk, rst
);
    // PC
    wire [`INSTR_SIZE-1:0] instr;
    wire [`ADDR_SIZE-1:0] pc, newPC, newSeqAddr, newJumpAddr;
    wire [`WORD_LEN-1:0] immOut, readData1, readData2, regWriteData;
    wire [`REG_IDX_WIDTH-1:0] readAddr1 = instr[19:15];
    wire [`REG_IDX_WIDTH-1:0] readAddr2 = instr[24:20];
    wire [`REG_IDX_WIDTH-1:0] writeAddr = instr[11:7];
    wire ALUSrcA, ALUSrcB, isBranchOp, memRead, memWrite, regWrite;
    wire [`WORD_LEN-1:0] aluInputA, aluInputB, aluOut;
    wire [`WORD_LEN-1:0] memReadData;
    wire [4:0] immCtrl;
    wire [3:0] ALUCtrl;
    wire [2:0] funct3;
    wire [1:0] memtoReg;
    wire [1:0] jumpType;
    wire branchCtrl;

    // PC
    PC programCounter(clk, rst, 1'b1, newPC, pc);
    addrAdder adder1(pc, {{{`WORD_LEN-3}{1'b0}}, 3'b100}, newSeqAddr);
    wire [`ADDR_SIZE-1:0] addrAdderSrc1 = {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, immOut};
    wire [`ADDR_SIZE-1:0] addrAdderSrc2 = jumpType == `JUMP_TYPE_JALR ? {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, readData1} : pc;  // rs1 or PC
    addrAdder adder2(addrAdderSrc1, addrAdderSrc2 ,newJumpAddr);
    PCSrcMux pcSrcMux(newSeqAddr, newJumpAddr, branchCtrl, newPC);

    // Instruction Memory
    IMem imem(pc, instr);

    // Control Unit
    ControlUnit cu(
        .instr(instr),
        .immCtrl(immCtrl),
        .ALUCtrl(ALUCtrl),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .branch(isBranchOp),
        .funct3(funct3),
        .jumpType(jumpType),
        .memRead(memRead),
        .memWrite(memWrite),
        .memtoReg(memtoReg),
        .regWrite(regWrite)
    );
    PCSrcController pcSrcController(
        .isBranchOp(isBranchOp),
        .branchType(funct3),
        .isJumpOp(jumpType != `JUMP_TYPE_NONE),
        .rs1(readData1),
        .rs2(readData2),
        .branchCtrl(branchCtrl)
    );

    // Immdiate
    ImmGen immGen(instr, immCtrl, immOut);

    // Register File
    RegFile regfile(
        .clk(clk),
        .readAddr1(readAddr1),
        .readAddr2(readAddr2),
        .readData1(readData1),
        .readData2(readData2),
        .writeEnable(regWrite),
        .writeAddr(writeAddr),
        .writeData(regWriteData)
    );

    // ALU
    ALUSrcAMux aluSrcAMux(readData1, pc, ALUSrcA, aluInputA);
    ALUSrcBMux aluSrcBMux(readData2, immOut, ALUSrcB, aluInputB);
    ALU alu(aluInputA, aluInputB, ALUCtrl, aluOut);

    // Data Memory
    wire [`ADDR_SIZE-1:0] memAccessAddr = {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, aluOut};
    DMem dmem(
        .clk(clk),
        .readEnable(memRead),
        .writeEnable(memWrite),
        .addr(memAccessAddr),
        .unitSize(funct3),
        .writeData(readData2),
        .readData(memReadData)
    );
    MemtoRegMux memtoRegMux(
        .ALUResult(aluOut),
        .memData(memReadData),
        .newSeqAddr(newSeqAddr),
        .MemtoReg(memtoReg),
        .out(regWriteData)
    );
endmodule
//-----------------------------------------------------------------------------
`endif