// imm gen and shift left module

`include "defines.v"

module imm (
    input [11:0] iimm, //instr[31:20], 12 bits
    input [11:0] simm, //instr[31:25, 11:7], 12 bits
    input [11:0] bimm, //instrD[31], instrD[7], instrD[30:25], instrD[11:8], 12 bits
    input [19:0] uimm,
    input [19:0] jimm,
    input [4:0]  immctrl,

    output reg [`WORD_LEN-1:0]  immout
);
    always @(*)
    case (immctrl)
        `IMM_CTRL_ITYPE: immout <= {{{`WORD_LEN-12}{iimm[11]}}, iimm[11:0]};
        `IMM_CTRL_UTYPE: immout <= {uimm[19:0], 12'b0};
        default:         immout <= `WORD_LEN'b0;
    endcase
endmodule

// shift left by 1 for address calculation
module sl1(
    input  [`ADDR_SIZE-1:0] in,
    output [`ADDR_SIZE-1:0] out
);

  assign out = {in[`ADDR_SIZE-2:0], 1'b0};
endmodule