function spectrum = generate_v32_1_frequency_spectrum(engineRoot, options)
%GENERATE_V32_1_FREQUENCY_SPECTRUM Build one in-band CTF spectrum with a
%   missing-subcarrier pattern for v3.2-1 Frequency-axis synthesis.
%   Uses Full 6GPCM to produce a static CIR, converts it to a CTF on an
%   absolute frequency grid via the existing cir_to_ctf path, then removes
%   target subcarriers according to a labelled missing pattern. The complete
%   CTF is retained for ground-truth benchmark use; the missing pattern is
%   recorded for per-pattern reporting.

arguments
    engineRoot (1, 1) string
    options.ScenarioName (1, 1) string = "sub-6 GHz_UMa_LoS"
    options.CarrierFrequencyHz (1, 1) double {mustBePositive} = 3.5e9
    options.SubcarrierSpacingHz (1, 1) double {mustBePositive} = 120e3
    options.Nf (1, 1) double {mustBeInteger, mustBePositive} = 64
    options.MissingPattern (1, 1) string {mustBeMember(options.MissingPattern, ...
        ["uniform_half", "random_half", "block_8"])} = "uniform_half"
    options.TxCount (1, 1) double {mustBeInteger, mustBePositive} = 2
    options.RxCount (1, 1) double {mustBeInteger, mustBePositive} = 4
    options.Seed (1, 1) double = 11011
end

% 1. Generate a static CIR (Nt=1) from Full 6GPCM.
route = generate_v32_1_time_route(engineRoot, ...
    ScenarioName=options.ScenarioName, ...
    CarrierFrequencyHz=options.CarrierFrequencyHz, ...
    TxCount=options.TxCount, RxCount=options.RxCount, Nt=1, Seed=options.Seed);
cirDataset = route.dataset;

% 2. Build an absolute frequency grid centered on the carrier.
nf = options.Nf;
offsetHz = ((0:nf-1).' - (nf - 1) / 2) * options.SubcarrierSpacingHz;
frequencyHz = options.CarrierFrequencyHz + offsetHz;

% 3. CIR -> CTF on that grid (existing v3 transform, no engine change).
ctfDataset = create_ctf_dataset_from_cir(cirDataset, frequencyHz);

% 4. Apply the labelled missing pattern.
targetIdx = missingPatternIndices(nf, options.MissingPattern, options.Seed);
knownIdx = setdiff((1:nf).', targetIdx, "stable");

spectrum = struct( ...
    "schema_version", "v3.2-1-frequency-spectrum.1", ...
    "ctf_dataset", ctfDataset, ...
    "frequency_hz", frequencyHz, ...
    "subcarrier_spacing_hz", options.SubcarrierSpacingHz, ...
    "missing_pattern", options.MissingPattern, ...
    "known_subcarrier_index", knownIdx, ...
    "target_subcarrier_index", targetIdx, ...
    "scenario_name", options.ScenarioName, ...
    "carrier_frequency_hz", options.CarrierFrequencyHz, ...
    "seed", options.Seed, ...
    "engine", "full_6gpcm_public_api", ...
    "core_modified", false);
end

function targetIdx = missingPatternIndices(nf, pattern, seed)
rng(seed, "twister");
switch pattern
    case "uniform_half"
        targetIdx = (2:2:nf).';  % every other subcarrier
    case "random_half"
        perm = randperm(nf);
        targetIdx = sort(perm(1:floor(nf / 2))).';
    case "block_8"
        center = floor(nf / 2);
        targetIdx = (center - 3:center + 4).';  % contiguous 8
    otherwise
        error("generate_v32_1_frequency_spectrum:UnknownPattern", ...
            "Unsupported missing pattern: %s", pattern);
end
end
