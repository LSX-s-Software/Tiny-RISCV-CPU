// testbench for simulation

`include "defines.v"

module testbench();
    reg clk, rstn;
    
    wire [7:0] dummy1, dummy2;

    // instantiation of the CPU
    IP2SOC_Top cpu(clk, ~rstn, 16'b0, dummy1, dummy2);

    integer counter = 0;

    initial begin
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
            $display("PC:\t %h %h %h %h %h", cpu.cpuCore.pc_IF, cpu.cpuCore.pc_ID, cpu.cpuCore.pc_EX, cpu.cpuCore.pc_MEM, cpu.cpuCore.pc_WB);
            $display("instr: %h %h", cpu.cpuCore.instr_IF, cpu.cpuCore.instr_ID);
`else
            $display("PC:\t\t%h", cpu.pc);
            $display("instr:\t%h", cpu.instr);
`endif
`endif
`ifdef PIPELINING
            if (cpu.cpuCore.pc_WB == 32'h000000ac) // set to the address of the last instruction
            begin
                $display("pc_WB:\t%h", cpu.cpuCore.pc_WB);
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
