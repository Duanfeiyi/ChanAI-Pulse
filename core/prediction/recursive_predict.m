function futurePredictions = recursive_predict(net, normalizedWindow, normParams, options)
%RECURSIVE_PREDICT Generate future channel snapshots with the trained net.
%   The optional batch perturbation preserves the App's existing behavior
%   when the user requests more than one generated prediction set.

arguments
    net
    normalizedWindow {mustBeNumeric, mustBeNonempty}
    normParams (1, 1) struct
    options.PredictionSteps (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
    options.BatchSize (1, 1) double {mustBeInteger, mustBePositive} = 1
    options.BatchNoiseStd (1, 1) double {mustBeNonnegative} = 0.02
end

if ~isfield(normParams, "Mu") || ~isfield(normParams, "Sigma")
    error("recursive_predict:InvalidNormalization", ...
        "Normalization parameters must contain Mu and Sigma.");
end

featureCount = numel(normParams.Mu);
if size(normalizedWindow, 1) ~= featureCount
    error("recursive_predict:InvalidWindow", ...
        "Normalized window has %d features; expected %d.", ...
        size(normalizedWindow, 1), featureCount);
end

batchSize = max(1, round(options.BatchSize));
futurePredictions = cell(batchSize, 1);
muRow = normParams.Mu.';
sigmaRow = normParams.Sigma.';

for batchIndex = 1:batchSize
    currentWindow = normalizedWindow;
    if batchSize > 1
        currentWindow = currentWindow + randn(size(currentWindow)) * options.BatchNoiseStd;
    end

    currentFuture = zeros(options.PredictionSteps, featureCount);
    for stepIndex = 1:options.PredictionSteps
        normalizedPrediction = predict(net, {currentWindow});
        prediction = normalizedPrediction .* sigmaRow + muRow;
        currentFuture(stepIndex, :) = prediction;
        columnCount = size(currentWindow, 2);
        currentWindow = [currentWindow(:, 2:columnCount), normalizedPrediction.'];
    end
    futurePredictions{batchIndex} = currentFuture;
end
end
