function manifest = build_v32_1_corpus(engineRoot, outputRoot, options)
%BUILD_V32_1_CORPUS Build the v3.2-1 Time/Space parameter-sequence corpus.
%   Generates 120 routes per axis (12 scenarios x 10 seeds), derives
%   per-snapshot/per-position DS_mu/KF_mu (2 fields), wraps them into a
%   single parameter sequence per axis, builds 16->4 extrapolation windows,
%   splits by group (84/18/18), and writes one HDF5 per axis to OUTPUTROOT.
%   Raw CIR is NOT persisted (only parameter sequences); a few raw-CIR probe
%   samples are kept for calibration-regression use.

arguments
    engineRoot (1, 1) string
    outputRoot (1, 1) string
    options.RouteCount (1, 1) double {mustBeInteger, mustBePositive} = 120
    options.Scenarios (1, :) string = defaultScenarios()
    options.Nt (1, 1) double {mustBeInteger, mustBePositive} = 96
    options.SpeedMps (1, 1) double {mustBePositive} = 8.0
    options.SnapshotIntervalS (1, 1) double {mustBePositive} = 0.100
    options.SplitFractions (1, 3) double = [0.70, 0.15, 0.15]
    options.RawCirSampleCount (1, 1) double {mustBeInteger, mustBeNonnegative} = 3
end

if engineRoot == ""
    engineRoot = resolve_full_6gpcm_root().root;
end
if ~isfolder(outputRoot)
    mkdir(outputRoot);
end

names2 = ["DS_mu", "KF_mu"];
bounds2 = [-9.0, -5.0; -30, 30];
scenarios = options.Scenarios;
routeCount = options.RouteCount;
dataConfig = default_predictor_data_config();
dataConfig.split.fractions = options.SplitFractions;

%% Time axis
timeValues = zeros(routeCount * options.Nt, 2);
timeGroups = strings(routeCount * options.Nt, 1);
timeSampleIndex = zeros(routeCount * options.Nt, 1);
rawCirSamples = cell(options.RawCirSampleCount, 1);
for routeIndex = 1:routeCount
    scenario = scenarios(mod(routeIndex - 1, numel(scenarios)) + 1);
    seed = 81000 + routeIndex;
    route = generate_v32_1_time_route(engineRoot, ...
        ScenarioName=scenario, SpeedMps=options.SpeedMps, ...
        SnapshotIntervalS=options.SnapshotIntervalS, ...
        TxCount=2, RxCount=4, Nt=options.Nt, Seed=seed);
    seq = estimate_v32_1_time_p8_sequence(route.dataset);
    rows = (routeIndex - 1) * options.Nt + (1:options.Nt);
    timeValues(rows, :) = seq.values;
    timeGroups(rows) = "time-" + compose("%03d", routeIndex);
    timeSampleIndex(rows) = (1:options.Nt).';
    if routeIndex <= options.RawCirSampleCount
        rawCirSamples{routeIndex} = route.dataset;
    end
end
timePS = create_parameter_sequence(timeValues, names2, struct( ...
    "group_id", timeGroups, "parameter_sample_index", timeSampleIndex, ...
    "bounds", bounds2, "label_source", "direct_channel_observed", ...
    "quality_status", repmat("PASS", routeCount * options.Nt, 1), ...
    "provenance", struct("source", "per_snapshot_local_p8_observables")));
timeDS = build_predictor_dataset(timePS, "extrapolation", dataConfig);
timeSplit = split_predictor_dataset_by_group(timeDS, dataConfig);
timeDS = normalize_predictor_dataset(timeDS, timePS, timeSplit, dataConfig);
timeFile = fullfile(outputRoot, "time_extrapolation_ds_kf.h5");
write_predictor_data_hdf5(timeFile, struct( ...
    "parameter_sequence", timePS, "dataset", timeDS, "split", timeSplit));
fprintf("Time corpus written: %s (%d examples)\n", ...
    timeFile, timeDS.summary.N_example);

%% Space axis
spaceValues = zeros(routeCount * options.Nt, 2);
spaceGroups = strings(routeCount * options.Nt, 1);
spaceSampleIndex = zeros(routeCount * options.Nt, 1);
spaceRawCirSamples = cell(options.RawCirSampleCount, 1);
for routeIndex = 1:routeCount
    scenario = scenarios(mod(routeIndex - 1, numel(scenarios)) + 1);
    seed = 82000 + routeIndex;
    route = generate_v32_1_space_route(engineRoot, ...
        ScenarioName=scenario, SpeedMps=options.SpeedMps, ...
        SnapshotIntervalS=options.SnapshotIntervalS, ...
        TxCount=2, RxCount=4, NSample=options.Nt, Seed=seed);
    seq = estimate_v32_1_space_p8_sequence(route.dataset);
    rows = (routeIndex - 1) * options.Nt + (1:options.Nt);
    spaceValues(rows, :) = seq.values;
    spaceGroups(rows) = "space-" + compose("%03d", routeIndex);
    spaceSampleIndex(rows) = (1:options.Nt).';
    if routeIndex <= options.RawCirSampleCount
        spaceRawCirSamples{routeIndex} = route.dataset;
    end
