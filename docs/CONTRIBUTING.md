# ChanAI Pulse 贡献指南

这份文档说明队友应该如何参与 ChanAI Pulse v1.0 RC 的开发。

## 1. 第一次参与项目

准备工作：

1. 安装 Git；
2. 安装 MATLAB 和所需工具箱；
3. 等正式 GitHub 仓库创建后，用 `git clone` 下载；
4. 在 MATLAB 中进入项目根目录；
5. 运行：

```matlab
run("tests/smoke_test.m")
```

如果 smoke test 不通过，先不要改代码，先记录报错。

## 2. 每次开始工作前

先同步：

```bash
git switch dev
git pull
```

再创建自己的分支：

```bash
git switch -c feature/ui-polish
```

## 3. 建议成员分工

UI 同学：

- 分支建议：`feature/ui`
- 负责页面小修复、控件重叠、字体、按钮文字、图表标题；
- 禁止大幅重做布局；
- 每次改完要人工打开 App 检查。

数据加载同学：

- 分支建议：`feature/data`
- 负责 `.mat` 数据格式识别、转换器、dataset schema；
- 真实数据只能本地使用，不能提交。

Benchmark 同学：

- 分支建议：`feature/benchmark`
- 负责 RMSE、NRMSE、Capacity Accuracy、K-S Distance 等报告脚本；
- 不要修改已有指标公式，除非有明确 bug 和 review。

文档同学：

- 分支建议：`feature/docs`
- 负责 README、安装说明、用户指南、协作教程；
- 注意区分英文开源文档和中文内部文档。

预测模块同学：

- 分支建议：`feature/prediction`
- 负责 TCN/LSTM/GRU 相关工作；
- 任何训练/预测逻辑修改都必须单独 review，并保留对比结果。

## 4. 哪些文件不能提交

不要提交：

- `datasets/measured/raw_archives/*`
- `datasets/measured/extracted_preview/*`
- 真实测量数据；
- 大型模型文件；
- 临时训练结果；
- 私人论文 PDF；
- 答辩 PPT；
- MATLAB 自动生成缓存。

如果不确定某个文件能不能提交，先问。

## 5. 提交前检查

查看状态：

```bash
git status
```

确认里面没有真实数据、大 zip、大模型。

运行 smoke test：

```matlab
run("tests/smoke_test.m")
```

然后提交：

```bash
git add .
git commit -m "fix: polish prediction status layout"
```

## 6. Pull Request 检查清单

提交 PR 时写清楚：

- 本次修改目的；
- 改了哪些文件；
- 是否运行 smoke test；
- 是否人工打开 GUI；
- 是否影响训练；
- 是否影响预测；
- 是否影响指标；
- 是否包含真实数据。

## 6.1 可运行 App 验收门槛

ChanAI Pulse 的第一验收标准是：现有 App 必须始终可运行。任何拆分、重构或功能 PR 都必须满足以下要求，未满足时不得合并：

1. `ChannelSimulatorApp` 可以启动；
2. 三个主页面可以切换；
3. 中英文切换不出现明显错误或控件重叠；
4. public synthetic demo 可以加载；
5. 原有信道特性分析、信道生成、训练和预测流程不因拆分而失效；
6. 对固定 demo 或基线样本，关键指标和图表结果与拆分前保持一致或处于预先记录的容差内；
7. `tests/smoke_test.m` 通过；
8. 涉及 GUI 的 PR 需要人工打开 App 验收。

拆分应采用“复制原逻辑 -> 外提纯函数 -> App 改为调用 -> 测试比较”的方式。不要在同一个 PR 中同时重写算法、修改 GUI 布局和改变数据格式。

## 7. Review 规则

必须 review 的内容：

- `app/ChannelSimulatorApp.m` 修改；
- 训练逻辑修改；
- 预测逻辑修改；
- 指标公式修改；
- 打包脚本修改；
- 数据转换器修改。

文档小改可以简化 review，但仍建议至少一名队友看过。

## 8. 出错时如何记录

如果 App 报错，请记录：

- MATLAB 版本；
- 当前 Git commit；
- 操作步骤；
- 报错全文；
- 截图；
- 使用的数据文件名。

不要只说“打不开”或“出错了”。

## 9. 回滚方法

查看历史：

```bash
git log --oneline
```

撤销单个文件：

```bash
git restore docs/CONTRIBUTING.md
```

安全撤销一个 commit：

```bash
git revert <commit-hash>
```

## 10. 当前最高优先级

1. App 能运行，并且每次拆分 PR 都通过可运行 App 验收门槛；
2. GUI 三页结构不变；
3. 训练/预测结果不被破坏；
4. 真实数据不公开；
5. 项目结构清楚，可维护，可回滚。

