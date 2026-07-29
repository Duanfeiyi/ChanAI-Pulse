# v3.0 Step 2 标准信道数据

这里保存四套小型、确定性、非测量的 CIR/CTF 测试数据。

| 场景 | CTF形状 | CIR形状 | 标准图能力 |
|---|---|---|---:|
| 窄带静态SISO | `1×1×1×1×32` | `1×1×1×1×32` | 1 |
| 宽带静态SISO | `1×1×64×1×32` | `1×1×4×1×32` | 3 |
| 宽带静态MIMO | `2×4×64×1×32` | `2×4×6×1×32` | 6 |
| 宽带动态MIMO | `2×4×64×16×32` | `2×4×6×16×32` | 9 |

`N_sample=32`均表示32个有序路线位置。后三套宽带数据支持附加的路线—时延热力图；窄带数据没有可分辨时延轴，因此不提供该热力图。

这些数据只用于：

- 数据协议和导入测试；
- CIR→CTF一致性测试；
- MATLAB/Python交换测试；
- 1/3/6/9能力分级测试；
- 后续模块回归测试。

它们不是测量数据，不证明6GPCM、预测器或平台的科学准确度。

配置来源：

```text
configs/v3_standard_scenarios.json
```

Python重新生成：

```powershell
python tools/python/generate_v3_standard_fixtures.py
```

MATLAB重新生成到一个新的空目录：

```matlab
addpath(genpath("core"));
write_v3_standard_fixtures("新的输出目录");
```

生成器拒绝覆盖已有文件，防止误改审阅基线。
