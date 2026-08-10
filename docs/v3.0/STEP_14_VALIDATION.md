# Step 14 自动验证记录

> 日期：2026-08-09
> 分支：`codex/v3-step-14-release`
> 状态：自动检查与项目负责人人工验收均已通过；PR #62 已于 2026-08-09 由项目负责人手动合并。2026-08-10 已在干净 worktree 完成 post-merge Manifest 预检和 Step 14 聚焦回归。

## 已通过

### MAT 转换专项

```text
PASS: Step 14 MAT inspection, explicit mapping, conversion,
source preservation, and wizard contracts.
```

覆盖：MAT v7/v7.3、单复数变量、实虚部配对、自动/人工维度映射、单位换算、1:N 样本编号降级、power-only 拒绝、SAGE、旧 WiFo、源哈希、禁止覆盖、强制 v7.3 分块读取、正式向导、中英文入口和进度合同。

### Step 12 正式平台

```text
PASS: Step 12 formal entry and target-free baseline contract are valid.
```

覆盖四类公开合成信道的 1/3/6/9 图能力、Lite/Full 自动兼容性选择和目标 Ground Truth 隔离。

### Step 13 Benchmark

```text
PASS: Step 13 Benchmark core, baselines, strict alignment, reports and UI.
PASS: Step 13 metrics follow the 1/3/6/9 capability classes.
PASS: Step 13 focused regression suite.
```

### Step 14 最终聚焦入口

```text
PASS: Step 14 MAT inspection, explicit mapping, conversion, source preservation, and wizard contracts.
PASS: Step 12 formal entry and target-free baseline contract are valid.
PASS: Step 13 focused regression suite.
PASS: Step 14 focused regression suite.
```

### Step 1–11 累计回归

临时设置已登记的外置 Full 6GPCM 和工作树内被 Git 忽略的 Python `.venv` 后：

```text
PASS: Step 1-9 complete MATLAB regression.
PASS: Step 10 MATLAB Predictor Adapter, auto/manual selection, and task isolation.
PASS: Step 1-10 complete MATLAB regression.
PASS: Step 11 predicted parameters to deterministic CIR/CTF, provenance,
strict failures, continuity, and export.
PASS: Step 11ABC corpus contract, P-bundle order, and group split are valid.
PASS: Step 1-11 complete MATLAB regression.
```

真实 Full 6GPCM Step 6 Adapter、Step 7 两候选 Grid Search 和 Step 8 最小 SA 均通过，测试未修改外部核心。

### Python 跨语言测试

```text
Ran 19 tests in 1.497s
OK
```

覆盖复数 CIR/CTF HDF5、五维顺序、标准夹具、Step 10 选择/适配/无泄漏、Step 11ABC 配对合同。

### 静态与仓库审计

- `git diff --check`：通过；
- 变更 MATLAB 文件 Code Analyzer：只有既有/非阻塞的未使用参数、脚本保存变量和性能建议，
  没有语法或未定义符号错误；
- 生产代码未发现 `C:\Users\Administrator`、临时目录、GitHub Token 或 OpenAI 风格密钥；
- 追踪的 MAT/H5/PT 仅位于公开合成 `demo_data`；
- 仓库没有追踪外置 `@channel_model` Full 6GPCM 核心、`datasets/measured` 或 `private_data`；
- `.venv`、review_data、转换结果和本地截图均由 `.gitignore` 排除。

## 自动检查结论

Step 14 自动检查和项目负责人人工验收均已通过，PR #62 已手动合并到
`main`（`d74157e86e59238c6345418439e922a687bc44ce`）。在干净收尾 worktree 上，
`create_v3_release_manifest` 已成功预检，记录 `git_dirty=false` 和上述 revision；
Step 14 聚焦回归亦再次通过。

正式收尾仍需：同步本文档与发布清单的合并后状态；由项目负责人手动合并该小型文档收尾 PR；
随后在新的干净 `main` revision 上重新生成最终 Manifest，并由项目负责人决定是否创建
`v3.0.0` Tag/GitHub Release。Codex 不执行合并或创建 Tag/Release。

## 人工验收入口

见 [STEP_14_MANUAL_REVIEW_GUIDE.md](STEP_14_MANUAL_REVIEW_GUIDE.md)。项目负责人已确认人工验收通过并已手动合并 PR #62；Codex 不执行合并。
