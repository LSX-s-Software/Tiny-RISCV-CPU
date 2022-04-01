// memory IO bus

`include "defines.v"

`timescale 1ns / 1ps

module MIO_BUS(
    input mem_w,
    input [15:0]  sw_i,               // switch input
    input [31:0]  cpu_data_out,       // data from CPU
    input [31:0]  cpu_data_addr,      // address for CPU
    input [2:0]   cpu_data_amp,       // access pattern from CPU
    input [31:0]  ram_data_out,       // data from data memory

    output reg [31:0]  cpu_data_in,   // data to CPU
    output reg [31:0]  ram_data_in,   // data to data memory
    output reg [`ADDR_SIZE-1:0]   ram_addr,      // address for data memory
    output reg [31:0]  cpuseg7_data,  // cpu seg7 data (from sw instruction)
    output reg         ram_we,        // signal to write data memory
    output reg [2:0]   ram_amp,       // access pattern for data memory
    output reg         seg7_we        // signal to write seg7 display
);


//RAM & IO decode signals:
  always @(*) begin
    ram_addr = `ADDR_SIZE'h0;
    ram_data_in = 32'h0;
    cpuseg7_data = 32'h0;
    cpu_data_in = 32'h0;
    seg7_we = 0;
    ram_we = 0;
    ram_amp = 3'b0;

    case(cpu_data_addr[31:0])
      32'hffff0004: // switch
        cpu_data_in = {16'h0, sw_i};
      32'hffff000c: begin // seg7
        cpuseg7_data = cpu_data_out;
        seg7_we = mem_w;
      end
      default: begin
        ram_addr = cpu_data_addr;
        ram_data_in = cpu_data_out;
        ram_we = mem_w;
        ram_amp = cpu_data_amp;
        cpu_data_in = ram_data_out;
      end
    endcase
  end

endmodule