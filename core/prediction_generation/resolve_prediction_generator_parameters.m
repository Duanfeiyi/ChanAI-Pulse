function [model, provenance] = resolve_prediction_generator_parameters( ...
        request, targetNumber)
%RESOLVE_PREDICTION_GENERATOR_PARAMETERS Resolve all generator parameters.
%   Predicted values win. Remaining values use calibrated -> scenario ->
%   versioned_defaults. Every value carries explicit provenance.

arguments
    request (1, 1) struct
    targetNumber (1, 1) double {mustBeInteger, mustBePositive}
end

if targetNumber > request.target_count
    error("resolve_prediction_generator_parameters:TargetOutOfRange", ...
        "targetNumber exceeds request.target_count.");
end
required = ["DS_mu", "DS_sigma", "r_DS", "num_clusters", ...
    "num_rays", "LNS_ksi", "KF_mu", "KF_sigma", "doppler_hz"];
predictedNames = string(request.parameter_names(:));
predictedValues = double(request.predicted_parameters(targetNumber, :));
provenance = repmat(struct( ...
    "name", "", "value", NaN, "source", "", "source_version", ""), ...
    numel(required), 1);
model = struct();

for index = 1:numel(required)
    name = required(index);
    predictedIndex = find(predictedNames == name, 1);
    if ~isempty(predictedIndex)
        value = predictedValues(predictedIndex);
        source = "predicted";
        sourceVersion = string(request.prediction_manifest.schema_version);
    elseif hasFiniteField(request.parameter_sources.calibrated, name)
        value = request.parameter_sources.calibrated.(name);
        source = "module2_calibrated";
        sourceVersion = sourceVersionOf( ...
            request.parameter_sources.calibrated, "calibration_version");
    elseif hasFiniteField(request.parameter_sources.scenario, name)
        value = request.parameter_sources.scenario.(name);
        source = "scenario_config";
        sourceVersion = sourceVersionOf( ...
            request.parameter_sources.scenario, "scenario_version");
    elseif hasFiniteField(request.parameter_sources.versioned_defaults, name)
        value = request.parameter_sources.versioned_defaults.(name);
        source = "versioned_default";
        sourceVersion = string( ...
            request.parameter_sources.defaults_version);
    else
        error("resolve_prediction_generator_parameters:MissingParameter", ...
            "Required generator parameter %s has no approved source.", name);
    end
    validateValue(name, value, request.parameter_bounds);
    model.(name) = double(value);
    provenance(index) = struct( ...
        "name", name, ...
        "value", double(value), ...
        "source", source, ...
        "source_version", sourceVersion);
end
end

function tf = hasFiniteField(value, name)
tf = isstruct(value) && isscalar(value) && isfield(value, name) && ...
    isnumeric(value.(name)) && isscalar(value.(name)) && ...
    isfinite(value.(name));
end

function value = sourceVersionOf(source, fieldName)
value = "unspecified";
if isfield(source, fieldName)
    value = string(source.(fieldName));
end
end

function validateValue(name, value, bounds)
if ~isnumeric(value) || ~isscalar(value) || ~isreal(value) || ...
        ~isfinite(value)
    error("resolve_prediction_generator_parameters:InvalidParameter", ...
        "%s must be a finite real scalar.", name);
end
if ~isfield(bounds, name) || numel(bounds.(name)) ~= 2
    error("resolve_prediction_generator_parameters:MissingBounds", ...
        "No validation bounds are declared for %s.", name);
end
range = double(bounds.(name));
if value < range(1) || value > range(2)
    error("resolve_prediction_generator_parameters:OutOfRange", ...
        "%s=%g is outside approved range [%g, %g].", ...
        name, value, range(1), range(2));
end
if any(name == ["num_clusters", "num_rays"]) && floor(value) ~= value
    error("resolve_prediction_generator_parameters:NonIntegerParameter", ...
        "%s must be an integer; silent rounding is forbidden.", name);
end
end
