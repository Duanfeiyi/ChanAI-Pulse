function result = run_prediction_generation(request, options)
%RUN_PREDICTION_GENERATION Generate target CIR from predicted parameters.
%   Each target is generated separately because the shared generator API
%   accepts one parameter set per call. Results are published all-or-
%   nothing and never silently switch backend.
%
%   OPTIONS may contain:
%     progress_callback(event) - target/phase/progress updates
%     cancel_check()            - checked between target calls

arguments
    request (1, 1) struct
    options (1, 1) struct = struct()
end

started = utcNow();
clock = tic;
result = emptyResult(request, started);
events = repmat(emptyEvent(), 0, 1);
diagnostics = repmat(emptyDiagnostic(), requestTargetCount(request), 1);
targetResults = cell(requestTargetCount(request), 1);

try
    emit("validate", 0, 0.01, "Validating PredictionGenerationRequest");
    validation = validate_prediction_generation_request(request);
    result.validation.request = validation;
    if ~validation.is_valid
        result.errors = validation.errors;
        finalize();
        return;
    end
    result.cache_key = compute_prediction_generation_cache_key(request);

    for targetNumber = 1:request.target_count
        if isCancelled()
            result.cancelled = true;
            result.outcome = "CANCELLED";
            result.status = "WARNING";
            result.warnings(end + 1, 1) = ...
                "Cancelled before target " + targetNumber + ...
                "; no partial CIR was published.";
            result.target_diagnostics = diagnostics;
            finalize();
            return;
        end
        progressBase = (targetNumber - 1) / request.target_count;
        emit("resolve_parameters", targetNumber, ...
            progressBase + 0.02 / request.target_count, ...
            "Resolving generator parameters for target " + targetNumber);
        [model, provenance] = ...
            resolve_prediction_generator_parameters(request, targetNumber);
        targetSeed = derive_prediction_target_seed( ...
            request.master_seed, targetNumber, ...
            request.target_axis_values(targetNumber));
        generatorConfig = buildGeneratorConfig( ...
            request, model, targetSeed);
        diagnostics(targetNumber) = beginDiagnostic( ...
            request, targetNumber, targetSeed, provenance, generatorConfig);

        emit("generate_target", targetNumber, ...
            progressBase + 0.08 / request.target_count, ...
            "Generating target " + targetNumber + ...
            " of " + request.target_count);
        targetClock = tic;
        targetResult = run_generator_adapter(generatorConfig);
        elapsed = toc(targetClock);
        diagnostics(targetNumber) = finishDiagnostic( ...
            diagnostics(targetNumber), targetResult, elapsed);
        targetResults{targetNumber} = targetResult;

        if request.backend == "full_6gpcm" && ...
                elapsed > request.runtime.full_timeout_s
            diagnostics(targetNumber).success = false;
            diagnostics(targetNumber).errors(end + 1, 1) = ...
                "Full backend exceeded full_timeout_s; returned output was discarded.";
            result.errors = targetFailure(targetNumber, ...
                diagnostics(targetNumber).errors);
            result.target_diagnostics = diagnostics;
            finalize();
            return;
        end
        if ~targetResult.success
            result.errors = targetFailure(targetNumber, ...
                targetResult.errors);
            result.warnings = targetResult.warnings;
            result.target_diagnostics = diagnostics;
            finalize();
            return;
        end
        dimensionErrors = verifyTargetDimensions( ...
            targetResult.dataset, request.dimensions);
        if ~isempty(dimensionErrors)
            diagnostics(targetNumber).success = false;
            diagnostics(targetNumber).errors = [ ...
                diagnostics(targetNumber).errors; dimensionErrors];
            result.errors = targetFailure(targetNumber, dimensionErrors);
            result.target_diagnostics = diagnostics;
            finalize();
            return;
        end
        if request.mode == "formal" && ~targetResult.formal_eligible
            diagnostics(targetNumber).success = false;
            diagnostics(targetNumber).errors(end + 1, 1) = ...
                "Target output is not eligible for formal publication.";
            result.errors = targetFailure(targetNumber, ...
                diagnostics(targetNumber).errors);
            result.target_diagnostics = diagnostics;
            finalize();
            return;
        end
        emit("target_complete", targetNumber, ...
            targetNumber / request.target_count, ...
            "Target " + targetNumber + " completed");
    end

    emit("combine", request.target_count, 0.91, ...
        "Combining target CIR in requested order");
    [cirDataset, combinationManifest] = ...
        combine_prediction_target_cir(targetResults, request);
    ctfDataset = struct();
    if request.ctf.enabled
        emit("ctf", request.target_count, 0.94, ...
            "Computing CTF on the explicit frequency axis");
        ctfDataset = create_ctf_dataset_from_cir( ...
            cirDataset, double(request.ctf.frequency_hz(:)));
    end

    emit("characteristics", request.target_count, 0.97, ...
        "Running the shared module-one characteristic engine");
    analysis = analyze_channel_characteristics(cirDataset, ...
        Region="all", ModuleRole="prediction");
    analysis = apply_prediction_continuity_policy( ...
        analysis, request.continuity);
    predictionResult = create_prediction_result( ...
        request, cirDataset, ctfDataset, analysis, ...
        diagnostics, combinationManifest, result.cache_key);

    result.success = true;
    result.outcome = "SUCCEEDED";
    result.status = "PASS";
    result.formal_eligible = request.mode == "formal" && ...
        all(cellfun(@(item) item.formal_eligible, targetResults));
    result.prediction_result = predictionResult;
    result.target_diagnostics = diagnostics;
    result.warnings = collectWarnings(targetResults);
    if request.mode ~= "formal" || ~isempty(result.warnings)
        result.status = "WARNING";
    end
    emit("complete", request.target_count, 1.0, ...
        "Prediction CIR generation completed");
