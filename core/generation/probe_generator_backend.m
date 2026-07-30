function report = probe_generator_backend(config)
%PROBE_GENERATOR_BACKEND Check availability without generating a channel.

[validation, config] = validate_generator_config(config);
report = struct( ...
    "backend", "", ...
    "available", false, ...
    "status", validation.status, ...
    "test_only", false, ...
    "supports_progress", false, ...
    "supports_cancel_between_samples", false, ...
    "supports_mid_core_cancel", false, ...
    "supports_ctf", true, ...
    "limitations", strings(0, 1), ...
    "errors", validation.errors, ...
    "warnings", validation.warnings);
if isempty(fieldnames(config))
    return;
end
report.backend = config.backend;
report.test_only = logical(config.engine.test_only);
if ~validation.is_valid
    return;
end

switch config.backend
    case "mock"
        report.available = true;
        report.supports_progress = true;
        report.supports_cancel_between_samples = true;
    case "lite_6gpcm"
        report.available = exist("generate_6gpcm_lite", "file") == 2;
        report.supports_progress = true;
        report.supports_cancel_between_samples = true;
        if ~report.available
            report.errors(end + 1, 1) = ...
                "generate_6gpcm_lite.m is not available on the MATLAB path.";
        end
    case "full_6gpcm"
        root = string(config.engine_root);
        if strlength(strtrim(root)) == 0
            report.errors(end + 1, 1) = ...
                "Full 6GPCM engine_root is not configured.";
        elseif ~isfolder(root)
            report.errors(end + 1, 1) = ...
                "The configured Full 6GPCM engine_root does not exist.";
        elseif ~isfile(fullfile(root, "generate_channel_v1.m"))
            report.errors(end + 1, 1) = ...
                "generate_channel_v1.m is missing under the configured engine_root.";
        else
            report.available = true;
        end
        report.supports_progress = true;
        report.supports_cancel_between_samples = false;
        report.supports_mid_core_cancel = false;
        report.limitations(end + 1, 1) = ...
            "The external full 6GPCM core is unmodified; cancellation is checked only before and after its monolithic call.";
end

if ~isempty(report.errors)
    report.status = "FAIL";
    report.available = false;
elseif ~isempty(report.warnings)
    report.status = "WARNING";
else
    report.status = "PASS";
end
end
