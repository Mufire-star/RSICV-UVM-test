# PORTING NOTES — uvm_e203 测试环境迁移指南

简短说明
---
本文件记录将 `uvm_e203` 测试环境迁移到其它目录或机器时需要检查和修改的关键路径与注意事项，包含常见故障排查与示例命令，便于上传到 GitHub 作为项目迁移文档。

目录
---
- [关键文件与路径](#关键文件与路径)
- [仿真与平台差异](#仿真与平台差异)
- [E203 相关注意事项](#e203-相关注意事项)
- [故障排查快速指南](#故障排查快速指南)
- [最小迁移步骤示例](#最小迁移步骤示例)

关键文件与路径
---
请在迁移后逐项确认并根据目标环境修改：

- `uvm_e203/Makefile`
  - `VCS_BIN`：指向本机的 VCS 可执行文件（不同主机需修改）。
  - `VCS_OPTS`：包含 `+incdir+...` 的 include 目录应使用相对于 `uvm_e203` 的正确路径，必要时改为绝对路径。
  - 可在 Makefile 中通过 `-top <module>` 指定顶层模块，避免仓库中存在多个同名顶层引发冲突。

- `uvm_e203/filelist.f`
  - 列表中每行路径应可从运行目录（通常是 `uvm_e203`）访问。常见条目：`tb/*.sv`、`../rtl_pipeline/ALU.v`、`../e203_hbirdv2/...`。
  - 迁移时确认被引用的 RTL 与库文件存在或改为绝对路径。

- TB 源（`uvm_e203/tb`）
  - `top_tb.sv`：检查 `include` 指令（例如 `../rtl_pipeline/includes/ctrl_signal_def.v`），或改用 Makefile 的 `+incdir`。
  - 如果修改了顶层模块名（如 `top_tb_e203`），确保 Makefile 的 `-top` 与 `$dumpvars`（波形导出）一致。

- DUT 与 RTL
  - DUT wrapper：`uvm_e203/tb/dut.sv`；DUT 实际实现通常在 `rtl_pipeline/ALU.v`。
  - `ALU.v` 内部使用 `include "ctrl_signal_def.v"`，因此需要正确设置 include 路径。

- 第三方库（例如 `e203_hbirdv2`）
  - 若库位置变化，更新 `filelist.f` 与 Makefile 的 `+incdir`。若不需要 E203 比对，可临时移除这些条目以简化调试。

仿真与平台差异
---
- 路径分隔：在 Verilog `include` 与 filelist 中统一使用正斜杠 `/`，避免 Windows 反斜杠 `\` 导致的问题。 
- VCS 可执行与许可：确认目标机器上可以执行 `vcs`，并且许可可用。
- 文件编码/行尾：保持 UTF-8、无 BOM，并尽量统一 LF（或根据 CI 要求使用 CRLF）。

E203 相关注意事项（避免 X 传播）
---
- E203 的 ALU datapath 比简单 ALU 有更多控制与共享缓冲接口（BJP/AGU/MULDIV 等）。若这些输入未被驱动（或在 reset 后未初始化），会产生未知值（X）并传播到 `alu_req_alu_res`。
- 迁移时务必在 TB 中对这些端口做明确 tie-off（例如 `1'b0`、`32'b0` 或带宽匹配的 sized 0）。
- 推荐调试流程：先只编译 DUT + TB（从 `filelist.f` 临时移除 E203 条目），确认 DUT/TB 正常；然后逐步加入 E203 源并调整 tie-off。

故障排查快速指南
---
1. 编译错误：检查 `filelist.f` 中路径是否可读，Makefile 中 `+incdir` 是否正确。
2. 重复顶层模块（module previously declared）：检查仓库是否存在其他 `top_tb`，解决方法：
   - 在 Makefile 用 `-top <module>` 指定唯一顶层，或
   - 移除不需要的 TB 文件（或改名）。
3. 未初始化 / X 值：TB 中保持 `X-DETECT` 打印（或增加波形信号），观察 `a,b,op,y,alu_req_alu_res,rst_n`。使用 `+lint=TFIPC-L` 获取未连接端口详细信息。
4. Verdi/Elaboration log：若使用 Verdi，查看 `run/simv.daidir/elabcomLog/compiler.log` 获取 elaboration 错误详情。

最小迁移步骤示例
---
1. 将 `uvm_e203` 整个目录复制到目标位置。
2. 检查并根据需要修改 `uvm_e203/Makefile`：`VCS_BIN`、`+incdir`、`-top`。
3. 进入目标目录并运行：

```bash
cd uvm_e203
make clean
make run
```

4. 若编译失败：逐行检查 `filelist.f` 中列出的文件路径，确保所有文件存在并可访问。
5. 若运行出现 X 或功能异常：将 `NUM_TESTS` 缩短为 20，启用 TB 的 `X-DETECT` 输出以定位问题。

附：常用命令与建议
---
- 快速测试（短用例）：

```bash
cd uvm_e203
sed -i 's/NUM_TESTS = 10000/NUM_TESTS = 20/' tb/top_tb.sv
make clean && make run
```

- 恢复完整回归后再提交到 CI：

```bash
git add .
git commit -m "Update porting notes and testbench tweaks"
git push
```

是否删除 `alu_ref.sv`？
---
如果决定只用 E203 作为参考，可以删除 `uvm_e203/tb/alu_ref.sv`（已在仓库修改历史中删除过一次）。建议先在版本控制中保留一份备份（或在合并分支前删除），以便回退。

我可以为你做的额外工作
---
- 将 `filelist.f` 与 Makefile 中的相对路径自动换成绝对路径（按你提供目标主机绝对路径）。
- 生成一个小脚本来在目标机器上自动修改 `VCS_BIN` 与 `+incdir` 并运行一次编译/仿真。

---
如需我自动生成迁移脚本或把这份文档再美化成仓库根目录 README（并添加徽章/运行示例），告诉我目标路径与偏好，我来处理。

