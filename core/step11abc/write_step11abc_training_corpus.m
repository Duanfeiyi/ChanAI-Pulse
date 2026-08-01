function manifest = write_step11abc_training_corpus(corpus, outputDirectory)
%WRITE_STEP11ABC_TRAINING_CORPUS Persist HDF5 bundles and a review manifest.

arguments
    corpus (1, 1) struct
    outputDirectory (1, 1) string
end

if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
taskNames = string(fieldnames(corpus.bundles)).';
outputRows = strings(0, 1);
for taskName = taskNames
    bundleStruct = corpus.bundles.(taskName);
    bundleNames = string(fieldnames(bundleStruct)).';
    for bundleName = bundleNames
        sourceBundle = bundleStruct.(bundleName);
        bundle = struct( ...
            "parameter_sequence", sourceBundle.sequence, ...
            "dataset", sourceBundle.dataset, ...
            "split", sourceBundle.split);
        fileName = "step11abc_" + taskName + "_" + lower(bundleName) + ".h5";
        filePath = fullfile(outputDirectory, fileName);
        if isfile(filePath)
            error("write_step11abc_training_corpus:FileExists", ...
                "Refusing to overwrite review asset: %s", filePath);
        end
        write_predictor_data_hdf5(filePath, bundle);
        outputRows(end + 1, 1) = fileName; %#ok<AGROW>
    end
end
manifest = struct( ...
    "schema_version", "v3.0-step11abc-corpus-manifest.1", ...
    "created_utc", string(datetime("now", "TimeZone", "UTC", "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'")), ...
    "files", outputRows, ...
    "summary", corpus.summary, ...
    "group_catalog", table2struct(corpus.group_catalog), ...
    "scenario_profiles", [corpus.profiles{:}], ...
    "generator_defaults", corpus.generator_defaults, ...
    "parameter_bundles", corpus.config.parameter_bundles, ...
    "selection_rules", corpus.config.selection, ...
    "external_data_policy", corpus.config.external_data);
manifestPath = fullfile(outputDirectory, "step11abc_corpus_manifest.json");
fid = fopen(manifestPath, "w");
if fid < 0
    error("write_step11abc_training_corpus:CannotWriteManifest", ...
        "Cannot write %s", manifestPath);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, "%s\n", jsonencode(manifest, PrettyPrint=true));
end
