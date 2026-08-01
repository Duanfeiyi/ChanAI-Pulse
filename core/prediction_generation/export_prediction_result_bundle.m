function files = export_prediction_result_bundle(result, outputDirectory)
%EXPORT_PREDICTION_RESULT_BUNDLE Export CIR, optional CTF, and manifests.
%   Existing files are never overwritten.

arguments
    result (1, 1) struct
    outputDirectory (1, 1) string
end

if ~isfield(result, "schema_version") || ...
        string(result.schema_version) ~= "v3.0-prediction-result.1"
    error("export_prediction_result_bundle:InvalidResult", ...
        "A v3.0-prediction-result.1 structure is required.");
end
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
files = struct( ...
    "cir_hdf5", fullfile(outputDirectory, "predicted_cir.h5"), ...
    "ctf_hdf5", "", ...
    "result_json", fullfile(outputDirectory, "prediction_result.json"), ...
    "generator_manifest_json", ...
        fullfile(outputDirectory, "generator_manifest.json"), ...
    "prediction_manifest_json", ...
        fullfile(outputDirectory, "prediction_manifest.json"));
paths = [files.cir_hdf5, files.result_json, ...
    files.generator_manifest_json, files.prediction_manifest_json];
if any(isfile(paths))
    error("export_prediction_result_bundle:FileExists", ...
        "Refusing to overwrite an existing Step 11 export.");
end

write_channel_dataset_hdf5(files.cir_hdf5, result.cir_dataset);
if isstruct(result.ctf_dataset) && ...
        ~isempty(fieldnames(result.ctf_dataset))
    files.ctf_hdf5 = fullfile(outputDirectory, "predicted_ctf.h5");
    if isfile(files.ctf_hdf5)
        error("export_prediction_result_bundle:FileExists", ...
            "Refusing to overwrite predicted_ctf.h5.");
    end
    write_channel_dataset_hdf5(files.ctf_hdf5, result.ctf_dataset);
end

summary = rmfield(result, ["cir_dataset", "ctf_dataset"]);
summary.analysis = compactAnalysis(result.analysis);
writeJson(files.result_json, summary);
writeJson(files.generator_manifest_json, result.generator_manifest);
writeJson(files.prediction_manifest_json, result.prediction_manifest);
end

function compact = compactAnalysis(analysis)
compact = struct( ...
    "status", analysis.status, ...
    "classification", analysis.classification, ...
    "dataset_summary", analysis.dataset_summary, ...
    "registry", analysis.registry, ...
    "warnings", analysis.warnings, ...
    "errors", analysis.errors);
if isfield(analysis, "continuity_policy")
    compact.continuity_policy = analysis.continuity_policy;
end
end

function writeJson(path, value)
identifier = fopen(path, "w", "n", "UTF-8");
if identifier < 0
    error("export_prediction_result_bundle:WriteFailed", ...
        "Could not create %s.", path);
end
cleanup = onCleanup(@() fclose(identifier));
fprintf(identifier, "%s", jsonencode(value, PrettyPrint=true));
clear cleanup
end
