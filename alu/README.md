# ALU verification framework (alu)

快速说明：

- RTL: [alu/rtl/alu.v](alu_2/rtl/alu.v)
- Testbench: [alu/tb/top_tb.sv](alu_2/tb/top_tb.sv), [alu_2/tb/dut.sv](alu_2/tb/dut.sv), [alu_2/tb/driver.sv](alu_2/tb/driver.sv)
- 列表: [alu/filelist.f](alu_2/filelist.f)
- Makefile: [alu/Makefile](alu_2/Makefile)

运行（需安装 Icarus Verilog）:

```sh
cd alu
make run
```

或手动:

```sh
iverilog -g2012 -o alu_tb.vvp $(cat filelist.f)
vvp alu_tb.vvp
```

该 ALU 支持的操作（至少 6 个）：ADD, SUB, AND, OR, XOR, SLL, SRL。
