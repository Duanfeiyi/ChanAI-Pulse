function split = create_chronological_train_val_test_split(sequence, options)
%CREATE_CHRONOLOGICAL_TRAIN_VAL_TEST_SPLIT Build leakage-safe time splits.
%   The sequence is divided into contiguous train, validation, and test
%   blocks before windows are built. A window never crosses a block
%   boundary, so future samples cannot leak into training.

arguments
    sequence {mustBeNumeric, mustBeNonempty}
    options.TrainFraction (1, 1) double {mustBeGreaterThan(options.TrainFraction, 0), mustBeLessThan(options.TrainFraction, 1)} = 0.70
    options.ValidationFraction (1, 1) double {mustBeGreaterThan(options.ValidationFraction, 0), mustBeLessThan(options.ValidationFraction, 1)} = 0.15
    options.WindowLength (1, 1) double {mustBeInteger, mustBePositive} = 10
    options.Horizon (1, 1) double {mustBeInteger, mustBePositive} = 1
end

if ndims(sequence) ~= 2
    error("create_chronological_train_val_test_split:InvalidDimensions", ...
        "Sequence must be a [record, feature] matrix.");
end
if options.TrainFraction + options.ValidationFraction >= 1
    error("create_chronological_train_val_test_split:InvalidFractions", ...
        "TrainFraction + ValidationFraction must be less than 1.");
end

recordCount = size(sequence, 1);
trainEnd = floor(recordCount * options.TrainFraction);
validationEnd = trainEnd + floor(recordCount * options.ValidationFraction);
testStart = validationEnd + 1;

if trainEnd < 1 || validationEnd <= trainEnd || testStart > recordCount
    error("create_chronological_train_val_test_split:InsufficientRecords", ...
        "Sequence is too short for the requested three-way split.");
end

split = struct();
split.strategy = "chronological_nonoverlapping_windows";
split.train = buildPartition(sequence, 1:trainEnd, options.WindowLength, options.Horizon, "real_train");
split.validation = buildPartition(sequence, trainEnd + 1:validationEnd, options.WindowLength, options.Horizon, "real_validation");
split.test = buildPartition(sequence, testStart:recordCount, options.WindowLength, options.Horizon, "real_test");
split.fractions = struct("train", options.TrainFraction, ...
    "validation", options.ValidationFraction, ...
    "test", 1 - options.TrainFraction - options.ValidationFraction);
split.record_count = recordCount;
split.window_length = options.WindowLength;
split.horizon = options.Horizon;
end

function partition = buildPartition(sequence, rawIndices, windowLength, horizon, sourceType)
block = sequence(rawIndices, :);
minimumRecords = windowLength + horizon;
if size(block, 1) < minimumRecords
    error("create_chronological_train_val_test_split:PartitionTooShort", ...
        "%s needs at least %d records for the requested window and horizon.", sourceType, minimumRecords);
end

[inputs, targets, windowMeta] = build_sliding_windows(block, windowLength, horizon);
partition = struct();
partition.inputs = inputs;
partition.targets = targets;
partition.raw_indices = rawIndices(:);
partition.target_indices = rawIndices(windowMeta.target_indices).';
partition.provenance = record_data_provenance(sourceType, size(inputs, 1));
end
