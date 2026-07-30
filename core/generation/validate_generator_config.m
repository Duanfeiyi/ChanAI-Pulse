function [report, config] = validate_generator_config(config)
%VALIDATE_GENERATOR_CONFIG Validate and normalize a Step 6 request.
%   [REPORT, CONFIG] = VALIDATE_GENERATOR_CONFIG(CONFIG) fills missing
%   fields from backend defaults and returns PASS, WARNING, or FAIL.

report = emptyReport();
if ~isstruct(config) || ~isscalar(config)
    report = addError(report, "GeneratorConfig must be a scalar struct.");
    report = finalize(report);
    config = struct();
    return;
end
if ~isfield(config, "backend")
    report = addError(report, "GeneratorConfig.backend is required.");
    report = finalize(report);
    config = struct();
    return;
end

try
    defaults = default_generator_config(string(config.backend));
catch exception
    report = addError(report, string(exception.message));
    report = finalize(report);
    config = struct();
    return;
end
config = mergeStruct(defaults, config);
for fieldName = ["dimensions", "scenario", "model", "ctf", ...
        "backend_options", "engine"]
    if ~isfield(config, fieldName) || ...
            ~isstruct(config.(fieldName)) || ...
            ~isscalar(config.(fieldName))
        report = addError(report, ...
            fieldName + " must be a scalar struct.");
        config.(fieldName) = defaults.(fieldName);
    end
end

if ~isTextScalar(config.schema_version) || ...
        string(config.schema_version) ~= "v3.0-generator-config.1"
    report = addError(report, ...
        "schema_version must be v3.0-generator-config.1.");
end
config.backend = defaults.backend;
if isTextScalar(config.mode)
    config.mode = lower(strtrim(string(config.mode)));
else
    config.mode = "";
end
if ~isscalar(config.mode) || ...
        ~ismember(config.mode, ["preview", "formal"])
    report = addError(report, "mode must be preview or formal.");
end

if ~isNonnegativeInteger(config.random_seed)
    report = addError(report, ...
        "random_seed must be a nonnegative integer scalar.");
end

dimensionFields = ["Tx", "Rx", "Nt", "N_sample"];
for fieldName = dimensionFields
    if ~isfield(config.dimensions, fieldName) || ...
            ~isPositiveInteger(config.dimensions.(fieldName))
        report = addError(report, ...
            "dimensions." + fieldName + " must be a positive integer.");
    end
end
if ~isfield(config.dimensions, "Npath") || ...
        ~isNonnegativeInteger(config.dimensions.Npath)
    report = addError(report, ...
        "dimensions.Npath must be a nonnegative integer.");
end

positiveScenarioFields = ["center_frequency_hz", "bandwidth_hz", ...
    "snapshot_interval_s"];
for fieldName = positiveScenarioFields
    if ~isfield(config.scenario, fieldName) || ...
            ~isPositiveFinite(config.scenario.(fieldName))
        report = addError(report, ...
            "scenario." + fieldName + " must be positive and finite.");
    end
end
if ~isTextScalar(config.scenario.id) || ...
        strlength(strtrim(string(config.scenario.id))) == 0
    report = addError(report, "scenario.id must not be empty.");
end
if ~isfield(config.engine, "id") || ...
        ~isTextScalar(config.engine.id) || ...
        strlength(strtrim(string(config.engine.id))) == 0
    report = addError(report, "engine.id must not be empty.");
end
if ~isfield(config.engine, "version") || ...
        ~isTextScalar(config.engine.version) || ...
        strlength(strtrim(string(config.engine.version))) == 0
    report = addError(report, "engine.version must not be empty.");
end
if ~isfield(config.engine, "test_only") || ...
        ~islogical(config.engine.test_only) || ...
        ~isscalar(config.engine.test_only)
    report = addError(report, "engine.test_only must be a logical scalar.");
end
if ~isTextScalar(config.engine_root)
    report = addError(report, ...
        "engine_root must be a text scalar.");
else
    config.engine_root = string(config.engine_root);
end

finiteModelFields = ["DS_mu", "DS_sigma", "r_DS", "num_clusters", ...
    "num_rays", "LNS_ksi", "KF_mu", "KF_sigma", "doppler_hz"];
for fieldName = finiteModelFields
    if ~isfield(config.model, fieldName) || ...
            ~isFiniteScalar(config.model.(fieldName))
        report = addError(report, ...
            "model." + fieldName + " must be a finite numeric scalar.");
    end
end
for fieldName = ["r_DS", "num_clusters", "num_rays", "LNS_ksi"]
    if isfield(config.model, fieldName) && ...
            isFiniteScalar(config.model.(fieldName)) && ...
            config.model.(fieldName) <= 0
        report = addError(report, ...
            "model." + fieldName + " must be positive.");
    end
end
for fieldName = ["DS_sigma", "KF_sigma"]
    if isfield(config.model, fieldName) && ...
            isFiniteScalar(config.model.(fieldName)) && ...
            config.model.(fieldName) < 0
        report = addError(report, ...
            "model." + fieldName + " must be nonnegative.");
    end
end
for fieldName = ["num_clusters", "num_rays"]
    if isfield(config.model, fieldName) && ...
            ~isPositiveInteger(config.model.(fieldName))
        report = addError(report, ...
            "model." + fieldName + " must be a positive integer.");
    end
