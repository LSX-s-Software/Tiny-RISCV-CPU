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
    input  [`WORD_LEN-1:0]  writeData,
    output [`WORD_LEN-1:0]  readData
);

    reg  [31:0] RAM[1023:0];

    assign readData = RAM[addr[11:2]]; // word aligned

    always @(posedge clk)
    if (writeEnable)
    begin
        RAM[addr[11:2]] <= writeData;   // store word
        // DO NOT CHANGE THIS display LINE!!!
        // 不要修改下面这行display语句！！！
        /**********************************************************************/
        $display("dataaddr = %h, memdata = %h", {addr[31:2],2'b00}, RAM[addr[11:2]]);
        /**********************************************************************/
  	end
endmodule