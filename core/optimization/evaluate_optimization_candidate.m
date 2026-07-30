function evaluation = evaluate_optimization_candidate( ...
        target, parameters, config, options)
%EVALUATE_OPTIMIZATION_CANDIDATE Generate and score one parameter set.

arguments
    target (1, 1) struct
    parameters (1, 1) struct
    config (1, 1) struct
    options (1, 1) struct = struct()
end

started = tic;
evaluation = struct( ...
    "success", false, ...
    "status", "FAIL", ...
    "outcome", "FAILED", ...
    "parameters", parameters, ...
    "total_score", Inf, ...
    "pdp_score", Inf, ...
    "delay_spread_score", Inf, ...
    "generation_result", struct(), ...
    "score", struct(), ...
    "runtime_s", NaN, ...
    "warnings", strings(0, 1), ...
    "errors", strings(0, 1));

try
    generatorConfig = config.generator_config;
    names = string(fieldnames(parameters));
    for index = 1:numel(names)
        generatorConfig.model.(names(index)) = parameters.(names(index));
    end
    generationOptions = struct();
    if isfield(options, "progress_callback")
        generationOptions.progress_callback = options.progress_callback;
    end
    if isfield(options, "cancel_check")
        generationOptions.cancel_check = options.cancel_check;
    end
    generation = run_generator_adapter(generatorConfig, generationOptions);
    evaluation.generation_result = generation;
    evaluation.warnings = string(generation.warnings(:));
    if generation.cancelled
        evaluation.status = "WARNING";
        evaluation.outcome = "CANCELLED";
        evaluation.errors = string(generation.errors(:));
        evaluation.runtime_s = toc(started);
        return;
    end
    if ~generation.success
        evaluation.errors = string(generation.errors(:));
        evaluation.runtime_s = toc(started);
        return;
    end
    fitScore = score_channel_fit(target, generation.dataset, config.scoring);
    evaluation.score = fitScore;
    evaluation.warnings = uniqueNonempty([ ...
        evaluation.warnings; string(fitScore.warnings(:))]);
    if ~fitScore.success
        evaluation.errors = string(fitScore.errors(:));
        evaluation.runtime_s = toc(started);
        return;
    end
    evaluation.success = true;
    evaluation.status = fitScore.status;
    evaluation.outcome = "SUCCEEDED";
    evaluation.total_score = fitScore.total;
    evaluation.pdp_score = fitScore.components.pdp;
    evaluation.delay_spread_score = fitScore.components.delay_spread;
catch exception
    evaluation.errors = string(exception.identifier) + ...
        " | " + string(exception.message);
end
evaluation.runtime_s = toc(started);
end

function values = uniqueNonempty(values)
values = string(values(:));
values = values(strlength(strtrim(values)) > 0);
values = unique(values, "stable");
end