catch exception
    location = "";
    if ~isempty(exception.stack)
        location = " | at " + string(exception.stack(1).name) + ...
            ":" + exception.stack(1).line;
    end
    result.errors = string(exception.identifier) + " | " + ...
        string(exception.message) + location;
    result.target_diagnostics = diagnostics;
end
finalize();

    function emit(phase, targetNumber, progress, message)
        event = struct( ...
            "phase", string(phase), ...
            "target_number", double(targetNumber), ...
            "target_count", double(requestTargetCount(request)), ...
            "progress", max(0, min(1, double(progress))), ...
            "message", string(message), ...
            "timestamp_utc", utcNow());
        events(end + 1, 1) = event;
        if isfield(options, "progress_callback") && ...
                ~isempty(options.progress_callback)
            options.progress_callback(event);
        end
    end

    function cancelled = isCancelled()
        cancelled = false;
        if isfield(options, "cancel_check") && ...
                ~isempty(options.cancel_check)
            cancelled = logical(options.cancel_check());
            if ~isscalar(cancelled)
                error("run_prediction_generation:InvalidCancelCheck", ...
                    "cancel_check must return a logical scalar.");
            end
        end
    end

    function finalize()
        result.events = events;
        result.runtime.started_utc = started;
        result.runtime.finished_utc = utcNow();
        result.runtime.elapsed_s = toc(clock);
        if ~result.success && result.outcome ~= "CANCELLED"
            result.status = "FAIL";
            result.outcome = "FAILED";
            result.formal_eligible = false;
        end
        result.errors = uniqueNonempty(result.errors);
        result.warnings = uniqueNonempty(result.warnings);
    end
end

function config = buildGeneratorConfig(request, model, seed)
config = default_generator_config(request.backend);
config.mode = request.mode;
config.random_seed = seed;
config.dimensions.Tx = request.dimensions.Tx;
config.dimensions.Rx = request.dimensions.Rx;
config.dimensions.Nt = request.dimensions.Nt;
config.dimensions.N_sample = 1;
config.dimensions.Npath = request.dimensions.Npath;
config.scenario = mergeStruct(config.scenario, request.scenario);
config.model = model;
config.ctf.enabled = false;
config.ctf.frequency_hz = zeros(0, 1);
config.engine_root = request.engine_root;
config.engine = mergeStruct(config.engine, request.engine);
config = mergeStruct(config, request.generator_overrides);
end

function errors = verifyTargetDimensions(dataset, requested)
errors = strings(4, 1);
errorCount = 0;
actual = dataset.dimensions;
for name = ["Tx", "Rx", "Nt"]
    if actual.(name) ~= requested.(name)
        errorCount = errorCount + 1;
        errors(errorCount) = "Generated " + name + "=" + ...
            actual.(name) + " but request requires " + requested.(name) + ".";
    end
