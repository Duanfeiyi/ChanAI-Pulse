# ChanAI Pulse v1.0.0 中文安装说明

## 1. ChanAI Pulse 简介

ChanAI Pulse 是一个面向全频段、全场景无线信道研究的 AI 驱动信道特性分析、信道生成与信道预测平台，并面向 6G 通信场景进行应用扩展。

当前 v1.0.0 版本以 MATLAB App Package 形式发布，适合用于本地 MATLAB 环境中的教学、科研演示和平台功能验证。

## 2. MATLAB App Package 说明

Release 附件中的文件：

```text
ChanAI_Pulse_v1.0.0.mlappinstall
```

是 MATLAB App Package，不是独立 exe。

这意味着：

- 用户需要提前安装 MATLAB；
- 用户需要具备必要工具箱；
- 双击或在 MATLAB 中安装后，可以从 MATLAB Apps 面板启动；
- 该版本不包含 MATLAB Runtime 独立运行环境。

## 3. MATLAB 版本要求

推荐使用：

```text
MATLAB R2022b 或更新版本
```

如果使用更早版本，可能出现 App 组件、深度学习网络或绘图接口兼容性问题。

## 4. 必需工具箱

建议至少安装以下工具箱：

- Deep Learning Toolbox
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox

## 5. 推荐工具箱

以下工具箱不是最小运行条件，但对后续无线通信研究和扩展有帮助：

- Communications Toolbox
- 5G Toolbox

## 6. `.mlappinstall` 安装步骤

方法一：双击安装

1. 下载 `ChanAI_Pulse_v1.0.0.mlappinstall`；
2. 双击该文件；
3. MATLAB 会打开 App 安装界面；
4. 按提示完成安装。

方法二：从 MATLAB 安装

1. 打开 MATLAB；
2. 在 MATLAB 中选择 Apps 相关安装入口；
3. 选择 `ChanAI_Pulse_v1.0.0.mlappinstall`；
4. 完成安装。

## 7. 启动方法

安装完成后：

1. 打开 MATLAB；
2. 进入 Apps 面板；
3. 找到 ChanAI Pulse；
4. 点击启动。

如果从源码运行，可以在项目根目录执行：

```matlab
addpath(genpath(pwd))
run("tests/smoke_test.m")
ChannelSimulatorApp
```

## 8. Demo 数据使用方法

GitHub 仓库包含 synthetic demo data：

```text
demo_data/demo_sub6_scenario1.mat
demo_data/demo_mmwave_scenario2.mat
```

这些文件仅用于公开演示、加载测试和 GUI 可视化检查，不是真实测量数据，也不应作为正式论文 benchmark 结论使用。

## 9. 数据集说明

当前公开 Release 不包含真实测量数据。

不包含的内容包括：

- `datasets/`
- `datasets/measured/raw_archives/`
- `datasets/measured/extracted_preview/`
- 真实测量 `.mat` 数据
- 大型压缩包
- 私有实验输出

未来 ChanAIs Dataset 如果公开，将单独进行脱敏、授权、版本管理和引用说明。

## 10. 常见问题

### Q1：这个文件是独立安装包吗？

不是。它是 MATLAB App Package，需要 MATLAB 环境。

### Q2：为什么没有 exe？

当前 v1.0.0 优先发布 MATLAB App Package。独立 exe 需要 MATLAB Compiler 打包流程，后续版本再考虑。

### Q3：为什么没有真实测量数据？

真实测量数据涉及授权、隐私、实验元信息和格式统一问题，当前只用于本地内部验证，不随 GitHub Release 公开。

### Q4：没有 MATLAB 可以运行吗？

不能。当前版本需要 MATLAB。

### Q5：运行出错怎么办？

请记录：

- MATLAB 版本；
- 操作系统；
- 已安装工具箱；
- 报错信息截图或文本；
- 使用的是 synthetic demo data 还是私有数据。

然后在 GitHub Issue 中反馈。

## 11. 联系方式

请通过 GitHub Issues 反馈问题：

```text
https://github.com/Duanfeiyi/ChanAI-Pulse/issues
```

