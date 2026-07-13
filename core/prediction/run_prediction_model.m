function result = run_prediction_model(net, experiment, normParams, options)
%RUN_PREDICTION_MODEL Run hold-out evaluation and future prediction.
%   This is the non-UI counterpart of the App's prediction callback.

arguments
    net
    experiment (1, 1) struct
    normParams (1, 1) struct
    options.FutureSteps (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
    options.BatchSize (1, 1) double {mustBeInteger, mustBePositive} = 1
    options.BandwidthHz (1, 1) double {mustBePositive}
    options.NoiseDbm {mustBeNumeric} = [-95, -100, -105, -110, -115]
    options.ValidationRMSE (1, 1) double = NaN
    options.ValidationNRMSE (1, 1) double = NaN
end

if ~isfield(experiment, "test") || ~isfield(experiment.test, "input_cells") || ...
        ~isfield(experiment.test, "raw_targets")
    error("run_prediction_model:InvalidExperiment", ...
        "Experiment must contain a test partition with input_cells and raw_targets.");
end

inferenceTimer = tic;
[predictionsDbm, normalizedPredictions] = predict_holdout_partition( ...
    net, experiment.test, normParams);
futurePredictions = recursive_predict(net, experiment.test.input_cells{end}, normParams, ...
    "PredictionSteps", options.FutureSteps, "BatchSize", options.BatchSize);

result = evaluate_prediction_result(predictionsDbm, experiment.test.raw_targets, ...
    options.BandwidthHz, "NoiseDbm", options.NoiseDbm, ...
    "ValidationRMSE", options.ValidationRMSE, ...
    "ValidationNRMSE", options.ValidationNRMSE);
result.Normalized_Pre = normalizedPredictions;
result.Future_Pre = futurePredictions;
result.InferTime = toc(inferenceTimer);
end
