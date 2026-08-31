% Headless three-axis App import probe (v3.2-4a).
% Drives the public UI entry through the same callbacks a person uses
% (loadChannelFile with the approved 80/20 preset), verifying that the
% Frequency, Time and Space axes import, validate and render Module-1
% output without error. UI controls are located through findall because
% the app's control properties are private; the core task/axis semantics
% are asserted in tests/run_v32_4_regression.m.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, "core")));

corpusRoot = "D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\chanaipulse-v3.2-corpus.1";
if ~isfile(fullfile(corpusRoot, "frequency_inband_ctf.h5")) || ...
        ~isfile(fullfile(corpusRoot, "raw_cir_probe_samples.mat"))
    fprintf("SKIP: v3.2 corpus not present under %s\n", corpusRoot);
    return;
end

probeDir = fullfile(tempdir, "v32_4_probe_import");
if ~isfolder(probeDir)
    mkdir(probeDir);
end
export_v32_4_probe_import_files(probeDir);

app = ChannelSimulator(Visible="off");
cleanup = onCleanup(@() delete(app)); %#ok<NASGU>

axisDropdown = findDropdown(app.UIFigure, "space");
missingPattern = findDropdown(app.UIFigure, "uniform_half");
assert(~isempty(axisDropdown), "Task-axis dropdown not found.");
assert(~isempty(missingPattern), "Missing-pattern dropdown not found.");
assert(isequal(string(axisDropdown.Items), ["样本", "空间", "时间", "频率"]));
assert(string(missingPattern.Enable) == "off", ...
    "Missing pattern starts disabled (applies only to Frequency).");

% Simulate a user selecting the Frequency axis: uifigure callbacks are not
% auto-dispatched on programmatic value changes, so invoke the registered
% ValueChangedFcn explicitly (same handler a click would run).
axisDropdown.Value = "frequency";
feval(axisDropdown.ValueChangedFcn, axisDropdown, struct());
assert(string(missingPattern.Enable) == "on", ...
    "Missing pattern must enable for the Frequency axis.");
axisDropdown.Value = "sample";
feval(axisDropdown.ValueChangedFcn, axisDropdown, struct());
assert(string(missingPattern.Enable) == "off");

%% Frequency axis: interpolation 80/20 (middle target block).
app.loadChannelFile(fullfile(probeDir, "v32_4_frequency_import.h5"), ...
    TaskMode="interpolation", TaskAxis="frequency", TaskPreset="80_20");
state = app.getReviewState();
assert(state.input_dimensions.Nf == 64, "Frequency import must carry Nf=64.");
assert(hasTaskRangeTitle(app.UIFigure, "内插"), ...
    "Frequency module-1 task range must render.");

%% Time axis: extrapolation 80/20 (final 20% snapshots).
app.loadChannelFile(fullfile(probeDir, "v32_4_time_import.h5"), ...
    TaskMode="extrapolation", TaskAxis="time", TaskPreset="80_20");
state = app.getReviewState();
assert(state.input_dimensions.Nt == 96, "Time import must carry Nt=96.");
assert(hasTaskRangeTitle(app.UIFigure, "外推"), ...
    "Time module-1 task range must render.");

%% Space axis: extrapolation 80/20 (final 20% positions).
app.loadChannelFile(fullfile(probeDir, "v32_4_space_import.h5"), ...
    TaskMode="extrapolation", TaskAxis="space", TaskPreset="80_20");
state = app.getReviewState();
assert(state.input_dimensions.N_sample == 96, ...
    "Space import must carry N_sample=96.");
assert(hasTaskRangeTitle(app.UIFigure, "外推"), ...
    "Space module-1 task range must render.");

fprintf("PASS: v3.2-4a headless three-axis App import probe.\n");
fprintf("  frequency: Nf=%d | time: Nt=%d | space: N_sample=%d\n", ...
    64, 96, 96);

function dropdown = findDropdown(fig, dataMember)
dropdown = [];
allDropdowns = findall(fig, "Type", "uidropdown");
for index = 1:numel(allDropdowns)
    if any(string(allDropdowns(index).ItemsData) == dataMember)
        dropdown = allDropdowns(index);
        return;
    end
end
end

function tf = hasTaskRangeTitle(fig, expectedMode)
axesHandles = findall(fig, "Type", "axes");
for index = 1:numel(axesHandles)
    titleText = string(axesHandles(index).Title.String);
    if contains(titleText, expectedMode) && contains(titleText, "已知")
        tf = true;
        return;
    end
end
tf = false;
end
