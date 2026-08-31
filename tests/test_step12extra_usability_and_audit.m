% Step 12 Extra: compatibility audit, language switch, and large progress UI.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, "app")));
addpath(genpath(fullfile(repoRoot, "core")));

assert(translate_channel_simulator_text( ...
    "普通模式自动选择 Grid Search 或 SA，并把实际选择与理由写入 Manifest。", "en") == ...
    "Standard mode automatically chooses Grid Search or SA and records the selected method and rationale in the Manifest.");
assert(translate_channel_simulator_text("时延—样本功率热力图", "en") == ...
    "Delay–sample power heatmap");
assert(translate_channel_simulator_text( ...
    "开始预测（自动：6GPCM-Lite）", "en") == ...
    "Start prediction (automatic: 6GPCM-Lite)");
assert(translate_channel_simulator_text( ...
    "gru+local_guard(0.21)", "zh") == "gru+local_guard(0.21)");
assert(translate_channel_simulator_text("空间", "en") == "Space");
assert(translate_channel_simulator_text( ...
    "缺失子载波模式（仅频率轴）", "en") == ...
    "Missing-subcarrier pattern (Frequency axis only)");
assert(translate_channel_simulator_text("均匀隔1挖1（缺50%）", "en") == ...
    "Uniform half (every other)");
assert(translate_channel_simulator_text( ...
    "space（绿色：已知，橙色：目标，灰色：未使用）", "en") == ...
    "Space (green: known, orange: target, gray: unused)");

engineRoot = fullfile(fileparts(repoRoot), ...
    "ChanAI-Pulse-v3-step11abc-assets", "full6gpcm", "source");
if ~isfolder(engineRoot)
    engineRoot = "";
end

%% The audit must separate legitimate limits from false compatibility claims.
audit = audit_platform_compatibility(FullEngineRoot=engineRoot);
assert(audit.summary.fail_count == 0, ...
    "Compatibility audit found an unresolved possible false rejection.");
assert(audit.summary.time_frequency_target_generation_supported, ...
    "v3.2-4a must claim time/space/frequency target generation support.");
if strlength(engineRoot) > 0
    staticMimo = audit.records(3);
    dynamicMimo = audit.records(4);
    assert(staticMimo.status == "PASS");
    assert(dynamicMimo.status == "PASS");
    assert(staticMimo.selected_adapter_variant == "public_api");
    assert(dynamicMimo.selected_adapter_variant == "public_api");
end

%% Public API is preferred; legacy fixed entry is a controlled fallback.
mockFullRoot = fullfile(repoRoot, "tests", "fixtures", "mock_full_6gpcm");
legacy = select_generator_backend("auto", struct( ...
    "Tx", 2, "Rx", 2, "Nt", 2, "N_sample", 8), ...
    FullEngineRoot=mockFullRoot);
assert(legacy.success);
assert(legacy.selected_backend == "full_6gpcm");
assert(legacy.selected_adapter_variant == "fixed_entrypoint");
assert(legacy.candidates(2).adapter_variant == "public_api");
assert(~legacy.candidates(2).available);

%% English and Chinese update the formal UI without changing item data.
app = ChannelSimulator(Visible="off");
cleanup = onCleanup(@() delete(app)); %#ok<NASGU>
app.setLanguage("en");
state = app.getReviewState();
assert(state.language == "en");
assert(hasTabTitle(app.UIFigure, "1. Data & Task"));
assert(hasEnabledDropDownItem(app.UIFigure, "Load, validate & analyze"));
assert(hasPanelTitle(app.UIFigure, "Run progress"));
assert(progressPanelFits(app.UIFigure), ...
    "The large progress card must fit inside the application window.");

fixture = fullfile(repoRoot, "demo_data", "v3_standard_fixtures", ...
    "narrowband_static_siso_cir.h5");
app.loadChannelFile(fixture);
assert(hasEnabledDropDownItem(app.UIFigure, ...
    "Start prediction (automatic: 6GPCM-Lite)"));
app.runCurrentTask();
state = app.getReviewState();
assert(state.calibration_success && state.prediction_success);
assert(state.progress_visible, "Completed runs should leave the large progress card visible for review.");
assert(hasEnabledDropDownItem(app.UIFigure, "Hide progress panel"));

% Re-rendered plots must use the selected language rather than translating
% only the old title text after the fact.
dynamicFixture = fullfile(repoRoot, "demo_data", "v3_standard_fixtures", ...
    "wideband_dynamic_mimo_cir.h5");
app.loadChannelFile(dynamicFixture);
app.setLanguage("en");
assert(hasAxesTitle(app.UIFigure, "Delay–sample power heatmap"));

app.setLanguage("zh");
state = app.getReviewState();
assert(state.language == "zh");
assert(hasTabTitle(app.UIFigure, "1. 数据与任务"));
assert(hasEnabledDropDownItem(app.UIFigure, "收起进度面板"));

fprintf("PASS: Step 12 Extra audit, progress card, and bilingual UI are valid.\n");

function tf = hasTabTitle(figureHandle, expected)
tabs = findall(figureHandle, "Type", "uitab");
tf = any(string({tabs.Title}) == expected);
end

function tf = hasPanelTitle(figureHandle, expected)
panels = findall(figureHandle, "Type", "uipanel");
tf = any(string({panels.Title}) == expected);
end

function tf = hasEnabledDropDownItem(figureHandle, expectedText)
buttons = findall(figureHandle, "Type", "uibutton");
matches = buttons(string({buttons.Text}) == expectedText);
tf = ~isempty(matches) && any(string({matches.Enable}) == "on");
end

function tf = progressPanelFits(figureHandle)
panels = findall(figureHandle, "Type", "uipanel");
matches = panels(string({panels.Title}) == "Run progress");
if isempty(matches)
    tf = false;
    return;
end
position = matches(1).Position;
figurePosition = figureHandle.Position;
tf = position(1) >= 0 && position(2) >= 0 && ...
    position(1) + position(3) <= figurePosition(3) && ...
    position(2) + position(4) <= figurePosition(4);
end

function tf = hasAxesTitle(figureHandle, expected)
axesHandles = findall(figureHandle, "Type", "axes");
titles = strings(numel(axesHandles), 1);
for index = 1:numel(axesHandles)
    titles(index) = string(axesHandles(index).Title.String);
end
tf = any(titles == expected);
end
