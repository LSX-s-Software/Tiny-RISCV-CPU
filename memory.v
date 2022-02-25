// IMEM & DMEM

`include "defines.v"

module imem(
input  [`ADDR_SIZE-1:0]   a,
output [`INSTR_SIZE-1:0]  rd
);

    reg [`INSTR_SIZE-1:0] RAM[`IMEM_SIZE-1:0];

    initial
    begin
        $readmemh("riscv32_sim1.dat", RAM);
    end

    assign rd = RAM[a[11:2]]; // instruction size aligned
endmodule


module dmem(
input           	clk, we,
input  [`XLEN-1:0]  a, wd,
output [`XLEN-1:0]  rd
);

    reg  [31:0] RAM[1023:0];

    assign rd = RAM[a[11:2]]; // word aligned

    always @(posedge clk)
    if (we)
    begin
        RAM[a[11:2]] <= wd;   // store word
        // DO NOT CHANGE THIS display LINE!!!
        // 不要修改下面这行display语句！！！
        /**********************************************************************/
        $display("dataaddr = %h, memdata = %h", {a[31:2],2'b00}, RAM[a[11:2]]);
        /**********************************************************************/
  	end
endmodule