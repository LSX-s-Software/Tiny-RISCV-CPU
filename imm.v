// imm gen and shift left module

`include "defines.v"

module ImmGen (
    input [`INSTR_SIZE-1:0] instr,
    input [4:0]  immctrl,

    output reg [`WORD_LEN-1:0]  immout
);
    wire [11:0] iimm = instr[31:20];                // I-type immediate
    wire [11:0] simm = {instr[31:25], instr[11:7]}; // S-type immediate
    wire [11:0] bimm = {instr[31], instr[7], instr[30:25], instr[11:8]};    // B-type immediate
    wire [19:0] uimm = instr[31:12];                // U-type immediate
    wire [19:0] jimm = {instr[31], instr[19:12], instr[20], instr[30:21]};  // J-type immediate

    always @(*)
    case (immctrl)
        `IMM_CTRL_ITYPE:
            immout <= {{{`WORD_LEN-12}{iimm[11]}}, iimm[11:0]};
        `IMM_CTRL_STYPE:
            immout <= {{{`WORD_LEN-12}{simm[11]}}, simm[11:0]};
        `IMM_CTRL_BTYPE:
            immout <= {{{`WORD_LEN-13}{bimm[11]}}, bimm[11:0], 1'b0};
        `IMM_CTRL_UTYPE:
            immout <= {{{`WORD_LEN-32}{uimm[19]}}, uimm[19:0], 12'b0};
        `IMM_CTRL_JTYPE:
            immout <= {{{`WORD_LEN-21}{jimm[19]}}, jimm[19:0], 1'b0};
        default:
            immout <= `WORD_LEN'b0;
    endcase
endmodule

// shift left by 1 for address calculation
module SL1(
    input  [`ADDR_SIZE-1:0] in,
    output [`ADDR_SIZE-1:0] out
);

  assign out = {in[`ADDR_SIZE-2:0], 1'b0};
endmodule