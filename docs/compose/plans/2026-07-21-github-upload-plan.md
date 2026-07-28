# GitHub 上传方案

**日期：** 2026-07-21
**目标：** 将 Step V2-1 QuaDRiGa 管线安全上传至 GitHub

---

## 一、上传前检查清单

### 1.1 数据安全检查（最重要）

```bash
# 检查是否有真实数据被跟踪
git ls-files | grep -E "\.(mat|h5|hdf5|csv|dat|bin)$"

# 检查是否有大型文件
git ls-files | xargs -I {} du -h {} 2>/dev/null | sort -rh | head -20

# 检查 .gitignore 是否正确
cat .gitignore
```

**必须确保：**
- [ ] 没有真实测量数据文件被跟踪
- [ ] 没有私有模型权重被跟踪
- [ ] 没有实验输出（大型 .mat 文件）被跟踪
- [ ] `datasets/` 目录不在 Git 中
- [ ] `legacy/` 目录不在 Git 中

### 1.2 .gitignore 验证

确保 `.gitignore` 包含以下内容：

```gitignore
# 真实数据 - 绝不提交
datasets/
legacy/
*.mat
!demo_data/**/*.mat
!release/**/*.mat

# 实验输出
experiments/
results/
outputs/

# 临时文件
*.tmp
*.bak
*.swp

# MATLAB 临时文件
*.asv
*.mex*
*.mlappinstall

# 系统文件
.DS_Store
Thumbs.db
```

**注意：** `demo_data/quadriga_demo/` 下的 .mat 文件需要提交（这是合成 demo 数据），但其他 .mat 文件不应提交。

### 1.3 文件大小检查

```bash
# 检查即将提交的文件大小
git status --porcelain | awk '{print $2}' | while read f; do
    if [ -f "$f" ]; then
        size=$(du -h "$f" | cut -f1)
        echo "$size  $f"
    fi
done | sort -rh
```

**规则：**
- 单个文件 < 10MB（GitHub 建议）
- 总提交 < 50MB
- 如果有大文件，使用 Git LFS

---

## 二、Git 配置（首次）

### 2.1 检查 Git 状态

```bash
# 检查 git 是否可用
git --version

# 检查当前状态
git status

# 检查远程仓库
git remote -v
```

### 2.2 配置 Git（如果未配置）

```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### 2.3 检查分支

```bash
# 查看当前分支
git branch -a

# 确保在正确的分支上
# 如果是 v2.0 开发，应该在 develop/v2.0 分支
git checkout develop/v2.0
# 或者创建新分支
git checkout -b feature/v2-quadriga-pipeline
```

---

## 三、提交 Step V2-1 代码

### 3.1 查看所有新文件

```bash
# 查看未跟踪的文件
git status --porcelain

# 预期应看到以下新文件：
# ?? core/generation/quadriga/quadriga_check.m
# ?? core/generation/quadriga/quadriga_scenarios.m
# ?? core/generation/quadriga/default_quadriga_config.m
# ?? core/generation/quadriga/validate_quadriga_config.m
# ?? core/generation/quadriga/quadriga_adapter.m
# ?? core/generation/quadriga/quadriga_result_to_complex_h.m
# ?? core/generation/quadriga/quadriga_result_to_dpsd.m
# ?? core/generation/quadriga/generate_quadriga_demo.m
# ?? core/generation/quadriga/test_quadriga_adapter.m
# ?? core/generation/quadriga/README.md
# ?? docs/compose/specs/2026-07-21-step-v2-1-quadriga-pipeline-design.md
# ?? docs/compose/plans/2026-07-21-step-v2-1-quadriga-pipeline.md
# ?? docs/compose/plans/2026-07-21-quadriga-validation-plan.md
```

### 3.2 分批提交（推荐）

**第一批：核心管线代码**

```bash
git add core/generation/quadriga/quadriga_check.m
git add core/generation/quadriga/quadriga_scenarios.m
git add core/generation/quadriga/default_quadriga_config.m
git add core/generation/quadriga/validate_quadriga_config.m
git add core/generation/quadriga/quadriga_adapter.m
git add core/generation/quadriga/quadriga_result_to_complex_h.m
git add core/generation/quadriga/quadriga_result_to_dpsd.m
git add core/generation/quadriga/generate_quadriga_demo.m
git add core/generation/quadriga/test_quadriga_adapter.m
git add core/generation/quadriga/README.md