end

if ~islogical(config.ctf.enabled) || ~isscalar(config.ctf.enabled)
    report = addError(report, "ctf.enabled must be a logical scalar.");
elseif config.ctf.enabled
    frequencyHz = config.ctf.frequency_hz;
    if ~isnumeric(frequencyHz) || ~isreal(frequencyHz) || ...
            ~isvector(frequencyHz) || isempty(frequencyHz) || ...
            any(~isfinite(frequencyHz)) || ...
            (numel(frequencyHz) > 1 && any(diff(frequencyHz(:)) <= 0))
        report = addError(report, ...
            "ctf.frequency_hz must be a nonempty increasing finite vector.");
    else
        config.ctf.frequency_hz = double(frequencyHz(:));
    end
end

if isempty(report.errors)
    switch config.backend
        case "mock"
            if config.dimensions.Npath < 1
                report = addError(report, ...
                    "Mock adapter requires dimensions.Npath >= 1.");
            end
            report = addWarning(report, ...
                "Mock adapter is a project-owned test double, not a physical channel generator.");
        case "lite_6gpcm"
            if config.dimensions.Tx ~= 1 || config.dimensions.Rx ~= 1
                report = addError(report, ...
                    "6GPCM-lite currently supports Tx=1 and Rx=1 only.");
            end
            if config.dimensions.Npath ~= 0
                report = addWarning(report, ...
                    "6GPCM-lite derives Npath from its delay grid; dimensions.Npath is ignored.");
                config.dimensions.Npath = 0;
            end
            if ~isfield(config.backend_options, "lite_delay_max_ns") || ...
                    ~isPositiveFinite( ...
                    config.backend_options.lite_delay_max_ns)
                report = addError(report, ...
                    "backend_options.lite_delay_max_ns must be positive and finite.");
            end
            report = addWarning(report, ...
                "6GPCM-lite is an internal engineering generator and does not claim full 6GPCM fidelity.");
        case "full_6gpcm"
            report = validateFullFixedSettings(report, config);
    end
end

report = finalize(report);
end

function report = validateFullFixedSettings(report, config)
fixed = struct( ...
    "Tx", 2, "Rx", 2, "Nt", 2, ...
    "scenario_id", "cmWave_Indoor_LoS", ...
    "center_frequency_hz", 16e9, ...
    "track_type", "static", ...
    "snapshot_interval_s", 1.0);
if config.dimensions.Tx ~= fixed.Tx || config.dimensions.Rx ~= fixed.Rx || ...
        config.dimensions.Nt ~= fixed.Nt
    report = addError(report, ...
        "The current external generate_channel_v1 entry point fixes Tx=2, Rx=2, and Nt=2.");
end
scenarioMatches = isTextScalar(config.scenario.id) && ...
    string(config.scenario.id) == fixed.scenario_id;
trackMatches = isfield(config.scenario, "track_type") && ...
    isTextScalar(config.scenario.track_type) && ...
    lower(string(config.scenario.track_type)) == fixed.track_type;
if ~scenarioMatches || ...
        config.scenario.center_frequency_hz ~= fixed.center_frequency_hz || ...
        ~trackMatches || ...
        config.scenario.snapshot_interval_s ~= fixed.snapshot_interval_s
    report = addError(report, ...
        "The current external generate_channel_v1 entry point fixes scenario, carrier, static track, and 1 s snapshot interval.");
end
if config.dimensions.Npath ~= 0
    report = addWarning(report, ...
        "Full 6GPCM derives Npath from the generated result; dimensions.Npath is ignored.");
    config.dimensions.Npath = 0;
end
end

function output = mergeStruct(defaults, supplied)
output = defaults;
for nameCell = fieldnames(supplied).'
    name = nameCell{1};
    if isfield(output, name) && isstruct(output.(name)) && ...
            isscalar(output.(name)) && isstruct(supplied.(name)) && ...
            isscalar(supplied.(name))
        output.(name) = mergeStruct(output.(name), supplied.(name));
    else
        output.(name) = supplied.(name);
    end
end
end

function tf = isFiniteScalar(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value);
end

function tf = isTextScalar(value)
tf = (ischar(value) && (isrow(value) || isempty(value))) || ...
    (isstring(value) && isscalar(value));
end

function tf = isPositiveFinite(value)
tf = isFiniteScalar(value) && value > 0;
end

function tf = isNonnegativeInteger(value)
tf = isFiniteScalar(value) && value >= 0 && floor(value) == value;
end

function tf = isPositiveInteger(value)
tf = isNonnegativeInteger(value) && value > 0;
end

function report = emptyReport()
report = struct( ...
    "is_valid", true, ...
    "status", "PASS", ...
    "errors", strings(0, 1), ...
    "warnings", strings(0, 1));
end

function report = addError(report, message)
report.errors(end + 1, 1) = string(message);
report.is_valid = false;
end

function report = addWarning(report, message)
report.warnings(end + 1, 1) = string(message);
end

function report = finalize(report)
if ~isempty(report.errors)
    report.status = "FAIL";
    report.is_valid = false;
elseif ~isempty(report.warnings)
    report.status = "WARNING";
else
    report.status = "PASS";
end
end
