# Step 12 Extra 人工审阅指南

> 审阅目标：大型运行进度、完整中英文界面切换、兼容性审计与 Full 公共接口优先规则。
> 当前阶段：本地实现等待人工审阅；尚未 commit、push 或创建 PR。

## 1. 启动

```matlab
close all force
clear classes
rehash

cd("D:\Codex_Feiyi\ChanAI-Pulse-v3-step12")
ChannelSimulator
```

## 2. 审阅大型运行进度卡片

先选择：

```text
D:\Codex_Feiyi\ChanAI-Pulse-v3-step12\demo_data\v3_standard_fixtures\wideband_static_siso_cir.h5
```

保持“外推—样本—自动80/20”，点击“加载、验证并分析”。

应出现中央的大型“运行进度”卡片。它应至少包含：

- 大号百分比和宽进度条；
- 当前阶段和详细说明；
- 已用时间；
- 完成后可点击“收起进度面板”。

还请把主窗口最大化、还原一次。进度卡片必须始终完整地位于窗口内部：百分比、进度条、详情、已用时间和按钮都不能被底边裁切，也不能跑到窗口外。

输入分析结束后，卡片应显示 100% 和“输入数据已就绪”，而不是停在小百分比且无法关闭。

然后点击“开始预测”。此时卡片应重新开始，并依次出现模块二标定、生成器选择、模块三生成目标 CIR 等阶段。Lite 任务很快完成；这主要用于检查流程可见性。

再用下面文件重复一次：

```text
D:\Codex_Feiyi\ChanAI-Pulse-v3-step12\demo_data\v3_standard_fixtures\wideband_dynamic_mimo_cir.h5
```

预期自动使用 Full 6GPCM public API。它可能需要几十秒；进度卡片应持续显示后端、当前目标编号和已用时间，不应只剩一条细小进度条。

## 3. 审阅中英文切换

在右上角把语言从“中文”改为“English”。不需要重启软件。

至少检查以下内容立即变为英文：

- 三个页签：`Data & Task`、`Run Details`、`Prediction Result`；
- 主要按钮：`Load, validate & analyze`、`Start prediction`、`Run prediction & generate CIR`；
- 大进度卡片：`Run progress`、百分比、阶段、已用时间和 `Hide progress panel`；
- 图表分类：`Overview`、`Delay / Frequency`、`Space / Angle`、`Time / Doppler`；
- 运行完成或失败后的状态提示。

再分别进入三个页签检查一次：模块一的右侧数据摘要和热力图标题、模块二的说明/阶段/Manifest、模块三的参数图图例与 CDF 标题都应为英文。允许保留 `Tx`、`Rx`、`Nt`、`DS_mu`、`KF_mu`、`CIR`、`CTF` 等科学字段，但不应再出现中文提示语或中文图名。

`Tx`、`Rx`、`Nt`、`DS_mu`、`KF_mu`、`CIR`、`CTF` 等科学字段应保持不变。这是为了让界面、导出 Manifest 与论文/代码术语一致。

切回“中文”，上述界面应恢复中文；已加载数据和预测结果不能丢失。

## 4. 审阅兼容性统计报告

在 MATLAB 命令窗口运行：

```matlab
full6gpcmRoot = ...
"D:\Codex_Feiyi\ChanAI-Pulse-v3-step11abc-assets\full6gpcm\source";

audit = audit_platform_compatibility(FullEngineRoot=full6gpcmRoot);
disp(audit.summary_table)
disp(audit.findings)
```

若该 Full 根目录存在，预期：

- `Wideband static MIMO` 与 `Wideband dynamic MIMO` 均为 `PASS`，并显示 `full_6gpcm / public_api`；
- `Manual Lite for MIMO` 与 `Full resource guard` 为 `PASS`，但分类是 `genuine_limit`；
- `audit.summary.fail_count` 为 `0`；
- `audit.summary.time_frequency_target_generation_supported` 为 `false`。这说明平台没有虚假宣称时间轴/频率轴目标生成已完成。

## 5. 审阅结论

以下全部成立即可批准 Step 12 Extra 提交：

1. 长时间运行时，大型进度卡片足够清楚、始终不越界，且完成/失败后能收起。
2. 中英文切换立即生效，三个模块的动态文字、图例与图名都不残留另一种语言，也不影响任务、数据或预测结果。
3. 自动 MIMO 选择 Full public API，未再错误使用固定 2×2×Nt=2 入口。
4. 审计报告将真实限制与平台误判分开，且没有 `FAIL`。
5. 不支持的时间/频率目标生成仍被诚实标记为后续边界。
