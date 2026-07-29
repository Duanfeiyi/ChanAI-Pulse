# Step 2 可选 QuaDRiGa 接入示例

## 定位

四套确定性标准数据负责测试 ChanAI Pulse 自己的软件接口。QuaDRiGa 示例负责证明：

```text
外部专业生成器
    → 不修改核心
    → 转换 Tx/Rx 维度顺序
    → ChanAI Pulse CIR
    → 同一 CIR 推导 CTF
```

它不是四套“标准答案”的替代品，也不用于宣称平台预测准确。

## 上游来源

- 项目：Fraunhofer HHI QuaDRiGa
- 官方仓库：<https://github.com/fraunhoferhhi/QuaDRiGa>
- 本次检查版本：`2.8.1-0`
- 本次检查提交：`277866650eb115adb5b3e8ac252b0d1df073596d`
- 许可：QuaDRiGa 自带非商业软件许可，允许科研、教育和标准化用途；再分发时必须保留完整许可并遵守其条件

本仓库不复制 QuaDRiGa 核心。使用者自行准备外部 checkout，并将根目录传给示例函数。

## 最小调用

```matlab
quadrigaRoot = "C:/path/to/QuaDRiGa";
outputDirectory = "C:/temporary/quadriga-v3-output";

pair = generate_quadriga_v3_example( ...
    quadrigaRoot, outputDirectory);
```

输出：

```text
quadriga_umi_nlos_cir.h5
quadriga_umi_nlos_ctf.h5
```

示例使用32个路线快照、2发4收阵列和64个频点。QuaDRiGa输出顺序为：

```text
Rx × Tx × path × snapshot
```

外围适配器转换为：

```text
Tx × Rx × Npath × Nt × N_sample
```

这里每个QuaDRiGa快照是一处路线样本，所以：

```text
Nt = 1
N_sample = 32
```

## 边界

- `convert_quadriga_channel_to_v3_pair.m`只读取第三方输出，不修改第三方对象或源码。
- 本示例只从`qd_channel`导出复数路径系数和时延；角度等生成器内部参数需在未来专门Adapter中显式接出，不能靠猜测。
- Step 3仍负责验证完整版6GPCM最小无界面调用；两者不能混为同一个生成器。
