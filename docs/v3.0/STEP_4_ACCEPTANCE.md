# Step 4 验收清单

> 当前状态：核心输入流水线、SAGE/WiFo Adapter、独立 Demo、回归测试、人工审阅、提交和 PR 自审均已完成。后续 UI 自动编号换算已登记，等待项目负责人决定是否合并 PR #33。

## GitHub

- [x] 创建 [Step 4 Issue #32](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/32)
- [x] 创建独立分支 `codex/v3-step-4-input-pipeline`
- [x] PR #31 合并后同步最新 `main`

## 正式输入流水线

- [x] 正式输入只接受一个 v3 `.h5`
- [x] CIR 和 CTF 均可读取
- [x] 原文件只读
- [x] 保留复数值和五维结构
- [x] 返回 `dataset/task/validation/capabilities/provenance`
- [x] PASS/WARNING/FAIL 汇总
- [x] 缺少任务时返回 WARNING

## 任务

- [x] interpolation
- [x] extrapolation
- [x] sample
- [x] position
- [x] time
- [x] frequency
- [x] 手动索引
- [x] 80/20 内插预设
- [x] 80/20 外推预设
- [x] 调用 Step 1 任务验证器

## 错误分类

- [x] 文件不存在
- [x] 非 `.h5`
- [x] 非法 HDF5
- [x] 非 v3 HDF5
- [x] 旧 WiFo HDF5
- [x] SAGE MAT
- [x] DPSD/PDP 功率特征
- [x] 训练输入输出与预测结果
- [x] 不完整 CIR/CTF payload

## 旧数据转换

- [x] SAGE 文件夹自然排序
- [x] 指定 record
- [x] 固定 CIR tap grid 合并为 N_sample
- [x] 必须明确带宽或时延间隔
- [x] 不猜测 SAGE angle/path 参数
- [x] WiFo `real/imag/delay/doppler` 转 v3 CIR
- [x] 必须明确 WiFo 第四维是 sample 或 time
- [x] 不覆盖已存在输出

## 真实数据技术验证

- [x] 横向道路1全部 337 个文件只读转换
- [x] 转换尺寸 `1×16×683×1×337`
- [x] 使用 200 MHz 技术假设，不宣称物理定标完成
- [x] 原始 WiFo `3D_CSI_01.h5` 返回 FAIL
- [x] WiFo 转换后返回 PASS
- [x] WiFo 转换尺寸 `16×4×8×1×1000`
- [x] 临时输出已删除

## Demo

- [x] 与正式 `ChannelSimulatorApp` 隔离
- [x] 文件选择
- [x] 任务类型和方向
- [x] 快速预设和手动索引
- [x] 状态与错误显示
- [x] 五维摘要
- [x] 能力表
- [x] 已知区/目标区示意图
- [x] 隐藏窗口冒烟测试

## 自动与人工验收

- [x] Step 4 专项自动测试
- [x] Step 1～3 相关回归
- [x] Python 读取验证
- [x] 生成 Demo 审阅截图
- [x] 生成人工审阅 HDF5 包（不进入 Git）
- [x] 项目负责人人工审阅
- [x] 将正式 UI 自动编号/坐标换算登记为 [UI-TODO-001](UI_DEFERRED_TODOS.md#ui-todo-001任务区间编号与真实坐标自动换算)
- [x] 人工审阅通过后提交和 push
- [x] 创建 [Draft PR #33](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/33)
- [x] PR 自审
- [ ] 项目负责人最终决定合并
