# rtl_pipeline 说明文档

## 1. 这个目录是什么

`rtl_pipeline/` 是当前工程里一套**独立于原始 `rtl/` 目录**的新实现。

它的目标不是修改旧版 CPU，而是单独建立一套更适合后续综合、面积优化和结构演进的 RTL 原型。  
当前这版采用的是**面向真实 memory macro 的简化三级流水线**思路，而不是传统教材里常见的五级流水线。

这样做有两个原因：

1. 原始 `rtl/` 目录更像“多周期 / 教学实验风格”的骨架。
2. 对你当前这组指令和后续 PPA 优化目标来说，先做一套更紧凑、更容易综合分析的实现更合适。

这个目录目前主要服务于三件事：

- 功能验证
- 后续面积优化
- 为综合 / STA / 布局布线预留更清晰的结构

---

## 2. 当前支持什么指令

这套 `rtl_pipeline` 当前只面向下面这组 RISC-V 指令子集：

- `add`
- `sub`
- `and`
- `or`
- `sll`
- `srl`
- `ori`
- `addi`
- `lw`
- `sw`
- `beq`
- `bne`
- `jal`
- `jalr`

这意味着它不是完整的 `RV32I`。

当前**没有实现**的内容包括但不限于：

- `xor`
- `sra`
- `slt/sltu`
- `auipc/lui`
- 异常 / 中断
- CSR
- 乘除法
- 分支预测
- cache
- 更复杂的多级 hazard / forwarding 网络

---

## 3. 目录结构概览

`rtl_pipeline/` 中的文件可以分成 5 类：

### 3.1 顶层与数据通路模块

- `riscv_pipeline.v`
- `PC.v`
- `IF_ID.v`
- `RF.v`
- `ALU.v`
- `ImmGen.v`
- `IM.v`
- `DM.v`

### 3.2 控制模块

- `Decoder.v`

### 3.3 存储与技术实现相关模块

- `IM.v`
- `DM.v`
- `IM_TECH.v`
- `DM_TECH.v`
- `RF_TECH.v`

### 3.4 公共头文件

- `includes/global_def.v`
- `includes/instruction_def.v`
- `includes/ctrl_signal_def.v`

### 3.5 设计说明与规划文件

- `TODO.md`
- `README.md`

---

## 4. 这套 CPU 的总体结构

当前顶层是 [riscv_pipeline.v](./riscv_pipeline.v)。

你可以把它理解成一个简化的三级结构：

### 第一级：取指级 IF

包括：

- `PC`
- 指令存储器 `IM`
- 取到的指令寄存到 `IF_ID`

这一级负责：

- 产生当前指令地址
- 从指令存储器取出指令
- 把取到的 `PC / PC+4 / 指令` 暂存下来

### 第二级：执行级 EX

包括：

- `Decoder`
- `RF`
- `ImmGen`
- `ALU`
- `DM`
- 访存请求
- 分支 / 跳转目标计算

这一级负责：

- 指令译码
- 寄存器读取
- 立即数生成
- 算术逻辑运算
- 向数据存储器发出访问请求
- 决定是否跳转 / 分支

### 第三级：写回级 WB

包括：

- `WB` 级寄存器
- `DM` 的同步读出结果
- 写回选择逻辑
- 写回到执行级的前递数据

这一级负责：

- 保存上一拍执行结果
- 接收 `lw` 的同步读数据
- 统一形成写回数据
- 向执行级提供 `WB -> EX` 前递

### 控制转移处理

如果执行级判断：

- `beq` 成立
- `bne` 成立
- `jal`
- `jalr`

那么会：

- 修改 `PC`
- 清空 `IF_ID`

也就是说，当前采用的是一种非常直接的 `flush` 方式。对跳转成立的分支和 `jal/jalr`，会冲掉一条已经取到但不应执行的指令。

### 4.1 模块连接示意图

下面这张图只画核心连接关系，省略部分次要控制信号，目的是帮助你先建立整体印象：

