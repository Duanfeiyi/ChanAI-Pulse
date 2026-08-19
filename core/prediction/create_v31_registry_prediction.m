function prediction = create_v31_registry_prediction( ...
        channelDataset, calibrationResult, task, backend, config)
%CREATE_V31_REGISTRY_PREDICTION Fit real known P8, backtest, then predict.
%   Unlike the discarded repeated-aggregate bridge, this product path
%   derives an ordered P8 sequence from target-free local channel windows.
%   A candidate must pass uploaded-known-region backtest and continuity
%   gates before its parameters can reach a channel generator.

arguments
    channelDataset (1, 1) struct
    calibrationResult (1, 1) struct
    task (1, 1) struct
    backend (1, 1) string = "lite_6gpcm"
    config (1, 1) struct = struct()
end

extractionOptions = struct();
if isfield(config, "fit_window_length")
    extractionOptions.window_length = config.fit_window_length;
end
if isfield(config, "fit_stride")
    extractionOptions.stride = config.fit_stride;
end
if isfield(config, "fit_progress_callback")
    extractionOptions.fit_progress_callback = ...
        config.fit_progress_callback;
end
if isfield(config, "cancel_check")
    extractionOptions.cancel_check = config.cancel_check;
end
extraction = extract_known_region_p8_sequence( ...
    channelDataset, task, calibrationResult, backend, extractionOptions);
predictionConfig = config;
for name = ["fit_window_length", "fit_stride", ...
        "fit_progress_callback", "cancel_check"]
    if isfield(predictionConfig, name)
        predictionConfig = rmfield(predictionConfig, name);
    end
end
prediction = run_v31_product_safety_gate( ...
    extraction, task, predictionConfig);
prediction.known_region_extraction = struct( ...
    "schema_version", extraction.schema_version, ...
    "valid_row_count", extraction.valid_row_count, ...
    "failed_row_count", extraction.failed_row_count, ...
    "target_channel_samples_read", false, ...
    "parameter_sample_index", extraction.sequence.parameter_sample_index, ...
    "fit_score", extraction.sequence.fit_score, ...
    "quality_status", extraction.sequence.quality_status, ...
    "provenance", extraction.sequence.provenance);
end
