# ChanAIs Dataset 初步规划

## 1. 数据集定位

ChanAIs Dataset 计划作为 ChanAI Pulse 平台的长期数据生态基础，用于支撑无线信道特性分析、信道生成、AI 预测、Benchmark 对比和跨场景泛化研究。

它不是当前 GitHub 仓库中的 demo 数据，也不是未经处理的真实测量原始数据。未来如果公开，ChanAIs Dataset 应作为独立、授权、脱敏、版本化的数据集项目进行维护。

## 2. 为什么需要数据集生态

ChanAI Pulse 的长期目标不是只提供一个 MATLAB App，而是形成“数据、模型、指标、任务、报告”互相连接的研究平台。稳定的数据集生态可以带来：

- 可复现实验；
- 不同算法之间的公平比较；
- 跨频段、跨场景的泛化验证；
- 生成模型和预测模型的统一评估；
- 面向论文、竞赛和企业合作的标准化实验入口。

## 3. 当前真实数据不公开的原因

当前本地真实测量数据不进入 GitHub，原因包括：

- 可能包含采集地点、设备参数、时间、人员或项目相关元信息；
- 可能涉及实验室、学校、合作单位或设备授权；
- 数据格式尚未统一，直接公开会造成误用；
- 未完成脱敏、授权、版本管理和引用说明；
- 数据规模可能较大，不适合直接放入源码仓库。

因此，当前 GitHub 只公开 synthetic demo data，用于软件加载和界面测试，不作为正式 benchmark 数据。

## 4. 数据脱敏流程

未来公开数据前，建议至少经过以下流程：

1. 权属确认：确认数据采集者、实验室、合作方和资助项目是否允许公开。
2. 元信息审查：删除或泛化采集地点、人员、设备序列号、精确时间等敏感信息。
3. 文件结构清理：去除临时文件、缓存文件、原始未整理脚本和私人路径。
4. 变量审查：检查 `.mat` 文件中是否包含非公开备注、内部路径或实验记录。
5. 数据降采样：必要时发布小规模公开版本，完整版本通过单独申请方式提供。
6. 文档配套：提供数据来源、变量解释、使用限制和引用方式。
7. 版本冻结：为每次公开发布标记明确版本号。

## 5. 数据格式规范草案

建议未来公开数据采用统一 schema。每个数据样本至少包含：

```text
scenario
frequency_band
center_frequency
bandwidth
antenna_configuration
measurement_setup
CIR
CTF
PDP
Doppler
metadata
license
version
```

字段含义：

- `scenario`：场景名称，例如 indoor, urban, UAV, maritime, RIS, industrial IoT。
- `frequency_band`：Sub-6, mmWave, THz, optical wireless 等。
- `center_frequency`：中心频率。
- `bandwidth`：测量或仿真带宽。
- `antenna_configuration`：天线数量、阵列形式、极化方式等。
- `measurement_setup`：采样间隔、设备类型、运动方式等公开可说明信息。
- `CIR`：Channel Impulse Response，时域信道冲激响应。
- `CTF`：Channel Transfer Function，频域信道传输函数。
- `PDP`：Power Delay Profile，功率时延谱。
- `Doppler`：多普勒相关谱或统计量。
- `metadata`：非敏感元数据。
- `license`：数据使用协议。
- `version`：数据集版本号。

## 6. 数据版本管理

建议采用独立版本体系：

- `ChanAIs-mini`：公开小样本，用于教学和快速 demo。
- `ChanAIs-benchmark`：固定 benchmark 子集，用于论文和模型对比。
- `ChanAIs-full`：完整数据集，可能需要申请或授权访问。

每个版本需要保存：

- 数据文件；
- schema 说明；
- 数据划分；
- baseline 结果；
- metrics 定义；
- changelog；
- citation 信息。

## 7. Benchmark 支撑作用

ChanAIs Dataset 应服务于 benchmark 任务，而不是只作为文件仓库。建议支持：

- 信道特性分析准确性；
- 生成数据与真实统计特性的匹配；
- 信道预测精度；
- 缺失信道补全；
- 跨场景泛化；
- 推理延迟和训练成本评估。

## 8. 长期规划路线图

短期：

- 保持真实数据本地私有；
- 完善 synthetic demo data；
- 建立统一 schema 草案；
- 明确数据集授权和脱敏流程。

中期：

- 构建 ChanAIs-mini 公开样本；
- 定义 benchmark split；
- 发布 baseline 模型和指标脚本。

长期：

- 建立 ChanAIs Dataset 独立仓库或数据主页；
- 支持更广泛频段和场景；
- 建立可复现 leaderboard；
- 与 ChanAI Pulse App、论文实验和教学材料形成联动。

