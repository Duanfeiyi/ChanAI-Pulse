# v3.2-5 Help Assistant 人工审阅指导

> 本指南用于人工验收从协作者 PR #84 提取的"操作帮助问答助手"（Help Assistant）功能。
> 该功能已在本地分支 `codex/v3.2-5-help-assistant` 完成移植并通过自动化回归，
> 提交 PR 前请按本清单逐项人工确认。

## 0. 本次改动的范围（审阅前先看 diff）

```text
M app/ChannelSimulatorV3App.m            # +181 行（纯新增，0 删除）
A tests/test_v32_5_help_assistant_ui.m   # 新增无头 UI 回归测试
```

`git diff app/ChannelSimulatorV3App.m` 应只包含 4 处：

1. **属性区**（`ProgressVisible` 之后）：新增 7 个控件属性 `HelpFloatingButton`、
   `HelpPanel`、`HelpHintLabel`、`HelpQuestionList`、`HelpAnswerArea`、
   `HelpCloseButton`、`HelpIsOpen`；
2. **`createComponents`** 末尾：`app.createHelpAssistant(blue, muted);` 一行调用；
3. **`layoutApplication`** 末尾 + 紧随其后的 **7 个新方法**（约 170 行）：
   `createHelpAssistant` / `layoutHelpAssistant` / `toggleHelpAssistant` /
   `refreshHelpQuestions` / `refreshHelpAnswer` / `updateHelpAssistantLanguage` /
   `helpEntries`（10 条中英双语问答数据）；
4. **`switchLanguage`** 末尾：`app.updateHelpAssistantLanguage();` 一行调用。

注意：`helpEntries` 等方法位于文件原有的 `methods (Access = private)` 块内，
这是仓库既有设计（内部方法全部私有），不是缺陷。

## 1. 启动准备

```matlab
close all force
clear classes
rehash

cd("D:\Codex_Feiyi\ChanAI-Pulse-v3.1-7")
addpath(genpath(pwd))
setenv("CHANAI_STEP10_PYTHON", "C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe")
app = ChannelSimulator;
```

预期：窗口正常打开，右下角出现一个蓝色圆形 **"?"** 悬浮按钮。

## 2. A：帮助面板开关（必测）

1. 点击右下角 **"?"** 按钮；
2. 预期：帮助面板在窗口内弹出（标题 `❓ 操作帮助`），按钮文本变为 **"✕"**；
3. 再点一次 **"✕"**（或面板内"✕ 收起"按钮）；
4. 预期：面板收起，按钮恢复为 **"?"**。

## 3. B：问答内容与切换（必测）

1. 打开帮助面板；
2. 预期左侧问题列表有 **10 个中文问题**（如何导入信道数据文件？…如何验证预测结果的准确度？）；
3. 逐一点击前 3 个问题，预期右侧答案区显示对应中文说明；
4. 点第 4 个问题（已知区/目标区），预期答案提到"原始样本编号（推荐）"与
   "MATLAB 数组位置（高级）"。

## 4. C：中英文切换（必测）

1. 保持帮助面板打开；
2. 在顶部把语言切换为 **English**；
3. 预期：面板标题变为 `❓ Operation Help`，问题列表变为英文
   （How do I import a channel data file? …），答案区同步英文；
4. 切回 **中文**，预期恢复中文。

## 5. D：窗口缩放锚定（必测）

1. 打开帮助面板；
2. 拖动窗口改变大小（放大和缩小各一次）；
3. 预期：**"?"/✕** 按钮始终贴在窗口右下角、不越界、不遮挡主要操作区；
4. 帮助面板始终完整位于窗口内。

## 6. E：与既有功能共存（必测）

1. 不打开帮助面板时，原有操作不受影响：
   - 模块一"浏览信道文件…"可用；
   - 任务类型/任务轴下拉框（样本/空间/时间/频率）可切换；
   - 语言切换、普通/高级模式切换正常；
   - 进度条覆盖层（开始任务时）仍能正常显示和收起。
2. 帮助面板与进度条覆盖层不冲突（两者都是 UIFigure 直接子级，靠 `uistack` 置顶）。

## 7. F：回归确认（机器已跑，人工复核可跳过）

以下已在 MATLAB R2024b 全部通过：

- `tests/test_v32_5_help_assistant_ui.m`：8 项断言全 PASS
  （构造、按钮存在、开关、10 问答、答案更新、中英切换、收起、布局锚定）；
- `tests/probe_v32_4_app_import.m`：PASS（三轴 App 导入探针）；
- `tests/run_v32_4_regression.m`：PASS（频率/时间/空间三轴完整预测链、
  频率混合恢复、泄漏安全、经典+神经网络模型、绘图能力）。

## 8. 审阅结论记录

| 检查项 | 结果（PASS / FAIL / 备注） |
|---|---|
| A 帮助面板开关 | |
| B 问答内容与切换 | |
| C 中英文切换 | |
| D 窗口缩放锚定 | |
| E 与既有功能共存 | |
| git diff 仅 4 处、纯新增 | |

审阅人：__________  日期：__________  结论：□ 通过  □ 需修改
