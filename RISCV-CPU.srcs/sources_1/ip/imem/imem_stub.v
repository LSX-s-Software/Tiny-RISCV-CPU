// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Thu Mar 24 16:31:35 2022
// Host        : 393A running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/linsixing/Documents/Vivado/RISCV-CPU/RISCV-CPU.srcs/sources_1/ip/imem/imem_stub.v
// Design      : imem
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "dist_mem_gen_v8_0_13,Vivado 2019.2" *)
module imem(a, spo)
/* synthesis syn_black_box black_box_pad_pin="a[6:0],spo[31:0]" */;
  input [6:0]a;
  output [31:0]spo;
endmodule
