function profile = read_step11abc_full_profile(engineRoot, scenarioName, carrierFrequencyHz, fallback)
%READ_STEP11ABC_FULL_PROFILE Read public Full 6GPCM scenario settings.
%   This adapter only adds the externally supplied engine to MATLAB's path
%   for the duration of the call. It does not alter its files or classes.

arguments
    engineRoot (1, 1) string
    scenarioName (1, 1) string
    carrierFrequencyHz (1, 1) double {mustBePositive}
    fallback (1, 1) struct
end

if ~isfolder(engineRoot)
    error("read_step11abc_full_profile:EngineNotFound", ...
        "Full 6GPCM root does not exist: %s", engineRoot);
end
oldPath = path;
cleanupPath = onCleanup(@() path(oldPath)); %#ok<NASGU>
addpath(genpath(engineRoot));
if exist("simulation_parameters", "class") ~= 8 || ...
        exist("channel_model", "class") ~= 8
    error("read_step11abc_full_profile:MissingPublicApi", ...
        "The supplied engine root does not expose simulation_parameters/channel_model.");
end

sps = simulation_parameters();
sps.carrier_frequency = carrierFrequencyHz;
sps.setScenario(char(scenarioName));
cm = channel_model(sps); %#ok<NASGU>
values = double(fallback.values(:)).';
names = string(fallback.parameter_names(:)).';
source = findScenarioContainer(sps);
parameterSources = repmat("versioned_default", size(names));
for name = names
    [values(names == name), found] = readScalar( ...
        source, name, values(names == name));
    if found
        parameterSources(names == name) = "full_6gpcm_scenario";
    end
end
fallbackNames = names(parameterSources == "versioned_default");

profile = struct( ...
    "scenario_name", scenarioName, ...
    "carrier_frequency_hz", carrierFrequencyHz, ...
    "values", values, ...
    "parameter_names", names, ...
    "source", "full_6gpcm_public_api", ...
    "engine_class", "channel_model", ...
    "parameter_sources", parameterSources, ...
    "fallback_parameter_names", fallbackNames, ...
    "fallback_used", ~isempty(fallbackNames));
end

function source = findScenarioContainer(sps)
source = sps;
candidateNames = ["scen_para", "scenario_parameters", "scenario_parameter"];
for fieldName = candidateNames
    if isprop(sps, fieldName)
        candidate = sps.(fieldName);
        if isstruct(candidate) || isobject(candidate)
            source = candidate;
            return;
        end
    end
end
end

function [value, found] = readScalar(source, fieldName, fallback)
value = fallback;
found = false;
if isobject(source) && isprop(source, fieldName)
    candidate = source.(fieldName);
elseif isstruct(source) && isfield(source, fieldName)
    candidate = source.(fieldName);
else
    return;
end
candidate = double(candidate);
if isscalar(candidate) && isfinite(candidate)
    value = candidate;
    found = true;
end
end