end
if actual.N_sample ~= 1
    errorCount = errorCount + 1;
    errors(errorCount) = ...
        "Each per-target generator call must return N_sample=1.";
end
errors = errors(1:errorCount);
end

function diagnostic = beginDiagnostic( ...
        request, targetNumber, seed, provenance, config)
diagnostic = emptyDiagnostic();
diagnostic.target_number = targetNumber;
diagnostic.target_parameter_sample_index = ...
    request.target_parameter_sample_index(targetNumber);
diagnostic.target_axis_value = request.target_axis_values(targetNumber);
diagnostic.random_seed = seed;
diagnostic.parameter_provenance = provenance;
diagnostic.generator_config = sanitize_generator_config(config);
diagnostic.target_position_injected = false;
diagnostic.position_limitation = ...
    "Current generator API accepts channel parameters but no explicit target coordinate.";
end

function diagnostic = finishDiagnostic(diagnostic, generation, elapsed)
diagnostic.success = generation.success;
diagnostic.status = generation.status;
diagnostic.outcome = generation.outcome;
diagnostic.elapsed_s = elapsed;
diagnostic.formal_eligible = generation.formal_eligible;
diagnostic.backend_manifest = generation.backend_manifest;
diagnostic.warnings = generation.warnings;
diagnostic.errors = generation.errors;
if isstruct(generation.dataset) && isfield(generation.dataset, "dimensions")
    diagnostic.actual_dimensions = generation.dataset.dimensions;
end
end

function values = targetFailure(targetNumber, errors)
values = "Target " + targetNumber + " failed: " + string(errors(:));
end

function warnings = collectWarnings(results)
counts = cellfun(@(item) numel(item.warnings), results);
warnings = strings(sum(counts), 1);
offset = 0;
for index = 1:numel(results)
    count = counts(index);
    if count > 0
        warnings(offset + (1:count), 1) = results{index}.warnings(:);
        offset = offset + count;
    end
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

function count = requestTargetCount(request)
count = 0;
if isstruct(request) && isscalar(request) && ...
        isfield(request, "target_count") && ...
        isnumeric(request.target_count) && isscalar(request.target_count) && ...
        isfinite(request.target_count) && request.target_count > 0
    count = double(request.target_count);
end
end

function result = emptyResult(request, started)
result = struct( ...
    "schema_version", "v3.0-prediction-generation-service-result.1", ...
    "status", "FAIL", ...
    "outcome", "FAILED", ...
    "success", false, ...
    "cancelled", false, ...
    "formal_eligible", false, ...
    "predicted_parameters", safeField(request, ...
        "predicted_parameters", []), ...
    "prediction_result", struct(), ...
    "target_diagnostics", repmat(emptyDiagnostic(), 0, 1), ...
    "validation", struct(), ...
    "cache_key", "", ...
    "warnings", strings(0, 1), ...
    "errors", strings(0, 1), ...
    "events", repmat(emptyEvent(), 0, 1), ...
    "runtime", struct( ...
        "started_utc", started, ...
        "finished_utc", "", ...
        "elapsed_s", NaN));
end

function value = safeField(input, name, fallback)
value = fallback;
if isstruct(input) && isscalar(input) && isfield(input, name)
    value = input.(name);
end
end

function diagnostic = emptyDiagnostic()
diagnostic = struct( ...
    "target_number", 0, ...
    "target_parameter_sample_index", NaN, ...
    "target_axis_value", NaN, ...
    "random_seed", NaN, ...
    "success", false, ...
    "status", "NOT_RUN", ...
    "outcome", "NOT_RUN", ...
    "formal_eligible", false, ...
    "elapsed_s", NaN, ...
    "parameter_provenance", struct([]), ...
    "generator_config", struct(), ...
    "target_position_injected", false, ...
    "position_limitation", "", ...
    "actual_dimensions", struct(), ...
    "backend_manifest", struct(), ...
    "warnings", strings(0, 1), ...
    "errors", strings(0, 1));
end

function event = emptyEvent()
event = struct("phase", "", "target_number", 0, ...
    "target_count", 0, "progress", 0, "message", "", ...
    "timestamp_utc", "");
end

function values = uniqueNonempty(values)
values = string(values(:));
values = values(strlength(strtrim(values)) > 0);
values = unique(values, "stable");
end

function value = utcNow()
value = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
end
