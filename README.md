# Tiny RISC-V CPU
> An implementation of RV32I ISA

## 描述

一个简单的 RV32I 指令集 CPU，带有冲突检测和前递功能，包含单周期和五阶段流水线的版本。

## 支持的指令

这个 CPU 支持的指令是 RV32I 的一个**真子集**

- 访存指令: sb, sh, sw, lb, lh, lw, lbu, lhu
- 整数运算指令: add, sub, xor, or, and, srl, sra, sll
- 逻辑指令: xori, ori, andi, srli, srai, slli
- 整数比较指令: slt, sltu, slti, sltiu
- 跳转指令: jal, jalr
- 分支指令: beq, bne, blt, bge, bltu, bgeu

## 运行方法

### 准备工作

根据实际情况修改 `defines.v` 文件的以下参数：

- `DEBUG`：启用调试模式（会在 ModelSim 或者 Vivado 的仿真控制台输出调试信息）
- `PIPELINING`：选择流水线版本
- `FPGA`：提供 Nexys4-DDR 支持
- `IMEM_SIZE` 和 `IMEM_SIZE_WIDTH`：指令内存的大小和地址位宽
- `DMEM_SIZE` 和 `DMEM_SIZE_WIDTH`：数据内存的大小和地址位宽

### ModelSim 仿真

1. 将项目根目录中所有.v文件导入到 ModelSim 中；

2. 注释 `defines.v` 文件中的 ``define FPGA`；

3. 将 `teshbench.v` 文件中的以下代码改为希望执行的 RISC-V 机器码程序文件（可从tests文件夹获取，需添加到 ModelSim 项目中）

   ```verilog
   $readmemh("riscv32_sim1.dat", cpu.imem.RAM);
   ```

4. 编译后即可选择顶层文件 `testbench` 进行仿真。

### FPGA

> 本仓库仅提供在 Nexys4-DDR 开发平台上运行的约束文件，如需使用其他开发平台，请根据开发平台提供商提供的文档进行修改。

1. 切换到 Nexys4DDR 分支；
2. 在 Vivado 中打开此项目；
3. 修改初始化 IMEM 的 coe 文件来更改希望运行的程序；
4. 依次执行综合、实现、生成比特流后即可下载到 Nexys4-DDR 开发平台。

本仓库默认的 coe 文件是一个冒泡排序程序，各个开关的含义和具体的使用方法请参考 tests/FPGA/riscv-studentnosorting.asm
