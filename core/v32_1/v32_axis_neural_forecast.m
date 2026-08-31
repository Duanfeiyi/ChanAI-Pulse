function predicted = v32_axis_neural_forecast(model, knownValues, knownIndices, targetIndices, options)
%V32_AXIS_NEURAL_FORECAST Experimental online-fit neural forecast (v3.2-4a).
%   Mirrors v32_axis_manual_forecast's interface and combination semantics
%   (one-sided forecasts combined with distance weighting) but runs the
%   neural models gru/lstm/tcn/dlinear/nlinear through the Python adapter
%   (v32_4_axis_neural.py), fitting a small model online on the known
%   sequence because no axis-sequence checkpoint exists. Experimental:
%   quality is not guaranteed; results are deterministic per seed.
%
%   OPTIONS may contain python_executable (default: CHANAI_STEP10_PYTHON or
%   "python"), lookback, epochs, seed.

arguments
    model (1, 1) string
    knownValues (:, :) double
    knownIndices (:, 1) double
    targetIndices (:, 1) double
    options.PythonExecutable (1, 1) string = ""
    options.Lookback (1, 1) double = 8
    options.Epochs (1, 1) double = 200
    options.Seed (1, 1) double = 7
end

model = lower(strtrim(model));
mustBeMember(model, ["gru", "lstm", "tcn", "dlinear", "nlinear"]);
knownIndices = double(knownIndices(:));
targetIndices = double(targetIndices(:));
knownValues = double(knownValues);

pythonExecutable = pythonPath(options.PythonExecutable);
scriptPath = fullfile( ...
    fileparts(fileparts(fileparts(mfilename("fullpath")))), ...
    "python", "chanai_predictor", "v32_4_axis_neural.py");
if ~isfile(scriptPath)
    error("v32_axis_neural_forecast:MissingScript", ...
        "Python adapter not found: %s", scriptPath);
end

leftMask = knownIndices < min(targetIndices);
rightMask = knownIndices > max(targetIndices);
if any(leftMask) && any(rightMask)
    forward = callOneSided(model, knownValues(leftMask, :), ...
        knownIndices(leftMask), targetIndices, "left", ...
        pythonExecutable, scriptPath, options);
    backward = callOneSided(model, knownValues(rightMask, :), ...
        knownIndices(rightMask), targetIndices, "right", ...
        pythonExecutable, scriptPath, options);
    leftDistance = abs(targetIndices - knownIndices(find(leftMask, 1, "last")));
    rightDistance = abs(knownIndices(find(rightMask, 1, "first")) - targetIndices);
    rightWeight = leftDistance ./ max(leftDistance + rightDistance, eps);
    predicted = forward .* (1 - rightWeight) + backward .* rightWeight;
elseif any(leftMask)
    predicted = callOneSided(model, knownValues(leftMask, :), ...
        knownIndices(leftMask), targetIndices, "left", ...
        pythonExecutable, scriptPath, options);
elseif any(rightMask)
    predicted = callOneSided(model, knownValues(rightMask, :), ...
        knownIndices(rightMask), targetIndices, "right", ...
        pythonExecutable, scriptPath, options);
else
    error("v32_axis_neural_forecast:NoKnownSide", ...
        "Known region must lie on at least one side of the targets.");
end
end

function predicted = callOneSided(model, values, indices, targetIndices, side, ...
        pythonExecutable, scriptPath, options)
inputFile = string(tempname) + ".json";
outputFile = string(tempname) + ".json";
cleanup = onCleanup(@() deleteFiles(inputFile, outputFile));
payload = struct( ...
    "model", model, ...
    "known_values", values, ...
    "known_index", indices(:), ...
    "target_index", targetIndices(:), ...
    "side", side, ...
    "lookback", double(options.Lookback), ...
    "epochs", double(options.Epochs), ...
    "seed", double(options.Seed));
fid = fopen(inputFile, "w", "n", "UTF-8");
fwrite(fid, jsonencode(payload), "char");
fclose(fid);
parts = [quote(pythonExecutable), quote(scriptPath), ...
    "--input", quote(inputFile), "--output", quote(outputFile)];
[status, commandOutput] = system(strjoin(parts, " "));
if status ~= 0
    error("v32_axis_neural_forecast:PythonFailure", ...
        "Python neural forecast failed (exit %d): %s", ...
        status, strtrim(commandOutput));
end
if ~isfile(outputFile)
    error("v32_axis_neural_forecast:MissingOutput", ...
        "Python completed without creating the output file.");
end
report = jsondecode(fileread(outputFile));
predicted = double(report.prediction);
if size(predicted, 1) ~= numel(targetIndices)
    error("v32_axis_neural_forecast:BadShape", ...
        "Prediction rows %d != targets %d.", ...
        size(predicted, 1), numel(targetIndices));
end
end

function value = pythonPath(configured)
value = strtrim(string(configured));
if strlength(value) == 0
    value = strtrim(string(getenv("CHANAI_STEP10_PYTHON")));
end
if strlength(value) == 0
    value = "python";
end
end

function value = quote(value)
value = string(value);
value = replace(value, """", """""");
value = """" + value + """";
end

function deleteFiles(varargin)
for index = 1:numel(varargin)
    path = varargin{index};
    if isfile(path)
        delete(path);
    end
end
end
