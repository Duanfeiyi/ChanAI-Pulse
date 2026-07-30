function result = run_predictor_adapter(dataPath, registryPath, config)
%RUN_PREDICTOR_ADAPTER Call the Step 10 Python predictor through JSON files.
%   RESULT = RUN_PREDICTOR_ADAPTER(DATA, REGISTRY, CONFIG) never reads
%   target truth to choose a model. Ordinary users use CONFIG.selection_mode
%   "auto"; advanced users may request "gru", "lstm", or "tcn".

arguments
    dataPath (1, 1) string
    registryPath (1, 1) string
    config (1, 1) struct = default_predictor_adapter_config()
end

root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
scriptPath = fullfile(root, "tools", "python", ...
    "run_step10_predictor.py");
assertFile(dataPath, "predictor data");
assertFile(registryPath, "model registry");
assertFile(scriptPath, "Python adapter entry point");
config = validateConfig(config);

deleteOutput = strlength(string(config.output_path)) == 0;
if deleteOutput
    outputPath = string(tempname) + ".json";
else
    outputPath = string(config.output_path);
end
cleanup = onCleanup(@() cleanupOutput(outputPath, deleteOutput));

parts = [ ...
    quote(config.python_executable), ...
    quote(scriptPath), ...
    "predict", ...
    "--data", quote(dataPath), ...
    "--registry", quote(registryPath), ...
    "--output", quote(outputPath), ...
    "--selection", quote(config.selection_mode), ...
    "--partition", quote(config.partition), ...
    "--adaptation", quote(config.adaptation_mode), ...
    "--minimum-adaptation-improvement", ...
        string(config.minimum_adaptation_improvement), ...
    "--device", quote(config.device)];
if string(config.selection_mode) == "manual"
    parts(end + 1:end + 2) = ["--model", quote(config.requested_model)];
end
[status, commandOutput] = system(strjoin(parts, " "));
if status ~= 0
    error("run_predictor_adapter:PythonFailure", ...
        "Python Predictor Adapter failed (exit %d): %s", ...
        status, strtrim(commandOutput));
end
if ~isfile(outputPath)
    error("run_predictor_adapter:MissingOutput", ...
        "Python completed without creating %s.", outputPath);
end
result = jsondecode(fileread(outputPath));
validateResult(result);
result.adapter = struct( ...
    "schema_version", "v3.0-matlab-predictor-adapter.1", ...
    "python_command_status", status, ...
    "python_summary", string(strtrim(commandOutput)));
end

function config = validateConfig(config)
defaults = default_predictor_adapter_config();
names = fieldnames(defaults);
for index = 1:numel(names)
    name = names{index};
    if ~isfield(config, name)
        config.(name) = defaults.(name);
    end
end
mustBeMember(string(config.selection_mode), ["auto", "manual"]);
mustBeMember(string(config.partition), ["train", "validation", "test", "all"]);
mustBeMember(string(config.adaptation_mode), ["off", "auto", "force"]);
mustBeMember(string(config.device), ["auto", "cpu", "cuda"]);
if string(config.selection_mode) == "manual"
    mustBeMember(string(config.requested_model), ["gru", "lstm", "tcn"]);
end
if ~isnumeric(config.minimum_adaptation_improvement) || ...
        ~isscalar(config.minimum_adaptation_improvement) || ...
        config.minimum_adaptation_improvement < 0
    error("run_predictor_adapter:InvalidConfig", ...
        "minimum_adaptation_improvement must be a nonnegative scalar.");
end
end

function validateResult(result)
required = ["schema_version", "task_type", "parameter_names", ...
    "prediction_shape", "prediction_parameters", "selection", ...
    "adaptation", "cir_status"];
for name = required
    if ~isfield(result, name)
        error("run_predictor_adapter:InvalidResult", ...
            "Prediction result is missing %s.", name);
    end
end
if logical(result.cir_status.available)
    error("run_predictor_adapter:UnexpectedCIR", ...
        "Step 10 must not claim that predicted CIR is available.");
end
end

function assertFile(path, label)
if ~isfile(path)
    error("run_predictor_adapter:MissingFile", ...
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
