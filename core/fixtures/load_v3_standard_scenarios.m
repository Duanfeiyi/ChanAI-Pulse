function scenarios = load_v3_standard_scenarios(configPath)
%LOAD_V3_STANDARD_SCENARIOS Load the four frozen Step 2 scenario configs.
%   SCENARIOS = LOAD_V3_STANDARD_SCENARIOS() reads
%   configs/v3_standard_scenarios.json relative to the repository root.
%   The returned struct array uses SI units and the canonical dimensions
%   Tx, Rx, Nf/Npath, Nt, N_sample.

arguments
    configPath (1, 1) string = ""
end

if strlength(configPath) == 0
    thisFile = mfilename("fullpath");
    repoRoot = fileparts(fileparts(fileparts(thisFile)));
    configPath = fullfile(repoRoot, "configs", ...
        "v3_standard_scenarios.json");
end
if ~isfile(configPath)
    error("load_v3_standard_scenarios:MissingConfig", ...
        "Standard-scenario config not found: %s", configPath);
end

document = jsondecode(fileread(configPath));
requiredTopFields = ["schema_version", "sample_semantics", ...
    "sample_count", "route_spacing_m", "scenarios"];
for fieldName = requiredTopFields
    if ~isfield(document, fieldName)
        error("load_v3_standard_scenarios:InvalidConfig", ...
            "Missing config field: %s", fieldName);
    end
end

scenarios = document.scenarios;
for index = 1:numel(scenarios)
    scenarios(index).schema_version = string(document.schema_version);
    scenarios(index).sample_semantics = ...
        string(document.sample_semantics);
    scenarios(index).N_sample = double(document.sample_count);
    scenarios(index).route_spacing_m = ...
        double(document.route_spacing_m);
    scenarios(index).id = string(scenarios(index).id);
    scenarios(index).display_name_zh = ...
        string(scenarios(index).display_name_zh);
end
end
