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
    output reg [`WORD_LEN-1:0]  readData
);

    reg [7:0] RAM[`DMEM_SIZE-1:0];

    wire [`WORD_LEN-1:0] readWord = {RAM[addr + 3], RAM[addr + 2], RAM[addr + 1], RAM[addr]};

    // Read data
    always @(*)
    case (unitSize)
        `FUNCT3_BYTE:
            readData <= {{{`WORD_LEN-8}{readWord[7]}}, readWord[7:0]};
        `FUNCT3_HALF:
            readData <= {{{`WORD_LEN-16}{readWord[15]}}, readWord[15:0]};
        `FUNCT3_WORD:
            readData <= readWord;
        `FUNCT3_BYTE_UNSIGNED:
            readData <= {{{`WORD_LEN-8}{1'b0}}, readWord[7:0]};
        `FUNCT3_HALF_UNSIGNED:
            readData <= {{{`WORD_LEN-16}{1'b0}}, readWord[15:0]};
        default:
            readData <= readWord;
    endcase

    // Write data
    always @(posedge clk)
    if (writeEnable)
    begin
        case (unitSize)
            `FUNCT3_BYTE:
                RAM[addr] = writeData[7:0];
            `FUNCT3_HALF:
                {RAM[addr + 1], RAM[addr]} = writeData[15:0];
            `FUNCT3_WORD:
                {RAM[addr + 3], RAM[addr + 2], RAM[addr + 1], RAM[addr]} = writeData;
            default:
                RAM[addr] = writeData;
        endcase
        // DO NOT CHANGE THIS display LINE!!!
        // 不要修改下面这行display语句！！！
        /**********************************************************************/
        $display("dataaddr = %h, memdata = %h", {addr[31:2],2'b00}, {RAM[addr + 3], RAM[addr + 2], RAM[addr + 1], RAM[addr]});
        /**********************************************************************/
  	end
endmodule