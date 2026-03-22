# ALU verification framework (alu_2)

快速说明：

- RTL: [alu_2/rtl/alu.v](alu_2/rtl/alu.v)
- Testbench: [alu_2/tb/top_tb.sv](alu_2/tb/top_tb.sv), [alu_2/tb/dut.sv](alu_2/tb/dut.sv), [alu_2/tb/driver.sv](alu_2/tb/driver.sv)
- 列表: [alu_2/filelist.f](alu_2/filelist.f)
- Makefile: [alu_2/Makefile](alu_2/Makefile)

运行（需安装 Icarus Verilog）:

```sh
cd alu_2
make run
```

或手动:

```sh
iverilog -g2012 -o alu_tb.vvp $(cat filelist.f)
vvp alu_tb.vvp
```

该 ALU 支持的操作（至少 6 个）：ADD, SUB, AND, OR, XOR, SLL, SRL。
