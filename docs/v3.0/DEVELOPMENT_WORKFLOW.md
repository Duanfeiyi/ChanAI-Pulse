# ChanAI Pulse v3.0 开发与 PR 流程

> 仓库：`Duanfeiyi/ChanAI-Pulse`
>
> PR 最终批准人：`Duanfeiyi`
>
> 目标分支：`main`

## 1. 基本流程

```text
最新 origin/main
      ↓
一个 Step 的短期分支
      ↓
本地实现、测试和文档
      ↓
Push 到 GitHub
      ↓
Pull Request → main
      ↓
Duanfeiyi 审阅并决定是否合并
```

不建立长期堆积全部 v3.0 修改的巨型开发分支。

## 2. 分支命名

Codex 创建的分支：

```text
codex/v3-step-0-foundation
codex/v3-step-1-data-contract
codex/v3-step-3-full-6gpcm-spike
```

团队成员也可以使用：

```text
feature/v3-step-4-input-module
fix/v3-delay-axis
docs/v3-interface-guide
```

## 3. 一个 PR 应该包含什么

一个 PR 应形成一个可以解释和验收的成果。PR 必须说明：

- 完成的需求 ID；
- 修改的文件；
- 没有完成的内容；
- 自动测试结果；
- MATLAB 版本和必要 Toolbox；
- 是否运行人工 GUI 检查；
- 是否影响数据格式；
- 是否影响生成或预测结果；
- 是否包含第三方代码、数据或权重；
- 是否需要额外本地依赖。

避免在一个 PR 中同时：

- 重做 GUI；
- 改数据契约；
- 改科学公式；
- 改默认参数；
- 接入新的第三方生成器。

如果确实必须同时修改，要在 PR 中解释它们为什么不能拆开。

## 4. Commit 规则

推荐：

```text
docs: establish v3.0 requirement baseline
data: define path-domain CIR contract
feat: add full 6GPCM adapter
feat: implement simulated annealing search
test: add wideband dynamic MIMO fixture
fix: correct delay-axis unit conversion
```

禁止：

- 直接向 `main` 提交；
- 强制推送共享分支；
- 使用含义不明的 `update`、`final`、`test2`；
- 把真实数据和临时结果一起提交；
- 为了通过测试偷偷改变验收标准。

## 5. 合并标准

PR 合并前至少满足：

1. `git diff --check` 通过；
2. 相关自动测试通过；
3. MATLAB App 能启动；
4. 三个页面能够切换；
5. 涉及 GUI 时完成人工检查；
6. 涉及科学计算时有固定输入和参考结果；
7. 涉及接口时有输入输出文档和最小示例；
8. 涉及第三方代码时完成来源和许可证检查；
9. 不包含无意上传的数据、权重或实验输出；
10. 需求追踪表已更新；
11. `Duanfeiyi` 完成最终审阅。

## 6. Step 完成定义

“代码已经写了”不等于 Step 完成。一个 Step 完成必须同时具有：

```text
实现
+ 测试
+ 接口/使用文档
+ 需求追踪更新
+ PR 审阅
+ 合并到 main
```

未合并的成果可以称为“实现完成”或“等待审阅”，不能称为“正式完成”。
