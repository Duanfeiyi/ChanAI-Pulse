function result = run_generator_adapter(config, options)
%RUN_GENERATOR_ADAPTER Execute one Step 6 generator through a shared API.
%   RESULT = RUN_GENERATOR_ADAPTER(CONFIG) returns a versioned
%   GenerationResult. Operational failures are represented by RESULT.status
%   and RESULT.errors; the dispatcher never silently changes backend.
%
%   OPTIONS may contain:
%     progress_callback(event) - receives phase/progress/message events
%     cancel_check()            - cooperative cancellation predicate

arguments
    config (1, 1) struct
    options (1, 1) struct = struct()
end

startClock = tic;
startedUtc = utcNow();
events = repmat(emptyEvent(), 0, 1);
callbackWarnings = strings(0, 1);
normalized = config;
backend = requestedBackend(config);
result = emptyResult(backend, config, startedUtc);
hooks = struct("emit", @emitEvent, "is_cancelled", @isCancelled);

try
    emitEvent("validate", 0.02, "Validating GeneratorConfig");
    [configReport, normalized] = validate_generator_config(config);
    if isempty(fieldnames(normalized))
        result = failResult(result, configReport.errors, ...
            configReport.warnings, "FAILED");
        finalizeResult();
        return;
    end
    result.backend = normalized.backend;
    result.mode = normalized.mode;
    result.config = sanitize_generator_config(normalized);
    result.validation.config = configReport;
    if ~configReport.is_valid
        result = failResult(result, configReport.errors, ...
            configReport.warnings, "FAILED");
        finalizeResult();
        return;
    end
    if isCancelled()
        result = cancelledResult(result, ...
            "Generation was cancelled before backend probing.");
        finalizeResult();
        return;
    end

    emitEvent("probe", 0.06, "Checking backend availability");
    backendReport = probe_generator_backend(normalized);
    result.backend_report = backendReport;
    result.warnings = uniqueNonempty([ ...
        configReport.warnings; backendReport.warnings]);
    if ~backendReport.available
        result = failResult(result, backendReport.errors, ...
            [configReport.warnings; backendReport.warnings], "FAILED");
        finalizeResult();
        return;
    end
    if isCancelled()
        result = cancelledResult(result, ...
            "Generation was cancelled before backend execution.");
        finalizeResult();
        return;
    end

    emitEvent("generate", 0.10, ...
        "Running " + normalized.backend + " without GUI");
    switch normalized.backend
        case "mock"
            payload = run_mock_generator_adapter(normalized, hooks);
        case "lite_6gpcm"
            payload = run_lite_6gpcm_adapter(normalized, hooks);
        case "full_6gpcm"
            payload = run_full_6gpcm_adapter(normalized, hooks);
        otherwise
            error("run_generator_adapter:UnsupportedBackend", ...
                "Unsupported backend: %s", normalized.backend);
    end

    if isCancelled()
        result = cancelledResult(result, ...
            "Generation completed, but cancellation discarded the result.");
        finalizeResult();
        return;
    end
    emitEvent("validate_output", 0.90, ...
        "Validating generated v3 CIR");
    datasetReport = validate_channel_dataset(payload.dataset);
    result.validation.dataset = datasetReport;
    if ~datasetReport.is_valid
        result = failResult(result, datasetReport.errors, ...
            [configReport.warnings; backendReport.warnings; ...
            payload.warnings; datasetReport.warnings], "FAILED");
        finalizeResult();
        return;
    end

    ctfDataset = struct();
    ctfReport = struct();
    if normalized.ctf.enabled
        emitEvent("ctf", 0.94, "Converting CIR to requested CTF");
        ctfDataset = create_ctf_dataset_from_cir( ...
            payload.dataset, normalized.ctf.frequency_hz);
        ctfReport = validate_channel_dataset(ctfDataset);
        if ~ctfReport.is_valid
            result = failResult(result, ctfReport.errors, ...
                [configReport.warnings; backendReport.warnings; ...
                payload.warnings; datasetReport.warnings; ...
                ctfReport.warnings], "FAILED");
            finalizeResult();
            return;
        end
    end

    result.dataset = payload.dataset;
    result.ctf_dataset = ctfDataset;
    result.validation.ctf = ctfReport;
    result.backend_manifest = payload.backend_manifest;
    result.warnings = uniqueNonempty([ ...
        configReport.warnings; backendReport.warnings; ...
        string(payload.warnings(:)); datasetReport.warnings; ...
        reportWarnings(ctfReport); callbackWarnings]);
    result.errors = strings(0, 1);
    result.success = true;
    result.cancelled = false;
    result.outcome = "SUCCEEDED";
    result.formal_eligible = normalized.mode == "formal" && ...
        ~backendReport.test_only;
    if isempty(result.warnings)
        result.status = "PASS";
    else
        result.status = "WARNING";
    end
    emitEvent("complete", 1.0, ...
        "Generation completed with status " + result.status);
catch exception
    if endsWith(string(exception.identifier), ":Cancelled")
        result = cancelledResult(result, string(exception.message));
    else
        identifier = string(exception.identifier);
        if identifier == ""
            identifier = "run_generator_adapter:UnhandledFailure";
        end
        publicMessage = redactMessage(string(exception.message), normalized);
        result = failResult(result, ...
            identifier + " | " + publicMessage, ...
            [result.warnings; callbackWarnings], "FAILED");
    end