git commit -m "feat(v2): Step V2-1 - QuaDRiGa minimal reproducible generation pipeline

- Add quadriga_check.m for environment verification
- Add quadriga_scenarios.m with 6 3GPP scenario defaults
- Add default_quadriga_config.m and validate_quadriga_config.m
- Add quadriga_adapter.m wrapping official QuaDRiGa API
- Add quadriga_result_to_complex_h.m and quadriga_result_to_dpsd.m
- Add generate_quadriga_demo.m for synthetic demo generation
- Add test_quadriga_adapter.m with 8 self-tests
- Add README.md with usage documentation

Output: Complex-H H(t,f) data with 6 3GPP scenarios, multi-band support,
seed reproducibility, and physical axis verification."
```

**第二批：设计文档（可选）**

```bash
git add docs/compose/specs/2026-07-21-step-v2-1-quadriga-pipeline-design.md
git add docs/compose/plans/2026-07-21-step-v2-1-quadriga-pipeline.md
git add docs/compose/plans/2026-07-21-quadriga-validation-plan.md

git commit -m "docs(v2): add Step V2-1 design spec, implementation plan, and validation plan"
```

### 3.3 查看提交历史

```bash
git log --oneline -5
```

---

## 四、推送到 GitHub

### 4.1 检查远程仓库

```bash
git remote -v
```

如果没有远程仓库：

```bash
# 添加远程仓库
git remote add origin https://github.com/Duanfeiyi/ChanAI-Pulse.git

# 或者使用 SSH
git remote add origin git@github.com:Duanfeiyi/ChanAI-Pulse.git
```

### 4.2 推送到分支

```bash
# 推送到 develop/v2.0 分支（推荐）
git push origin develop/v2.0

# 或者推送到 feature 分支
git push origin feature/v2-quadriga-pipeline
```

### 4.3 创建 Pull Request（推荐）

在 GitHub 网页上：

1. 进入仓库页面
2. 点击 "Compare & pull request"
3. 选择 base: `develop/v2.0` <- compare: `feature/v2-quadriga-pipeline`
4. 填写 PR 描述：

```markdown
## Summary

Step V2-1: QuaDRiGa Minimal Reproducible Generation Pipeline

### What this PR adds

- **quadriga_check.m**: Environment verification for QuaDRiGa installation
- **quadriga_scenarios.m**: 6 3GPP scenario registry with physical defaults
- **default_quadriga_config.m + validate_quadriga_config.m**: Configuration management
- **quadriga_adapter.m**: Core adapter wrapping official QuaDRiGa API → Complex-H output
- **quadriga_result_to_complex_h.m / quadriga_result_to_dpsd.m**: Conversion utilities
- **generate_quadriga_demo.m**: Synthetic demo dataset generator
- **test_quadriga_adapter.m**: 8-test self-test suite
- **README.md**: Pipeline documentation

### Key features

- 6 3GPP scenarios: UMi, UMi-LOS, UMa, UMa-LOS, RMa, INH
- Multi-band: Sub-6 GHz, mmWave, THz
- Seed reproducibility: same config + seed → identical output
- Physical axes: explicit time (s) and frequency (Hz) coordinates
- Legacy compatibility: DPSD conversion for v1.0 pipeline

### Verification

- [ ] Environment check passes
- [ ] All 6 scenarios load correctly
- [ ] Default config validates
- [ ] Adapter produces correct dimensions
- [ ] Complex-H output is complex-valued
- [ ] Same seed produces identical output

