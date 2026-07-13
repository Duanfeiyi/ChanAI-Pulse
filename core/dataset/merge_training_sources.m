function merged = merge_training_sources(realTrain, generatedTrain, options)
%MERGE_TRAINING_SOURCES Merge real-train and synthetic-train samples only.
%   Validation and test partitions are intentionally not accepted here.

arguments
    realTrain (1, 1) struct
    generatedTrain (1, 1) struct
    options.GeneratedSourceType (1, 1) string = "synthetic_generated"
    options.GeneratedSourceId (1, 1) string = "unspecified"
end

validatePartition(realTrain, "real_train");
if ~any(options.GeneratedSourceType == ["synthetic_generated", "measurement_calibrated_synthetic"])
    error("merge_training_sources:InvalidGeneratedType", ...
        "Generated data must be synthetic_generated or measurement_calibrated_synthetic.");
end
validateInputsTargets(generatedTrain, "generatedTrain");

realInputShape = size(realTrain.inputs);
generatedInputShape = size(generatedTrain.inputs);
if ~isequal(realInputShape(2:end), generatedInputShape(2:end))
    error("merge_training_sources:InputShapeMismatch", ...
        "Real and generated training windows must have matching non-sample dimensions.");
end
if size(realTrain.targets, 2) ~= size(generatedTrain.targets, 2)
    error("merge_training_sources:TargetShapeMismatch", ...
        "Real and generated training targets must have matching feature dimensions.");
end

generatedCount = size(generatedTrain.inputs, 1);
merged = struct();
merged.inputs = cat(1, realTrain.inputs, generatedTrain.inputs);
merged.targets = cat(1, realTrain.targets, generatedTrain.targets);
merged.provenance = [ ...
    realTrain.provenance; ...
    record_data_provenance(options.GeneratedSourceType, generatedCount, "SourceId", options.GeneratedSourceId)];
merged.policy = "training_only_real_plus_synthetic";
end

function validatePartition(partition, expectedType)
validateInputsTargets(partition, "realTrain");
if ~isfield(partition, "provenance") || partition.provenance.source_type ~= expectedType
    error("merge_training_sources:InvalidRealPartition", ...
        "The first argument must be a real_train partition.");
end
end

function validateInputsTargets(partition, name)
if ~isfield(partition, "inputs") || ~isfield(partition, "targets")
    error("merge_training_sources:InvalidPartition", "%s must contain inputs and targets.", name);
end
if size(partition.inputs, 1) ~= size(partition.targets, 1)
    error("merge_training_sources:SampleCountMismatch", ...
        "%s inputs and targets must have the same sample count.", name);
end
end
