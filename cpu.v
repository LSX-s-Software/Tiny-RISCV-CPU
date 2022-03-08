// RISC-V CPU (RV32I ISA)

`include "defines.v"

module xgriscv_pipeline (
    input clk, rst,
    output [`ADDR_SIZE-1:0] pc_WB
);
    //-------------------------------------------------------------------------
    // IF
    wire [`ADDR_SIZE-1:0] pc_IF, pc_ID, pc_EX, pc_MEM;
    wire [`ADDR_SIZE-1:0] newPC, newSeqAddr;
    wire [`ADDR_SIZE-1:0] newJumpAddr_EX, newJumpAddr_MEM;
    wire [`INSTR_SIZE-1:0] instr_IF, instr_ID;
    wire [1:0] jumpType_ID, jumpType_EX, jumpType_MEM;
    wire branchCtrl_MEM;

    addrAdder adder1(pc_IF, {{{`WORD_LEN-3}{1'b0}}, 3'b100}, newSeqAddr);
    PCSrcMux pcSrcMux(newSeqAddr, newJumpAddr_MEM, branchCtrl_MEM, newPC);
    PC programCounter(clk, rst, 1'b1, newPC, pc_IF);
    IMem U_imem(pc_IF, instr_IF);
    //-------------------------------------------------------------------------
    // IF/ID
    IFIDPipeReg ifidPipeReg(
        .clk(clk),
        .reset(rst),
        .IFIDFlush(1'b0),
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
    wire branch_ID, branch_EX, branch_MEM;
    wire memWrite_ID, memWrite_EX, memWrite_MEM;
    wire regWrite_ID, regWrite_EX, regWrite_MEM, regWrite_WB;
    wire [`WORD_LEN-1:0] imm_ID, imm_EX;
    wire [4:0] immCtrl;
    wire [3:0] ALUCtrl_ID, ALUCtrl_EX;
    wire [2:0] funct3_ID, funct3_EX, funct3_MEM;
    wire [1:0] memtoReg_ID, memtoReg_EX, memtoReg_MEM, memtoReg_WB;

    wire [`REG_IDX_WIDTH-1:0] readAddr1 = instr_ID[19:15];
    wire [`REG_IDX_WIDTH-1:0] readAddr2 = instr_ID[24:20];
    wire [`REG_IDX_WIDTH-1:0] writeAddr_ID = instr_ID[11:7];
    wire [`REG_IDX_WIDTH-1:0] writeAddr_EX, writeAddr_MEM, writeAddr_WB;

    ControlUnit cu(instr_ID, immCtrl, ALUCtrl_ID, ALUSrcA_ID, ALUSrcB_ID, branch_ID, funct3_ID, jumpType_ID, memWrite_ID, memtoReg_ID, regWrite_ID);
    RegFile regfile(clk, readAddr1, readAddr2, readData1_ID, readData2_ID, regWrite_WB, writeAddr_WB, regWriteData_WB, pc_WB);
    ImmGen immGen(instr_ID, immCtrl, imm_ID);
    //-------------------------------------------------------------------------
    // ID/EX
    IDEXPipeReg idexPipeReg(
        .clk(clk),
        .reset(rst),
        .IDEXFlush(1'b0),
        .ALUCtrlIn(ALUCtrl_ID),
        .ALUCtrlOut(ALUCtrl_EX),
        .ALUSrcAIn(ALUSrcA_ID),
        .ALUSrcBIn(ALUSrcB_ID),
        .ALUSrcAOut(ALUSrcA_EX),
        .ALUSrcBOut(ALUSrcB_EX),
        .branchIn(branch_ID),
        .branchOut(branch_EX),
        .jumpTypeIn(jumpType_ID),
        .jumpTypeOut(jumpType_EX),
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
    wire [`WORD_LEN-1:0] aluInputA, aluInputB;
    wire [`WORD_LEN-1:0] aluOut_EX, aluOut_MEM, aluOut_WB;
    wire [`ADDR_SIZE-1:0] addrAdderSrc1 = {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, imm_EX};
    wire [`ADDR_SIZE-1:0] addrAdderSrc2 = jumpType_EX == `JUMP_TYPE_JALR ? {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, readData1_EX} : pc_EX;  // rs1 or PC

    ALUSrcAMux aluSrcAMux(readData1_EX, pc_EX, ALUSrcA_EX, aluInputA);
    ALUSrcBMux aluSrcBMux(readData2_EX, imm_EX, ALUSrcB_EX, aluInputB);
    ALU alu(aluInputA, aluInputB, ALUCtrl_EX, aluOut_EX, zeroFlag_EX);
    addrAdder adder2(addrAdderSrc1, addrAdderSrc2, newJumpAddr_EX);
    //-------------------------------------------------------------------------
    // EX/MEM
    EXMEMPipeReg exmemPipeReg(
        .clk(clk),
        .reset(rst),
        .newJumpAddrIn(newJumpAddr_EX),
        .newJumpAddrOut(newJumpAddr_MEM),
        .branchIn(branch_EX),
        .branchOut(branch_MEM),
        .jumpTypeIn(jumpType_EX),
        .jumpTypeOut(jumpType_MEM),
        .zeroFlagIn(zeroFlag_EX),
        .zeroFlagOut(zeroFlag_MEM),
        .funct3In(funct3_EX),
        .funct3Out(funct3_MEM),
        .memWriteIn(memWrite_EX),
        .memWriteOut(memWrite_MEM),
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
    wire [`WORD_LEN-1:0] memReadData_MEM, memReadData_WB;

    PCSrcController pcSrcController(branch_MEM, funct3_MEM, jumpType_MEM != `JUMP_TYPE_NONE, aluOut_MEM[0], zeroFlag_MEM, branchCtrl_MEM);
    DMem dmem(clk, memWrite_MEM, {{{`ADDR_SIZE-`WORD_LEN}{1'b0}}, aluOut_MEM}, funct3_MEM, readData2_MEM, memReadData_MEM, pc_MEM);
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