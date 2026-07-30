# Step 9 验收清单

> 当前状态：核心实现、自动验证和项目负责人人工审阅均已通过，已获准提交、push 并创建 PR。

## GitHub

- [x] 创建 [Step 9 Issue #47](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/47)
- [x] 创建独立分支 `codex/v3-step-9-predictor-data`
- [x] 项目负责人人工审阅
- [ ] 人工审阅通过后 commit、push、创建 PR
- [ ] PR 自审
- [ ] 项目负责人最终决定是否合并

## 数据契约

- [x] 支持全部 8 个参数的任意非空子集
- [x] 第一版标准档固定 `DS_mu/KF_mu`
- [x] 参数序列 `[N_parameter_sample,P]`
- [x] 模型输入 `[N_example,N_context,P]`
- [x] 模型标签 `[N_example,N_target,P]`
- [x] 生成器真值、Grid 拟合和 SA 拟合来源
- [x] 拟合分数和 `PASS/WARNING/FAIL`
- [x] 局部窗口 16、步长 4，可配置

## 任务、切分和归一化

- [x] 外推 16→4
- [x] 内插左8+右8→中4
- [x] 禁止跨路线/场景组形成样本
- [x] 默认按组 70/15/15
- [x] 独立组不足时 `WARNING`
- [x] 训练组专属 Z-score
- [x] 验证/测试变化不影响归一化统计
- [x] 反归一化和物理边界投影

## 跨语言和公开样例

- [x] MATLAB HDF5 写入和读取
- [x] Python HDF5 读取
- [x] 单参数 `P=1` 显式形状边界
- [x] 两份确定性合成 HDF5 fixture
- [x] 真实/大型派生数据不进入 Git

## 审阅和文档

- [x] 独立交互 Demo
- [x] Demo 实际运行截图
- [x] 六部分汇总审阅图
- [x] 初学者接口指南
- [x] 科学与数据隔离规则
- [x] 历史预测资产复查
- [x] 项目负责人人工审阅通过

## 明确不在本 Step

- [x] 不训练泛用预测模型
- [x] 不确定微调最低数据阈值
- [x] 不生成预测后 CIR
- [x] 不修改正式三页 UI
- [x] 不修改或复制完整版 6GPCM 核心
