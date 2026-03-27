# RISC ALU 验证工程

本工程用于验证自研 ALU 模块（基于“第十届集创赛/叩持赛题”），包含 RTL 实现、轻量级测试平台与与 E203 校验的对接示例。

目录结构（概要）
```
rtl_pipeline/        # 被测设计（ALU 等 RTL）
sim_pipeline/        # 仿真相关文件列表与脚本
tb_pipeline/         # 顶层 testbench 示例
uvm_alu_e203/            # UVM 风格的测试环境（含与 e203 对接的示例）
e203_hbirdv2/        # 蜂鸟 E203 核心源码（第三方库，用于对比检验）
```

主要组件说明
- `rtl_pipeline/ALU.v`：32-bit ALU 的 RTL 实现。
- `uvm_alu_e203/`：验证目录，包含 testbench、`filelist.f` 与用于运行 VCS 的 `Makefile`。
    - `uvm_alu_e203/tb/top_tb.sv`：顶层测试文件，驱动 DUT 并可选地实例化 E203 datapath 做交叉比对。
    - `uvm_alu_e203/filelist.f`：仿真文件列表，列出 TB、DUT 与可选的 E203 源。
 - `UVM` / `uvm_alu_tb` / `uvm_alu`：仓库中存在多个以 UVM 命名的测试目录，主要用途如下：
     - `UVM`（若存在）：简易 UVM 测试框架。
     - `uvm_alu_tb`：轻量级 SystemVerilog 测试顶层，用于快速功能回归，直接驱动 `a,b,ALUOp` 并比较 DUT 输出与参考值（行为模型或 E203）。
     - `uvm_alu_e203`：基于上述轻量 TB，额外并行实例化 `e203_exu_alu_dpath`，将 E203 的输出 `y_e203` 与 DUT 的 `y` 做交叉比对以发现差异。

快速开始（本地使用 VCS）
1. 进入 `uvm_alu_e203` 目录：

```bash
cd uvm_alu_e203
```

2. （可选）编辑 `Makefile`：将 `VCS_BIN` 指向本机的 VCS 可执行文件，确认 `+incdir` 路径正确。

3. 运行仿真（短用例）：

```bash
# 快速验证：把 NUM_TESTS 调小以便快速反馈
make clean
make run
```

核心测试说明
- TB 会驱动 `a`, `b`, `op` 并比较 DUT 输出 `y` 与期望值。
- 当启用 E203 对比时（`filelist.f` 中包含 `e203_hbirdv2` 的源码），TB 还会把相同输入喂给 `e203_exu_alu_dpath`，并比较其输出 `alu_req_alu_res`（在 TB 中记为 `y_e203`）。

常见问题与注意事项
- 路径与 include：Makefile 假定相对路径基于 `uvm_e203` 目录；迁移到其他位置请先检查 `filelist.f` 与 `+incdir`。
- 顶层冲突：仓库可能含有多个 `top_tb`，若出现 `module previously declared`，可在 Makefile 中用 `-top <module>` 指定，或从 `filelist.f` 中移除不需要的 TB。
- E203 未驱动端口会产生 X 值：E203 datapath 有许多控制/共享缓冲端口，若未 tie-off，会把 X 传播到 `y_e203`。在 TB 中请对这些端口显式 tie-off（例如 `1'b0` 或 `32'b0`）。
- VCS & 许可：目标主机需安装 VCS 并有有效许可。

迁移建议
- 先单独验证 DUT + TB（临时从 `filelist.f` 中移除 E203 源），确认 DUT/TB 正常后再加入 E203 相关源码进行比对。
- 在迁移到新机器时，把 `VCS_BIN` 与 `+incdir` 更新为目标机器上的路径，优先使用绝对路径以避免相对路径混淆。


