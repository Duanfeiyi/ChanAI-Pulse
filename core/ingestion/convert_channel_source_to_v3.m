function result = convert_channel_source_to_v3( ...
        inputPath, outputFile, mapping, options)
%CONVERT_CHANNEL_SOURCE_TO_V3 Dispatch approved Step 14 source adapters.

arguments
    inputPath (1, 1) string
    outputFile (1, 1) string
    mapping (1, 1) struct = default_mat_channel_mapping()
    options.ProgressCallback = []
    options.ChunkReadThresholdBytes (1, 1) double = 256 * 1024^2
    options.SampleChunkSize (1, 1) double = 64
end

inspection = inspect_mat_channel_source(inputPath);
if ~inspection.is_convertible
    error("convert_channel_source_to_v3:NotConvertible", "%s", ...
        strjoin([inspection.errors; inspection.warnings], " | "));
end
validateNewOutputs(outputFile);
sourceHashBefore = sourceHashValue(inputPath);
adapter = string(mapping.adapter);
if adapter == "" || adapter == "generic_mat"
    if inspection.source_kind == "sage_folder"
        adapter = "sage_folder";
    elseif inspection.source_kind == "legacy_wifo_hdf5"
        adapter = "legacy_wifo_hdf5";
    else
        adapter = "generic_mat";
    end
end

switch adapter
    case "generic_mat"
        result = convert_mat_channel_to_v3_hdf5(inputPath, outputFile, ...
            mapping, ProgressCallback=options.ProgressCallback, ...
            ChunkReadThresholdBytes=options.ChunkReadThresholdBytes, ...
            SampleChunkSize=options.SampleChunkSize);
    case "sage_folder"
        notify(options.ProgressCallback, 0.05, "inspection", ...
            "Known SAGE folder detected.");
        sageOptions = struct( ...
            "record_index", getField(mapping, "record_index", 1), ...
            "sample_semantics", getField(mapping, "sample_semantics", "ordered_route"), ...
            "source_id", getField(mapping, "source_id", ""));
        if isPositiveScalar(getField(mapping, "delay_bin_spacing_s", NaN))
            sageOptions.delay_bin_spacing_s = mapping.delay_bin_spacing_s;
        elseif isPositiveScalar(getField(mapping, "bandwidth_hz", NaN))
            sageOptions.bandwidth_hz = mapping.bandwidth_hz;
        else
            error("convert_channel_source_to_v3:SageDelayRequired", ...
                "SAGE conversion requires delay_bin_spacing_s or bandwidth_hz.");
        end
        notify(options.ProgressCallback, 0.25, "read_payload", ...
            "Reading ordered SAGE records.");
        legacy = convert_sage_folder_to_v3_hdf5(inputPath, outputFile, sageOptions);
        notify(options.ProgressCallback, 1.0, "complete", ...
            "SAGE folder converted to standard v3 HDF5.");
        assertSourceUnchanged(inputPath, sourceHashBefore);
        result = wrapLegacyResult(legacy, inspection, outputFile, ...
            mapping, sourceHashBefore);
    case "legacy_wifo_hdf5"
        notify(options.ProgressCallback, 0.10, "inspection", ...
            "Known legacy WiFo HDF5 detected.");
        wifoOptions = struct( ...
            "sequence_axis", getField(mapping, "sequence_axis", "sample"), ...
            "sample_semantics", getField(mapping, "sample_semantics", "ordered_route"), ...
            "source_id", getField(mapping, "source_id", ""));
        if isPositiveScalar(getField(mapping, "snapshot_interval_s", NaN))
            wifoOptions.snapshot_interval_s = mapping.snapshot_interval_s;
        end
        legacy = convert_legacy_wifo_hdf5_to_v3(inputPath, outputFile, wifoOptions);
        notify(options.ProgressCallback, 1.0, "complete", ...
            "Legacy WiFo HDF5 converted to standard v3 HDF5.");
        assertSourceUnchanged(inputPath, sourceHashBefore);
        result = wrapLegacyResult(legacy, inspection, outputFile, ...
            mapping, sourceHashBefore);
    otherwise
        error("convert_channel_source_to_v3:UnsupportedAdapter", ...
            "Unsupported conversion adapter: %s", adapter);
