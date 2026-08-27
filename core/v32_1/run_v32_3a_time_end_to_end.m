function result = run_v32_3a_time_end_to_end(engineRoot)
%RUN_V32_3A_TIME_END_TO_END v3.2-3a Time-axis end-to-end chain.
%   Loads one Time route's DS/KF known sequence, predicts the target
%   time-snapshots with AR(4) (the v3.2-2a recommended Time model), assembles
%   the full P8 generator parameters (predicted DS/KF + frozen fields from
%   the v3.2 registry defaults), and runs the existing prediction-generation
%   service to produce target CIR/CTF. Verifies the chain end to end.
%
%   This is a data/chain probe; it never modifies Full 6GPCM.

arguments
    engineRoot (1, 1) string = ""
end

if engineRoot == ""
    engineRoot = resolve_full_6gpcm_root().root;
end

%% 1. Load the Time corpus sequence (raw DS/KF) for one route.
corpusFile = fullfile( ...
    "D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\chanaipulse-v3.2-corpus.1", ...
    "time_extrapolation_ds_kf.h5");
sequence = readTimeSequence(corpusFile, "time-001");

%% 2. Known region: first 16 snapshots; target: next 4 (16->4).
knownValues = sequence.values(1:16, :);      % [16, 2] DS_mu, KF_mu
knownIndex = sequence.parameter_sample_index(1:16);
targetIndex = sequence.parameter_sample_index(17:20);
targetTimeS = sequence.time_s(17:20);

%% 3. AR(4) prediction per parameter (v3.2-2a recommended Time model).
predicted = zeros(numel(targetIndex), 2);
for column = 1:2
    predicted(:, column) = arForecast(knownValues(:, column), 4, ...
        numel(targetIndex));
end

%% 4. Assemble full P8 generator parameters: predicted DS/KF + frozen fields.
%    Frozen fields come from the v3.2-0 contract defaults (module-2 style).
frozen = struct( ...
    "DS_sigma", 0.35, "KF_sigma", 2.0, "r_DS", 2.66, ...
    "LNS_ksi", 3.33, "num_clusters", 12, "num_rays", 20);
parameterNames = ["DS_mu", "KF_mu", "DS_sigma", "KF_sigma", ...
    "r_DS", "LNS_ksi", "num_clusters", "num_rays"];
parameterUnits = ["log10_s", "dB", "log10_s_std", "dB", ...
    "dimensionless", "dB", "count", "count"];

%% 5. Build the prediction struct and generation request.
prediction = struct( ...
    "schema_version", "v3.2-3a-time-prediction.1", ...
    "task_type", "extrapolation", ...
    "parameter_names", parameterNames, ...
    "parameter_units", parameterUnits, ...
    "prediction_parameters", zeros(1, numel(targetIndex), 8), ...
    "target_parameter_sample_index", targetIndex(:).', ...
    "selection", struct( ...
        "selected_model", "ar", ...
        "selected_model_by_parameter", struct( ...
            "DS_mu", "ar", "KF_mu", "ar", "num_clusters", "frozen_known_anchor"), ...
        "target_ground_truth_read_for_selection", false), ...
    "adaptation", struct( ...
        "requested_mode", "off", "status", "not_performed", ...
        "accepted", false, "official_checkpoint_overwritten", false), ...
    "model", struct( ...
        "model_type", "ar", ...
        "execution_contract", "known_region_ar4_extrapolation", ...
        "known_history_policy", "all_available"), ...
    "request_contains_target_ground_truth", false, ...
    "target_region_channel_samples_read", false, ...
    "known_context_parameters", knownValues, ...
    "known_context_parameter_sample_index", knownIndex(:).', ...
    "provenance", struct( ...
        "source", "v32_3a_time_end_to_end_probe", ...
        "target_channel_samples_read", false));

for targetNumber = 1:numel(targetIndex)
    for name = ["DS_mu", "KF_mu"]
        prediction.prediction_parameters(1, targetNumber, ...
            find(name == parameterNames)) = ...
            predicted(targetNumber, find(name == ["DS_mu", "KF_mu"]));
    end
    for name = ["DS_sigma", "KF_sigma", "r_DS", "LNS_ksi", ...
            "num_clusters", "num_rays"]
        prediction.prediction_parameters(1, targetNumber, ...
            find(name == parameterNames)) = frozen.(name);
    end
end

generationConfig = default_prediction_generation_config("full_6gpcm");
generationConfig.task_axis = "time";
generationConfig.task_axis_unit = "s";
generationConfig.target_axis_values = targetTimeS(:);
generationConfig.dimensions.Tx = 2;
generationConfig.dimensions.Rx = 4;
generationConfig.dimensions.Nt = 1;
generationConfig.dimensions.Npath = 6;
generationConfig.master_seed = 42;
generationConfig.mode = "formal";
% v3.2 uses the configurable public API adapter, not the fixed legacy
% generate_channel_v1 entry point (which hard-codes Tx=2/Rx=2/Nt=2).
generationConfig.generator_overrides.backend_options.full_interface = ...
    "public_api";
generationConfig.generator_overrides.backend_options.full_track_speed_mps = 8.0;
request = create_prediction_generation_request(prediction, generationConfig);

%% 6. Run the existing generation service (Full 6GPCM adapter).
result = run_prediction_generation(request, struct());

%% 7. Verify.
assert(result.success, "Time end-to-end generation failed: %s", ...
    strjoin(result.errors, " | "));
predictionResult = result.prediction_result;
cir = predictionResult.cir_dataset;
assert(cir.dimensions.N_sample == numel(targetIndex), ...
    "Target CIR must have one sample per target time.");
assert(isfield(cir.axes, "time_s"), "Target CIR must carry time_s axis.");
assert(isfield(predictionResult, "ctf_dataset") && ...
    ~isempty(fieldnames(predictionResult.ctf_dataset)), ...
    "CTF must be produced when enabled.");
assert(isfield(predictionResult, "analysis"), "Characteristics analysis missing.");

fprintf("PASS: v3.2-3a Time end-to-end chain.\n");
fprintf("  targets=%d  CIR samples=%d  CTF present=%d\n", ...
    numel(targetIndex), cir.dimensions.N_sample, ...
    ~isempty(fieldnames(predictionResult.ctf_dataset)));
fprintf("  target time range [%.3f, %.3f] s\n", ...
    targetTimeS(1), targetTimeS(end));
fprintf("  predicted DS [%.4f, %.4f]  KF [%.3f, %.3f]\n", ...
    min(predicted(:, 1)), max(predicted(:, 1)), ...
    min(predicted(:, 2)), max(predicted(:, 2)));
end

function sequence = readTimeSequence(filePath, groupId)
bundle = read_predictor_data_hdf5(filePath);
seq = bundle.parameter_sequence;
rows = find(seq.group_id == groupId);
sequence = struct( ...
    "values", seq.values(rows, :), ...
    "parameter_sample_index", seq.parameter_sample_index(rows), ...
    "time_s", (0:(numel(rows) - 1)).' * 0.100);
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
