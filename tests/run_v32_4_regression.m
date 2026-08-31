% v3.2-4a three-axis UI regression: time/space/frequency prediction chain.
% Covers the unified run_v32_axis_prediction entry, the deterministic
% frequency recovery service, leakage-free guarantees, and the
% generation-layer axis mapping. Requires the Git-external v3.2 corpus;
% skips gracefully when it is absent. No Full 6GPCM call is needed.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, "core")));

corpusRoot = "D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\chanaipulse-v3.2-corpus.1";
frequencyH5 = fullfile(corpusRoot, "frequency_inband_ctf.h5");
rawMat = fullfile(corpusRoot, "raw_cir_probe_samples.mat");
if ~isfile(frequencyH5) || ~isfile(rawMat)
    fprintf("SKIP: v3.2 corpus not present under %s\n", corpusRoot);
    return;
end

probeDir = fullfile(tempdir, "v32_4_probe_import");
if ~isfolder(probeDir)
    mkdir(probeDir);
end
export_v32_4_probe_import_files(probeDir);

frozen = struct("DS_sigma", 0.35, "KF_sigma", 2.0, "r_DS", 2.66, ...
    "LNS_ksi", 3.33, "num_clusters", 12, "num_rays", 20);
calibration = struct("success", true, ...
    "best", struct("parameters", frozen), ...
    "manifest", struct("schema_version", "v3.2-4a-test"));

%% ===================== Frequency axis =====================
% block_8 spectrum: known = 1..28 and 37..64, targets 29..36 (strictly
% inside the known range, so the task is a valid interpolation task).
fprintf("--- Frequency axis ---\n");
frequencyFile = fullfile(probeDir, "v32_4_frequency_import.h5");
assert(isfile(frequencyFile), "Frequency import file missing.");
[knownIdx, targetIdx] = spectrumSplit(frequencyH5, 2);
assert(numel(targetIdx) == 8, "block_8 spectrum must have 8 targets.");
assert(all(targetIdx >= min(knownIdx) & targetIdx <= max(knownIdx)), ...
    "block_8 targets must lie strictly inside the known range.");
imported = import_channel_dataset(frequencyFile, struct( ...
    "task_mode", "interpolation", "task_axis", "frequency", ...
    "task_preset", "manual", ...
    "known_indices", knownIdx, "target_indices", targetIdx));
assert(imported.status == "PASS", "%s", ...
    strjoin(imported.validation.errors, " | "));
assert(string(imported.task.axis) == "frequency");
assert(string(imported.task.axis_unit) == "Hz");
assert(all(diff(imported.task.axis_values) > 0), ...
    "frequency axis_values must be strictly increasing.");

% Module-1 known-region analysis sees only known subcarriers.
inputAnalysis = analyze_channel_characteristics(imported.dataset, ...
    Task=imported.task, Region="known", ModuleRole="input");
assert(inputAnalysis.status ~= "FAIL");

frequencyPrediction = run_v32_axis_prediction( ...
    imported.dataset, calibration, imported.task, "full_6gpcm", struct());
% v3.2-4a 1A: contiguous missing blocks (29:36) dispatch to delay-domain OMP
% sparse recovery; the selection/manifest must record the actual method.
assert(string(frequencyPrediction.selection.selected_model) == ...
    "delay_domain_sparse");
assert(isequal(string(frequencyPrediction.parameter_names(:)).', ...
    ["magnitude", "phase"]));
assert(isequal(size(frequencyPrediction.prediction_parameters), ...
    [1, numel(targetIdx), 2]));
assert(all(isfinite(frequencyPrediction.prediction_parameters(1, :, 1)), ...
    "all"), "Recovered magnitude must be finite.");
assert(size(frequencyPrediction.known_context_parameters, 1) == ...
    numel(knownIdx));
assert(~logical(frequencyPrediction.target_region_channel_samples_read));
assert(~logical(frequencyPrediction.request_contains_target_ground_truth));

% Deterministic recovery service (no Full 6GPCM).
service = run_v32_frequency_generation( ...
    imported.dataset, frequencyPrediction, struct());
assert(service.success, "%s", strjoin(service.errors, " | "));
assert(service.status == "PASS");
assert(service.formal_eligible);
pr = service.prediction_result;
assert(~isempty(fieldnames(pr.cir_dataset)), "Recovered CIR missing.");
assert(~isempty(fieldnames(pr.ctf_dataset)), "Recovered CTF missing.");
assert(pr.ctf_dataset.dimensions.Nf == 64);
assert(pr.cir_dataset.dimensions.N_sample == 1);
assert(isfield(pr.ctf_dataset.axes, "frequency_hz"));
assert(all(isfinite(pr.ctf_dataset.ctf.H(:)), "all"));
assert(~isempty(fieldnames(pr.analysis)), "Characteristics missing.");
assert(string(pr.task_axis) == "frequency");
assert(string(pr.prediction_manifest.model.model_type) == ...
    "delay_domain_sparse", "Manifest must record the sparse method.");
