function result = train_prediction_model(experiment, algorithm, options)
%TRAIN_PREDICTION_MODEL Train the existing TCN, LSTM, or GRU baseline.
%   This function preserves the App's layer definitions and default Adam
%   options while keeping training independent from UI controls.

arguments
    experiment (1, 1) struct
    algorithm {mustBeTextScalar}
    options.MaxEpochs (1, 1) double {mustBeInteger, mustBePositive} = 500
    options.MiniBatchSize (1, 1) double {mustBeInteger, mustBePositive} = 16
    options.InitialLearnRate (1, 1) double {mustBePositive} = 0.005
    options.LearnRateDropPeriod (1, 1) double {mustBeInteger, mustBePositive} = 200
    options.LearnRateDropFactor (1, 1) double {mustBePositive} = 0.5
    options.GradientThreshold (1, 1) double {mustBePositive} = 1
    options.PlotMode {mustBeTextScalar} = "training-progress"
    options.Verbose (1, 1) logical = false
    options.ExecutionEnvironment {mustBeTextScalar} = ""
end

validateExperiment(experiment);

xTrain = experiment.train.input_cells;
yTrain = experiment.train.targets;
xValidation = experiment.validation.input_cells;
yValidation = experiment.validation.targets;
featureCount = size(yTrain, 2);
layers = build_prediction_layers(algorithm, featureCount);

validationFrequency = max(1, floor(numel(xTrain) / options.MiniBatchSize));
trainingArgs = { ...
    "MaxEpochs", options.MaxEpochs, ...
    "MiniBatchSize", options.MiniBatchSize, ...
    "InitialLearnRate", options.InitialLearnRate, ...
    "LearnRateSchedule", "piecewise", ...
    "LearnRateDropPeriod", options.LearnRateDropPeriod, ...
    "LearnRateDropFactor", options.LearnRateDropFactor, ...
    "GradientThreshold", options.GradientThreshold, ...
    "ValidationData", {xValidation, yValidation}, ...
    "ValidationFrequency", validationFrequency, ...
    "Plots", string(options.PlotMode), ...
    "Verbose", options.Verbose};
if strlength(string(options.ExecutionEnvironment)) > 0
    trainingArgs = [trainingArgs, {"ExecutionEnvironment", string(options.ExecutionEnvironment)}]; %#ok<AGROW>
end

trainingTimer = tic;
net = trainNetwork(xTrain, yTrain, layers, trainingOptions("adam", trainingArgs{:}));
[validationPrediction, normalizedValidationPrediction] = predict_holdout_partition( ...
    net, experiment.validation, experiment.norm_params);

result = struct();
result.algorithm = upper(string(algorithm));
result.net = net;
result.layers = layers;
result.train_time = toc(trainingTimer);
result.validation_prediction = validationPrediction;
result.normalized_validation_prediction = normalizedValidationPrediction;
result.validation_rmse = compute_rmse(validationPrediction, experiment.validation.raw_targets);
result.validation_nrmse = compute_nrmse(result.validation_rmse, experiment.validation.raw_targets);
result.training_config = struct( ...
    "max_epochs", options.MaxEpochs, ...
    "mini_batch_size", options.MiniBatchSize, ...
    "initial_learn_rate", options.InitialLearnRate, ...
    "learn_rate_drop_period", options.LearnRateDropPeriod, ...
    "learn_rate_drop_factor", options.LearnRateDropFactor, ...
    "gradient_threshold", options.GradientThreshold, ...
    "validation_frequency", validationFrequency, ...
    "plot_mode", string(options.PlotMode));
end

function validateExperiment(experiment)
requiredTopLevel = ["train", "validation", "norm_params"];
for fieldName = requiredTopLevel
    if ~isfield(experiment, fieldName)
        error("train_prediction_model:InvalidExperiment", ...
            "Experiment is missing required field: %s", fieldName);
    end
end

requiredPartitionFields = ["input_cells", "targets", "raw_targets"];
for partitionName = ["train", "validation"]
    partition = experiment.(partitionName);
    for fieldName = requiredPartitionFields
        if ~isfield(partition, fieldName)
            error("train_prediction_model:InvalidExperiment", ...
                "%s partition is missing required field: %s", partitionName, fieldName);
        end
    end
end
end
