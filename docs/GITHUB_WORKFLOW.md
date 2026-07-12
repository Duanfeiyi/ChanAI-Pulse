# ChanAI Pulse GitHub 协作教程

这份文档写给第一次接触 Git / GitHub 的队友。目标不是让大家立刻变成 Git 专家，而是让 4-5 个人能长期安全协作，不互相覆盖代码。

## 1. GitHub 是什么

Git 是一个“版本管理工具”。它会记录项目每一次修改，知道谁改了什么、什么时候改的、为什么改。

GitHub 是放 Git 仓库的网站。以后 ChanAI Pulse 的公开仓库会放：

- MATLAB App 源码；
- 文档；
- 测试脚本；
- synthetic demo data；
- release 说明。

GitHub 不应该放真实测量数据、大模型文件、论文 PDF、答辩 PPT 或私人材料。

## 2. 为什么不要用压缩包互传代码

压缩包适合一次性发文件，不适合团队开发。

常见问题：

- `最终版.zip`、`最终版2.zip`、`最终最终版.zip` 分不清；
- A 同学改了 UI，B 同学改了数据加载，两个人的压缩包互相覆盖；
- 出 bug 后不知道是哪一天哪一版引入的；
- 大文件反复复制，非常占空间；
- 不能清楚记录每个人的贡献。

GitHub 的好处是每次修改都有记录，可以比较、回滚、审查。

## 3. 基本协作逻辑

可以把项目理解成三层：

```text
GitHub 远程仓库
    ↓ clone / pull
你的电脑本地仓库
    ↓ MATLAB 编辑和运行
你的工作文件
```

你在本地修改，确认能运行后 `commit`，再 `push` 到 GitHub。队友通过 `pull` 获取你的更新。

## 4. clone：第一次下载项目

第一次拿到项目时使用：

```bash
git clone https://github.com/<team>/ChanAI-Pulse.git
cd ChanAI-Pulse
```

`clone` 只需要做一次。之后每天更新用 `git pull`。

## 5. pull：同步最新版本

开始工作前，先同步：

```bash
git pull
```

建议每天第一次打开项目时都执行一次，避免基于旧代码继续改。

## 6. branch：分支

分支就是“单独开一条工作线”。不要所有人都直接改 `main`。

建议分支：

```text
main
dev
feature/ui
feature/data
feature/benchmark
feature/docs
feature/prediction
```

含义：

- `main`：稳定版本，只放确认可发布的代码；
- `dev`：日常集成分支；
- `feature/ui`：UI 同学使用，做轻量界面修复；
- `feature/data`：数据加载同学使用，做数据格式、转换器、schema；
- `feature/benchmark`：Benchmark 同学使用，做评估脚本和报告；
- `feature/docs`：文档同学使用，写 README、教程、说明；
- `feature/prediction`：预测模块同学使用，涉及训练/预测，必须谨慎 review。

创建分支：

```bash
git switch -c feature/ui-polish
```

切换分支：

```bash
git switch dev
```

## 7. commit：保存一次修改记录

当你完成一个小任务后，先看状态：

```bash
git status
```

添加要提交的文件：

```bash
git add docs/GITHUB_WORKFLOW.md
```

提交：

```bash
git commit -m "docs: update GitHub workflow guide"
```

好的 commit 信息应该简短、明确，例如：

- `fix: adjust prediction status label position`
- `docs: add GUI manual checklist`
- `data: add synthetic demo generator`
- `test: add measured data validation script`

## 8. push：上传到 GitHub

提交在你电脑上完成后，用：

```bash
git push
```

团队协作时，一般 push 到自己的 feature 分支，不直接 push 到 `main`。

## 9. Pull Request：请求合并

Pull Request 简称 PR。它的意思是：“我这个分支做完了，请大家检查后合并。”

PR 里要写清楚：

- 改了什么；
- 为什么改；
- 怎么测试；
- 是否影响 GUI；
- 是否影响训练；
- 是否影响预测；
- 是否影响指标；
- 是否接触真实测量数据。

## 10. merge：合并

合并是把一个分支的修改并入另一个分支。

建议流程：

```text
feature/*  →  dev  →  main
```

`main` 只在准备 release 时合并。

## 11. 如何避免覆盖别人代码

开始前：

```bash
git pull
git status
```

使用自己的分支：

```bash
git switch -c feature/data-loader
```

不要同时多人修改同一个大文件。如果必须改 `app/ChannelSimulatorApp.m`，先在群里说一声。

如果出现 conflict，不要乱点“全部接受”。先看冲突文件，找对应同学一起确认。

## 12. 如何同步 dev 的更新

如果你在 `feature/docs` 工作，想拿到 `dev` 最新内容：

```bash
git switch dev
git pull
git switch feature/docs
git merge dev
```

合并后运行：

```matlab
run("tests/smoke_test.m")
```

## 13. 如何回滚

查看历史：

```bash
git log --oneline
```

撤销某个文件的未提交修改：

```bash
git restore app/ChannelSimulatorApp.m
```

安全撤销某次提交：

```bash
git revert <commit-hash>
```

不要随便用 `git reset --hard`，它可能把本地工作直接清掉。

## 14. ChanAI Pulse 项目特别规则

- 真实测量数据不能提交到 GitHub；
- `datasets/measured/raw_archives/` 不能上传；
- `datasets/measured/extracted_preview/` 不能上传；
- 大模型、训练结果、实验输出默认不上传；
- UI 改动要保持三页结构；
- 训练/预测逻辑改动必须 review；
- 每个阶段完成后运行 `tests/smoke_test.m`；
- 公开 demo 只能使用 synthetic demo data。

## 15. 拆分 PR 的硬性验收标准

项目会逐步把大 App 中的功能外提到 `core/`，但“App 始终可运行”高于拆分速度。每一个拆分 PR 在合并前都必须确认：

```text
1. ChannelSimulatorApp 可以启动
2. 三个主页面可以切换
3. 中英文界面没有明显错误或重叠
4. synthetic demo 可以加载
5. 原有特性分析、生成、训练和预测流程不失效
6. 固定输入下的关键指标和图表与基线一致或在容差内
7. tests/smoke_test.m 通过
8. GUI 相关修改已经人工打开 App 验收
```

推荐拆分方法：先复制原逻辑到独立函数，再让 App 调用该函数，最后比较拆分前后的结果。不要为了“拆得快”而在同一 PR 中同时改变算法、默认参数、数据格式和界面布局。

