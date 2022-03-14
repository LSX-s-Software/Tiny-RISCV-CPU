// testbench for simulation

`include "defines.v"

module testbench();
    reg clk, rstn;

    // instantiation of the CPU
    CPU cpu(clk, rstn);

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
`ifdef DEBUG
            counter = counter + 1;
            $display("clock: %d", counter);
`ifdef PIPELINING
            $display("stage: IF      ID      EX      MEM      WB");
            $display("PC:\t %h %h %h %h %h", cpu.pc_IF, cpu.pc_ID, cpu.pc_EX, cpu.pc_MEM, cpu.pc_WB);
            $display("instr: %h %h", cpu.instr_IF, cpu.instr_ID);
`else
            $display("PC:\t\t%h", cpu.pc);
            $display("instr:\t%h", cpu.instr);
`endif
`endif
`ifdef PIPELINING
            if (cpu.pc_WB == 32'h00000078) // set to the address of the last instruction
            begin
                $display("pc_WB:\t%h", cpu.pc_WB);
                //$finish;
                $stop;
            end
`else
            if (cpu.pc == 32'h00000078) // set to the address of the last instruction
            begin
                $display("pc:\t%h", cpu.pc);
                //$finish;
                $stop;
            end
`endif
        end
    end //end always
endmodule
