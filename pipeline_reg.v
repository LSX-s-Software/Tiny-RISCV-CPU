// Pipeline registers

`include "defines.v"

module PipelineReg #(
    parameter WIDTH = 1
) (
    input clk, reset,
    input [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);
    always @(posedge clk, posedge reset)
        if (reset) out <= {{WIDTH}{1'b0}};
        else       out <= in;
endmodule

// flushable pipeline register
module FlushablePipeReg #(
    parameter WIDTH = 1
) (
    input clk, reset, flush,
    input [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);
    always @(posedge clk, posedge reset)
        if (reset)      out <= {{WIDTH}{1'b0}};
        else if (flush) out <= {{WIDTH}{1'b0}};
        else            out <= in;
endmodule

// flushable pipeline register with write control
module FlushableEnPipeReg #(
    parameter WIDTH = 1
) (
    input clk, reset, en, flush,
    input [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);
    always @(posedge clk, posedge reset)
        if (reset)
            out <= {{WIDTH}{1'b0}};
        else if
            (en && flush) out <= {{WIDTH}{1'b0}};
        else if (en)
            out <= in;
endmodule

// IF/ID pipeline registers
module IFIDPipeReg (
    input clk, reset, en, IFIDFlush,
    input [`ADDR_SIZE-1:0] PCIn,
    input [`INSTR_SIZE-1:0] instrIn,

    output [`ADDR_SIZE-1:0] PCOut,
    output [`INSTR_SIZE-1:0] instrOut
);
    FlushableEnPipeReg #(`ADDR_SIZE) PCPipeReg (clk, reset, en, IFIDFlush, PCIn, PCOut);
    FlushableEnPipeReg #(`INSTR_SIZE) instrPipeReg (clk, reset, en, IFIDFlush, instrIn, instrOut);
endmodule

// ID/EX pipeline registers
module IDEXPipeReg (
    input clk, reset, IDEXFlush,
    // Control signals input
    // -----EX-----
    input [3:0] ALUCtrlIn,
    input [`REG_IDX_WIDTH-1:0] readAddr1In, readAddr2In,
    input ALUSrcAIn, ALUSrcBIn,
    // -----MEM----
    input [2:0] funct3In,
    input memReadIn, memWriteIn,
    input [`REG_IDX_WIDTH-1:0] writeAddrIn,
    // -----WB-----
    input [1:0] memtoRegIn,
    input regWriteIn,
    // Data input
    input [`WORD_LEN-1:0] readData1In, readData2In, PCIn, immdiateIn,

    // Control signals output
    output [3:0] ALUCtrlOut,
    output [`REG_IDX_WIDTH-1:0] readAddr1Out, readAddr2Out,
    output ALUSrcAOut, ALUSrcBOut,
    output [2:0] funct3Out,
    output [`REG_IDX_WIDTH-1:0] writeAddrOut,
    output memReadOut, memWriteOut,
    output [1:0] memtoRegOut,
    output regWriteOut,
    // Data output
    output [`WORD_LEN-1:0] readData1Out, readData2Out, PCOut, immdiateOut
);
    FlushablePipeReg #(4) ALUCtrlPipeReg (clk, reset, IDEXFlush, ALUCtrlIn, ALUCtrlOut);
    FlushablePipeReg #(`REG_IDX_WIDTH) readAddr1PipeReg (clk, reset, IDEXFlush, readAddr1In, readAddr1Out);
    FlushablePipeReg #(`REG_IDX_WIDTH) readAddr2PipeReg (clk, reset, IDEXFlush, readAddr2In, readAddr2Out);
    FlushablePipeReg #(1) ALUSrcAPipeReg (clk, reset, IDEXFlush, ALUSrcAIn, ALUSrcAOut);
    FlushablePipeReg #(1) ALUSrcBPipeReg (clk, reset, IDEXFlush, ALUSrcBIn, ALUSrcBOut);
    FlushablePipeReg #(3) funct3PipeReg (clk, reset, IDEXFlush, funct3In, funct3Out);
    FlushablePipeReg #(1) memReadPipeReg (clk, reset, IDEXFlush, memReadIn, memReadOut);
    FlushablePipeReg #(1) memWritePipeReg (clk, reset, IDEXFlush, memWriteIn, memWriteOut);
    FlushablePipeReg #(2) memtoRegPipeReg (clk, reset, IDEXFlush, memtoRegIn, memtoRegOut);
    FlushablePipeReg #(1) regWritePipeReg (clk, reset, IDEXFlush, regWriteIn, regWriteOut);

    FlushablePipeReg #(`WORD_LEN) readData1PipeReg (clk, reset, IDEXFlush, readData1In, readData1Out);
    FlushablePipeReg #(`WORD_LEN) readData2PipeReg (clk, reset, IDEXFlush, readData2In, readData2Out);
    FlushablePipeReg #(`ADDR_SIZE) PCPipeReg (clk, reset, IDEXFlush, PCIn, PCOut);
    FlushablePipeReg #(`WORD_LEN) immdiatePipeReg (clk, reset, IDEXFlush, immdiateIn, immdiateOut);

    FlushablePipeReg #(`REG_IDX_WIDTH) writeAddrPipeReg (clk, reset, IDEXFlush, writeAddrIn, writeAddrOut);
