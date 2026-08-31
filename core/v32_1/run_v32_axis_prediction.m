function prediction = run_v32_axis_prediction(channelDataset, calibrationResult, task, backend, config)
%RUN_V32_AXIS_PREDICTION v3.2-4a unified three-axis product prediction entry.
%   Dispatches by task.axis and returns a prediction struct compatible with
%   the v3.1-7 product chain (prediction_parameters, selection, model,
%   known_context_parameters, provenance, ...).
%
%     sample    -> existing v3.1-7 registry prediction (unchanged)
%     time      -> v3.2-3a AR(4) prediction of target-time DS/KF
%     space     -> v3.2-3b Persistence prediction of target-position DS/KF
%     frequency -> v3.2-3c linear-interpolation in-band recovery (no Full
%                  6GPCM; the recovered CTF is the target)
%
%   This function never reads target-region channel samples and never
%   modifies Full 6GPCM.

arguments
    channelDataset (1, 1) struct
    calibrationResult (1, 1) struct
    task (1, 1) struct
    backend (1, 1) string = "full_6gpcm"
    config (1, 1) struct = struct()
end

axis = axisName(task);
switch axis
    case "sample"
        prediction = create_v31_registry_prediction( ...
            channelDataset, calibrationResult, task, backend, config);
    case {"time", "space"}
        modelOverride = "";
        if isfield(config, "requested_model") && ...
                strlength(strtrim(string(config.requested_model))) > 0
            modelOverride = lower(strtrim(string(config.requested_model)));
        end
        prediction = predictSlowParameterAxis( ...
            channelDataset, calibrationResult, task, axis, modelOverride, config);
    case "frequency"
        modelOverride = "";
        if isfield(config, "requested_model") && ...
                strlength(strtrim(string(config.requested_model))) > 0
            modelOverride = lower(strtrim(string(config.requested_model)));
        end
        prediction = recoverInBandCtf( ...
            channelDataset, calibrationResult, task, modelOverride, config);
    otherwise
        error("run_v32_axis_prediction:UnsupportedAxis", ...
            "Unsupported product axis: %s", axis);
end
end

function axis = axisName(task)
if isfield(task, "axis")
    axis = lower(string(task.axis));
elseif isfield(task, "task_axis")
    axis = lower(string(task.task_axis));
else
    axis = "sample";
end
end

function prediction = predictSlowParameterAxis( ...
        channelDataset, calibrationResult, task, axis, modelOverride, config)
% Time/Space: extract known-region DS/KF, predict target via the studied
% method (AR for time, Persistence for space) or, when MODELOVERRIDE is a
% supported classical model, via that model; neural models (gru/lstm/tcn/
% dlinear/nlinear) are fitted online through the Python adapter (v3.2-4a,
% experimental). Assembles a v3.1-7-compatible prediction struct. Frozen
% fields come from the v3.2 registry defaults (module-2 calibration values
% when present).

knownIndices = double(task.known_indices(:));
targetIndices = double(task.target_indices(:));
knownValues = extractKnownDsKf(channelDataset, knownIndices);
nTarget = numel(targetIndices);

% Predict per parameter.
classicalModels = ["persistence", "linear", "quadratic", ...
    "holt", "harmonic", "ar", "kalman"];
neuralModels = ["gru", "lstm", "tcn", "dlinear", "nlinear"];
allModels = [classicalModels, neuralModels];
if strlength(modelOverride) > 0 && ~ismember(modelOverride, allModels)
    error("run_v32_axis_prediction:UnsupportedModel", ...
        "不支持的手动模型：%s。", modelOverride);
end

if strlength(modelOverride) > 0
    modelType = modelOverride;
    if ismember(modelType, neuralModels)
        predicted = v32_axis_neural_forecast(modelType, ...
            knownValues, knownIndices, targetIndices, ...
            PythonExecutable=neuralPython(config));
        executionContract = "known_region_manual_" + modelType + ...
            "_online_fit_extrapolation";
        selectionBasis = "v32_4a_manual_neural_online_" + axis;
    else
        predicted = v32_axis_manual_forecast( ...
            modelType, knownValues, knownIndices, targetIndices);
        executionContract = "known_region_manual_" + modelType + "_extrapolation";
        selectionBasis = "v32_4a_manual_classical_" + axis;
    end
