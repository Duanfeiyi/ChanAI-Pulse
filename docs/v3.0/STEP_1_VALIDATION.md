# Step 1 验证记录

> 验证日期：2026-07-28
>
> 分支：`codex/v3-step-1-data-contract`
>
> 状态：实现、验证、项目负责人审阅和 PR 合并均已完成。

## 1. 验证环境

- MATLAB：R2024b Update 1；
- Python：3.13.12；
- NumPy：2.5.1；
- h5py：3.16.0；
- Python 依赖安装在独立临时虚拟环境中，没有修改系统 Python。

Step 1 运行时只依赖：

```text
numpy>=2.0
h5py>=3.12
```

MATLAB 侧使用自带的 `h5create`、`h5write`、`h5read`，不要求安装新的
第三方 MATLAB 工具箱。

## 2. 已执行的检查

| 检查 | 结果 | 说明 |
|---|---|---|
| MATLAB 数据契约测试 | PASS | CTF、路径 CIR、维度、单位、坐标轴和错误输入 |
| MATLAB 任务契约测试 | PASS | 内插、外推、重叠目标和越界目标 |
| MATLAB 能力判断测试 | PASS | 根据维度、坐标轴和角度/多普勒字段判断可用特性 |
| MATLAB HDF5 往返 | PASS | CTF 和 CIR 写出后读回，形状与复数值不变 |
| Python 单元测试 | PASS | Python 恢复复数 CTF/CIR 五维数组，同时保留坐标表原始维度 |
| MATLAB → Python 集成 | PASS | `2 × 1 × 3 × 2 × 4` 的复数数据和二维位置坐标无损读取 |
| MATLAB Code Analyzer | PASS | Step 1 新增 MATLAB 文件无规范消息 |
| 现有数据契约回归 | PASS | `tests/test_dataset_contract.m` 未被新标准破坏 |
| Git 空白与冲突标记检查 | PASS | `git diff --check` 通过 |

## 3. 主要验证命令

MATLAB 新旧测试：

```matlab
addpath("core/contracts");
run("tests/test_v3_data_contract.m");
run("tests/test_dataset_contract.m");
```

Python 语法和单元测试：

```powershell
python -m py_compile tools/python/read_channel_hdf5.py `
    tests/python/test_channel_hdf5_reader.py
python -m unittest -v tests.python.test_channel_hdf5_reader
```

跨语言测试先由 MATLAB 执行
`examples/write_v3_ctf_hdf5_example.m`，再由 Python
`read_channel_hdf5` 读取，并逐项检查：

1. 形状仍为 `2 × 1 × 3 × 2 × 4`；
2. 实部数值不变；
3. 虚部数值不变；
4. 顺序仍为 MATLAB 的列优先顺序；
5. `N_sample × 2` 的位置坐标仍为二维表。

测试生成的 HDF5 临时文件已删除。

## 4. 验证中发现并修复的问题

MATLAB 把保存维度的向量写成二维列向量，而 Python 最初只按一维数组读取。
这会让 Python 恢复形状时出错。

修复后，Python 会先按 MATLAB 列优先顺序把维度数据展平，再重建五维数组。
对应行为已经加入 Python 回归测试，避免以后重新出现。

## 5. 项目流程结果

- 项目负责人已审阅 Step 1 成果；
- [PR #25](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/25)
  已合并到 `main`；
- [Issue #24](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/24)
  已关闭；
- [Roadmap #21](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/21)
  的 Step 1 已勾选。

Step 1 的实现、测试、文档、需求追踪、审阅和合并流程均已完成。
