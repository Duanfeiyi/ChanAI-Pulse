% ChanAI Pulse unified prediction-engine test.
% Uses a small synthetic sequence and never launches the App or reads data.

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

rng(20260713, "twister");
snapshotCount = 60;
featureCount = 8;
timeIndex = (1:snapshotCount).';
featureIndex = 1:featureCount;
sequence = -65 + 4 * sin(timeIndex / 7 + featureIndex / 3) + ...
    0.2 * randn(snapshotCount, featureCount);
experiment = prepare_temporal_prediction_experiment(sequence, "WindowLength", 6);

algorithms = ["TCN", "LSTM", "GRU"];
for algorithmIndex = 1:numel(algorithms)
    algorithm = algorithms(algorithmIndex);
    rng(20260713 + algorithmIndex, "twister");
    training = train_prediction_model(experiment, algorithm, ...
        "MaxEpochs", 1, "MiniBatchSize", 4, "PlotMode", "none", ...
        "Verbose", false, "ExecutionEnvironment", "cpu");

    assert(training.algorithm == algorithm, "Training result algorithm is incorrect.");
    assert(~isempty(training.net), "Training must return a network.");
    assert(isfinite(training.validation_rmse), "Validation RMSE must be finite.");

    prediction = run_prediction_model(training.net, experiment, experiment.norm_params, ...
        "FutureSteps", 3, "BatchSize", 2, "BandwidthHz", 100e6, ...
        "NoiseDbm", [-95, -100, -105, -110, -115], ...
        "ValidationRMSE", training.validation_rmse, ...
        "ValidationNRMSE", training.validation_nrmse);

    assert(isequal(size(prediction.Raw_Pre), size(experiment.test.raw_targets)), ...
        "Hold-out prediction dimensions must match test targets.");
    assert(numel(prediction.Future_Pre) == 2, "Prediction batch size is incorrect.");
    assert(isequal(size(prediction.Future_Pre{1}), [3, featureCount]), ...
        "Future prediction dimensions are incorrect.");
    assert(isfinite(prediction.RMSE) && isfinite(prediction.NRMSE), ...
        "Prediction metrics must be finite.");
end

fprintf("PASS: TCN, LSTM, and GRU train and predict through the unified engine.\n");