### Scope

This is Step V2-1 of the v2.0 roadmap. It establishes the data generation
foundation for Complex-H data contracts, Benchmarks, and Base Models.
```

5. 点击 "Create pull request"

---

## 五、上传后验证

### 5.1 在 GitHub 上检查

1. 访问 https://github.com/Duanfeiyi/ChanAI-Pulse
2. 检查 `develop/v2.0` 分支
3. 确认文件已上传：
   - `core/generation/quadriga/` 目录下有 10 个文件
   - `docs/compose/` 目录下有设计文档

### 5.2 检查文件内容

在 GitHub 上点击文件，确认：
- 代码格式正确
- 中英文注释正确
- 没有敏感信息泄露

### 5.3 检查 README

确认 README.md 显示正确，包括：
- 6 个场景表格
- 快速开始代码
- 测试说明

---

## 六、常见问题

### Q1: git 不在 PATH 中

**解决方案：**

```bash
# 方法 1: 使用完整路径
"C:\Program Files\Git\bin\git.exe" status

# 方法 2: 添加到 PATH
# Windows: 设置 → 系统 → 高级系统设置 → 环境变量 → Path → 添加 Git\bin

# 方法 3: 使用 MATLAB 的 git
!git status
```

### Q2: 文件太大无法提交

**解决方案：**

```bash
# 使用 Git LFS
git lfs install
git lfs track "*.mat"
git add .gitattributes
git add <large-file>
git commit -m "track large files with LFS"
```

### Q3: 提交了敏感数据

**紧急处理：**

```bash
# 从历史中删除文件
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch <sensitive-file>' \
  --prune-empty --tag-name-filter cat -- --all

# 强制推送（危险！）
git push origin --force --all

# 通知团队成员重新 clone
```

### Q4: 分支冲突

**解决方案：**

```bash
# 拉取最新代码
git fetch origin

# 合并
git merge origin/develop/v2.0

# 解决冲突后提交
git add .
git commit -m "merge: resolve conflicts"
```

---

## 七、发布流程（v2.0 完成后）

### 7.1 创建 Release

```bash
# 打标签
git tag -a v2.0.0-alpha.1 -m "v2.0-alpha.1: QuaDRiGa pipeline + Complex-H data contract"

# 推送标签
git push origin v2.0.0-alpha.1
```

### 7.2 在 GitHub 上创建 Release

1. 进入 "Releases" 页面
2. 点击 "Create a new release"
3. 选择标签 `v2.0.0-alpha.1`
4. 填写发布说明：

```markdown
# ChanAI Pulse v2.0-alpha.1

## What's New

- QuaDRiGa generation pipeline with 6 3GPP scenarios
- Complex-H H(t,f) data output
- Multi-band support (Sub-6/mmWave/THz)
- Seed reproducibility
- Self-test suite

## Breaking Changes

- None (this is an additive feature)

## Known Limitations

- QuaDRiGa must be installed separately
- SISO only (MIMO in v2.1)
- No real measurement data included

## Installation

1. Install MATLAB R2022b+
2. Install QuaDRiGa 2.6+
3. Add `core/generation/quadriga/` to MATLAB path
4. Run `test_quadriga_adapter()` to verify
```

---

## 八、检查清单总结

### 上传前
- [ ] .gitignore 配置正确
- [ ] 没有真实数据被跟踪
- [ ] 文件大小在限制内
- [ ] 代码格式正确
- [ ] 测试通过（QuaDRiGa 安装时）

### 上传中
- [ ] 分支正确（develop/v2.0 或 feature 分支）
- [ ] 提交信息清晰
- [ ] 分批提交（代码 + 文档）

### 上传后
- [ ] GitHub 上文件显示正确
- [ ] README 渲染正确
- [ ] PR 描述完整
- [ ] 无敏感信息泄露
