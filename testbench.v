// testbench for simulation

`include "defines.v"

module testbench();
    reg  clk, rstn;
    wire [`ADDR_SIZE-1:0] pc_IF;

    // instantiation of the CPU
    CPU cpu(clk, rstn, pc_IF);

    integer counter = 0;

    initial begin
        $readmemh("riscv32_sim1.dat", cpu.imem.RAM);
        clk = 1;
        rstn = 1;
        #5;
        rstn = 0;
    end

    always begin
        #(50) clk = ~clk;

        if (clk == 1'b1)
        begin
            counter = counter + 1;
            $display("clock: %d", counter);
            $display("pc_IF:\t%h", pc_IF);
            $display("instr_IF:\t%h", cpu.instr_IF);
            if (cpu.pc_WB == 32'h80000078) // set to the address of the last instruction
            begin
                //$display("pc_IF:\t\t%h", pc_IF);
                //$finish;
                $stop;
            end
        end
    end //end always
endmodule
