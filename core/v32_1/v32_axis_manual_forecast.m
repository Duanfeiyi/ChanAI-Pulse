function predicted = v32_axis_manual_forecast(model, knownValues, knownIndices, targetIndices)
%V32_AXIS_MANUAL_FORECAST Classical forecast family for time/space axes.
%   Predicts target DS_mu/KF_mu (or any per-parameter columns) from the
%   known-region values using the selected classical model. This is the
%   MATLAB port of the v3.1 product classical family
%   (python/chanai_predictor/flexible_forecast.py) so three-axis manual
%   model selection works without a Python runtime:
%
%     persistence | linear | quadratic | holt | harmonic | ar | kalman
%
%   KNOWNVALUES is [K, P], KNOWNINDICES [K], TARGETINDICES [T]. Returns
%   [T, P]. Interpolation (known on both sides of the targets) is combined
%   with distance-weighted forward/backward forecasts, exactly like the
%   v3.1 product gate.

arguments
    model (1, 1) string
    knownValues (:, :) double
    knownIndices (:, 1) double
    targetIndices (:, 1) double
end

model = lower(strtrim(model));
mustBeMember(model, ["persistence", "linear", "quadratic", ...
    "holt", "harmonic", "ar", "kalman"]);
knownIndices = double(knownIndices(:));
targetIndices = double(targetIndices(:));
knownValues = double(knownValues);

leftMask = knownIndices < min(targetIndices);
rightMask = knownIndices > max(targetIndices);
if any(leftMask) && any(rightMask)
    forward = oneSided(model, knownValues(leftMask, :), ...
        knownIndices(leftMask), targetIndices, "left");
    backward = oneSided(model, knownValues(rightMask, :), ...
        knownIndices(rightMask), targetIndices, "right");
    leftDistance = abs(targetIndices - knownIndices(find(leftMask, 1, "last")));
    rightDistance = abs(knownIndices(find(rightMask, 1, "first")) - targetIndices);
    rightWeight = leftDistance ./ max(leftDistance + rightDistance, eps);
    predicted = forward .* (1 - rightWeight) + backward .* rightWeight;
elseif any(leftMask)
    predicted = oneSided(model, knownValues(leftMask, :), ...
        knownIndices(leftMask), targetIndices, "left");
elseif any(rightMask)
    predicted = oneSided(model, knownValues(rightMask, :), ...
        knownIndices(rightMask), targetIndices, "right");
else
    error("v32_axis_manual_forecast:NoKnownSide", ...
        "Known region must lie on at least one side of the targets.");
end
end

function predicted = oneSided(model, values, indices, targetIndices, side)
% Port of forecast_one_sided: relative axis with the near-boundary rows
% weighted most (persistence/linear/quadratic/holt/harmonic/ar/kalman).
indices = double(indices(:));
targetIndices = double(targetIndices(:));
if side == "left"
    boundary = indices(end);
    order = (1:numel(indices)).';
    historyAxis = indices - boundary;
    targetAxis = targetIndices - boundary;
else
    boundary = indices(1);
    order = (numel(indices):-1:1).';
    historyAxis = boundary - indices(order);
    targetAxis = boundary - targetIndices;
end
history = values(order, :);
nTarget = numel(targetIndices);
predicted = zeros(nTarget, size(values, 2));
for column = 1:size(values, 2)
    series = history(:, column);
    switch model
        case "persistence"
            predicted(:, column) = repmat(series(end), nTarget, 1);
        case "linear"
            predicted(:, column) = polynomialForecast( ...
                series, historyAxis, targetAxis, 1);
        case "quadratic"
            predicted(:, column) = polynomialForecast( ...
                series, historyAxis, targetAxis, 2);
        case "holt"
            predicted(:, column) = holtForecast(series, nTarget);
        case "harmonic"
            predicted(:, column) = harmonicForecast( ...
                series, historyAxis, targetAxis);
        case "ar"
            predicted(:, column) = arForecast(series, nTarget);
        case "kalman"
            predicted(:, column) = kalmanForecast(series, nTarget);
    end
end
end

function output = polynomialForecast(history, historyAxis, targetAxis, degree)
history = double(history(:));
historyAxis = double(historyAxis(:));
targetAxis = double(targetAxis(:));
if numel(history) <= degree
    output = repmat(history(end), numel(targetAxis), 1);
    return;
