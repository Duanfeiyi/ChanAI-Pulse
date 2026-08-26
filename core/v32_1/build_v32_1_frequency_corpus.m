function manifest = build_v32_1_frequency_corpus(engineRoot, outputRoot, options)
%BUILD_V32_1_FREQUENCY_CORPUS Build the v3.2-1 Frequency CTF corpus.
%   Generates N spectra per missing pattern, each a 64-subcarrier CTF with a
%   labelled missing pattern. Stores per-spectrum known/target subcarrier
%   indices and the complete CTF (ground truth for benchmark). Raw CIR is not
%   persisted. Everything is written to OUTPUTROOT (Git-external).

arguments
    engineRoot (1, 1) string
    outputRoot (1, 1) string
    options.RouteCount (1, 1) double {mustBeInteger, mustBePositive} = 120
    options.Scenarios (1, :) string = defaultScenarios()
    options.Nf (1, 1) double {mustBeInteger, mustBePositive} = 64
    options.Patterns (1, :) string = ["uniform_half", "random_half", "block_8"]
    options.SplitFractions (1, 3) double = [0.70, 0.15, 0.15]
end

if engineRoot == ""
    engineRoot = resolve_full_6gpcm_root().root;
end
if ~isfolder(outputRoot)
    mkdir(outputRoot);
end

scenarios = options.Scenarios;
patterns = options.Patterns;
routeCount = options.RouteCount;
nf = options.Nf;
patternCount = numel(patterns);
totalSpectra = routeCount * patternCount;

% Allocate storage: each spectrum contributes a full CTF (Tx*Rx*Nf complex)
% plus known/target indices. We store them as cell arrays in a -v7.3 MAT.
ctfCells = cell(totalSpectra, 1);
knownIdxCells = cell(totalSpectra, 1);
targetIdxCells = cell(totalSpectra, 1);
patternLabel = strings(totalSpectra, 1);
scenarioLabel = strings(totalSpectra, 1);
freqHzCell = cell(totalSpectra, 1);

row = 0;
for routeIndex = 1:routeCount
    scenario = scenarios(mod(routeIndex - 1, numel(scenarios)) + 1);
    seed = 83000 + routeIndex;
    for patternIndex = 1:patternCount
        pattern = patterns(patternIndex);
        spectrum = generate_v32_1_frequency_spectrum(engineRoot, ...
            ScenarioName=scenario, Nf=nf, MissingPattern=pattern, ...
            Seed=seed + patternIndex);
        row = row + 1;
        ctfCells{row} = spectrum.ctf_dataset.ctf.H;
        knownIdxCells{row} = spectrum.known_subcarrier_index;
        targetIdxCells{row} = spectrum.target_subcarrier_index;
        patternLabel(row) = pattern;
        scenarioLabel(row) = scenario;
        freqHzCell{row} = spectrum.frequency_hz;
    end
end

% Store CTF + indices in one MAT for simplicity (Git-external, not tracked).
matFile = fullfile(outputRoot, "frequency_inband_ctf.mat");
save(matFile, "ctfCells", "knownIdxCells", "targetIdxCells", ...
    "patternLabel", "scenarioLabel", "freqHzCell", "-v7.3");
fprintf("Frequency corpus written: %s (%d spectra)\n", matFile, row);

manifest = struct( ...
    "schema_version", "v3.2-1-frequency-corpus-manifest.1", ...
    "created_utc", string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'")), ...
    "corpus_id", "chanaipulse-v3.2-corpus.1", ...
    "asset_policy", "git_external_local_asset_root", ...
    "spectra_count", row, ...
    "routes", routeCount, ...
    "patterns", patterns, ...
    "nf", nf, ...
    "split_fractions", options.SplitFractions, ...
    "engine", "full_6gpcm_public_api", ...
    "core_modified", false, ...
    "raw_cir_stored", false, ...
    "files", fileEntry("frequency_inband_ctf.mat", matFile));
manifestFile = fullfile(outputRoot, "frequency_corpus_manifest.json");
writeJsonFile(manifestFile, manifest);
fprintf("Frequency corpus manifest written: %s\n", manifestFile);
end

function entry = fileEntry(relativePath, absolutePath)
entry = struct( ...
    "relative_path", relativePath, ...
    "bytes", dir(absolutePath).bytes, ...
    "sha256", fileSha256(absolutePath));
end

function value = fileSha256(filePath)
identifier = fopen(filePath, "rb");
if identifier < 0
    error("build_v32_1_frequency_corpus:ReadFailed", ...
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
    error("build_v32_1_frequency_corpus:WriteFailed", ...
        "Could not create manifest: %s", filePath);
end
cleanup = onCleanup(@() fclose(identifier)); %#ok<NASGU>
fprintf(identifier, "%s\n", jsonencode(value, "PrettyPrint", true));
end