elseif axis == "time"
    predicted = zeros(nTarget, 2);
    for column = 1:2
        predicted(:, column) = arForecast(knownValues(:, column), 4, nTarget);
    end
    modelType = "ar";
    executionContract = "known_region_ar4_extrapolation";
    selectionBasis = "v32_2a_known_region_study_" + axis;
else
    predicted = zeros(nTarget, 2);
    predicted(:, 1) = repmat(knownValues(end, 1), nTarget, 1);
    predicted(:, 2) = repmat(knownValues(end, 2), nTarget, 1);
    modelType = "persistence";
    executionContract = "known_region_persistence_extrapolation";
    selectionBasis = "v32_2a_known_region_study_" + axis;
end

parameterNames = ["DS_mu", "KF_mu", "DS_sigma", "KF_sigma", ...
    "r_DS", "LNS_ksi", "num_clusters", "num_rays"];
parameterUnits = ["log10_s", "dB", "log10_s_std", "dB", ...
    "dimensionless", "dB", "count", "count"];
frozen = frozenDefaults(calibrationResult);

values = zeros(1, nTarget, 8);
for targetNumber = 1:nTarget
    for name = ["DS_mu", "KF_mu"]
        values(1, targetNumber, find(name == parameterNames)) = ...
            predicted(targetNumber, find(name == ["DS_mu", "KF_mu"]));
    end
    for name = ["DS_sigma", "KF_sigma", "r_DS", "LNS_ksi", ...
            "num_clusters", "num_rays"]
        values(1, targetNumber, find(name == parameterNames)) = frozen.(name);
    end
end

prediction = struct( ...
    "schema_version", "v3.2-4a-" + axis + "-prediction.1", ...
    "task_type", taskTypeOf(task), ...
    "parameter_names", parameterNames, ...
    "parameter_units", parameterUnits, ...
    "prediction_parameters", values, ...
    "target_parameter_sample_index", targetIndices(:).', ...
    "selection", struct( ...
        "selected_model", modelType, ...
        "selected_model_by_parameter", struct( ...
            "DS_mu", modelType, "KF_mu", modelType, ...
            "num_clusters", "frozen_known_anchor"), ...
        "selection_basis", selectionBasis, ...
        "target_ground_truth_read_for_selection", false), ...
    "adaptation", struct( ...
        "requested_mode", "off", "status", "not_performed", ...
        "accepted", false, "official_checkpoint_overwritten", false), ...
    "model", struct( ...
        "model_type", modelType, ...
        "execution_contract", executionContract, ...
        "known_history_policy", "all_available"), ...
    "request_contains_target_ground_truth", false, ...
    "target_region_channel_samples_read", false, ...
    "known_context_parameters", knownValues, ...
    "known_context_parameter_sample_index", knownIndices(:).', ...
    "provenance", struct( ...
        "source", "v32_4a_" + axis + "_prediction", ...
        "model_selection_evidence", "v3.2-2a model study", ...
        "target_channel_samples_read", false));
end

function prediction = recoverInBandCtf( ...
        channelDataset, calibrationResult, task, modelOverride, config)
% Frequency: recover missing in-band subcarriers. Automatic mode uses the
% v3.2-4a 1A structure hybrid (contiguous block -> delay-domain OMP sparse,
% otherwise complex linear). Manual mode (MODELOVERRIDE) forecasts the
% target subcarriers along the frequency axis with the selected model on
% the [Re, Im] columns of the known subcarrier values — classical models in
% MATLAB, neural models through the Python online-fit adapter
% (experimental). The recovered complete CTF is the target; no Full 6GPCM
% call. prediction_parameters carry the recovered magnitude/phase at the
% target subcarriers (complex mean over Tx/Rx). Leakage guard: only
% known-subcarrier values are read.

