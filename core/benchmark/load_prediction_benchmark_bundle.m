function bundle = load_prediction_benchmark_bundle(predictionDirectory)
%LOAD_PREDICTION_BENCHMARK_BUNDLE Read one formal prediction export.

arguments
    predictionDirectory (1, 1) string
end
if ~isfolder(predictionDirectory)
    error("load_prediction_benchmark_bundle:MissingDirectory", ...
        "Prediction export directory does not exist: %s", predictionDirectory);
end
required = ["predicted_cir.h5", "prediction_result.json", ...
    "generator_manifest.json", "prediction_manifest.json"];
for name = required
    if ~isfile(fullfile(predictionDirectory, name))
        error("load_prediction_benchmark_bundle:MissingFile", ...
            "Prediction export is incomplete; missing %s.", name);
    end
end
bundle = struct();
bundle.directory = predictionDirectory;
bundle.cir = read_channel_dataset_hdf5( ...
    fullfile(predictionDirectory, "predicted_cir.h5"));
ctfPath = fullfile(predictionDirectory, "predicted_ctf.h5");
bundle.ctf = struct();
if isfile(ctfPath)
    bundle.ctf = read_channel_dataset_hdf5(ctfPath);
end
bundle.result = readJson(fullfile(predictionDirectory, ...
    "prediction_result.json"));
bundle.generator_manifest = readJson(fullfile(predictionDirectory, ...
    "generator_manifest.json"));
bundle.prediction_manifest = readJson(fullfile(predictionDirectory, ...
    "prediction_manifest.json"));
if ~isfield(bundle.result, "schema_version") || ...
        string(bundle.result.schema_version) ~= "v3.0-prediction-result.1"
    error("load_prediction_benchmark_bundle:WrongSchema", ...
        "prediction_result.json is not a v3.0 prediction result.");
end
if ~isfield(bundle.result, "benchmark_context")
    error("load_prediction_benchmark_bundle:MissingBenchmarkContext", ...
        ["This export predates Step 13 and has no benchmark_context. " ...
        "Generate and export the prediction again with the current platform."]);
end
end

function value = readJson(path)
value = jsondecode(fileread(path));
end