```text
                +------------------+
                |        PC        |
                |     程序计数器    |
                +---------+--------+
                          |
                          v
                +------------------+
                |        IM        |
                |    指令存储器     |
                +---------+--------+
                          |
                          v
                +------------------+
                |      IF_ID       |
                |   取指级流水寄存   |
                +----+--------+----+
                     |        |
                     |        +-------------------+
                     |                            |
                     v                            v
              +-------------+              +-------------+
              |   Decoder   |              |   ImmGen    |
              |    译码器    |              | 立即数生成器 |
              +------+------+              +------+------+ 
                     |                            |
                     | 控制信号                    |
                     v                            |
                +------------------+              |
                |        RF        |<-------------+
                |      寄存器堆     |
                +----+--------+----+
                     |        |
                  rs1|        |rs2
                     v        v
                   +------------+
                   |    ALU     |
                   | 算术逻辑单元 |
                   +------+-----+
                          |
                          v
                     +---------+
                     |   DM    |
                     | 数据存储器 |
                     +----+----+
                          |
                          v
                   +-------------+
                   | 写回选择逻辑 |
                   +------+------+ 
                          |
                          v
                         RF

分支/跳转控制路径：

Decoder + RF + ImmGen + 比较/跳转结果
              |
              v
         redirect_valid / redirect_pc
              |
              v
         直接控制 PC 与 IF_ID
```

---

## 5. 每个模块是做什么的

下面这部分尽量按“一个完全不熟悉这个项目的人也能看懂”的方式来讲。

### 5.1 `riscv_pipeline.v`

文件： [riscv_pipeline.v](./riscv_pipeline.v)

这是整个 CPU 的**顶层模块**。

它做的事是把所有子模块连起来，包括：

- `PC`
- `IM`
- `IF_ID`
- `Decoder`
- `ImmGen`
- `RF`
- `ALU`
- `DM`

在这个文件里，你能看到整个 CPU 的主数据流：

1. `PC` 给出地址
2. `IM` 取出指令
3. `IF_ID` 保存当前取到的指令与 PC 信息
4. `Decoder` 根据指令生成控制信号
5. `RF` 读取寄存器
6. `ImmGen` 生成立即数
7. `ALU` 做运算或地址计算
8. `DM` 执行 `lw/sw`
9. `DM` 在同步读模型下返回上一拍请求的数据
10. `wb_data` 选择最终写回寄存器的数据
11. 分支 / 跳转逻辑决定下一拍 `PC`

如果你想理解“这颗 CPU 到底是怎么跑起来的”，应当最先读这个文件。

---

### 5.2 `PC.v`

文件： [PC.v](./PC.v)

这是程序计数器模块。

它的作用是保存当前取指地址。

输入：

- `clk`
- `rst`
- `en`
- `pc_next`

输出：

- `pc_q`

行为很简单：

- 复位时把 `pc_q` 置为 `RESET_PC`
- 平时在 `en=1` 时把 `pc_next` 写进来

为什么单独做成模块？

- 结构更清晰
- 后续可以在这里方便加入 clock gating、stall 或特殊 PC 控制

---

### 5.3 `IF_ID.v`

文件： [IF_ID.v](./IF_ID.v)

这是**取指级到执行级之间的流水寄存器**。

它保存：

- `valid`
- `pc`
- `pc4`
- `instruction`

这样执行级在下一拍就能读取上一拍取到的内容。

它有两个重要控制：

- `en`：允许更新
- `clear`：清空为无效 / NOP

`clear` 主要用于分支和跳转发生时，把错误路径上已经取到的指令冲掉。

---

### 5.4 `RF.v`

文件： [RF.v](./RF.v)

这是寄存器堆。

当前实现是：

- 32 个 32 位寄存器
- 2 个读端口
- 1 个写端口
- `x0` 永远保持为 0

这个文件非常重要，因为几乎所有非立即数指令都要读它，写回时也要写它。

当前版本是**功能模型**，更偏仿真友好。  
后面如果要真正做面积优化，最有可能被替换成：

- 工艺库里的 `2R1W register-file macro`
- 或一个 `RF wrapper`

所以你可以把它理解成“当前可用，但未来很可能被替换”的模块。

---

### 5.5 `ALU.v`

文件： [ALU.v](./ALU.v)

这是算术逻辑单元。

当前支持：

- `add`
- `sub`
- `and`
- `or`
- `sll`
- `srl`

这里有一个你之前特别要求的实现点：

- `add` 和 `sub` **显式复用同一个加法器**

具体做法是：

- 当是减法时，把 `B` 做按位取反
- 再加上进位 `1`
- 最终仍然走同一条加法路径

这是典型的二进制补码减法实现方式。

为什么这样做？

- 更符合“硬件里 add/sub 共享资源”的目标
- 让 RTL 的资源复用意图更明确
- 便于后续面积优化分析

---

### 5.6 `ImmGen.v`

文件： [ImmGen.v](./ImmGen.v)

这是立即数生成器。

