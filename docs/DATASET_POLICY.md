# ChanAI Pulse Dataset Policy / 数据集政策

本项目区分两类数据：

1. synthetic demo data：可公开的小型合成演示数据；
2. real measured data：真实测量数据，仅本地使用。

## 1. 真实测量数据不公开

以下目录中的数据不得提交、不得 push、不得上传 GitHub：

```text
datasets/measured/raw_archives/
datasets/measured/extracted_preview/
```

这些数据只能用于：

- 本地验证；
- 内部研究；
- 训练实验；
- benchmark 前期分析；
- 数据格式兼容性测试。

## 2. GitHub 只包含 synthetic demo data

GitHub 公开仓库只允许包含：

```text
demo_data/demo_sub6_scenario1.mat
demo_data/demo_mmwave_scenario2.mat
```

这些文件必须是 synthetic demo，不得来自真实测量数据的复制、抽样或脱敏版本。

## 3. 未来 ChanAIs Dataset

如果未来要公开 ChanAIs Dataset，必须单独处理：

- 数据授权；
- 脱敏；
- 元数据说明；
- 版本管理；
- DOI 或引用方式；
- 许可协议；
- 数据下载页面。

ChanAIs Dataset 不应直接混入 ChanAI Pulse 源码仓库。

## 4. 队友注意事项

不要把以下文件拖进 GitHub Desktop、VS Code Source Control 或命令行 `git add`：

```text
datasets/measured/raw_archives/*
datasets/measured/extracted_preview/*
*.zip
*.rar
*.7z
```

提交前必须运行：

```bash
git status
```

如果看到真实数据文件出现在待提交列表中，立刻停止并联系维护者。

## 5. English Summary

Real measured datasets are local-only and must not be committed to GitHub. The public repository may include only small synthetic demo data. Any future public ChanAIs Dataset release must be handled as a separate dataset project with independent licensing, metadata, and versioning.

