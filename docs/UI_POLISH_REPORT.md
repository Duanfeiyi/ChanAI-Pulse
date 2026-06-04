# UI Polish Report

Stage 3 scope: lightweight UI consistency only. No layout redesign, no new dashboard, and no changes to the three-tab structure.

## Before

- Axis style helpers lived inside `ChannelSimulatorApp.m`.
- Title, label, font, tick, and grid styling were already consistent in practice, but the rules were embedded in the App class.
- UI layout positions and panel structure were controlled by the existing `createComponents` and `UIFigureSizeChanged` methods.

## After

- The same axis styling behavior is now routed through:
  - `core/utils/init_axes_style.m`
  - `core/utils/apply_axes_style.m`
- App wrapper methods `initAxesStyle` and `applyAxesStyle` remain in place, so existing UI callbacks still call the same App methods.
- No panel, tab, button position, or visual layout structure was changed.
- No training, prediction, or metric display behavior was changed.

## Reason

This is a low-risk polish step: it centralizes chart styling without altering GUI layout. It prepares the codebase for future UI maintenance while keeping the current App appearance stable.

## Manual UI Check Still Recommended

The automated smoke test runs in non-GUI mode by default to avoid MATLAB batch-mode hangs. A manual MATLAB UI check should still verify:

- English/Chinese language switching;
- three tabs remain visible and switchable;
- all existing buttons remain in the same functional groups;
- plot title and axis label styles remain consistent.

## Stage 4 Fix: Prediction Status Label Overlap

问题：人工打开 App 后，在 `Prediction & Training` 页面的 `Future Gen` 面板中，红色状态文字 `Status: Waiting for Data...` 与面板标题发生重叠。

修改前：

- `DataScaleInfoLabel` 位于 `ParamPanel` 内部，位置为 `[10, 95, 230, 25]`。
- `ParamPanel` 高度为 120，标题区域占据顶部空间，状态文字过于靠上。

修改后：

- `DataScaleInfoLabel` 下移到 `[10, 8, 230, 20]`。
- `Prediction Steps` 行移动到 y=65。
- `Batch Size` 行移动到 y=35。
- `Future Gen` 面板本身、第三页结构、按钮组位置、训练/预测逻辑均未改变。

原因：

- 状态文字放在面板底部更符合信息层级：上方是参数输入，下方是状态反馈。
- 中英文状态文字都不再占用面板标题区域。
- 这是局部布局修复，不属于 UI 重做。

