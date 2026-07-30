# Step 8 Demo 与人工审阅说明

## 1. 怎样打开

在 MATLAB 仓库根目录执行：

```matlab
addpath("examples");
step8_optimizer_demo
```

默认使用 6GPCM-lite，界面会实际运行 Grid、Random Greedy 和 SA。

## 2. 推荐审阅顺序

### A. 自动选择

保持默认：

```text
后端：6GPCM-lite
请求策略：自动
离散组合：8
```

应看到实际选择 `GRID (auto)`，理由说明 8 组不超过 Lite 自动上限 125。

### B. 手动 SA

把请求策略改成“手动 SA”，重新运行。

应看到：

- 实际选择 `SA (manual)`；
- 分数图按提案序号变化；
- 温度总体下降；
- 接受率在 0～1；
- “接受较差”可以大于 0，这不是错误，而是 SA 的设计。

### C. 三算法对照

右侧表格的三行来自同一目标、同一生成器种子：

- Grid 完整评估全部 8 组；
- Random Greedy 不接受较差移动；
- SA 允许按概率接受较差移动；
- 最佳分数越小越好；
- 实际评估次数可能少于提案数，因为重复候选使用缓存。

小型确定性 Demo 中三者都找到 0 分是合格结果，说明候选中包含标准答案；
这不表示现实测量数据也一定得到 0。

### D. PDP 与时延扩展

左下是目标 known 与选中策略最佳 CIR 的 PDP，横轴为时延；中下是 RMS 时延扩展
分位曲线。两条线越接近，当前两项拟合距离越小。

这些是模块二解释参数拟合的图，不是模块三预测准确率图。

### E. Full 6GPCM

配置外置路径后选择 Full。默认只使用两个 DS 候选，避免人工审阅耗时过长。

应确认：

- 明确显示 Full 后端，不静默退回 Lite；
- 能产生最佳结果；
- Manifest 中不出现本机外置路径；
- 保留候选报告 `core_unchanged=true`。

## 3. 反例

- 手动 Grid 配连续区间：必须提前拒绝；
- 手动 Grid 超过 500 组：必须提前拒绝；
- 路径错误的 Full：必须 `FAIL`；
- 取消：必须 `CANCELLED`，不能显示正式结果；
- 非法边界或非整数簇数：必须在生成前失败。

## 4. 已生成审阅图

```text
docs/v3.0/review_assets/step8/step8_optimizer_demo.png
docs/v3.0/review_assets/step8/step8_optimizer_review.png
```

两张图均由 MATLAB 实际执行算法后导出。

## 5. 人工通过代表什么

通过表示：

- 模块二拥有 Grid 和 SA 两种正式拟合方法；
- 自动选择和手动覆盖规则可解释；
- Random Greedy 对照、缓存、停止和可视化可用；
- Mock、Lite、Full 共用同一科学链路。

不表示模块三预测模型、预测后 CIR 或正式三页 UI 已完成。
