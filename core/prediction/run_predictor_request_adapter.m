function result = run_predictor_request_adapter(requestPath, registryPath, config)
%RUN_PREDICTOR_REQUEST_ADAPTER Predict from a target-free JSON request.

arguments
    requestPath (1, 1) string
    registryPath (1, 1) string
    config (1, 1) struct = default_predictor_adapter_config()
end

root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
scriptPath = fullfile(root, "tools", "python", ...
    "run_step10_predictor.py");
assertFile(requestPath, "prediction request");
assertFile(registryPath, "model registry");
assertFile(scriptPath, "Python adapter entry point");
config = fillAndValidate(config);

deleteOutput = strlength(string(config.output_path)) == 0;
if deleteOutput
    outputPath = string(tempname) + ".json";
else
    outputPath = string(config.output_path);
end
cleanup = onCleanup(@() cleanupOutput(outputPath, deleteOutput));
parts = [ ...
    quote(config.python_executable), quote(scriptPath), ...
    "predict-request", ...
    "--request", quote(requestPath), ...
    "--registry", quote(registryPath), ...
    "--output", quote(outputPath), ...
    "--selection", quote(config.selection_mode), ...
    "--adaptation", quote(config.adaptation_mode), ...
    "--device", quote(config.device)];
if string(config.selection_mode) == "manual"
    parts(end + 1:end + 2) = ["--model", quote(config.requested_model)];
end
if strlength(string(config.adaptation_data_path)) > 0
    assertFile(config.adaptation_data_path, "known-region adaptation data");
    parts(end + 1:end + 2) = [ ...
        "--adaptation-data", quote(config.adaptation_data_path)];
end
[status, commandOutput] = system(strjoin(parts, " "));
if status ~= 0
    error("run_predictor_request_adapter:PythonFailure", ...
        "Target-free Predictor Adapter failed (exit %d): %s", ...
        status, strtrim(commandOutput));
end
if ~isfile(outputPath)
    error("run_predictor_request_adapter:MissingOutput", ...
        "Python completed without creating %s.", outputPath);
end
result = jsondecode(fileread(outputPath));
if ~isfield(result, "request_contains_target_ground_truth") || ...
        logical(result.request_contains_target_ground_truth)
    error("run_predictor_request_adapter:UnsafeResult", ...
        "Product prediction must declare a target-free request.");
end
if logical(result.cir_status.available)
    error("run_predictor_request_adapter:UnexpectedCIR", ...
        "Step 10 must not claim that predicted CIR is available.");
end
result.adapter = struct( ...
    "schema_version", "v3.0-matlab-predictor-request-adapter.1", ...
    "python_command_status", status, ...
    "python_summary", string(strtrim(commandOutput)));
end

function config = fillAndValidate(config)
defaults = default_predictor_adapter_config();
names = fieldnames(defaults);
for index = 1:numel(names)
    name = names{index};
    if ~isfield(config, name)
        config.(name) = defaults.(name);
    end
end
mustBeMember(string(config.selection_mode), ["auto", "manual"]);
mustBeMember(string(config.adaptation_mode), ["off", "auto", "force"]);
mustBeMember(string(config.device), ["auto", "cpu", "cuda"]);
if string(config.selection_mode) == "manual"
    mustBeMember(string(config.requested_model), ["gru", "lstm", "tcn"]);
end
end

function assertFile(path, label)
if ~isfile(path)
    error("run_predictor_request_adapter:MissingFile", ...
        "Missing %s file: %s", label, path);
end
end

function value = quote(value)
value = string(value);
value = replace(value, """", """""");
value = """" + value + """";
end

function cleanupOutput(path, shouldDelete)
if shouldDelete && isfile(path)
    delete(path);
end
end
