function grid = enumerate_parameter_grid(config)
%ENUMERATE_PARAMETER_GRID Enumerate every Cartesian-product candidate once.

[report, config] = validate_grid_search_config(config);
if ~report.is_valid
    error("enumerate_parameter_grid:InvalidConfig", ...
        "GridSearchConfig is invalid: %s", strjoin(report.errors, " | "));
end

names = report.parameter_names(:);
counts = zeros(numel(names), 1);
for index = 1:numel(names)
    counts(index) = numel(config.parameter_space.(names(index)));
end
total = prod(counts);
template = struct( ...
    "index", 0, ...
    "id", "", ...
    "parameters", struct(), ...
    "generator_config", struct());
grid = repmat(template, total, 1);

for candidateIndex = 1:total
    remainder = candidateIndex - 1;
    selected = zeros(numel(names), 1);
    for parameterIndex = numel(names):-1:1
        selected(parameterIndex) = ...
            mod(remainder, counts(parameterIndex)) + 1;
        remainder = floor(remainder / counts(parameterIndex));
    end

    parameters = struct();
    generatorConfig = config.generator_config;
    for parameterIndex = 1:numel(names)
        name = names(parameterIndex);
        values = config.parameter_space.(name);
        value = values(selected(parameterIndex));
        parameters.(name) = value;
        generatorConfig.model.(name) = value;
    end
    [generatorReport, generatorConfig] = ...
        validate_generator_config(generatorConfig);
    if generatorReport.status == "FAIL"
        error("enumerate_parameter_grid:InvalidCandidate", ...
            "Candidate %d is invalid: %s", candidateIndex, ...
            strjoin(generatorReport.errors, " | "));
    end

    grid(candidateIndex).index = candidateIndex;
    grid(candidateIndex).id = sprintf("GS-%06d", candidateIndex);
    grid(candidateIndex).parameters = parameters;
    grid(candidateIndex).generator_config = generatorConfig;
end
end