assert(string(pr.prediction_manifest.selection.selected_model) == ...
    "delay_domain_sparse");

% v3.2-4a 1A: structure dispatcher must be leakage-free and correct.
Hslice = imported.dataset.ctf.H;
Hslice = reshape(double(Hslice), size(Hslice, 1), size(Hslice, 2), ...
    size(Hslice, 3));
[~, blockMethod] = recover_inband_ctf_hybrid( ...
    Hslice, knownIdx(:), targetIdx(:));
assert(blockMethod == "delay_domain_sparse", ...
    "Contiguous target block must dispatch to sparse recovery.");
alternatingTargets = (2:2:64).';
[~, alternatingMethod] = recover_inband_ctf_hybrid( ...
    Hslice, knownIdx(:), alternatingTargets);
assert(alternatingMethod == "linear_interpolation", ...
    "Alternating targets must dispatch to complex linear interpolation.");

% Leakage: tampering target-subcarrier input values must not change the
% prediction (recovery reads only known subcarriers).
tampered = imported.dataset;
tampered.ctf.H(:, :, targetIdx, 1, 1) = ...
    tampered.ctf.H(:, :, targetIdx, 1, 1) * 1e3 + (5 + 6i);
tamperedPrediction = run_v32_axis_prediction( ...
    tampered, calibration, imported.task, "full_6gpcm", struct());
assert(isequaln(frequencyPrediction.prediction_parameters, ...
    tamperedPrediction.prediction_parameters), ...
    "Changing target-subcarrier values must not alter the frequency prediction.");

%% ===================== Time axis =====================
fprintf("--- Time axis ---\n");
timeFile = fullfile(probeDir, "v32_4_time_import.h5");
assert(isfile(timeFile), "Time import file missing.");
timeImported = import_channel_dataset(timeFile, struct( ...
    "task_mode", "extrapolation", "task_axis", "time", ...
    "task_preset", "manual", ...
    "known_indices", 1:16, "target_indices", 17:20));
assert(timeImported.status == "PASS", "%s", ...
    strjoin(timeImported.validation.errors, " | "));
assert(string(timeImported.task.axis) == "time");
assert(string(timeImported.task.axis_unit) == "s");
assert(numel(timeImported.task.axis_values) == 96);

timePrediction = run_v32_axis_prediction( ...
    timeImported.dataset, calibration, timeImported.task, ...
    "full_6gpcm", struct());
assert(string(timePrediction.selection.selected_model) == "ar");
assert(numel(timePrediction.parameter_names) == 8);
assert(isequal(size(timePrediction.prediction_parameters), [1, 4, 8]));
predicted = reshape(timePrediction.prediction_parameters, [4, 8]);
assert(all(isfinite(predicted(:, [1, 2])), "all"), ...
    "Predicted DS_mu/KF_mu must be finite.");
assert(all(predicted(:, 3) == frozen.DS_sigma), "DS_sigma must stay frozen.");
assert(all(predicted(:, 7) == frozen.num_clusters), ...
    "num_clusters must stay frozen.");
assert(isequal(size(timePrediction.known_context_parameters), [16, 2]));
assert(~logical(timePrediction.target_region_channel_samples_read));

% Time leakage: tampering target snapshots must not change the prediction.
tamperedTime = timeImported.dataset;
tamperedTime.cir.coefficient(:, :, :, 17:20, 1) = ...
    tamperedTime.cir.coefficient(:, :, :, 17:20, 1) * 1e6 + (10 + 20i);
tamperedTimePred = run_v32_axis_prediction( ...
    tamperedTime, calibration, timeImported.task, "full_6gpcm", struct());
assert(isequaln(timePrediction.prediction_parameters, ...
    tamperedTimePred.prediction_parameters), ...
    "Changing target-time channel samples must not alter the time prediction.");

% Generation request assembly (no engine needed for validation).
timeConfig = default_prediction_generation_config("full_6gpcm");
timeConfig.task_axis = "time";
timeConfig.task_axis_unit = "s";
timeConfig.target_axis_values = ...
    timeImported.task.axis_values(17:20);
timeConfig.dimensions.Tx = 2;
timeConfig.dimensions.Rx = 4;
timeConfig.dimensions.Nt = 1;
timeConfig.dimensions.Npath = 400;
timeConfig.parameter_sources.calibrated = frozen;
timeRequest = create_prediction_generation_request(timePrediction, timeConfig);
timeValidation = validate_prediction_generation_request(timeRequest);
assert(timeValidation.is_valid, "%s", ...
    strjoin(timeValidation.errors, " | "));
