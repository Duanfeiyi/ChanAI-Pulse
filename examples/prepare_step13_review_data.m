function paths = prepare_step13_review_data(outputRoot, options)
%PREPARE_STEP13_REVIEW_DATA Create deterministic Benchmark review inputs.
%   These files test the Benchmark itself; they are not model-accuracy evidence.

arguments
    outputRoot (1, 1) string = ""
    options.FixtureName (1, 1) string = "wideband_dynamic_mimo_cir.h5"
    options.NoiseSeed (1, 1) double = 1313
end
repoRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, "core")));
if outputRoot == ""
    outputRoot = fullfile(repoRoot, "review_data", "step13");
end
if isfolder(outputRoot)
    stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss_SSS"));
    outputRoot = outputRoot + "_" + stamp;
end
originalFile = fullfile(repoRoot, "demo_data", "v3_standard_fixtures", ...
    options.FixtureName);
goodDirectory = fullfile(outputRoot, "prediction_export_good");
badDirectory = fullfile(outputRoot, "prediction_export_misaligned");
mkdir(outputRoot);

original = read_channel_dataset_hdf5(originalFile);
knownCount = max(1, ceil(0.8 * original.dimensions.N_sample));
known = (1:knownCount).';
target = (knownCount + 1:original.dimensions.N_sample).';
predicted = subsetSamples(original, target);
rng(options.NoiseSeed, "twister");
noise = 0.025 * (randn(size(predicted.cir.coefficient)) + ...
    1i * randn(size(predicted.cir.coefficient))) / sqrt(2);
predicted.cir.coefficient = predicted.cir.coefficient .* (1 + noise);
predicted.axes.sample_index = target;
predicted.metadata.source = "step13_deterministic_review_fixture";
analysis = analyze_channel_characteristics(predicted, ...
    Region="all", ModuleRole="prediction");
task = struct("schema_version", "v3.0-channel-task.1", ...
    "mode", "extrapolation", "axis", "sample", ...
    "known_indices", known, "target_indices", target, ...
    "axis_values", (1:original.dimensions.N_sample).', ...
    "axis_unit", "index");
context = struct("schema_version", "v3.0-benchmark-context.1", ...
    "task", task, "original_dimensions", original.dimensions, ...
    "original_schema_version", original.schema_version, ...
    "original_file_sha256", compute_benchmark_file_sha256(originalFile), ...
    "target_ground_truth_read_by_prediction", false);
result = struct( ...
    "schema_version", "v3.0-prediction-result.1", ...
    "created_utc", utcNow(), "task_type", "extrapolation", ...
    "task_axis", "sample", "target_parameter_sample_index", target, ...
    "target_axis_values", target, "parameter_names", "review_fixture", ...
    "parameter_units", "none", "predicted_parameters", zeros(numel(target), 1), ...
    "cir_dataset", predicted, "ctf_dataset", struct(), ...
    "analysis", analysis, "capabilities", infer_channel_capabilities(predicted), ...
    "dimensions", struct("requested", predicted.dimensions, ...
        "cir_actual", predicted.dimensions, "ctf_actual", struct()), ...
    "prediction_manifest", struct("schema_version", ...
        "v3.0-step13-review-prediction.1", "model", "deterministic_perturbation", ...
        "purpose", "benchmark_review_only", ...
        "request_contains_target_ground_truth", false), ...
    "generator_manifest", struct("backend", "review_fixture", ...
        "mode", "test", "master_seed", options.NoiseSeed), ...
    "validation", struct(), "cache_key", "step13-review", ...
    "benchmark_context", context);
export_prediction_result_bundle(result, goodDirectory);

copyfile(goodDirectory, badDirectory);
badResultPath = fullfile(badDirectory, "prediction_result.json");
badResult = jsondecode(fileread(badResultPath));
badResult.benchmark_context.task.target_indices(end) = ...
    badResult.benchmark_context.task.target_indices(end) - 1;
writeJson(badResultPath, badResult);

paths = struct("original_file", originalFile, ...
    "prediction_directory", goodDirectory, ...
    "misaligned_prediction_directory", badDirectory, ...
    "output_root", outputRoot);
fprintf("Step 13 review data prepared.\nOriginal: %s\nPrediction: %s\n", ...
    paths.original_file, paths.prediction_directory);
end

function selected = subsetSamples(dataset, indices)
selected = dataset;
fields = ["coefficient", "delay_s", "path_valid", ...
    "aoa_rad", "aod_rad", "doppler_hz"];
for field = fields
    if isfield(selected.cir, field)
        value = selected.cir.(field);
        shape = size5(value);
        outputSampleCount = 1;
        if shape(5) > 1
            value = value(:, :, :, :, indices);
            outputSampleCount = numel(indices);
        end
        selected.cir.(field) = reshape(value, ...
            [shape(1:4), outputSampleCount]);
    end
end
selected.dimensions.N_sample = numel(indices);
for field = ["sample_index", "sample_position_m"]
    if isfield(selected.axes, field)
        value = selected.axes.(field);
        selected.axes.(field) = value(indices, :);
    end
end
end

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end

function writeJson(path, value)
identifier = fopen(path, "w", "n", "UTF-8");
cleanup = onCleanup(@() fclose(identifier));
fprintf(identifier, "%s", jsonencode(value, PrettyPrint=true));
clear cleanup
end

function value = utcNow()
value = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
end
