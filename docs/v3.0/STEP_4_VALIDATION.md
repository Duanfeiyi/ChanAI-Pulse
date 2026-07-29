# Step 4 验证记录

## 1. 环境

- MATLAB：R2024b，无界面 batch；
- Python：3.13 临时隔离环境；
- NumPy：2.5.1；
- h5py：3.16.0；
- matplotlib：3.11.1。

临时 Python 环境位于系统临时目录，不修改全局 Python，也不进入仓库。

## 2. MATLAB 专项测试

```text
PASS: Step 4 input pipeline, task presets, and legacy adapters.
```

覆盖：

- 标准 CTF HDF5；
- 80/20 内插；
- 手动 frequency 外推；
- 未设置任务 WARNING；
- DPSD MAT 拒绝；
- 原始 WiFo FAIL；
- WiFo 转换后 PASS；
- SAGE 自然排序和 CIR 合并；
- 缺少时延定义拒绝；
- 不具备 time 维度时任务 FAIL。

## 3. Step 1～4 回归

```text
PASS: v3 CIR/CTF data, task, capability, and HDF5 contracts.
PASS: four deterministic v3 standard CIR/CTF fixture pairs.
PASS: Step 3 full 6GPCM probe contract and error paths.
PASS: Step 4 input pipeline, task presets, and legacy adapters.
PASS: Step 1-4 regression suite.
```

Step 3 回归使用项目自有测试替身，不修改或重新打包完整版第三方 6GPCM 核心。

## 4. Python 回归

```text
Ran 5 tests
OK
```

覆盖 Python HDF5 读取、CIR/CTF 五维结构、标准 fixture 重复性和文件哈希。

## 5. MATLAB→Python 实际转换读取

MATLAB 把真实旧 WiFo `3D_CSI_01.h5` 转成临时 v3 CIR，Python 返回：

```json
{
  "schema_version": "v3.0-data-contract.1",
  "domain": "cir",
  "dimension_order": ["Tx", "Rx", "Npath", "Nt", "N_sample"],
  "shape": [16, 4, 8, 1, 1000],
  "source": "legacy_wifo:3D_CSI_01.h5"
}
```

临时 HDF5 已删除。

## 6. 真实横向道路技术验证

横向道路1全部 337 个 SAGE 文件只读转换并重新导入：

```text
REAL_SAGE
status=PASS
Tx=1
Rx=16
Npath=683
Nt=1
Nsample=337
files=337
```

测试输出位于系统临时目录并已删除。200 MHz 只用于结构技术验证，正式物理参数仍待确认。

## 7. 真实 WiFo 技术验证

```text
REAL_WIFO
before=FAIL
after=PASS
Tx=16
Rx=4
Npath=8
Nt=1
Nsample=1000
```

## 8. Demo

```text
PASS: Step 4 standalone demo smoke test.
PASS: sanitized Step 4 review screenshot generated.
```

截图只显示文件名，不包含本机绝对路径或真实测量数据。

## 9. 合并依赖后的提交前复验

PR #31 合并后，Step 4 分支已快进到最新 `main`，并重新执行：

```text
PASS: v3 CIR/CTF data, task, capability, and HDF5 contracts.
PASS: four deterministic v3 standard CIR/CTF fixture pairs.
PASS: Step 3 full 6GPCM probe contract and error paths.
PASS: Step 4 input pipeline, task presets, and legacy adapters.
PASS: Step 1-4 post-main-sync regression suite.
PASS: Step 4 post-main-sync demo smoke test.
```

## 10. Draft PR 自审

- PR：[Draft PR #33](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/33)
- 基线：`main`
- 状态：`OPEN / DRAFT / MERGEABLE`
- 差异：18 个文件，2332 行新增，6 行删除
- MATLAB Code Analyzer：`CHECKCODE_MESSAGES=0`
- 本机绝对路径扫描：未发现
- 私有测量数据和人工审阅 HDF5：未进入 Git
- GitHub 自动检查：仓库未为该分支报告 checks，不是测试失败
- 自审结论：未发现阻止合并的问题

## 11. 尚未完成

- 项目负责人最终批准合并。
