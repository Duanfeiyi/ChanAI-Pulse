# 信道生成模块拆分说明

## 目标

`6GPCM-lite` 是 ChanAI Pulse 内部实现的轻量信道生成内核。它借鉴簇、射线、时延扩展、Rician K 因子、阴影起伏与多普勒等通用建模概念，用于生成**合成参考数据**和扩充训练集；它不是外部 6GPCM 工程的复制版本，也不依赖外部 6GPCM 软件包。

## 数据流

```text
Generation controls
  -> default_6gpcm_lite_config
  -> generate_6gpcm_lite
  -> CIR / delay / cluster parameters / DS samples
  -> generation_result_to_dpsd
  -> existing App augmentation and AI pipeline
```

## 生成参数

| 参数 | 含义 |
| --- | --- |
| `ds_mu`, `ds_sigma` | 对数域 RMS 时延扩展分布参数 |
| `r_ds` | 簇时延扩张比例 |
| `clusters`, `rays` | 簇数与每簇射线数 |
| `lns_ksi_db` | 簇功率阴影起伏 |
| `kf_mu_db`, `kf_sigma_db` | Rician K 因子分布参数 |
| `doppler_hz` | 场景驱动的最大多普勒尺度 |
| `snapshots` | 输出快拍数量 |

## 数据集使用规则

- 输出数据必须标记为 `synthetic_generated`。
- 生成数据可用于训练集扩充或预训练。
- 若研究目标是对真实测量信道的预测能力，验证集和测试集应保持为未见真实数据，不能混入生成数据。
- 任何基于真实数据调参的公开生成参考数据，必须进行脱敏并说明其生成配置；不得包含原始测量快拍、文件名或位置。

## 验收

```matlab
run("tests/test_generation_6gpcm_lite.m")
run("tests/smoke_test.m")
```

人工验收需检查生成页能够生成 CIR、PDP 与 DS CDF，并能将合成数据送入现有 AI pipeline。
