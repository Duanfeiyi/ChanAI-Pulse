function split = split_predictor_dataset_by_group(dataset, config)
%SPLIT_PREDICTOR_DATASET_BY_GROUP Split without scene/route leakage.

arguments
    dataset (1, 1) struct
    config (1, 1) struct = default_predictor_data_config()
end
datasetReport = validate_predictor_dataset(dataset);
if ~datasetReport.is_valid
    error("split_predictor_dataset_by_group:InvalidDataset", ...
        "%s", strjoin(datasetReport.errors, " | "));
end
configReport = validate_predictor_data_config(config);
if ~configReport.is_valid
    error("split_predictor_dataset_by_group:InvalidConfig", ...
        "%s", strjoin(configReport.errors, " | "));
end

groups = unique(string(dataset.example_group_id), "stable");
groupCount = numel(groups);
fractions = double(config.split.fractions(:)).';
if numel(fractions) ~= 3 || any(fractions < 0) || ...
        abs(sum(fractions) - 1) > 1e-12
    error("split_predictor_dataset_by_group:InvalidFractions", ...
        "Split fractions must contain three nonnegative values summing to one.");
end

status = "PASS";
warnings = strings(0, 1);
counts = allocateCounts(groupCount, fractions);
if groupCount < 3
    status = "WARNING";
    warnings(end + 1, 1) = ...
        "Fewer than three groups are available; at least one partition is empty.";
end
trainGroups = groups(1:counts(1));
validationGroups = groups(counts(1) + (1:counts(2)));
testGroups = groups(sum(counts(1:2)) + (1:counts(3)));

partitionCode = zeros(numel(dataset.example_group_id), 1, "uint8");
partitionCode(ismember(dataset.example_group_id, trainGroups)) = 1;
partitionCode(ismember(dataset.example_group_id, validationGroups)) = 2;
partitionCode(ismember(dataset.example_group_id, testGroups)) = 3;

split = struct( ...
    "schema_version", "v3.0-predictor-split.1", ...
    "strategy", string(config.split.strategy), ...
    "partition_names", ["train", "validation", "test"], ...
    "requested_fractions", fractions, ...
    "group_order", groups, ...
    "train_group_id", trainGroups, ...
    "validation_group_id", validationGroups, ...
    "test_group_id", testGroups, ...
    "example_partition_code", partitionCode, ...
    "train_example_index", find(partitionCode == 1), ...
    "validation_example_index", find(partitionCode == 2), ...
    "test_example_index", find(partitionCode == 3), ...
    "status", status, ...
    "warnings", warnings, ...
    "leakage_check", validateNoGroupLeakage( ...
        trainGroups, validationGroups, testGroups));
end

function counts = allocateCounts(groupCount, fractions)
if groupCount == 0
    counts = [0, 0, 0];
elseif groupCount == 1
    counts = [1, 0, 0];
elseif groupCount == 2
    counts = [1, 0, 1];
else
    trainCount = max(1, floor(groupCount * fractions(1)));
    validationCount = max(1, floor(groupCount * fractions(2)));
    testCount = groupCount - trainCount - validationCount;
    if testCount < 1
        testCount = 1;
        if trainCount >= validationCount && trainCount > 1
            trainCount = trainCount - 1;
        else
            validationCount = validationCount - 1;
        end
    end
    counts = [trainCount, validationCount, testCount];
end
end

function check = validateNoGroupLeakage(trainGroups, valGroups, testGroups)
% INTERSECT can return differently shaped empty string arrays depending on
% MATLAB release. Force every result to a column before concatenating so a
% clean (no-leakage) split is itself always representable.
trainValidation = intersect(trainGroups, valGroups);
trainTest = intersect(trainGroups, testGroups);
validationTest = intersect(valGroups, testGroups);
overlap = [trainValidation(:); trainTest(:); validationTest(:)];
check = struct( ...
    "passed", isempty(overlap), ...
    "overlapping_group_id", unique(overlap));
end
