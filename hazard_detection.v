// Hazard detection unit

`include "defines.v"

module HazardDetectionUnit (
    input memRead_EX, memWrite_ID, branchOrJump_ID, regWrite_EX,
    input [`REG_IDX_WIDTH-1:0] readAddr1_ID, readAddr2_ID, writeAddr_EX,

    output PCEn, IFIDEn, IDEXFlush
);
    assign IDEXFlush = ((branchOrJump_ID || memRead_EX && !memWrite_ID) && regWrite_EX && (readAddr1_ID == writeAddr_EX || readAddr2_ID == writeAddr_EX));
    assign IFIDEn = ~IDEXFlush;
    assign PCEn = ~IDEXFlush;
endmodule