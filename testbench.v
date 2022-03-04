// testbench for simulation

`include "defines.v"

module testbench();
    reg  clk, rstn;
    wire [`ADDR_SIZE-1:0] pcW;

    // instantiation of the CPU
    CPU cpu(clk, rstn, pcW);

    integer counter = 0;

    initial begin
        $readmemh("riscv32_sim2.dat", cpu.imem.RAM);
        clk = 1;
        rstn = 1;
        #5 ;
        rstn = 0;
    end

    always begin
        #(50) clk = ~clk;

        if (clk == 1'b1)
        begin
            counter = counter + 1;
            // comment these three lines for online judge
            $display("clock: %d", counter);
            $display("pc:\t\t%h", pcW);
            $display("instr:\t%h", cpu.instr);
        end
    end //end always
endmodule
