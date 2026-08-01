# Step 11 验收清单

> 当前状态：实现、静态检查、MATLAB/Python 全回归、真实 Full 调用和 Demo 均已完成；等待项目负责人 PR 前人工审阅。

## GitHub

- [x] Issue #52 已建立
- [x] 独立分支 `codex/v3-step-11-predicted-cir`
- [ ] 项目负责人人工审阅通过
- [ ] 提交并 push
- [ ] 创建 PR
- [ ] 项目负责人手动合并 PR

## 端到端链路

- [x] Step 10 预测结果转换为 Step 11 请求
- [x] 首版直接预测 `DS_mu/KF_mu`
- [x] 其他参数按标定、场景、版本默认值补齐
- [x] 参数逐项来源追踪
- [x] 四目标逐点确定性种子
- [x] 四目标逐次生成并按原顺序合并
- [x] 复数 CIR 和 delay
- [x] 显式频率轴 CTF
- [x] 统一 `PredictionResult`

## 严格性

- [x] 参数类型、范围、整数和有限值校验
- [x] 正式模式仅允许 Full
- [x] Full 失败不静默降级
- [x] 维度不支持时明确失败
- [x] 单目标失败不发布部分 CIR
- [x] 取消不发布部分 CIR
- [x] 目标位置未注入被如实记录
- [x] 独立目标连续性限制
- [x] Full 单体调用中途不可取消的限制有文档

## 后端与验证

- [x] Mock 已知答案和错误路径
- [x] Lite 可重复集成
- [x] Full 测试替身
- [x] 真实外置 Full 四目标正式链路
- [x] 真实 Full 核心调用前后哈希不变
- [x] CIR/CTF/JSON/Manifest 导出
- [x] MATLAB Code Analyzer 0 条提示
- [x] MATLAB Step 1～11 全回归通过
- [x] Python 18 项测试通过

## 模块三 Demo

- [x] 复用正式模块三页面风格
- [x] 普通用户自动选模型
- [x] 高级用户手选模型
- [x] `off/auto/force` 适配入口
- [x] 显示实际模型和 `DIRECT/ADAPTED`
- [x] 真实预测参数和真实生成 CIR
- [x] 与模块一共用特性引擎和图表注册表
- [x] 只显示合法图
- [x] 不显示 Ground Truth 或准确度
- [x] 可导出结果和页面截图

## 明确不在 Step 11

- [x] 不增加新的预测参数目标
- [x] 不把当前参考模型当作精度合格模型
- [x] 不完成 Step 11A/B/C
- [x] 不把 Demo 直接接入三页正式 App（等待 Step 12）
- [x] 不自动合并任何 PR
