% ChanAI Pulse v3 Step 12 formal-entry and baseline-prediction checks.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, "core")));

%% The public entry point opens the formal v3 UI without demo dependencies.
app = ChannelSimulator(Visible="off");
cleanup = onCleanup(@() delete(app));
assert(isvalid(app.UIFigure));
assert(app.UIFigure.Name == "ChanAI Pulse v3.1.0");

%% v3.2-4a three-axis UI controls are present and consistent.
axisDropdown = findDropdown(app.UIFigure, "space");
missingPattern = findDropdown(app.UIFigure, "uniform_half");
assert(~isempty(axisDropdown), "Task-axis dropdown not found.");
assert(~isempty(missingPattern), "Missing-pattern dropdown not found.");
assert(isequal(string(axisDropdown.ItemsData), ...
    ["sample", "space", "time", "frequency"]));
assert(isequal(string(axisDropdown.Items), ...
    ["样本", "空间", "时间", "频率"]));
assert(isequal(string(missingPattern.ItemsData), ...
    ["uniform_half", "random_half", "block_8"]));
assert(string(missingPattern.Enable) == "off", ...
    "Missing pattern applies only to the Frequency axis.");
% Simulate the user selecting the Frequency axis: invoke the registered
% ValueChangedFcn explicitly (uifigure does not auto-dispatch callbacks on
% programmatic value changes in headless runs).
axisDropdown.Value = "frequency";
feval(axisDropdown.ValueChangedFcn, axisDropdown, struct());
assert(string(missingPattern.Enable) == "on");
axisDropdown.Value = "sample";
feval(axisDropdown.ValueChangedFcn, axisDropdown, struct());
assert(string(missingPattern.Enable) == "off");

%% Four standard fixtures expose 1/3/6/9 standard plus optional heatmap.
fixtureRoot = fullfile(repoRoot, "demo_data", "v3_standard_fixtures");
fixtureNames = [ ...
    "narrowband_static_siso_cir.h5", ...
    "wideband_static_siso_cir.h5", ...
    "wideband_static_mimo_cir.h5", ...
    "wideband_dynamic_mimo_cir.h5"];
expectedOverviewCounts = [1, 4, 7, 10];
expectedAdditionalCounts = [0, 1, 1, 1];
for fixtureIndex = 1:numel(fixtureNames)
    app.loadChannelFile(fullfile(fixtureRoot, fixtureNames(fixtureIndex)));
    assert(hasTabTitle(app.UIFigure, ...
        "全部概览（" + expectedOverviewCounts(fixtureIndex) + "）"));
    assert(hasTabTitle(app.UIFigure, ...
        "附加可视化（" + expectedAdditionalCounts(fixtureIndex) + "）"));
end
assert(app.UIFigure.Visible == "off", ...
    "Programmatic hidden loading must not steal focus or show the window.");
externalFullRoot = fullfile(fileparts(repoRoot), ...
    "ChanAI-Pulse-v3-step11abc-assets", "full6gpcm", "source");
bundledFullRoot = fullfile(repoRoot, "third_party", "full_6gpcm");
if isfile(fullfile(externalFullRoot, "@channel_model", "channel_model.m")) || ...
        isfile(fullfile(bundledFullRoot, "@channel_model", "channel_model.m"))
    assert(hasEnabledButton(app.UIFigure, ...
        "开始预测（自动：Full 6GPCM）"), ...
        "The 2x4x16 fixture should select the configurable Full public API.");
else
    assert(hasDisabledButton(app.UIFigure, "当前无兼容生成器"), ...
        "Without an external Full engine, all formal candidates must be audited before blocking.");
end
app.loadChannelFile(fullfile(fixtureRoot, "wideband_static_siso_cir.h5"));
assert(hasEnabledButton(app.UIFigure, "开始预测（自动：6GPCM-Lite）"), ...
    "A compatible SISO fixture should automatically select 6GPCM-Lite.");

%% Automatic generator selection never changes the requested dimensions.
sisoSelection = select_generator_backend("auto", struct( ...
    "Tx", 1, "Rx", 1, "Nt", 8, "N_sample", 20));
assert(sisoSelection.success);
assert(sisoSelection.selected_backend == "lite_6gpcm");

fullSelection = select_generator_backend("auto", struct( ...
    "Tx", 2, "Rx", 2, "Nt", 2, "N_sample", 20), ...
    FullEngineRoot=fullfile(repoRoot, "tests", "fixtures", "mock_full_6gpcm"));
assert(fullSelection.success);
assert(fullSelection.selected_backend == "full_6gpcm");
assert(~fullSelection.candidates(1).compatible);

unsupportedSelection = select_generator_backend("auto", struct( ...
    "Tx", 2, "Rx", 4, "Nt", 16, "N_sample", 20), ...
    FullEngineRoot=fullfile(repoRoot, "tests", "fixtures", "mock_full_6gpcm"));
assert(~unsupportedSelection.success);
assert(numel(unsupportedSelection.candidates) == 2);
assert(~unsupportedSelection.candidates(1).compatible);
assert(unsupportedSelection.candidates(2).compatible);
assert(unsupportedSelection.candidates(2).adapter_variant == "public_api");
assert(~unsupportedSelection.candidates(2).available);

%% The frozen v3.0 product fallback contains no target ground truth.
calibration = struct( ...
    "success", true, ...
    "selected_strategy", "grid", ...
    "best", struct("parameters", struct( ...
        "DS_mu", -8.0, "KF_mu", -0.8, "num_clusters", 12)), ...
    "manifest", struct("schema_version", "v3.0-test-manifest"));
task = struct( ...
    "mode", "extrapolation", ...
    "target_indices", (33:36).');
prediction = create_calibrated_persistence_prediction( ...
    calibration, task, "lite_6gpcm");
assert(prediction.model.model_type == "persistence");
assert(~prediction.request_contains_target_ground_truth);
assert(isequal(size(prediction.prediction_parameters), [1, 4, 6]));
assert(all(prediction.target_parameter_sample_index == 33:36));

fprintf("PASS: Step 12 formal entry and target-free baseline contract are valid.\n");

function tf = hasTabTitle(figureHandle, expected)
tabs = findall(figureHandle, "Type", "uitab");
tf = any(string({tabs.Title}) == expected);
end

function tf = hasDisabledButton(figureHandle, expectedText)
buttons = findall(figureHandle, "Type", "uibutton");
matches = buttons(string({buttons.Text}) == expectedText);
tf = numel(matches) == 1 && string(matches.Enable) == "off";
end

function tf = hasEnabledButton(figureHandle, expectedText)
buttons = findall(figureHandle, "Type", "uibutton");
matches = buttons(string({buttons.Text}) == expectedText);
tf = numel(matches) == 1 && string(matches.Enable) == "on";
end

function dropdown = findDropdown(figureHandle, dataMember)
dropdown = [];
allDropdowns = findall(figureHandle, "Type", "uidropdown");
for index = 1:numel(allDropdowns)
    if any(string(allDropdowns(index).ItemsData) == dataMember)
        dropdown = allDropdowns(index);
        return;
    end
end
end
