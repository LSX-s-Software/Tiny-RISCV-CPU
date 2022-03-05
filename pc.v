// Program Counter register with write enable and address adder

`include "defines.v"

module PC (
    input                       clk, reset, en,
    input      [`ADDR_SIZE-1:0]	writeData,
    output reg [`ADDR_SIZE-1:0]	readData
);
    always @(posedge clk, posedge reset)
    if (reset)
        readData <= `ADDR_SIZE'h80000000;
    else if (en)
        readData <= writeData;
endmodule

module addrAdder (
    input  [`ADDR_SIZE-1:0] a, b,
    output [`ADDR_SIZE-1:0] result
);
    wire [`ADDR_SIZE-1:0] sum = a + b;
    assign result = {sum[`ADDR_SIZE-1:1], 1'b0};
endmodule

module PCSrcController (
    input       branch,
    input [2:0] branchType, // funct3
    input       jump,       // unconditional jump
    input       sltResult,  // SLT / SLTU result from ALU
    input       zeroFlag,

    output reg branchCtrl
);
    always @(*)
    if (jump)
        branchCtrl <= 1'b1;
    else if(branch)
    case (branchType)
        `FUNCT3_BEQ:
            branchCtrl <= zeroFlag;
        `FUNCT3_BNE:
            branchCtrl <= ~zeroFlag;
        `FUNCT3_BLT:
            branchCtrl <= sltResult;
        `FUNCT3_BGE:
            branchCtrl <= ~sltResult;
        `FUNCT3_BLTU:
            branchCtrl <= sltResult;
        `FUNCT3_BGEU:
            branchCtrl <= ~sltResult;
        default:
            branchCtrl <= 1'b0;
    endcase
    else
        branchCtrl <= 1'b0;
endmodule