end
spacePS = create_parameter_sequence(spaceValues, names2, struct( ...
    "group_id", spaceGroups, "parameter_sample_index", spaceSampleIndex, ...
    "bounds", bounds2, "label_source", "direct_channel_observed", ...
    "quality_status", repmat("PASS", routeCount * options.Nt, 1), ...
    "provenance", struct("source", "per_position_local_p8_observables")));
spaceDS = build_predictor_dataset(spacePS, "extrapolation", dataConfig);
spaceSplit = split_predictor_dataset_by_group(spaceDS, dataConfig);
spaceDS = normalize_predictor_dataset(spaceDS, spacePS, spaceSplit, dataConfig);
spaceFile = fullfile(outputRoot, "space_extrapolation_ds_kf.h5");
write_predictor_data_hdf5(spaceFile, struct( ...
    "parameter_sequence", spacePS, "dataset", spaceDS, "split", spaceSplit));
fprintf("Space corpus written: %s (%d examples)\n", ...
    spaceFile, spaceDS.summary.N_example);

%% Raw-CIR probe samples (small, calibration-regression only)
rawFile = fullfile(outputRoot, "raw_cir_probe_samples.mat");
save(rawFile, "rawCirSamples", "spaceRawCirSamples", "-v7.3");
fprintf("Raw-CIR probe samples written: %s\n", rawFile);

files = [ ...
    fileEntry("time_extrapolation_ds_kf.h5", timeFile, outputRoot); ...
    fileEntry("space_extrapolation_ds_kf.h5", spaceFile, outputRoot); ...
    fileEntry("raw_cir_probe_samples.mat", rawFile, outputRoot)];

manifest = struct( ...
    "schema_version", "v3.2-1-corpus-manifest.1", ...
    "created_utc", string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'")), ...
    "corpus_id", "chanaipulse-v3.2-corpus.1", ...
    "asset_policy", "git_external_local_asset_root", ...
    "route_count_per_axis", routeCount, ...
    "nt_per_route", options.Nt, ...
    "speed_mps", options.SpeedMps, ...
    "snapshot_interval_s", options.SnapshotIntervalS, ...
    "split_fractions", options.SplitFractions, ...
    "time_example_count", timeDS.summary.N_example, ...
    "space_example_count", spaceDS.summary.N_example, ...
    "parameter_names", names2, ...
    "frozen_parameter_names", ...
        ["DS_sigma", "KF_sigma", "r_DS", "LNS_ksi", "num_rays", "num_clusters"], ...
    "engine", "full_6gpcm_public_api", ...
    "core_modified", false, ...
    "raw_cir_stored", false, ...
    "raw_cir_probe_samples_kept", options.RawCirSampleCount, ...
    "files", files);
manifestFile = fullfile(outputRoot, "corpus_manifest.json");
writeJsonFile(manifestFile, manifest);
fprintf("Corpus manifest written: %s\n", manifestFile);
end

function entry = fileEntry(relativePath, absolutePath, outputRoot)
entry = struct( ...
    "relative_path", relativePath, ...
    "bytes", dir(absolutePath).bytes, ...
    "sha256", fileSha256(absolutePath));
end

function value = fileSha256(filePath)
identifier = fopen(filePath, "rb");
if identifier < 0
    error("build_v32_1_corpus:ReadFailed", ...
        "Could not read file for hashing: %s", filePath);
end
cleanup = onCleanup(@() fclose(identifier)); %#ok<NASGU>
digest = javaMethod("getInstance", ...
    "java.security.MessageDigest", "SHA-256");
while ~feof(identifier)
    chunk = fread(identifier, 1024 * 1024, "*uint8");
    if ~isempty(chunk)
        digest.update(typecast(uint8(chunk(:)), "int8"));
    end
end
unsignedBytes = typecast(int8(digest.digest()), "uint8");
value = lower(string(reshape(dec2hex(unsignedBytes, 2).', 1, [])));
end

function scenarios = defaultScenarios()
scenarios = [ ...
    "sub-6 GHz_UMa_LoS", "sub-6 GHz_UMa_NLoS", ...
    "sub-6 GHz_UMi_LoS", "sub-6 GHz_UMi_NLoS", ...
    "sub-6 GHz_RMa_LoS", "sub-6 GHz_RMa_NLoS", ...
    "sub-6 GHz_Indoor_LoS", "sub-6 GHz_Indoor_NLoS", ...
    "cmWave_UMa_LoS", "cmWave_UMa_NLoS", ...
    "mmWave_UMi_LoS", "mmWave_UMi_NLoS"];
end

function writeJsonFile(filePath, value)
identifier = fopen(filePath, "w", "n", "UTF-8");
if identifier < 0
    error("build_v32_1_corpus:WriteFailed", ...
        "Could not create manifest: %s", filePath);
end
cleanup = onCleanup(@() fclose(identifier)); %#ok<NASGU>
fprintf(identifier, "%s\n", jsonencode(value, "PrettyPrint", true));
end