不同 RISC-V 指令格式的立即数位置不一样，比如：

- `I-type`
- `S-type`
- `B-type`
- `J-type`

这个模块根据 `imm_sel`，从指令中把立即数拼出来并做符号扩展。

为什么要单独做？

- 顶层更清晰
- 后续扩展指令时更好维护

---

### 5.7 `Decoder.v`

文件： [Decoder.v](./Decoder.v)

这是当前设计里的主译码器。

它读取整条 32 位指令，然后输出执行这条指令所需要的控制信号，例如：

- 要不要写寄存器
- 要不要写数据存储器
- 写回来自哪里
- 立即数类型是什么
- ALU 应该做什么运算
- 是不是 branch
- 是不是 jump

你可以把它理解为“把汇编指令翻译成 CPU 内部动作”的模块。

例如：

- `add` 会告诉 ALU 做加法，同时允许写回
- `lw` 会告诉 ALU 去算地址、数据来自内存、最后写回寄存器
- `beq` 会告诉控制逻辑进行比较并决定是否跳转

如果以后你想新增一条指令，这通常是你必须要修改的文件之一。

---

### 5.8 `IM.v`

文件： [IM.v](./IM.v)

这是指令存储器模块。

当前它有两种工作方式，由宏控制：

#### 功能仿真模式

默认情况，不定义任何额外宏时：

- 使用行为级数组 `memory`
- 允许 testbench 用 `$readmemh` 直接往里加载程序

这很适合功能验证。

#### 技术存储器模式

如果定义了：

