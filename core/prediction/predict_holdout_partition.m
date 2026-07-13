function [prediction, normalizedPrediction] = predict_holdout_partition(net, partition, normParams)
%PREDICT_HOLDOUT_PARTITION Predict one validation or test partition.

arguments
    net
    partition (1, 1) struct
    normParams (1, 1) struct
end

if ~isfield(partition, "input_cells") || ~isfield(partition, "raw_targets")
    error("predict_holdout_partition:InvalidPartition", ...
        "Partition must contain input_cells and raw_targets.");
end
if ~isfield(normParams, "Mu") || ~isfield(normParams, "Sigma")
    error("predict_holdout_partition:InvalidNormalization", ...
        "Normalization parameters must contain Mu and Sigma.");
end

normalizedPrediction = predict(net, partition.input_cells);
prediction = normalizedPrediction .* normParams.Sigma.' + normParams.Mu.';
end
