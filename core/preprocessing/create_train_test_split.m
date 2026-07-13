function split = create_train_test_split(inputs, targets, testFraction)
%CREATE_TRAIN_TEST_SPLIT Create chronological train/test partitions.
%   Chronological splitting avoids future samples leaking into training.

arguments
    inputs {mustBeNumeric, mustBeNonempty}
    targets {mustBeNumeric, mustBeNonempty}
    testFraction (1, 1) double {mustBeGreaterThan(testFraction, 0), mustBeLessThan(testFraction, 1)} = 0.2
end

sampleCount = size(inputs, 1);
if size(targets, 1) ~= sampleCount
    error("create_train_test_split:SizeMismatch", "Inputs and targets must contain the same number of samples.");
end

testCount = max(1, round(sampleCount * testFraction));
trainCount = sampleCount - testCount;
if trainCount < 1
    error("create_train_test_split:InsufficientSamples", "At least two samples are required for a train/test split.");
end

trainIndices = (1:trainCount).';
testIndices = (trainCount + 1:sampleCount).';

split = struct();
split.train.inputs = inputs(trainIndices, :, :);
split.train.targets = targets(trainIndices, :);
split.train.indices = trainIndices;
split.test.inputs = inputs(testIndices, :, :);
split.test.targets = targets(testIndices, :);
split.test.indices = testIndices;
split.strategy = "chronological";
split.test_fraction = testFraction;
end

