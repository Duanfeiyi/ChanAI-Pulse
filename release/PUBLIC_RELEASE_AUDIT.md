# ChanAI Pulse v1.0.0 公开发布安全审计

生成日期：2026-06-04

## 1. 当前将要 push 的分支

- 当前公开发布分支：`main`
- 本地仍存在内部历史分支：`internal/history-before-public-release`
- 本地仍存在旧分支：`master`
- 发布要求：只 push `main`，不要 push `internal/history-before-public-release` 或 `master`
- 当前 remote：未配置

## 2. 当前 Git tracked 文件数量

- 当前 `git ls-files` 跟踪文件数量：45
- 跟踪文件范围包括：源码、公开 demo 数据、文档、测试、Release 说明、License、Citation、Roadmap、Issue templates

## 3. 是否包含 datasets/

- 当前公开 `main` 分支未跟踪 `datasets/`
- `datasets/` 已由 `.gitignore` 忽略
- 真实测量数据只允许保留在本地，不进入公开仓库

## 4. 是否包含真实测量压缩包

- 当前 `git ls-files` 未发现 `.zip`、`.rar`、`.7z`
- 当前 `git ls-files` 未发现 `datasets/measured/raw_archives/`
- 当前 `git ls-files` 未发现 `datasets/measured/extracted_preview/`
- 结论：未发现真实测量压缩包被 Git 跟踪

## 5. 是否包含 legacy/

- 当前公开 `main` 分支未跟踪 `legacy/`
- `legacy/` 已由 `.gitignore` 忽略
- 结论：原始大文件备份不会随公开源码发布

## 6. 是否包含大型压缩包、旧 installer 或 exe

- 当前 `git ls-files` 未发现 `.zip`、`.rar`、`.7z`
- 当前 `git ls-files` 未发现 `.exe`
- 当前 `git ls-files` 未发现旧 installer
- 结论：未发现大型压缩包或旧安装包进入 Git

## 7. MATLAB App Package 状态

- 人工打包文件位置：`release/matlab_app_package/ChanAI Pulse.mlappinstall`
- Release 附件文件位置：`release/github_release_assets/ChanAI_Pulse_v1.0.0.mlappinstall`
- Release 附件大小：213,155 bytes
- `.mlappinstall` 已由 `.gitignore` 忽略
- 发布策略：不提交到源码仓库，只作为 GitHub Release asset 上传

## 8. Release assets

准备上传到 GitHub Release 的附件：

- `release/github_release_assets/ChanAI_Pulse_v1.0.0.mlappinstall`
- `release/github_release_assets/安装说明.md`
- `release/github_release_assets/README_RELEASE.md`

Release notes 文件：

- `release/github_release_assets/RELEASE_DESCRIPTION.md`

Release 说明已明确：

- This release requires MATLAB and required toolboxes. It is not a standalone executable.
- No private measured datasets are included in this release.

## 9. 是否适合公开发布

当前 `main` 分支适合公开发布源码版，前提是：

1. 只 push `main` 分支；
2. 不 push `master`；
3. 不 push `internal/history-before-public-release`；
4. 不提交 `.mlappinstall` 到源码仓库；
5. `.mlappinstall` 只通过 GitHub Release 附件上传；
6. push 前再次确认 `git status` 干净；
7. 如果 GitHub CLI 不可用，需要人工创建 GitHub 仓库或安装并登录 GitHub CLI。

## 10. 当前结论

安全审计通过。当前未发现真实测量数据、legacy 备份、旧安装包、大型压缩包或 `.mlappinstall` 被 Git 跟踪。

