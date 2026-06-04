# ChanAI Pulse GUI 人工验收清单

这份清单用于人工打开 MATLAB App 后做功能验收。自动 smoke test 默认不启动 GUI，所以正式发布前必须至少做一次人工检查。

## 1. 启动 MATLAB

打开 MATLAB，进入项目根目录：

```matlab
cd("D:\Codex_Feiyi\ChanAI Pulse")
```

## 2. 添加路径

运行：

```matlab
addpath(genpath(pwd))
```

这会把 `app/`、`core/`、`tests/` 等目录加入 MATLAB path。

## 3. 打开 App

运行：

```matlab
ChannelSimulatorApp
```

如果提示找不到函数，先检查当前目录是否为项目根目录。

## 4. 检查三个页面

依次点击三个 Tab：

- `Characterization`
- `Channel Generation`
- `Prediction & Training`

检查点：

- 三个页面都能显示；
- 页面没有明显空白、错位、控件重叠；
- 按钮和输入框没有跑出窗口；
- 缩放窗口后布局仍基本可用。

## 5. 检查中英文切换

右上角语言下拉框切换：

- English
- 中文

检查点：

- Tab 标题能切换；
- Panel 标题能切换；
- 按钮文字能切换；
- 中文状态下没有严重重叠；
- 英文状态下没有严重重叠。

## 6. 加载真实数据

真实数据只允许本地测试，不能上传 GitHub。

可以选择 `datasets/measured/extracted_preview/` 中极少量 `.mat` 文件做人工加载测试。

检查点：

- App 能打开文件选择框；
- 选择 SAGE `.mat` 后能识别数据；
- 没有 MATLAB 报错；
- 数据规模提示合理。

## 7. 检查特性分析图

在 `Characterization` 页面查看：

- Angular Power；
- Delay Power；
- Doppler；
- Spread CDF。

检查点：

- 图表有标题；
- 坐标轴可读；
- 图线不为空；
- 没有异常 NaN/Inf 报错。

## 8. 检查信道生成

进入 `Channel Generation` 页面：

1. 保持默认参数；
2. 点击 `Generate Channel`；
3. 等待生成完成。

检查点：

- PDP 图出现；
- CDF 图出现；
- 弹窗提示生成成功；
- `Send to AI` 可用。

## 9. 检查预测页面

进入 `Prediction & Training` 页面：

- 检查 `Algo`、`Domain`、`Task Control`、`Future Gen` 四个区域；
- 检查 `Train Model` 和 `Run Predict` 按钮；
- 检查 `Prediction Steps` 和 `Batch Size` 输入框。

已发现并修复示例：

- 问题：`Future Gen` 面板标题和红色状态文字 `Status: Waiting for Data...` 重叠；
- 修复：将状态文字移动到 `Future Gen` 面板底部，参数输入保留在上方；
- 验收：中英文状态下均不应与标题重叠。

## 10. 如何记录截图

建议截图：

- App 初始页面；
- 三个 Tab；
- 中英文切换后页面；
- 成功加载数据后的 Characterization 页面；
- 成功生成信道后的 Channel Generation 页面；
- Prediction 页面状态区域。

截图命名建议：

```text
screenshots/manual_check_YYYYMMDD_characterization.png
```

## 11. 报错时记录什么

如果出现错误，请记录：

- MATLAB 版本；
- 当前 Git commit；
- 操作步骤；
- 选择的数据文件；
- 报错全文；
- 截图；
- 是否能复现。

## 12. 必须修复的问题

- App 无法启动；
- 三个 Tab 任意一个无法显示；
- 中英文切换导致控件遮挡严重；
- 加载合法 `.mat` 文件直接崩溃；
- 训练/预测按钮基本流程无法使用；
- 真实数据被误提交到 Git。

## 13. 可后续优化的问题

- 个别标题不够美观；
- 图例位置不够理想；
- 字体大小可进一步统一；
- 小窗口下布局略拥挤；
- 需要更多提示文字或用户指南。