assert(timeRequest.target_count == 4);

%% ===================== Space axis =====================
fprintf("--- Space axis ---\n");
spaceFile = fullfile(probeDir, "v32_4_space_import.h5");
assert(isfile(spaceFile), "Space import file missing.");
spaceImported = import_channel_dataset(spaceFile, struct( ...
    "task_mode", "extrapolation", "task_axis", "space", ...
    "task_preset", "manual", ...
    "known_indices", 1:16, "target_indices", 17:20));
assert(spaceImported.status == "PASS", "%s", ...
    strjoin(spaceImported.validation.errors, " | "));
assert(string(spaceImported.task.axis) == "space");
assert(string(spaceImported.task.axis_unit) == "m");
spaceAxis = spaceImported.task.axis_values;
assert(numel(spaceAxis) == 96);
assert(all(diff(spaceAxis) > 0), ...
    "space axis must be strictly increasing along-track x.");

spacePrediction = run_v32_axis_prediction( ...
    spaceImported.dataset, calibration, spaceImported.task, ...
    "full_6gpcm", struct());
assert(string(spacePrediction.selection.selected_model) == "persistence");
assert(isequal(size(spacePrediction.prediction_parameters), [1, 4, 8]));
spacePredicted = reshape(spacePrediction.prediction_parameters, [4, 8]);
assert(all(spacePredicted(:, 1) == spacePredicted(1, 1), "all"), ...
    "Persistence must hold DS_mu constant.");
assert(all(spacePredicted(:, 2) == spacePredicted(1, 2), "all"), ...
    "Persistence must hold KF_mu constant.");
assert(isequal(size(spacePrediction.known_context_parameters), [16, 2]));

