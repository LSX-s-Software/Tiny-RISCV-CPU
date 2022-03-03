// Program Counter register with write enable and address adder

`include "defines.v"

module pc (
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
    assign result = a + b;
endmodule