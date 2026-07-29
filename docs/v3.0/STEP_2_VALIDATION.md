# Step 2 验证记录

> 验证日期：2026-07-29

## MATLAB

```text
PASS: four deterministic v3 standard CIR/CTF fixture pairs.
PASS: v3 CIR/CTF data, task, capability, and HDF5 contracts.
```

覆盖：

- 四类尺寸和重复生成；
- CIR→CTF一致性；
- 1/3/6/9能力；
- 窄带单路径边界；
- 八个HDF5往返；
- Step 1回归。

## Python

```text
Ran 4 tests
OK
```

覆盖：

- Step 1 HDF5读取器；
- 四类Python生成；
- 文件哈希重复；
- CIR/CTF形状和路线坐标；
- HDF5元数据。

## MATLAB→Python

```text
PASS: MATLAB exports match the Python Step 2 reference values.
```

比较字段：

- 复数CIR系数；
- 路径时延；
- 复数CTF；
- 路线位置。

## QuaDRiGa外部适配

外部版本：

```text
QuaDRiGa 2.8.1-0
commit 277866650eb115adb5b3e8ac252b0d1df073596d
```

验证输出：

```text
CIR: 2 × 4 × 58 × 1 × 32
CTF: 2 × 4 × 64 × 1 × 32
QUADRIGA_STEP2_OK
```

第三方代码只位于临时外部checkout，未复制进项目，也未修改。

## 尚未完成

- PR前人工可视化审阅；
- PR创建、自审和合并；
- 合并后的Issue/Roadmap收尾。