end
finalizeResult();

    function emitEvent(phase, progress, message)
        event = struct( ...
            "phase", string(phase), ...
            "progress", max(0, min(1, double(progress))), ...
            "message", string(message), ...
            "timestamp_utc", utcNow());
        events(end + 1, 1) = event;
        if isfield(options, "progress_callback") && ...
                ~isempty(options.progress_callback)
            try
                options.progress_callback(event);
            catch callbackException
                callbackWarnings(end + 1, 1) = ...
                    "Progress callback failed: " + ...
                    string(callbackException.message);
            end
        end
    end

    function cancelled = isCancelled()
        cancelled = false;
        if isfield(options, "cancel_check") && ...
                ~isempty(options.cancel_check)
            try
                cancelled = logical(options.cancel_check());
                if ~isscalar(cancelled)
                    cancelled = false;
                    callbackWarnings(end + 1, 1) = ...
                        "cancel_check returned a non-scalar value and was ignored.";
                end
            catch cancelException
                callbackWarnings(end + 1, 1) = ...
                    "cancel_check failed and was ignored: " + ...
                    string(cancelException.message);
                cancelled = false;
            end
        end
    end

    function finalizeResult()
        result.warnings = uniqueNonempty([ ...
            result.warnings; callbackWarnings]);
        if result.success && ~isempty(result.warnings)
            result.status = "WARNING";
        end
        result.events = events;
        result.runtime.started_utc = startedUtc;
        result.runtime.finished_utc = utcNow();
        result.runtime.elapsed_s = toc(startClock);
        result.manifest = buildManifest(result, normalized);
    end

end

function result = emptyResult(backend, config, startedUtc)
result = struct( ...
    "schema_version", "v3.0-generation-result.1", ...
    "status", "FAIL", ...
    "outcome", "FAILED", ...
    "success", false, ...
    "cancelled", false, ...
    "formal_eligible", false, ...
    "backend", backend, ...
    "mode", "", ...
    "dataset", struct(), ...
    "ctf_dataset", struct(), ...
    "config", safePublicConfig(config), ...
    "backend_report", struct(), ...
    "backend_manifest", struct(), ...
    "validation", struct(), ...
    "warnings", strings(0, 1), ...
    "errors", strings(0, 1), ...
    "events", repmat(emptyEvent(), 0, 1), ...
    "runtime", struct( ...
        "started_utc", startedUtc, ...
        "finished_utc", "", ...
        "elapsed_s", NaN), ...
    "manifest", struct());
end

function result = failResult(result, errors, warnings, outcome)
result.status = "FAIL";
result.outcome = string(outcome);
result.success = false;
result.cancelled = false;
result.formal_eligible = false;
result.errors = uniqueNonempty(string(errors(:)));
result.warnings = uniqueNonempty(string(warnings(:)));
end

function result = cancelledResult(result, message)
result.status = "WARNING";
result.outcome = "CANCELLED";
result.success = false;
result.cancelled = true;
result.formal_eligible = false;
result.errors = strings(0, 1);
result.warnings = uniqueNonempty([result.warnings; string(message)]);
end

function manifest = buildManifest(result, normalized)
manifest = struct( ...
    "schema_version", "v3.0-generation-manifest.1", ...
    "adapter_api_version", "v3.0-step6.1", ...
    "backend", result.backend, ...
    "mode", result.mode, ...
    "status", result.status, ...
    "outcome", result.outcome, ...
    "formal_eligible", result.formal_eligible, ...
    "random_seed", safeField(normalized, "random_seed", NaN), ...
    "config", safePublicConfig(normalized), ...
    "runtime", result.runtime, ...
    "backend_manifest", result.backend_manifest, ...
    "cir_dimensions", outputDimensions(result.dataset), ...
    "ctf_dimensions", outputDimensions(result.ctf_dataset), ...
    "warnings", result.warnings, ...
    "errors", result.errors);
end

function dimensions = outputDimensions(dataset)
dimensions = struct();
if isstruct(dataset) && isscalar(dataset) && ...
        isfield(dataset, "dimensions")
    dimensions = dataset.dimensions;
end
end

function value = safeField(input, fieldName, fallback)
value = fallback;
if isstruct(input) && isscalar(input) && isfield(input, fieldName)
    value = input.(fieldName);
end
end

function public = safePublicConfig(config)
if isstruct(config) && isscalar(config)
    public = sanitize_generator_config(config);
else
    public = struct();
end
end

function backend = requestedBackend(config)
backend = "";
if isstruct(config) && isscalar(config) && isfield(config, "backend")
    backend = string(config.backend);
end
end

function warnings = reportWarnings(report)
warnings = strings(0, 1);
if isstruct(report) && isscalar(report) && isfield(report, "warnings")
    warnings = string(report.warnings(:));
end
end

function values = uniqueNonempty(values)
values = string(values(:));
values = values(strlength(strtrim(values)) > 0);
values = unique(values, "stable");
end

function message = redactMessage(message, config)
message = string(message);
if isstruct(config) && isscalar(config) && ...
        isfield(config, "engine_root")
    root = string(config.engine_root);
    if strlength(root) > 0
        message = replace(message, root, "[external_engine_root]");
        message = replace(message, replace(root, "\", "/"), ...
            "[external_engine_root]");
    end
end
end

function event = emptyEvent()
event = struct( ...
    "phase", "", ...
    "progress", 0, ...
    "message", "", ...
    "timestamp_utc", "");
end

function value = utcNow()
value = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
end
