// three ported register file
// read two ports combinationally
// write third port on falling edge of clock
// register 0 hardwired to 0

`include "defines.v"

module regfile(
    input                      	clk,
    input  [`REG_IDX_WIDTH-1:0] readAddr1, readAddr2,
    output [`WORD_LEN-1:0]      readData1, readData2,

    input                      	writeEnable,
    input  [`REG_IDX_WIDTH-1:0] writeAddr,
    input  [`WORD_LEN-1:0]      writeData
);

    reg [`WORD_LEN-1:0] registerFile[`RFREG_NUM-1:0];

    always @(negedge clk)
        if (writeEnable && writeAddr != 0)
        begin
            registerFile[writeAddr] <= writeData;
            // DO NOT CHANGE THIS display LINE!!!
            // 不要修改下面这行display语句！！！
            /**********************************************************************/
            $display("x%d = %h", writeAddr, writeData);
            /**********************************************************************/
        end

    assign readData1 = (readAddr1 != 0) ? registerFile[readAddr1] : 0;
    assign readData2 = (readAddr2 != 0) ? registerFile[readAddr2] : 0;
endmodule