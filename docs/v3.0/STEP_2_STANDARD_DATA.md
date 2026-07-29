# Step 2 四套标准信道数据说明

## 1. 本步骤解决什么问题

Step 1规定了数据格式，Step 2把格式变成可运行的固定测试材料：

```text
场景配置
  → 确定性路径参数
  → 复数路径域CIR
  → 同一CIR推导频域CTF
  → HDF5
  → MATLAB/Python读取和能力分级
```

“确定性”表示同一配置重复运行时，数值和输出文件哈希保持一致。它检查软件稳定性，不表示数据是真实测量或科学标准答案。

## 2. 冻结配置

| 场景 | Tx | Rx | Nf | Nt | N_sample | Npath | 预期标准图 |
|---|---:|---:|---:|---:|---:|---:|---:|
| 窄带静态SISO | 1 | 1 | 1 | 1 | 32 | 1 | 1 |
| 宽带静态SISO | 1 | 1 | 64 | 1 | 32 | 4 | 3 |
| 宽带静态MIMO | 2 | 4 | 64 | 1 | 32 | 6 | 6 |
| 宽带动态MIMO | 2 | 4 | 64 | 16 | 32 | 6 | 9 |

数据顺序不变：

```text
CTF：Tx × Rx × Nf × Nt × N_sample
CIR：Tx × Rx × Npath × Nt × N_sample
```

`Nt`是一处样本内部的连续时间快照；`N_sample`是32个有序路线位置。

## 3. 图表能力规则

- 窄带静态SISO：功率。
- 宽带静态SISO：PDP、频率自相关、时延扩展CDF。
- 宽带静态MIMO：再增加角度功率谱、空间相关、角度扩展CDF。
- 宽带动态MIMO：再增加多普勒功率谱、时间自相关、多普勒扩展CDF。
- 路线—时延热力图只在“宽带+有序样本”时作为附加图，不计入1/3/6/9。

Step 2的图片是数据质量预览；正式科学计算和平台绘图仍在Step 5实现。

## 4. 可重复性设计

- 固定四个场景种子；
- 固定创建时间字段，避免时间戳造成文件变化；
- MATLAB和Python共享同一JSON配置；
- 初始相位使用跨语言显式公式，不依赖两种语言不同的随机数实现；
- 复数值以`float32 real + float32 imag`保存；
- HDF5继续使用Step 1规定的MATLAB列优先展开顺序。

## 5. 文件

- 配置：`configs/v3_standard_scenarios.json`
- MATLAB生成：`core/fixtures/generate_v3_standard_pair.m`
- Python生成：`tools/python/generate_v3_standard_fixtures.py`
- CIR→CTF：`core/fixtures/cir_to_ctf.m`
- 标准数据：`demo_data/v3_standard_fixtures/`
- MATLAB测试：`tests/test_v3_standard_fixtures.m`
- Python测试：`tests/python/test_v3_standard_fixtures.py`
- 跨语言验证：`tests/python/verify_v3_matlab_exports.py`
- 可视化审阅：`docs/v3.0/STEP_2_VISUAL_REVIEW.md`

## 6. QuaDRiGa补充示例

外部QuaDRiGa只作为专业生成器适配验证，不替代四套标准答案。项目不复制、不修改其核心，只读取`qd_channel.coeff/delay`并转换维度。详见：

- [可选QuaDRiGa接入示例](QUADRIGA_OPTIONAL_EXAMPLE.md)

完整版6GPCM仍由Step 3验证，不能用QuaDRiGa示例代替。
