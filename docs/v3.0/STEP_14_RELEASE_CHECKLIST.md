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

- [ ] 标准 H5 直接加载；
- [ ] 自动 MAT 转换并回到模块一；
- [ ] 手动维度映射；
- [ ] power-only 拒绝；
- [ ] SAGE 文件夹转换；
- [ ] 横向进度条比例、状态色、窗口缩放；
- [ ] 主平台和 MAT 向导中文/English；
- [ ] 完整内插和外推；
- [ ] CIR/CTF/Manifest 导出；
- [ ] `ChannelBenchmark` 严格对齐和报告导出。

人工步骤见 [STEP_14_MANUAL_REVIEW_GUIDE.md](STEP_14_MANUAL_REVIEW_GUIDE.md)。

## v3.0 冻结内容

- `ChannelDataset`、任务、生成、预测结果、Benchmark 和 MAT 转换合同；
- 模块一/模块三共用的图表能力矩阵；
- Grid/SA 自动选择与高级覆盖逻辑；
- Lite/Full 6GPCM Adapter 兼容性选择；
- P6/P8 Persistence 产品注册表；
- 预测端不读取目标 Ground Truth；
- 独立 Benchmark 准确度评估边界。

## 合并后才能完成的最后动作

以下内容现在不能伪装成已完成：

1. 由项目负责人手动合并 Step 14 PR；
2. 在干净 `main` 上重新运行 `create_v3_release_manifest`；
3. 确认 Manifest 中 `git_dirty=false` 且 revision 为合并提交；
4. 项目负责人决定是否创建 `v3.0.0` Tag/GitHub Release；
5. 以该 revision 作为 v3.1-0 唯一正式对照组。
