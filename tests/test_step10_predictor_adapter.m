% Step 10 MATLAB-to-Python Predictor Adapter smoke tests.

root = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(root, "core")));

pythonExecutable = string(getenv("CHANAI_STEP10_PYTHON"));
if strlength(pythonExecutable) == 0
    pythonExecutable = "python";
end
dataRoot = fullfile(root, "demo_data", "v3_step9");
modelRoot = fullfile(root, "demo_data", "v3_step10", "models");

config = default_predictor_adapter_config();
config.python_executable = pythonExecutable;
config.device = "cpu";
config.selection_mode = "auto";
config.adaptation_mode = "off";
extrapolation = run_predictor_adapter( ...
    fullfile(dataRoot, "step9_extrapolation_standard.h5"), ...
    fullfile(modelRoot, "extrapolation", ...
        "extrapolation_model_registry.json"), config);
assert(string(extrapolation.task_type) == "extrapolation");
assert(string(extrapolation.selection.mode) == "auto");
assert(~logical(extrapolation.selection.target_ground_truth_read_for_selection));
assert(isequal(double(extrapolation.prediction_shape(:))', [18, 4, 2]));
assert(~logical(extrapolation.cir_status.available));

requestResult = run_predictor_request_adapter( ...
    fullfile(root, "demo_data", "v3_step10", "requests", ...
        "extrapolation_request.json"), ...
    fullfile(modelRoot, "extrapolation", ...
        "extrapolation_model_registry.json"), config);
assert(~logical(requestResult.request_contains_target_ground_truth));
assert(isequal(double(requestResult.prediction_shape(:))', [18, 4, 2]));
assert(max(abs(double(requestResult.prediction_normalized(:)) - ...
    double(extrapolation.prediction_normalized(:)))) < 1e-6);

config.adaptation_mode = "auto";
config.adaptation_data_path = fullfile(dataRoot, ...
    "step9_extrapolation_standard.h5");
adapted = run_predictor_request_adapter( ...
    fullfile(root, "demo_data", "v3_step10", "requests", ...
        "extrapolation_request.json"), ...
    fullfile(modelRoot, "extrapolation", ...
        "extrapolation_model_registry.json"), config);
assert(any(string(adapted.adaptation.status) == ...
    ["accepted", "rolled_back"]));
assert(double(adapted.adaptation.actual_target_overlap_count) == 0);

config.selection_mode = "manual";
config.requested_model = "gru";
config.adaptation_mode = "off";
config.adaptation_data_path = "";
interpolation = run_predictor_adapter( ...
    fullfile(dataRoot, "step9_interpolation_standard.h5"), ...
    fullfile(modelRoot, "interpolation", ...
        "interpolation_model_registry.json"), config);
assert(string(interpolation.task_type) == "interpolation");
assert(string(interpolation.selection.selected_model) == "gru");
assert(isequal(double(interpolation.prediction_shape(:))', [18, 4, 2]));

failed = false;
try
    run_predictor_adapter( ...
        fullfile(dataRoot, "step9_extrapolation_standard.h5"), ...
        fullfile(modelRoot, "interpolation", ...
            "interpolation_model_registry.json"), config);
catch exception
    failed = contains(string(exception.message), "incompatible");
end
assert(failed, "A registry for the wrong task must be rejected.");

fprintf("PASS: Step 10 MATLAB Predictor Adapter, auto/manual selection, and task isolation.\n");