parameterNames = ["magnitude", "phase"];
parameterUnits = ["linear", "rad"];
targetIndices = double(task.target_indices(:));
knownIndices = double(task.known_indices(:));
report = validate_channel_dataset(channelDataset);
if ~report.is_valid
    error("run_v32_axis_prediction:InvalidDataset", ...
        "%s", strjoin(report.errors, " | "));
end
H = channelDataset.ctf.H;                 % [Tx, Rx, Nf, Nt, N_sample]
if size(H, 4) > 1 || size(H, 5) > 1
    error("run_v32_axis_prediction:NotStaticSpectrum", ...
        "Frequency axis import must be a static spectrum (Nt=1, N_sample=1).");
end
H = reshape(double(H), size(H, 1), size(H, 2), size(H, 3));
% The imported CTF may contain values at every subcarrier (the task
% partition decides known/target). Recovery reads ONLY the known-subcarrier
% values (indexed access inside the recovery helpers); target subcarrier
% values of the input are never read, keeping the prediction leakage-free.

allModels = ["persistence", "linear", "quadratic", "holt", "harmonic", ...
    "ar", "kalman", "gru", "lstm", "tcn", "dlinear", "nlinear"];
manual = strlength(modelOverride) > 0;
if manual && ~ismember(modelOverride, allModels)
    error("run_v32_axis_prediction:UnsupportedModel", ...
        "不支持的手动模型：%s。", modelOverride);
end

if manual
    [HRecovered, method, experimental] = recoverWithModel( ...
        H, knownIndices, targetIndices, modelOverride, config);
else
    [HRecovered, method] = recover_inband_ctf_hybrid( ...
        H, knownIndices, targetIndices);
    experimental = false;
end
targetMean = mean(HRecovered(:, :, targetIndices), [1, 2]);
knownMean = mean(HRecovered(:, :, knownIndices), [1, 2]);
predicted = [abs(targetMean(:)), angle(targetMean(:))];  % [T, 2]
known = [abs(knownMean(:)), angle(knownMean(:))];        % [K, 2]

if manual
    if experimental
        selectionBasis = "v32_4a_manual_neural_online_frequency";
        executionContract = "in_band_recovery_manual_" + method + "_online_fit";
    else
        selectionBasis = "v32_4a_manual_classical_frequency";
        executionContract = "in_band_recovery_manual_" + method;
    end
    evidence = "v3.2-4a manual model override (experimental)";
    dispatch = "manual_override_model_" + method;
else
    selectionBasis = "v32_4a_structure_hybrid_1a";
    executionContract = hybridContract(method);
    evidence = "v3.2-4a study 1A (delay-domain sparse)";
    dispatch = hybridRule(method, targetIndices);
end

prediction = struct( ...
    "schema_version", "v3.2-4a-frequency-prediction.1", ...
    "task_type", taskTypeOf(task), ...
    "parameter_names", parameterNames, ...
    "parameter_units", parameterUnits, ...
    "prediction_parameters", reshape(predicted, [1, numel(targetIndices), 2]), ...
    "target_parameter_sample_index", targetIndices(:).', ...
    "selection", struct( ...
        "selected_model", method, ...
        "selected_model_by_parameter", struct( ...
            "magnitude", method, ...
            "phase", method), ...
        "selection_basis", selectionBasis, ...
        "target_ground_truth_read_for_selection", false), ...
    "adaptation", struct( ...
        "requested_mode", "off", "status", "not_performed", ...
        "accepted", false, "official_checkpoint_overwritten", false), ...
    "model", struct( ...
        "model_type", method, ...
        "execution_contract", executionContract, ...
        "known_history_policy", "known_subcarrier_observations"), ...
    "request_contains_target_ground_truth", false, ...
    "target_region_channel_samples_read", false, ...
    "known_context_parameters", known, ...
    "known_context_parameter_sample_index", knownIndices(:).', ...
    "provenance", struct( ...
        "source", "v32_4a_frequency_prediction", ...
        "model_selection_evidence", evidence, ...
        "recovery_dispatch", dispatch, ...
        "manual_experimental_override", experimental, ...
        "cir_derivation", "deterministic_ifft_of_predicted_ctf", ...
        "target_channel_samples_read", false));
