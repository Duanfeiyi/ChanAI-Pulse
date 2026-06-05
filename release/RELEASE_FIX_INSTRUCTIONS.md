# ChanAI Pulse v1.0.0 Release 附件修正说明

## 背景

当前 GitHub Release 中存在一个附件：

```text
default.md
```

该名称不够专业，容易让用户误解。建议删除该附件，并上传新的中文安装说明：

```text
INSTALL_CN.md
```

## 为什么需要网页端手动修正

当前本机未检测到 GitHub CLI，无法使用 `gh release delete-asset` 或 `gh release upload` 自动修改 Release 附件。

请通过 GitHub 网页端手动完成修正。

## 操作步骤

1. 打开仓库：

```text
https://github.com/Duanfeiyi/ChanAI-Pulse
```

2. 进入 Release 页面：

```text
Releases -> ChanAI Pulse v1.0.0
```

也可以直接打开：

```text
https://github.com/Duanfeiyi/ChanAI-Pulse/releases/tag/v1.0.0
```

3. 点击编辑 Release：

```text
Edit release
```

4. 在附件列表中删除：

```text
default.md
```

5. 上传新的附件：

```text
release/github_release_assets/INSTALL_CN.md
```

6. 保留已有附件：

```text
ChanAI_Pulse_v1.0.0.mlappinstall
README_RELEASE.md
```

7. 如需更新 Release description，请复制：

```text
release/github_release_assets/RELEASE_DESCRIPTION.md
```

8. 点击：

```text
Update release
```

## 发布后检查

确认 Release 附件列表包含：

- `ChanAI_Pulse_v1.0.0.mlappinstall`
- `README_RELEASE.md`
- `INSTALL_CN.md`

确认 Release 附件列表不再包含：

- `default.md`

确认 Release 说明中保留：

```text
This release requires MATLAB and required toolboxes. It is not a standalone executable.
No private measured datasets are included in this release.
```

