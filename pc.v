// Program Counter register with write enable and address adder

`include "defines.v"

module PC (
    input                       clk, reset,
    input                       en,
    input      [`WORD_LEN-1:0]	writeData,
    output reg [`WORD_LEN-1:0]	readData
);
    always @(posedge clk, posedge reset)
    if (reset)
        readData <= `ADDR_SIZE'h80000000;
    else if (en)
        readData <= writeData;
endmodule

// PC + 4
module addr_adder1 (
    input  [`ADDR_SIZE-1:0] a,
    output [`ADDR_SIZE-1:0] result
);
    assign result = a + 4;
endmodule

// PC + imm << 1
module addr_adder2 (
    input  [`ADDR_SIZE-1:0] a, b,
    output [`ADDR_SIZE-1:0] result
);
    wire [`ADDR_SIZE-1:0] sum = a + b;
    assign result = {sum[`ADDR_SIZE-1:1], 1'b0};
endmodule

module PCSrcController (
    input branch,
    input branchType,
    input jump, // unconditional jump
    input zeroFlag,
    input ltFlag,
    input geFlag,

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
            branchCtrl <= ltFlag;
        `FUNCT3_BGE:
            branchCtrl <= geFlag;
        `FUNCT3_BLTU:
            branchCtrl <= ltFlag;
        `FUNCT3_BGEU:
            branchCtrl <= geFlag;
        default:
            branchCtrl <= 1'b0;
    endcase
endmodule