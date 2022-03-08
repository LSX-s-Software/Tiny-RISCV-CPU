// IMEM & DMEM

`include "defines.v"

module IMem(
    input  [`ADDR_SIZE-1:0]   addr,
    output [`INSTR_SIZE-1:0]  data
);
    reg [`INSTR_SIZE-1:0] RAM[`IMEM_SIZE-1:0];

    assign data = RAM[addr[11:2]]; // instruction size aligned
endmodule


module DMem(
    input                   clk, writeEnable,
    input  [`ADDR_SIZE-1:0] addr,
    input  [2:0]            unitSize,
    input  [`WORD_LEN-1:0]  writeData,
    output reg [`WORD_LEN-1:0]  readData,
    input [`ADDR_SIZE-1:0] pc_MEM
);
    reg [`WORD_LEN-1:0] RAM[`DMEM_SIZE-1:0];

    // word aligned data
    wire [`ADDR_SIZE-3:0] realAccessAddr = addr[`ADDR_SIZE-1:2];
    wire [`WORD_LEN-1:0] readWord = RAM[realAccessAddr];
    wire [1:0] wordOffset = addr[1:0];

    // split data
    always @(*)
    case (unitSize)
        `FUNCT3_BYTE:
            case (wordOffset)
                2'b00: readData <= {{{`WORD_LEN-8}{readWord[7]}}, readWord[7:0]};
                2'b01: readData <= {{{`WORD_LEN-8}{readWord[15]}}, readWord[15:8]};
                2'b10: readData <= {{{`WORD_LEN-8}{readWord[23]}}, readWord[23:16]};
                2'b11: readData <= {{{`WORD_LEN-8}{readWord[31]}}, readWord[31:24]};
                default: readData <= {{{`WORD_LEN-8}{readWord[7]}}, readWord[7:0]};
            endcase
        `FUNCT3_HALF:
            case (wordOffset)
                2'b00: readData <= {{{`WORD_LEN-16}{readWord[15]}}, readWord[15:0]};
                2'b10: readData <= {{{`WORD_LEN-16}{readWord[31]}}, readWord[31:16]};
                default: readData <= {{{`WORD_LEN-16}{readWord[15]}}, readWord[15:0]};
            endcase
        `FUNCT3_WORD:
            readData <= readWord;
        `FUNCT3_BYTE_UNSIGNED:
            case (wordOffset)
                2'b00: readData <= {{{`WORD_LEN-8}{1'b0}}, readWord[7:0]};
                2'b01: readData <= {{{`WORD_LEN-8}{1'b0}}, readWord[15:8]};
                2'b10: readData <= {{{`WORD_LEN-8}{1'b0}}, readWord[23:16]};
                2'b11: readData <= {{{`WORD_LEN-8}{1'b0}}, readWord[31:24]};
                default: readData <= {{{`WORD_LEN-8}{1'b0}}, readWord[7:0]};
            endcase
        `FUNCT3_HALF_UNSIGNED:
            case (wordOffset)
                2'b00: readData <= {{{`WORD_LEN-16}{1'b0}}, readWord[15:0]};
                2'b10: readData <= {{{`WORD_LEN-16}{1'b0}}, readWord[31:16]};
                default: readData <= {{{`WORD_LEN-16}{1'b0}}, readWord[15:0]};
            endcase
        default:
            readData <= readWord;
    endcase

    // Write data
    always @(posedge clk)
    if (writeEnable)
    begin
        case (unitSize)
            `FUNCT3_BYTE:
                case (wordOffset)
                    2'b00: RAM[realAccessAddr][7:0] <= writeData[7:0];
                    2'b01: RAM[realAccessAddr][15:8] <= writeData[7:0];
                    2'b10: RAM[realAccessAddr][23:16] <= writeData[7:0];
                    2'b11: RAM[realAccessAddr][31:24] <= writeData[7:0];
                    default: RAM[realAccessAddr][7:0] <= writeData[7:0];
                endcase
            `FUNCT3_HALF:
                case (wordOffset)
                    2'b00: RAM[realAccessAddr][15:0] <= writeData[15:0];
                    2'b10: RAM[realAccessAddr][31:16] <= writeData[15:0];
                    default: RAM[realAccessAddr][15:0] <= writeData[15:0];
                endcase
            `FUNCT3_WORD:
                RAM[realAccessAddr] <= writeData;
            default:
                RAM[realAccessAddr] <= writeData;
        endcase
        $display("pc = %h: dataaddr = %h, memdata = %h", pc_MEM, {realAccessAddr, 2'b00}, RAM[realAccessAddr]);
  	end
endmodule