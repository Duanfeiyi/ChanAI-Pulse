# Step 14 人工审阅指南

> 验收状态：项目负责人已完成人工验收并允许提交、push 和创建 PR。本文保留为可复现的验收操作记录。

## 1. 准备样例并启动正式平台

在 MATLAB 中完整复制：

```matlab
close all force
clear classes
rehash

cd("D:\Codex_Feiyi\ChanAI-Pulse-v3-step13")
addpath(genpath(pwd))
paths = prepare_step14_review_data();
app = ChannelSimulator;
```

唯一正式入口仍是 `ChannelSimulator.m`。MAT 向导是模块一中的正式功能，不是另一个临时 Demo。

## 2. 审阅 A：标准 H5 仍能直接加载

1. 点击“浏览信道文件…”；
2. 选择命令窗口显示的 `paths.direct_standard_h5`；
3. 点击“加载、验证并分析”；
4. 确认仍显示宽带动态 MIMO 的 `9+1` 图表能力；
5. 确认不会强制进入 MAT 向导。

意义：Step 14 不能破坏原有标准 H5 工作流。

## 3. 审阅 B：可自动识别的 MAT

1. 点击“MAT 数据转换向导…”；
2. 在第 1 页选择文件 `paths.auto_ctf_mat`；
3. 检查报告应为 `PASS`，变量表中 `H` 为复数，建议域为 CTF；
4. 第 2 页应自动填写：`H`、`Tx,Rx,Nf,Nt,N_sample`、频率/时间/样本/位置轴；
5. 第 3 页选择一个**不存在的新文件名**，点击“转换为标准 v3 H5 并自动加载”；
6. 观察横向填充进度条；成功时变为绿色 100%；
7. 转换成功后主平台应自动加载新 H5，并显示与维度相符的能力。

意义：验证普通用户的主要 MAT 工作流，以及转换后自动回到模块一。

## 4. 审阅 C：需要用户确认的 MAT

选择 `paths.manual_cir_mat`。它故意把数组保存成不常见顺序，软件应显示 `NEEDS_MAPPING`，不能悄悄猜测。

在第 2 页填写：

- 数据域：CIR；
- 复数变量：`cir_payload`；
- 源维度顺序：`N_sample,Npath,Rx,Tx`；
- 时延轴变量：`delay_ns`；
- 时延单位：`ns`；
- 勾选“我已确认……”；
- 点击“验证当前映射”，再到第 3 页转换。

意义：验证未知 MAT 的安全边界。正确行为是“让用户明确”，不是“软件自信猜错”。

## 5. 审阅 D：功率-only 数据应被拒绝

选择 `paths.power_only_mat`。应看到：

- 分类为 power-only；
- 明确说明缺少相位，不能重建完整复数 CIR；
- 不允许发布成可供预测使用的标准 CIR/CTF。

意义：防止平台输出看似完整、实际物理信息不真实的数据。

## 6. 审阅 E：已知 SAGE 文件夹

1. 在向导第 1 页点击“选择 SAGE 文件夹…”；
2. 选择 `paths.sage_folder`；
3. 应识别为 `sage_folder`；
4. 在“时延间隔（秒）”填写 `1e-9`；
5. 另存并转换。

意义：确认没有重复发明 SAGE 解析，而是复用已有专用 Adapter。

## 7. 审阅 F：进度条与中英文

1. 主平台长任务和 MAT 转换均应为横向填充式读条，不再显示指针/刻度尺；
2. 进度卡不得超出主窗口；
3. 在主平台和 MAT 向导分别切换中文/English；
4. 按钮、步骤标题、提示和表头不应残留明显中文；科学标识 `Tx/Rx/Nt/CIR/CTF` 保持不变是正常的。

## 8. 建议给我的验收反馈

请按以下格式回复即可：

```text
A 标准 H5：通过/不通过
B 自动 MAT：通过/不通过
C 手动映射：通过/不通过
D power-only 拒绝：通过/不通过
E SAGE 文件夹：通过/不通过
F 进度条与中英文：通过/不通过
其他现象：……
```
