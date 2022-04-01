// Program Counter register with write enable and address adder

`include "defines.v"

module PC (
    input                       clk, reset, en,
    input      [`ADDR_SIZE-1:0]	writeData,
    output reg [`ADDR_SIZE-1:0]	readData
);
    always @(posedge clk, posedge reset)
    if (reset)
        readData <= `ADDR_SIZE'h00000000;
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
    input       isBranchOp,
    input [2:0] branchType, // funct3
    input       isJumpOp,   // unconditional jump
    input [`WORD_LEN-1:0] rs1, rs2,  // register data

    output reg branchCtrl
);
    wire equal = (rs1 == rs2);
    wire lessThan = ($signed(rs1) < $signed(rs2));
    wire lessThanUnsigned = (rs1 < rs2);

    always @(*)
    if (isJumpOp)
        branchCtrl <= 1'b1;
    else if (isBranchOp)
        case (branchType)
            `FUNCT3_BEQ:
                branchCtrl <= equal;
            `FUNCT3_BNE:
                branchCtrl <= ~equal;
            `FUNCT3_BLT:
                branchCtrl <= lessThan;
            `FUNCT3_BGE:
                branchCtrl <= ~lessThan;
            `FUNCT3_BLTU:
                branchCtrl <= lessThanUnsigned;
            `FUNCT3_BGEU:
                branchCtrl <= ~lessThanUnsigned;
            default:
                branchCtrl <= 1'b0;
        endcase
    else
        branchCtrl <= 1'b0;
endmodule