# ChanAI Pulse GitHub 发布前检查清单

发布前逐项确认。

## 1. 数据安全

- [ ] `datasets/measured/raw_archives/` 没有进入 Git；
- [ ] `datasets/measured/extracted_preview/` 没有进入 Git；
- [ ] GitHub 仓库不包含真实测量数据；
- [ ] GitHub 仓库只包含 synthetic demo data；
- [ ] 没有大型私有数据、zip、rar、7z。

## 2. 模型和结果

- [ ] 没有提交大型模型文件；
- [ ] 没有提交临时训练输出；
- [ ] 没有提交 `experiments/exp_*`；
- [ ] 没有提交本地 benchmark 原始输出。

## 3. 测试

- [ ] 已运行：

```matlab
run("tests/smoke_test.m")
```

- [ ] smoke test 通过；
- [ ] demo 数据能被 MATLAB 读取；
- [ ] 外提 core 函数可用。

## 4. GUI 人工检查

- [ ] App 能启动；
- [ ] 三个页面都能切换；
- [ ] 中英文切换正常；
- [ ] `Prediction & Training` 页没有状态文字重叠；
- [ ] 信道生成按钮可运行；
- [ ] 图表标题和坐标轴显示正常。

## 5. 文档

- [ ] README 完整；
- [ ] License 存在；
- [ ] 协作文档存在；
- [ ] GUI 人工验收清单存在；
- [ ] 数据政策文档存在；
- [ ] Packaging / Compiler 诊断文档存在。

## 6. Git 状态

- [ ] `git status` clean；
- [ ] 没有 remote 指向旧草稿仓库；
- [ ] commit 历史清楚；
- [ ] 发布前 tag 方案已确认。

