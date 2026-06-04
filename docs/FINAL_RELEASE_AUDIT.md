# ChanAI Pulse v1.0 RC 最终发布审计

本报告用于 GitHub 上传前人工确认。生成时间：2026-06-04。

## 1. 可以上传 GitHub 的内容

当前 Git 已追踪内容主要包括：

- MATLAB App 源码：`app/ChannelSimulatorApp.m`
- 原始 App 备份：`legacy/ChannelSimulatorApp_0604_original.m`
- 低风险外提函数：`core/`
- synthetic demo data：`demo_data/`
- smoke test 和验证脚本：`tests/`
- 开源元文件：`LICENSE`、`CITATION.cff`、`CHANGELOG.md`、`ROADMAP.md`
- 协作文档和发布文档：`docs/`
- GitHub issue templates：`.github/ISSUE_TEMPLATE/`
- MATLAB Compiler / packaging 诊断文档：`release/`

## 2. 不应上传 GitHub 的内容

以下内容不得进入 GitHub：

- `datasets/measured/raw_archives/*`
- `datasets/measured/extracted_preview/*`
- 真实测量数据；
- 大型压缩包：`*.zip`、`*.rar`、`*.7z`；
- 安装包：`*.exe`、`*.mlappinstall`；
- MATLAB packaging 临时输出；
- 私人论文 PDF；
- 答辩 PPT；
- 大型模型和实验结果。

## 3. 当前审计结果

已检查：

- Git 已追踪文件中未发现 `datasets/measured/raw_archives`；
- Git 已追踪文件中未发现 `datasets/measured/extracted_preview`；
- Git 已追踪文件中未发现 `.zip`、`.rar`、`.7z`；
- Git 已追踪文件中未发现 `.exe`、`.mlappinstall`、`.prj`；
- 本地确实存在两个真实测量压缩包，但它们位于 ignored 目录中，没有进入 Git；
- synthetic demo data 已生成并进入 Git；
- README 未包含真实数据下载方式、论文 PDF 或答辩 PPT；
- MATLAB Compiler 问题已记录，当前不提供 installer。

## 4. 当前风险

- `datasets/measured/DATASET_AUDIT.md` 是由真实数据审计生成的文档，包含文件名、变量名和结构信息，但不包含原始测量矩阵数据。发布前如对数据来源敏感，应人工复核是否允许公开这些元信息。
- `legacy/ChannelSimulatorApp_0604_original.m` 是完整原始 App 备份，便于回滚，但会增加仓库体积。当前大小可接受。
- MATLAB Compiler 未安装或不可见，因此 v1.0 RC 只能发布源码版。

## 5. 上传前人工确认事项

发布前请确认：

- [ ] `git status` clean；
- [ ] `git remote -v` 没有指向旧草稿仓库；
- [ ] `run("tests/smoke_test.m")` 通过；
- [ ] 人工 GUI 验收通过；
- [ ] demo data 可加载；
- [ ] README 内容正确；
- [ ] License 为 Apache-2.0；
- [ ] 真实测量数据没有进入 Git；
- [ ] 如数据审计报告涉及敏感元信息，已获得团队确认。