endmodule

module EXMEMPipeReg (
    input clk, reset,
    // Control signals input
    // -----MEM-----
    input [2:0] funct3In,
    input memReadIn, memWriteIn,
    input [`REG_IDX_WIDTH-1:0] readAddr2In, writeAddrIn,
    // -----WB-----
    input [1:0] memtoRegIn,
    input regWriteIn,
    // Data input
    input [`WORD_LEN-1:0] ALUResultIn,
    input [`WORD_LEN-1:0] readData2In,
    input [`ADDR_SIZE-1:0] PCIn,

    // Control signals output
    output [2:0] funct3Out,
    output memReadOut, memWriteOut,
    output [`REG_IDX_WIDTH-1:0] readAddr2Out, writeAddrOut,
    output [1:0] memtoRegOut,
    output regWriteOut,
    // Data output
    output [`WORD_LEN-1:0] ALUResultOut,
    output [`WORD_LEN-1:0] readData2Out,
    output [`ADDR_SIZE-1:0] PCOut
);
    PipelineReg #(3) funct3PipeReg (clk, reset, funct3In, funct3Out);
    PipelineReg #(1) memReadPipeReg (clk, reset, memReadIn, memReadOut);
    PipelineReg #(1) memWritePipeReg (clk, reset, memWriteIn, memWriteOut);
    PipelineReg #(`REG_IDX_WIDTH) writeAddrPipeReg (clk, reset, writeAddrIn, writeAddrOut);
    PipelineReg #(`REG_IDX_WIDTH) readAddr2PipeReg (clk, reset, readAddr2In, readAddr2Out);
    PipelineReg #(2) memtoRegPipeReg (clk, reset, memtoRegIn, memtoRegOut);
    PipelineReg #(1) regWritePipeReg (clk, reset, regWriteIn, regWriteOut);

    PipelineReg #(`WORD_LEN) ALUResultPipeReg (clk, reset, ALUResultIn, ALUResultOut);
    PipelineReg #(`WORD_LEN) readData2PipeReg (clk, reset, readData2In, readData2Out);
    PipelineReg #(`ADDR_SIZE) pcPipeReg (clk, reset, PCIn, PCOut);
endmodule

// MEM/WB pipeline register
module MEMWBPipeReg (
    input clk, reset,
    // Control signals input
    input [`REG_IDX_WIDTH-1:0] writeAddrIn,
    input regWriteIn,
    // Data input
    input [`ADDR_SIZE-1:0] PCIn,
    input [`WORD_LEN-1:0] regWriteDataIn,

    // Control signals output
    output [`REG_IDX_WIDTH-1:0] writeAddrOut,
    output regWriteOut,
    // Data output
    output [`ADDR_SIZE-1:0] PCOut,
    output [`WORD_LEN-1:0] regWriteDataOut
);
    PipelineReg #(`REG_IDX_WIDTH) writeAddrPipeReg (clk, reset, writeAddrIn, writeAddrOut);
    PipelineReg #(1) regWritePipeReg (clk, reset, regWriteIn, regWriteOut);

    PipelineReg #(`ADDR_SIZE) pcPipeReg (clk, reset, PCIn, PCOut);
    PipelineReg #(`WORD_LEN) regWriteDataPipeReg (clk, reset, regWriteDataIn, regWriteDataOut);
endmodule