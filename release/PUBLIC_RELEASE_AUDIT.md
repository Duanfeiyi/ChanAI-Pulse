# ChanAI Pulse v1.0.0 公开发布安全审计

生成时间：2026-06-04

## 1. 将要公开的文件

公开仓库应只包含以下内容：

- `app/`
- `core/`
- `configs/`（如存在公开配置）
- `demo_data/`
- `docs/`
- `tests/`
- `release/` 中的脚本和发布说明
- `README.md`
- `LICENSE`
- `CITATION.cff`
- `CHANGELOG.md`
- `ROADMAP.md`
- `.gitignore`
- `.github/ISSUE_TEMPLATE/`

## 2. 不会公开的文件

以下内容不得公开：

- `datasets/measured/raw_archives/`
- `datasets/measured/extracted_preview/`
- `datasets/measured/DATASET_AUDIT.md`
- `datasets/measured/REAL_DATA_VALIDATION.md`
- `datasets/measured/BEGINNER_GUIDE.md`
- `legacy/`
- 真实测量数据
- zip / rar / 7z
- 旧安装包 exe
- 大型实验输出

说明：`DATASET_AUDIT.md` 包含真实数据文件名和变量结构信息，存在元信息泄露风险，因此不应进入公开仓库。

## 3. 真实数据泄露风险

当前公开分支必须使用干净历史，不能包含曾经提交过的真实数据审计文档或 legacy 备份文件。

建议做法：

- 保留本地内部历史分支；
- 创建 orphan `main` 分支作为公开发布分支；
- 只添加公开文件；
- 不 push 内部分支。

## 4. 大型压缩包与旧安装包检查

公开仓库不得包含：

```text
*.zip
*.rar
*.7z
*.exe
*.mlappinstall
```

`.mlappinstall` 应作为 GitHub Release 附件上传，不直接提交到源码仓库。

## 5. MATLAB App Package 状态

目标文件：

```text
release/matlab_app_package/ChanAI_Pulse_v1.0.0.mlappinstall
```

当前自动生成未成功。原因：`matlab.apputil.package` 需要有效的 App Packaging `.prj` 文件，而该 `.prj` 需要通过 MATLAB 图形化 App Packaging 工具创建。

需要人工操作：

1. MATLAB 中运行 `addpath(genpath(pwd))`；
2. 打开 Apps > Package App；
3. Main file 选择 `app/ChannelSimulatorApp.m`；
4. App name: `ChanAI Pulse`；
5. Version: `1.0.0`；
6. Include: `core/`, `configs/`, `demo_data/`, `docs/`, `README.md`, `LICENSE`；
7. Exclude: `datasets/`, `legacy/`, build outputs；
8. 输出 `ChanAI_Pulse_v1.0.0.mlappinstall`；
9. 放入 `release/github_release_assets/` 用于 Release 附件。

## 6. GitHub CLI 状态

`gh` 未安装或不可用，因此本机当前无法自动创建 GitHub 仓库或 GitHub Release。

需要人工操作：

- 安装 GitHub CLI 并登录；或
- 在 GitHub 网页手动创建 `ChanAI-Pulse` 公共仓库和 `v1.0.0` Release。

## 7. 是否适合发布

源码内容在清理为公开 orphan `main` 分支后适合发布。

当前阻塞：

- `.mlappinstall` 尚未生成；
- `gh` 不可用，无法自动创建仓库和 Release。

