// Forwarding unit
// MEM -> WB, WB -> EX, WB -> MEM

`include "defines.v"

module ForwardingUnit (
    input regWrite_MEM, regWrite_WB, memWrite_MEM,
    input [`REG_IDX_WIDTH-1:0] readAddr1_EX, readAddr2_EX, readAddr2_MEM,
    input [`REG_IDX_WIDTH-1:0] writeAddr_MEM, writeAddr_WB,

    output reg [1:0] forwardA, forwardB,
    output forwardMEM
);
    // forward to ALU
    wire MEM2ALU_A = regWrite_MEM && writeAddr_MEM != `REG_IDX_WIDTH'b0 && readAddr1_EX == writeAddr_MEM;
    wire WB2ALU_A = regWrite_WB && writeAddr_WB != `REG_IDX_WIDTH'b0 && readAddr1_EX == writeAddr_WB;
    wire MEM2ALU_B = regWrite_MEM && writeAddr_MEM != `REG_IDX_WIDTH'b0 && readAddr2_EX == writeAddr_MEM;
    wire WB2ALU_B = regWrite_WB && writeAddr_WB != `REG_IDX_WIDTH'b0 && readAddr2_EX == writeAddr_WB;
    // forward to MEM
    assign forwardMEM = regWrite_WB && writeAddr_WB != `REG_IDX_WIDTH'b0 && memWrite_MEM && readAddr2_MEM == writeAddr_WB;

    always @(*) begin
        // ALUSrcA forwarding
        if (MEM2ALU_A)
            forwardA <= 2'b01;
        else if (WB2ALU_A)
            forwardA <= 2'b10;
        else
            forwardA <= 2'b00;

        // ALUSrcB forwarding
        if (MEM2ALU_B)
            forwardB <= 2'b01;
        else if (WB2ALU_B)
            forwardB <= 2'b10;
        else
            forwardB <= 2'b00;
    end
endmodule

module ALUForwardMux (
    input [`WORD_LEN-1:0] data_ID,  // data from ID stage
    input [`WORD_LEN-1:0] data_MEM, // data from EX stage
    input [`WORD_LEN-1:0] data_WB,  // data from WB stage
    input [1:0] forwardSrc,         // forwarding source

    output reg [`WORD_LEN-1:0] out
);
    always @(*) begin
        case (forwardSrc)
            2'b00: out <= data_ID;
            2'b01: out <= data_MEM;
            2'b10: out <= data_WB;
        endcase
    end
endmodule

module MEMForwardMux (
    input [`WORD_LEN-1:0] data_EX,  // data from EX stage
    input [`WORD_LEN-1:0] data_WB,  // data from WB stage
    input forwardSrc,               // forwarding source

    output [`WORD_LEN-1:0] out
);
    assign out = (forwardSrc == 0) ? data_EX : data_WB;
endmodule