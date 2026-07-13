function experiment = prepare_temporal_prediction_experiment(sequence, options)
%PREPARE_TEMPORAL_PREDICTION_EXPERIMENT Create leakage-safe model inputs.
%   SEQUENCE is [snapshot, delay_bin]. The chronological split is created
%   before windows and normalization. Normalization statistics are derived
%   from real training snapshots only.

arguments
    sequence {mustBeNumeric, mustBeNonempty}
    options.TrainFraction (1, 1) double = 0.70
    options.ValidationFraction (1, 1) double = 0.15
    options.WindowLength (1, 1) double {mustBeInteger, mustBePositive} = 10
    options.Horizon (1, 1) double {mustBeInteger, mustBePositive} = 1
end

if ndims(sequence) ~= 2
    error("prepare_temporal_prediction_experiment:InvalidDimensions", ...
        "Sequence must be a [snapshot, feature] matrix.");
end

sequence = double(sequence);
snapshotCount = size(sequence, 1);
trainCount = floor(snapshotCount * options.TrainFraction);
validationCount = floor(snapshotCount * options.ValidationFraction);
testCount = snapshotCount - trainCount - validationCount;
largestSafeWindow = min([trainCount, validationCount, testCount]) - options.Horizon;

if largestSafeWindow < 1
    error("prepare_temporal_prediction_experiment:InsufficientSnapshots", ...
        "At least %d snapshots are required for the requested chronological split.", ...
        3 * (options.Horizon + 1));
end

effectiveWindow = min(options.WindowLength, largestSafeWindow);
split = create_chronological_train_val_test_split(sequence, ...
    "TrainFraction", options.TrainFraction, ...
    "ValidationFraction", options.ValidationFraction, ...
    "WindowLength", effectiveWindow, ...
    "Horizon", options.Horizon);

trainingSnapshots = sequence(split.train.raw_indices, :);
mu = mean(trainingSnapshots, 1).';
sigma = std(trainingSnapshots, 0, 1).';
sigma(sigma == 0) = 1;

experiment = struct();
experiment.strategy = "chronological_train_validation_test";
experiment.fractions = split.fractions;
experiment.window_length = effectiveWindow;
experiment.horizon = options.Horizon;
experiment.norm_params = struct("Mu", mu, "Sigma", sigma, ...
    "source", "real_train_only");
experiment.train = normalizePartition(split.train, mu, sigma);
experiment.validation = normalizePartition(split.validation, mu, sigma);
experiment.test = normalizePartition(split.test, mu, sigma);
experiment.training_policy = "real_train_only";
end

function partition = normalizePartition(rawPartition, mu, sigma)
featureCount = numel(mu);
muInput = reshape(mu, 1, featureCount, 1);
sigmaInput = reshape(sigma, 1, featureCount, 1);

partition = rawPartition;
partition.raw_inputs = rawPartition.inputs;
partition.raw_targets = rawPartition.targets;
partition.inputs = (double(rawPartition.inputs) - muInput) ./ sigmaInput;
partition.targets = (double(rawPartition.targets) - mu.') ./ sigma.';
partition.input_cells = tensorToCells(partition.inputs);
end

function cells = tensorToCells(inputs)
sampleCount = size(inputs, 1);
featureCount = size(inputs, 2);
windowLength = size(inputs, 3);
cells = cell(sampleCount, 1);
for sampleIdx = 1:sampleCount
    cells{sampleIdx} = reshape(inputs(sampleIdx, :, :), featureCount, windowLength);
end
end