```verilog
`define PIPELINE_TECH_MEM
```

或者在编译命令里加：

```bash
-DPIPELINE_TECH_MEM
```

那么 `IM.v` 会实例化 `IM_TECH`。

这样做的目的是：

- 功能仿真时用简单模型
- 综合 / STA / 布局布线时改用更接近真实工艺库的 memory wrapper

---

### 5.9 `DM.v`

文件： [DM.v](./DM.v)

这是数据存储器模块。

它和 `IM.v` 的思路一样，也分为两种模式：

#### 功能仿真模式

- 内部是行为级数组
- 采用同步读 / 同步写行为，更接近真实 SRAM macro
- 适合提前验证 `lw/sw` 的时序影响

#### 技术存储器模式

- 实例化 `DM_TECH`
- 用来承接后面真实的 SRAM wrapper

这个设计的意义是：

- 功能验证和综合实现可以共用一个统一接口
- 不需要以后大规模改顶层

---

### 5.10 `IM_TECH.v`

文件： [IM_TECH.v](./IM_TECH.v)

这是**技术实现占位模块**。

注意，它现在还不是一个真正的 TSMC65nm ROM/SRAM 宏封装。  
它的主要作用是：

- 先把结构和接口占出来
- 让 `PIPELINE_TECH_MEM` 这条路径能单独编译通过

后续你需要把它替换成真正的：

- ROM wrapper
- 或 instruction SRAM wrapper

---

### 5.11 `DM_TECH.v`

文件： [DM_TECH.v](./DM_TECH.v)

这和 `IM_TECH.v` 的作用一样，只不过它是给数据存储器用的。

当前它只是一个占位版本，方便后续换成真实 SRAM macro wrapper。

---

### 5.12 `RF_TECH.v`

文件： [RF_TECH.v](./RF_TECH.v)

这是寄存器堆的技术实现占位模块。

它当前还不是一个真实的 `2R1W` 寄存器堆工艺宏封装，主要作用是：

- 把 `RF` 的技术路径接口先定下来
- 让技术版本编译检查能够覆盖寄存器堆

后续如果接入真实工艺库，通常需要把它替换成真正的：

- `2R1W register-file wrapper`
- 或工艺团队提供的寄存器堆宏模块

---

### 5.13 `includes/global_def.v`

文件： [includes/global_def.v](./includes/global_def.v)

这里放全局常量，例如：

- 复位 PC
- NOP 指令编码
- 默认存储器深度

如果你想修改默认起始地址、默认存储器大小，这通常是一个入口。

---

### 5.14 `includes/instruction_def.v`

文件： [includes/instruction_def.v](./includes/instruction_def.v)

这里定义了当前支持指令所需要的：

- opcode
- funct3
- funct7

作用是避免在各个模块里反复写二进制字面量。

好处是：

- 可读性更高
- 修改更集中
- 译码逻辑不容易写错

---

### 5.15 `includes/ctrl_signal_def.v`

文件： [includes/ctrl_signal_def.v](./includes/ctrl_signal_def.v)

这里定义了内部控制信号的编码，例如：

- ALU 操作类型
- 立即数类型
- 写回来源
- branch 类型
- jump 类型

这是连接 `Decoder`、`ALU`、顶层控制逻辑的重要基础文件。

---

### 5.16 `TODO.md`

文件： [TODO.md](./TODO.md)

这是当前这套 `rtl_pipeline` 的后续优化规划。

里面主要记录了：

- 面积优化方向
- 存储器 macro 化方向
- 寄存器堆替换方向
- 数据通路进一步压缩方向

如果你想继续朝综合和 PPA 优化推进，这个文件是很好的入口。

---

## 6. 这些模块是怎么连起来的

如果你不熟悉 RTL，下面这段可以帮助你建立整体画面。

### 6.1 取指路径

数据流：

`PC -> IM -> IF_ID`

含义：

- `PC` 给出地址
- `IM` 根据地址输出指令
- `IF_ID` 把这条指令和对应的 `PC` 保存下来

### 6.2 执行路径

数据流：

`IF_ID -> Decoder / RF / ImmGen -> ALU -> DM请求 -> WB`

含义：

- `Decoder` 看指令要做什么
- `RF` 读源寄存器
- `ImmGen` 生成立即数
- `ALU` 做算术运算或地址计算
- 如果是 `lw/sw`，执行级向 `DM` 发出访问请求
- 下一拍在 `WB` 级统一完成写回

### 6.3 控制转移路径

数据流：

`branch/jump decision -> redirect_valid -> PC / IF_ID`

含义：

- 执行级判断是否跳转
- 如果跳转，直接清空 `IF_ID`
- 同时 `PC` 改成跳转目标地址

---

## 7. 功能仿真怎么用

### 7.1 相关文件不在这个目录里

虽然 RTL 在 `pipeline_3/rtl_pipeline/`，但仿真入口还分散在同级的其他目录：

- 文件列表： [files_pipeline.f](/home/distortionk/WorkSpace/VCS/riscv_cpu_design/pipeline_3/sim_pipeline/files_pipeline.f)
- 回环测试文件列表： [files_pipeline_loop.f](/home/distortionk/WorkSpace/VCS/riscv_cpu_design/pipeline_3/sim_pipeline/files_pipeline_loop.f)
- Makefile： [Makefile.pipeline](/home/distortionk/WorkSpace/VCS/riscv_cpu_design/pipeline_3/sim_pipeline/Makefile.pipeline)
- 基础 testbench： [riscv_pipeline_sim.v](/home/distortionk/WorkSpace/VCS/riscv_cpu_design/pipeline_3/tb_pipeline/riscv_pipeline_sim.v)
- loop testbench： [riscv_pipeline_loop_sim.v](/home/distortionk/WorkSpace/VCS/riscv_cpu_design/pipeline_3/tb_pipeline/riscv_pipeline_loop_sim.v)
- 程序文件： [pipeline_basic.hex](/home/distortionk/WorkSpace/VCS/riscv_cpu_design/pipeline_3/hex_pipeline/pipeline_basic.hex), [pipeline_loop.hex](/home/distortionk/WorkSpace/VCS/riscv_cpu_design/pipeline_3/hex_pipeline/pipeline_loop.hex)

### 7.2 最常用的命令

进入 `pipeline_3/sim_pipeline/` 目录后：

```bash
make -f Makefile.pipeline test_ivl
```

这个命令会：

1. 用 `iverilog` 编译基础测试
2. 运行基础测试
3. 用 `iverilog` 编译 loop 测试
4. 运行 loop 测试

如果一切正常，你会看到：

- `PIPELINE TEST PASS`
- `PIPELINE LOOP TEST PASS`

### 7.3 单独跑某一个测试

只跑基础测试：

```bash
make -f Makefile.pipeline test_ivl_basic
```

只跑 loop 测试：

```bash
make -f Makefile.pipeline test_ivl_loop
```

### 7.4 清理中间文件

```bash
make -f Makefile.pipeline clean
```

---

## 8. 综合 / 时序版本怎么用

当前 `IM`、`DM` 和 `RF` 都支持通过宏切换到技术实现占位版本。

### 8.1 编译技术实现路径

在 `pipeline_3/sim_pipeline/` 目录下：

```bash
make -f Makefile.pipeline check_ivl_techmem
```

这个命令会：

- 定义 `PIPELINE_TECH_MEM`
- 定义 `PIPELINE_TECH_RF`
- 编译 `riscv_pipeline` 顶层
- 不运行 testbench

为什么不运行 testbench？

因为功能 testbench 需要直接访问行为模型里的 `memory` 数组，  
而技术存储器版本本来就是为了将来接 macro，不再保证有这个内部数组。

### 8.2 什么时候该用这条路径

当你准备：

- 对接 SRAM / ROM wrapper
- 跑综合
- 跑 STA
- 做后端准备

就应该逐渐从功能模型转向这条路径。

---

## 9. 如果我要新增一条指令，应该改哪里

这取决于新增的是什么指令。

通常至少要看这些地方：

### 9.1 指令编码定义

改：

- [includes/instruction_def.v](./includes/instruction_def.v)

### 9.2 译码逻辑

改：

- [Decoder.v](./Decoder.v)

### 9.3 数据通路

如果新指令需要：

- 新的 ALU 运算
- 新的立即数类型
- 新的写回来源
- 新的跳转规则

那么可能还要改：

- [ALU.v](./ALU.v)
- [ImmGen.v](./ImmGen.v)
- [riscv_pipeline.v](./riscv_pipeline.v)

### 9.4 测试程序

最后别忘了补：

- `hex/*.hex`
- `tb/*.v`

---

## 10. 如果我要做面积优化，应该优先看哪里

按照当前结构，通常优先级是：

1. `IM`
2. `DM`
3. `RF`
4. 跳转 / 地址加法路径
5. `ALU`
6. 流水寄存器与控制逻辑

也就是说，真正的面积大头通常是：

- 存储器
- 寄存器堆

所以如果你后面开始做 PPA，不要一开始就只盯 `ALU`。

更高收益的动作通常是：

- 把 `IM/DM` 换成真实 macro wrapper
- 把 `RF` 换成 `2R1W` 宏
- 再考虑进一步压缩数据通路

这也是为什么 `TODO.md` 里有很多条都围绕 memory 和 RF。

---

## 11. 当前已知限制

为了避免误解，这里把当前设计的边界明确写出来。

### 11.1 这不是完整流水线 CPU

虽然目录名叫 `rtl_pipeline`，但它现在更准确地说是：

- 一个面向真实 memory macro 的简化三级流水线原型

而不是：

- 完整的五级流水线工业实现

### 11.2 Hazard 处理仍然是简化版

当前已经实现了：

- `WB -> EX` 前递
- 跳转成立时的 `flush`

但还没有完整实现：

- 更复杂的多源 forwarding
- 更细粒度的 stall 控制
- 针对真实同步取指存储器的停顿策略

### 11.3 技术存储器模块还是占位版本

`IM_TECH.v` 和 `DM_TECH.v` 目前还只是接口占位，  
后续必须换成真实工艺宏封装。

### 11.4 当前更偏“可理解、可验证”

这版的主要目标是：

- 结构清晰
- 容易验证
- 便于继续优化

还不是最终 tapeout 版本。

---

## 12. 建议的阅读顺序

如果你是第一次看这个目录，建议按下面顺序读：

1. [README.md](./README.md)
2. [riscv_pipeline.v](./riscv_pipeline.v)
3. [Decoder.v](./Decoder.v)
4. [ALU.v](./ALU.v)
5. [RF.v](./RF.v)
6. [ImmGen.v](./ImmGen.v)
7. [IF_ID.v](./IF_ID.v)
8. [IM.v](./IM.v) / [DM.v](./DM.v)
9. [TODO.md](./TODO.md)

如果你更关心“怎么跑测试”，就先看：

1. [Makefile.pipeline](/home/distortionk/WorkSpace/VCS/riscv_cpu_design/pipeline_3/sim_pipeline/Makefile.pipeline)
2. [riscv_pipeline_sim.v](/home/distortionk/WorkSpace/VCS/riscv_cpu_design/pipeline_3/tb_pipeline/riscv_pipeline_sim.v)
3. [riscv_pipeline_loop_sim.v](/home/distortionk/WorkSpace/VCS/riscv_cpu_design/pipeline_3/tb_pipeline/riscv_pipeline_loop_sim.v)

---

## 13. 一句话总结

`rtl_pipeline/` 是这个工程里一套新的、独立的、面向后续优化的 CPU RTL 原型。  
它目前已经可以完成功能仿真，支持一组精简的 RISC-V 指令，并且已经开始为后续的综合 / memory macro 对接 / 面积优化做结构准备。
