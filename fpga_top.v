`timescale 1ns / 1ps

`ifdef FPGA
// FPGA Top Level Module
module IP2SOC_Top(
    input         clk,
    input         rstn,
    input [15:0]  sw_i,
    output [7:0]  disp_seg_o, disp_an_o
);

    wire [`ADDR_SIZE-1:0] pc_IF;
    wire [`ADDR_SIZE-1:0] memAccessAddr;
    wire [`INSTR_SIZE-1:0] instr_IF;
    wire [`WORD_LEN-1:0] memWriteData, memReadData_MEM;
    wire [2:0] memAccessUnitSize;
    wire memRead_MEM, memWrite_MEM;

    wire          rst;
    assign rst = ~rstn;

    wire [31:0]   seg7_data;
    wire [6:0]    ram_addr;
    wire [3:0]    cpu_data_amp, ram_amp;
    wire          ram_we;
    wire          seg7_we;

    wire [31:0]   cpu_data_out;       // data from CPU
    wire [31:0]   ram_data_in, ram_data_out;
    wire [31:0]   cpu_data_in;
    wire [31:0]   cpuseg7_data;
    wire [31:0]   reg_data;

    // Clock speed switch
    CLK_DIV U_CLKDIV(
        .clk(clk),
        .rst(rst),
        .SW15(sw_i[15]),
        .Clk_CPU(clk_CPU)
    );

    // instruction memory
    imem U_IM(
        .a(pc_IF[8:2]),
        .spo(instr_IF)
    );

    // data memory bus
    MIO_BUS U_MIO (
        .mem_w(memWrite_MEM),
        .sw_i(sw_i),
        .cpu_data_out(memWriteData),
        .cpu_data_addr(memAccessAddr),
        .cpu_data_amp(memAccessUnitSize),
        .ram_data_out(ram_data_out),
        .cpu_data_in(memReadData_MEM),
        .ram_data_in(ram_data_in),
        .ram_addr(ram_addr),
        .cpuseg7_data(cpuseg7_data),
        .ram_we(ram_we),
        .ram_amp(ram_amp),
        .seg7_we(seg7_we)
    );

    // data memory
    DMem dmem(
        .clk(clk_CPU),
        .readEnable(memRead_MEM),
        .writeEnable(ram_we),
        .addr(ram_addr),
        .unitSize(ram_amp),
        .writeData(ram_data_in),
        .readData(ram_data_out)
    );

    CPUCore cpuCore(
        .clk(clk_CPU),
        .rst(rst),
        .pc_IF(pc_IF),
        .instr_IF(instr_IF),
        .memRead_MEM(memRead_MEM),
        .memWrite_MEM(memWrite_MEM),
        .memAccessAddr(memAccessAddr),
        .memAccessUnitSize(memAccessUnitSize),
        .memWriteData(memWriteData),
        .memReadData_MEM(memReadData_MEM),
        .readAddr3(sw_i[4:0]),
        .readData3(reg_data)
    );

    // segment 7 display content mux
    MULTI_CH32 U_Multi(
        .clk(clk),
        .rst(rst),
        .EN(seg7_we),                // write enable
        .ctrl(sw_i[5:0]),            // switch 5~0
        .data0(cpuseg7_data),
        // display CPU data
        .data1({2'b0, pc_IF[31:2]}),
        .data2(pc_IF),
        .data3(instr_IF),
        .data4(memAccessAddr),
        .data5(memWriteData),
        .data6(ram_data_out),
        .data7({ram_addr, 2'b00}),
        .reg_data(reg_data),
        .seg7_data(seg7_data)
    );

    SEG7x16 U_7SEG(
        .clk(clk),
        .rst(rst),
        .cs(1'b1),
        .i_data(seg7_data),
        .o_seg(disp_seg_o),
        .o_sel(disp_an_o)
    );
endmodule
`endif