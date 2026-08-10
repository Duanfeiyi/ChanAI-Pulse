# Step 14 发布检查与冻结边界

## 自动检查

- [x] MAT v7/v7.3 复数值、维度和单位往返一致；
- [x] v7.3 强制分块读取与普通读取结果一致；
- [x] HDF5 分块写入可被 MATLAB 重新读取；
- [x] 实部/虚部配对正确；
- [x] 模糊维度需要显式映射；
- [x] power-only 数据被诚实拒绝；
- [x] SAGE 与旧 WiFo 专用 Adapter 经统一调度器工作；
- [x] 源文件/文件夹哈希在转换前后不变；
- [x] 已存在 H5 或 Manifest 不会被覆盖；
- [x] 正式 UI、MAT 向导、中英文入口和填充式进度合同通过不可见测试；
- [x] Step 12 四类 1/3/6/9 图与生成器选择回归通过；
- [x] Step 13 Benchmark 聚焦回归通过；
- [x] Step 1–11 完整累计回归（含真实外置 Full 6GPCM 与 Python Predictor Adapter）；
- [x] Python HDF5/Predictor 全部 19 项单元测试；
- [x] `git diff --check` 与仓库绝对路径、密钥、私有数据、外部 Full 核心扫描。

## 人工检查

> 项目负责人已于 2026-08-09 确认整体人工验收通过；下列项目据该验收记录冻结。

- [x] 标准 H5 直接加载；
- [x] 自动 MAT 转换并回到模块一；
- [x] 手动维度映射；
- [x] power-only 拒绝；
- [x] SAGE 文件夹转换；
- [x] 横向进度条比例、状态色、窗口缩放；
- [x] 主平台和 MAT 向导中文/English；
- [x] 完整内插和外推；
- [x] CIR/CTF/Manifest 导出；
- [x] `ChannelBenchmark` 严格对齐和报告导出。

人工步骤见 [STEP_14_MANUAL_REVIEW_GUIDE.md](STEP_14_MANUAL_REVIEW_GUIDE.md)。

## v3.0 冻结内容

- `ChannelDataset`、任务、生成、预测结果、Benchmark 和 MAT 转换合同；
- 模块一/模块三共用的图表能力矩阵；
- Grid/SA 自动选择与高级覆盖逻辑；
- Lite/Full 6GPCM Adapter 兼容性选择；
- P6/P8 Persistence 产品注册表；
- 预测端不读取目标 Ground Truth；
- 独立 Benchmark 准确度评估边界。

## PR #62 合并后、v3.0.0 Tag 前的最后动作

PR #62 已于 2026-08-09 由项目负责人手动合并，合并提交为
`d74157e86e59238c6345418439e922a687bc44ce`。2026-08-10 的干净 worktree 预检已成功生成
Manifest，记录 `git_dirty=false` 和该 revision；该预检产物位于 Git 忽略的 `review_data/`，
不能代替最终发布基线。

1. [x] 项目负责人手动合并 Step 14 PR；
2. [x] 在干净 worktree 上运行 `create_v3_release_manifest` 预检，并确认 `git_dirty=false`；
3. [ ] 将本文档收尾状态经独立 PR 由项目负责人手动合并；
4. [ ] 在该 PR 合并后的干净 `main` 上重新运行 `create_v3_release_manifest`，使最终 Manifest 指向最终发布 revision；
5. [ ] 项目负责人决定是否创建 `v3.0.0` Tag/GitHub Release；
6. [ ] 以最终 revision 作为 v3.1-0 唯一正式对照组。
