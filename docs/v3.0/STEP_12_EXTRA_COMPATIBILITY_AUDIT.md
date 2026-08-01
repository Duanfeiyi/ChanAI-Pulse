# Step 12 Extra：平台兼容性审计说明

## 目的

这次审计专门回答一个容易被忽略的问题：某个信道数据究竟是真的不被生成器支持，还是平台代码中的固定入口、固定维度或回退策略把它误判成了“不兼容”。

审计函数为：

```matlab
audit = audit_platform_compatibility(FullEngineRoot=full6gpcmRoot);
disp(audit.summary_table)
```

它只读取平台代码与生成器可用性，不生成信道、不改写外部 Full 6GPCM 核心，也不读取目标区域真值。

## 审计的六项标准情形

| 情形 | 预期结论 | 含义 |
|---|---|---|
| 窄带静态 SISO | Lite | 合法的单天线任务应正常进入 Lite。 |
| 宽带静态 SISO | Lite | 宽带 SISO 不应被误送到 Full。 |
| 宽带静态 MIMO（2×4×Nt=1） | Full public API | Lite 被拒绝是正常的；Full 应自动接手。 |
| 宽带动态 MIMO（2×4×Nt=16） | Full public API | Full 应保持 Tx、Rx、Nt，不得缩维。 |
| 手动指定 Lite 处理 MIMO | 明确拒绝 | 尊重高级用户选择，不能偷偷改用 Full。 |
| 超出 Full 资源保护边界 | 明确拒绝 | 这是工程资源保护，不是格式不兼容。 |

## 本次修正的关键规则

Full 6GPCM 现在有两种入口：

1. `public_api`：可配置 Tx、Rx、Nt，是正式自动流程优先使用的入口。
2. `fixed_entrypoint`：历史 2×2×Nt=2 示例入口，仅在公共接口缺失、且请求恰好是该尺寸时作最后回退。

因此，历史固定入口不再决定“Full 是否兼容”。它只是保证旧外部包在自己的精确范围内仍可运行。

## 审计状态的阅读方式

- `verified_compatible`：已验证平台会选到正确正式后端。
- `genuine_limit`：平台明确拒绝是正确的，例如 Lite 不能生成 MIMO，或任务超过资源上限。
- `environment_unavailable`：本机没有提供 Full 公共 API 根目录；不是数据维度问题。
- `possible_false_rejection`：这是需要修复的风险项；自动测试会失败。
- `planned_boundary`：功能边界已如实记录，但不能误称为兼容。

## 当前仍保留的真实边界

样本轴和位置轴已完成正式“目标参数 → 目标 CIR”流程。时间轴、频率轴可以导入、验证和画输入特性图，但尚未支持在 `Nt` 或 `Nf` 内部指定目标区并端到端生成预测 CIR。该项被审计标记为 `planned_boundary`，不会伪装为生成器不兼容，也不会伪装为已完成。