end
end

function result = wrapLegacyResult(legacy, inspection, outputFile, mapping, sourceHash)
manifest = struct( ...
    "schema_version", "v3.0-mat-conversion-manifest.1", ...
    "created_utc", string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'")), ...
    "source_kind", inspection.source_kind, ...
    "source_sha256", sourceHash, ...
    "source_unchanged", true, ...
    "output_file_name", fileNameOnly(outputFile), ...
    "mapping", mapping, ...
    "domain", legacy.dataset.domain, ...
    "dimensions", legacy.dataset.dimensions, ...
    "validation_status", legacy.validation.status, ...
    "validation_warnings", string(legacy.validation.warnings(:)), ...
    "capability_classification", string(legacy.capabilities.classification));
manifestFile = outputManifestPath(outputFile);
writeJson(manifestFile, manifest);
result = legacy;
result.schema_version = "v3.0-mat-conversion-result.1";
result.manifest_file = manifestFile;
result.inspection = inspection;
result.source_sha256 = sourceHash;
result.source_file_unchanged = true;
end

function validateNewOutputs(outputFile)
[folder, ~, extension] = fileparts(outputFile);
if lower(string(extension)) ~= ".h5"
    error("convert_channel_source_to_v3:InvalidOutput", ...
        "Output must use the .h5 extension.");
end
if folder ~= "" && ~isfolder(folder)
    error("convert_channel_source_to_v3:MissingOutputFolder", ...
        "Output folder does not exist: %s", folder);
end
manifestFile = outputManifestPath(outputFile);
if isfile(outputFile) || isfile(manifestFile)
    error("convert_channel_source_to_v3:OutputExists", ...
        "Refusing to overwrite an existing output or manifest: %s", outputFile);
end
end

function assertSourceUnchanged(inputPath, expectedHash)
actualHash = sourceHashValue(inputPath);
if actualHash ~= expectedHash
    error("convert_channel_source_to_v3:SourceModified", ...
        "Source data changed during conversion; output is not trusted.");
end
end

function value = sourceHashValue(path)
if isfile(path)
    value = compute_benchmark_file_sha256(path);
    return;
end
files = dir(fullfile(path, "*.mat"));
[~, order] = sort(lower(string({files.name})));
files = files(order);
parts = strings(numel(files), 1);
for index = 1:numel(files)
    filePath = string(fullfile(files(index).folder, files(index).name));
    parts(index) = string(files(index).name) + ":" + ...
        compute_benchmark_file_sha256(filePath);
end
value = sha256Text(join(parts, newline));
end

function value = sha256Text(textValue)
bytes = unicode2native(char(textValue), "UTF-8");
digest = javaMethod("getInstance", "java.security.MessageDigest", "SHA-256");
digest.update(typecast(uint8(bytes(:)), "int8"));
raw = typecast(int8(digest.digest()), "uint8");
value = lower(string(reshape(dec2hex(raw, 2).', 1, [])));
end

function notify(callback, fraction, phase, detail)
if isempty(callback), return; end
callback(struct("fraction", fraction, "phase", string(phase), ...
    "detail", string(detail), "indeterminate", false));
end

function value = getField(structure, fieldName, defaultValue)
if isfield(structure, fieldName)
    value = structure.(fieldName);
else
    value = defaultValue;
end
end

function writeJson(filePath, value)
if isfile(filePath)
    error("convert_channel_source_to_v3:ManifestExists", ...
        "Refusing to overwrite existing manifest: %s", filePath);
end
identifier = fopen(filePath, "wt", "n", "UTF-8");
if identifier < 0
    error("convert_channel_source_to_v3:ManifestWriteFailed", ...
        "Cannot create conversion manifest: %s", filePath);
end
cleanup = onCleanup(@() fclose(identifier));
fprintf(identifier, "%s\n", jsonencode(value, "PrettyPrint", true));
clear cleanup
end

function value = outputManifestPath(outputFile)
[folder, baseName] = fileparts(outputFile);
value = string(fullfile(folder, baseName + ".conversion_manifest.json"));
end

function value = fileNameOnly(path)
[~, name, extension] = fileparts(path);
value = string(name) + string(extension);
end

function tf = isPositiveScalar(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value) && value > 0;
end