end

function [HRecovered, method, experimental] = recoverWithModel( ...
        H, knownIndices, targetIndices, model, config)
% Forecast the target subcarriers along the frequency axis on the [Re, Im]
% columns of the known complex values; keep the known values as-is.
classicalModels = ["persistence", "linear", "quadratic", ...
    "holt", "harmonic", "ar", "kalman"];
neuralModels = ["gru", "lstm", "tcn", "dlinear", "nlinear"];
method = model;
experimental = ismember(method, neuralModels);
HRecovered = complex(zeros(size(H)));
known = sort(round(double(knownIndices(:))));
target = sort(round(double(targetIndices(:))));
for tx = 1:size(H, 1)
    for rx = 1:size(H, 2)
        values = squeeze(H(tx, rx, :));
        knownValues = values(known);
        reIm = [real(knownValues), imag(knownValues)];   % [K, 2]
        if experimental
            pred = v32_axis_neural_forecast(method, reIm, known, target, ...
                PythonExecutable=neuralPython(config));
        else
            pred = v32_axis_manual_forecast(method, reIm, known, target);
        end
        HRecovered(tx, rx, known) = knownValues;
        HRecovered(tx, rx, target) = pred(:, 1) + 1j * pred(:, 2);
    end
end
end

function executable = neuralPython(config)
executable = "";
if isfield(config, "python_executable")
    executable = string(config.python_executable);
end
end

function contract = hybridContract(method)
if method == "delay_domain_sparse"
    contract = "in_band_missing_subcarrier_recovery_delay_omp";
else
    contract = "in_band_missing_subcarrier_recovery_linear";
end
end

function rule = hybridRule(method, targetIndices)
if method == "delay_domain_sparse"
    rule = "target_block_ge_4_chose_delay_domain_sparse";
else
    rule = "no_contiguous_block_ge_4_chose_linear_interpolation";
end
end

function knownValues = extractKnownDsKf(channelDataset, knownIndices)
% Extract per-snapshot/per-position DS_mu and KF_mu from the known region of
% the uploaded channel (same observables as the v3.2-1 estimators).
sequence = estimate_known_region_ds_kf(channelDataset, knownIndices);
knownValues = sequence.values;
end

function frozen = frozenDefaults(calibrationResult)
frozen = struct( ...
    "DS_sigma", 0.35, "KF_sigma", 2.0, "r_DS", 2.66, ...
    "LNS_ksi", 3.33, "num_clusters", 12, "num_rays", 20);
if isfield(calibrationResult, "best") && ...
        isfield(calibrationResult.best, "parameters")
    params = calibrationResult.best.parameters;
    for name = ["DS_sigma", "KF_sigma", "r_DS", "LNS_ksi", ...
            "num_clusters", "num_rays"]
        if isfield(params, name) && isnumeric(params.(name)) && ...
                isscalar(params.(name)) && isfinite(params.(name))
            frozen.(name) = double(params.(name));
        end
    end
end
end

function value = taskTypeOf(task)
if isfield(task, "task_type")
    value = string(task.task_type);
elseif isfield(task, "mode")
    value = string(task.mode);
else
    value = "extrapolation";
end
end

function output = arForecast(values, order, horizon)
values = double(values(:));
order = min(order, numel(values) - 1);
output = nan(horizon, 1);
if order < 1
    output(:) = values(end);
    return;
end
rows = zeros(numel(values) - order, order);
for i = order + 1:numel(values)
    rows(i - order, :) = values(i - order:i - 1).';
end
target = values(order + 1:end);
design = [rows, ones(size(rows, 1), 1)];
regularizer = eye(order + 1) * 1e-3;
regularizer(end, end) = 0;
coefficients = (design.' * design + regularizer) \ (design.' * target);
rolling = values(:);
for step = 1:horizon
    row = [rolling(end - order + 1:end); 1];
    value = row.' * coefficients;
    rolling(end + 1, 1) = value; %#ok<AGROW>
    output(step) = value;
end
end