% Generation layer maps space -> position (request validator's contract).
spaceConfig = default_prediction_generation_config("full_6gpcm");
spaceConfig.task_axis = "position";
spaceConfig.task_axis_unit = "m";
spaceConfig.target_axis_values = spaceAxis(17:20);
spaceConfig.dimensions.Tx = 2;
spaceConfig.dimensions.Rx = 4;
spaceConfig.dimensions.Nt = 1;
spaceConfig.dimensions.Npath = 400;
spaceConfig.parameter_sources.calibrated = frozen;
spaceRequest = create_prediction_generation_request( ...
    spacePrediction, spaceConfig);
spaceValidation = validate_prediction_generation_request(spaceRequest);
assert(spaceValidation.is_valid, "%s", ...
    strjoin(spaceValidation.errors, " | "));
assert(spaceRequest.target_count == 4);

%% ===================== Known-region DS/KF estimator =====================
fprintf("--- Known-region estimator ---\n");
knownTime = estimate_known_region_ds_kf(timeImported.dataset, (1:16).');
assert(string(knownTime.provenance.index_dimension) == "time");
assert(all(isfinite(knownTime.values(:)), "all"));
knownSpace = estimate_known_region_ds_kf(spaceImported.dataset, (1:16).');
assert(string(knownSpace.provenance.index_dimension) == "sample");
assert(all(isfinite(knownSpace.values(:)), "all"));
assert(~logical(knownTime.provenance.target_channel_samples_read));

%% ===================== Manual classical models (time/space) =====================
% v3.2-4a: manual model selection on time/space axes uses the classical
% forecast family (MATLAB port of flexible_forecast.py).
fprintf("--- Manual classical models ---\n");
classicalModels = ["persistence", "linear", "quadratic", ...
    "holt", "harmonic", "ar", "kalman"];
for model = classicalModels
    manualConfig = struct("requested_model", model);
    manualPred = run_v32_axis_prediction( ...
        timeImported.dataset, calibration, timeImported.task, ...
        "full_6gpcm", manualConfig);
    assert(string(manualPred.selection.selected_model) == model, ...
        "Manual model %s must be selected.", model);
    manualValues = reshape(manualPred.prediction_parameters, [4, 8]);
    assert(all(isfinite(manualValues(:, [1, 2])), "all"), ...
        "Manual %s DS/KF prediction must be finite.", model);
    assert(~logical(manualPred.target_region_channel_samples_read));
    % Persistence manual forecast must hold the last known value.
    if model == "persistence"
        assert(all(manualValues(:, 1) == manualValues(1, 1), "all"));
        assert(all(manualValues(:, 2) == manualValues(1, 2), "all"));
    end
end
% Neural models run on time/space via the Python online-fit adapter
% (experimental; no axis-sequence checkpoint) and must produce a finite
% prediction, never a silent fallback.
fprintf("--- Manual neural models (online fit) ---\n");
pythonExecutable = string(getenv("CHANAI_STEP10_PYTHON"));
if strlength(pythonExecutable) == 0
    pythonExecutable = "python";
end
for model = ["gru", "lstm", "tcn", "dlinear", "nlinear"]
    neuralConfig = struct("requested_model", model, ...
        "python_executable", pythonExecutable);
    neuralPred = run_v32_axis_prediction( ...
        timeImported.dataset, calibration, timeImported.task, ...
        "full_6gpcm", neuralConfig);
    assert(string(neuralPred.selection.selected_model) == model, ...
        "Neural model %s must be selected.", model);
    neuralValues = reshape(neuralPred.prediction_parameters, [4, 8]);
    assert(all(isfinite(neuralValues(:, [1, 2])), "all"), ...
        "Neural %s DS/KF prediction must be finite.", model);
    assert(~logical(neuralPred.target_region_channel_samples_read));
    assert(contains(string(neuralPred.model.execution_contract), ...
        "online_fit"), "Neural forecast must be marked experimental.");
end

% Frequency manual models: classical forecast along frequency on [Re, Im],
% neural via Python online-fit; both must run and stay finite.
fprintf("--- Frequency manual models ---\n");
frequencyManual = run_v32_axis_prediction(imported.dataset, calibration, ...
    imported.task, "full_6gpcm", struct("requested_model", "quadratic"));
assert(string(frequencyManual.selection.selected_model) == "quadratic");
assert(all(isfinite(frequencyManual.prediction_parameters(1, :, 1)), "all"));
frequencyNeural = run_v32_axis_prediction(imported.dataset, calibration, ...
    imported.task, "full_6gpcm", struct( ...
    "requested_model", "gru", "python_executable", pythonExecutable));
assert(string(frequencyNeural.selection.selected_model) == "gru");
assert(all(isfinite(frequencyNeural.prediction_parameters(1, :, 1)), "all"));

%% ===================== Module-1 plot capability per axis =====================
% v3.2-4a review: enriched probe metadata (frequency grid + ULA geometry)
% must give the full 6 standard plots for the Space axis, 6 for Time (the
% three CDF plots need >= 2 samples and degrade honestly on one route), and
% the known-region Frequency spectrum shows the beamspace/spatial plots.
fprintf("--- Module-1 plot capability ---\n");
spaceAnalysis = analyze_channel_characteristics(spaceImported.dataset, ...
    Task=spaceImported.task, Region="known", ModuleRole="input");
assert(spaceAnalysis.registry.available_standard_plot_count == 6, ...
    "Space must show 6 standard plots, got %d.", ...
    spaceAnalysis.registry.available_standard_plot_count);
assert(spaceAnalysis.registry.available_additional_plot_count == 1, ...
    "Space must show the delay-sample heatmap.");
timeAnalysis = analyze_channel_characteristics(timeImported.dataset, ...
    Task=timeImported.task, Region="known", ModuleRole="input");
assert(timeAnalysis.registry.available_standard_plot_count >= 6, ...
    "Time must show at least 6 standard plots, got %d.", ...
    timeAnalysis.registry.available_standard_plot_count);
freqAnalysis = analyze_channel_characteristics(imported.dataset, ...
    Task=imported.task, Region="known", ModuleRole="input");
assert(freqAnalysis.registry.available_standard_plot_count >= 2, ...
    "Frequency known-region must show beamspace/spatial plots.");

fprintf("PASS: v3.2-4a three-axis regression.\n");
fprintf("  frequency: recovered Nf=%d targets=%d\n", ...
    pr.ctf_dataset.dimensions.Nf, numel(targetIdx));
fprintf("  time: model=%s targets=%d\n", ...
    timePrediction.selection.selected_model, ...
    numel(timePrediction.target_parameter_sample_index));
fprintf("  space: model=%s targets=%d\n", ...
    spacePrediction.selection.selected_model, ...
    numel(spacePrediction.target_parameter_sample_index));
fprintf("  plots: space=%d+%d time=%d+%d frequency=%d+%d\n", ...
    spaceAnalysis.registry.available_standard_plot_count, ...
    spaceAnalysis.registry.available_additional_plot_count, ...
    timeAnalysis.registry.available_standard_plot_count, ...
    timeAnalysis.registry.available_additional_plot_count, ...
    freqAnalysis.registry.available_standard_plot_count, ...
    freqAnalysis.registry.available_additional_plot_count);

function [knownIdx, targetIdx] = spectrumSplit(filePath, spectrumIndex)
knownAll = h5read(filePath, "/known_index");
knownIdx = knownAll(:, spectrumIndex + 1);
knownIdx = knownIdx(~isnan(knownIdx));
targetAll = h5read(filePath, "/target_index");
targetIdx = targetAll(:, spectrumIndex + 1);
targetIdx = targetIdx(~isnan(targetIdx));
end
