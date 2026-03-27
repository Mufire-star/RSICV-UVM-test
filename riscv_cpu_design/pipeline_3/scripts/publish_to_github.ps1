# 1) 克隆远端到临时目录
git clone git@github.com:Mufire-star/RSICV-UVM-test.git C:\temp\rsicv_remote
cd C:\temp\rsicv_remote

# 2) 切到 main 并更新
git fetch origin
git checkout main
git pull origin main

# 3) 如果存在子模块，先取消并移除子模块引用（忽略错误继续）
git submodule deinit -f -- riscv_cpu_design 2>$null || $true
git rm -f riscv_cpu_design 2>$null || $true
if (Test-Path .git\modules\riscv_cpu_design) { rd /s /q .git\modules\riscv_cpu_design }

# 清理 .gitmodules 中的 riscv_cpu_design 条目（如果存在）
if (Test-Path .gitmodules) {
  (Get-Content .gitmodules) -notmatch 'riscv_cpu_design' | Set-Content .gitmodules
  git add .gitmodules
}

# 4) 删除旧目录（如果存在）并创建目标路径
if (Test-Path riscv_cpu_design) { rd /s /q riscv_cpu_design }
New-Item -ItemType Directory -Force -Path riscv_cpu_design | Out-Null

# 5) 复制本地内容到仓库子目录（排除 .git、run 等）
robocopy "D:\Projects\RISC\pipeline_3" "riscv_cpu_design\pipeline_3" /E /XD "D:\Projects\RISC\pipeline_3\.git" "D:\Projects\RISC\pipeline_3\run"

# 6) 添加并提交变更
git add riscv_cpu_design
git commit -m "Force add pipeline_3 under riscv_cpu_design (overwrite)"

# 7) 强推到 main（若被拒绝，可改用 --force-with-lease）
git push origin main --force