end
[design, rootWeight] = weightedDesign(historyAxis, degree, 2.0);
regularizer = eye(degree + 1) * 1e-5;
regularizer(1, 1) = 0;
designW = design .* rootWeight;
coefficients = (designW.' * designW + regularizer) \ ...
    (designW.' * (history .* rootWeight));
scale = max(max(historyAxis) - min(historyAxis), 1.0);
normalizedTarget = targetAxis / scale;
targetDesign = zeros(numel(targetAxis), degree + 1);
for power = 0:degree
    targetDesign(:, power + 1) = normalizedTarget.^power;
end
output = targetDesign * coefficients;
if degree == 2
    % Long quadratic extrapolation is gradually damped toward the boundary
    % tangent instead of being allowed to explode unchecked (v3.1 policy).
    linear = polynomialForecast(history, historyAxis, targetAxis, 1);
    horizon = max(targetAxis, 0);
    damping = exp(-horizon / max(numel(history), 4));
    output = linear + damping .* (output - linear);
end
end

function [design, rootWeight] = weightedDesign(historyAxis, degree, decay)
axis = double(historyAxis(:));
scale = max(max(axis) - min(axis), 1.0);
normalized = axis / scale;
design = zeros(numel(axis), degree + 1);
for power = 0:degree
    design(:, power + 1) = normalized.^power;
end
age = max(axis) - axis;
weights = exp(-decay * age / scale);
rootWeight = sqrt(weights);
end

function output = holtForecast(history, horizon)
history = double(history(:));
if numel(history) < 2
    output = repmat(history(end), horizon, 1);
    return;
end
alpha = 0.45;
beta = 0.20;
damping = 0.92;
level = history(1);
trend = history(2) - history(1);
for index = 2:numel(history)
    previous = level;
    level = alpha * history(index) + (1 - alpha) * (level + damping * trend);
    trend = beta * (level - previous) + (1 - beta) * damping * trend;
end
output = zeros(horizon, 1);
for lead = 1:horizon
    stepSum = 0;
    for step = 1:lead
        stepSum = stepSum + damping^step;
    end
    output(lead) = level + stepSum * trend;
end
end

function output = arForecast(history, horizon)
history = double(history(:));
if numel(history) < 3
    output = holtForecast(history, horizon);
    return;
end
maximumOrder = min([12, max(1, floor(numel(history) / 3)), numel(history) - 2]);
validation = min(max(2, floor(numel(history) / 5)), 6);
train = history(1:end - validation);
bestOrder = 1;
bestError = Inf;
for order = 1:min(maximumOrder, numel(train) - 2)
    coefficients = arCoefficients(train, order);
    rolling = train;
    guesses = zeros(validation, 1);
    for step = 1:validation
        row = [rolling(end - order + 1:end); 1];
        guesses(step) = row.' * coefficients;
        rolling(end + 1, 1) = guesses(step); %#ok<AGROW>
    end
    errorValue = mean((guesses - history(end - validation + 1:end)).^2);
    if errorValue < bestError
        bestError = errorValue;
        bestOrder = order;
    end
end
coefficients = arCoefficients(history, bestOrder);
rolling = history;
for step = 1:horizon
    row = [rolling(end - bestOrder + 1:end); 1];
    rolling(end + 1, 1) = row.' * coefficients; %#ok<AGROW>
end
output = rolling(end - horizon + 1:end);
end

function coefficients = arCoefficients(history, order)
history = double(history(:));
rows = zeros(numel(history) - order, order);
for index = order + 1:numel(history)
    rows(index - order, :) = history(index - order:index - 1).';
end
target = history(order + 1:end);
design = [rows, ones(size(rows, 1), 1)];
regularizer = eye(order + 1) * 1e-2;
regularizer(end, end) = 0;
coefficients = (design.' * design + regularizer) \ (design.' * target);
end

function output = kalmanForecast(history, horizon)
history = double(history(:));
if numel(history) < 2
    output = repmat(history(end), horizon, 1);
    return;
end
state = [history(1); history(2) - history(1)];
covariance = eye(2);
transition = [1, 1; 0, 1];
observation = [1, 0];
processNoise = diag([1e-3, 1e-4]);
observationNoise = 5e-2;
for index = 1:numel(history)
    state = transition * state;
    covariance = transition * covariance * transition.' + processNoise;
    innovation = history(index) - observation * state;
    residual = observation * covariance * observation.' + observationNoise;
    gain = covariance * observation.' / residual;
    state = state + gain .* innovation;
    covariance = (eye(2) - gain * observation) * covariance;
end
output = zeros(horizon, 1);
for step = 1:horizon
    state = transition * state;
    output(step) = state(1);
end
end

function output = harmonicForecast(history, historyAxis, targetAxis)
history = double(history(:));
historyAxis = double(historyAxis(:));
targetAxis = double(targetAxis(:));
if numel(history) < 8
    output = polynomialForecast(history, historyAxis, targetAxis, 2);
    return;
end
age = max(historyAxis) - historyAxis;
rootWeight = sqrt(exp(-age / max(max(historyAxis) - min(historyAxis), 1.0)));
regularizer = diag([0, 1e-4, 1e-3, 1e-3]);
spacing = max(median(diff(historyAxis)), eps);
span = max(max(historyAxis) - min(historyAxis), spacing);
candidates = linspace(2 * pi / (4 * span), pi / spacing, 256);
bestError = Inf;
bestOmega = NaN;
bestCoefficients = [];
for omega = candidates
    design = [ones(numel(history), 1), historyAxis, ...
        sin(omega * historyAxis), cos(omega * historyAxis)];
    weighted = design .* rootWeight;
    coefficients = (weighted.' * weighted + regularizer) \ ...
        (weighted.' * (history .* rootWeight));
    residual = (design * coefficients - history) .* rootWeight;
    errorValue = mean(residual.^2);
    if errorValue < bestError
        bestError = errorValue;
        bestOmega = omega;
        bestCoefficients = coefficients;
    end
end
if ~isfinite(bestOmega)
    output = polynomialForecast(history, historyAxis, targetAxis, 2);
    return;
end
targetDesign = [ones(numel(targetAxis), 1), targetAxis, ...
    sin(bestOmega * targetAxis), cos(bestOmega * targetAxis)];
output = targetDesign * bestCoefficients;
end
