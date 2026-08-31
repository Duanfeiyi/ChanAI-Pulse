function result = run_channel_benchmark(originalFile, predictionDirectory, config)
%RUN_CHANNEL_BENCHMARK Compare predicted CIR with hidden target truth.
%   Prediction quality is reported independently from comparability status.

arguments
    originalFile (1, 1) string
    predictionDirectory (1, 1) string
    config (1, 1) struct = default_channel_benchmark_config()
end
config = mergeStruct(default_channel_benchmark_config(), config);
if double(config.repeat_count) ~= 1
    error("run_channel_benchmark:UseRepeatedEntry", ...
        ["run_channel_benchmark evaluates one export. Use " ...
        "run_repeated_channel_benchmark for repeat_count > 1."]);
end
rng(double(config.master_seed), "twister");
clock = tic;
original = read_channel_dataset_hdf5(originalFile);
bundle = load_prediction_benchmark_bundle(predictionDirectory);
alignment = validate_benchmark_alignment(original, bundle, originalFile);
if ~alignment.is_comparable
    error("run_channel_benchmark:AlignmentFailed", "%s", ...
        strjoin(alignment.errors, " | "));
end

task = bundle.result.benchmark_context.task;
target = double(task.target_indices(:));
known = double(task.known_indices(:));
axisName = lower(string(task.axis));
if axisName == "position"
    axisName = "space";
end
[allReference, prediction, representation] = ...
    comparableRepresentations(original, bundle, task, config);
reference = extractTargetRepresentation(allReference, task);
if axisName == "frequency"
    % The predicted CTF carries the full spectrum; keep only the target
    % subcarriers so reference and prediction share the target shape.
    prediction = extractTargetRepresentation(prediction, task);
end
if ~isequal(size5(reference), size5(prediction))
    error("run_channel_benchmark:RepresentationShapeMismatch", ...
        "Aligned reference and prediction representations have different shapes.");
end
config.internal_frequency_hz = representation.frequency_hz;
axisValues = resolveTaskAxis(original, task);
baselineClock = tic;
baselinePersistence = baselineRepresentation(allReference, axisValues, ...
    known, target, "persistence", axisName);
persistenceBuildRuntime = toc(baselineClock);
baselineClock = tic;
baselineLinear = baselineRepresentation(allReference, axisValues, ...
    known, target, "linear", axisName);
linearBuildRuntime = toc(baselineClock);

metricClock = tic;
metricsPrediction = computeMetrics(reference, prediction, ...
    original, bundle.cir, target, config, axisName);
metricsPrediction.evaluation_runtime_s = toc(metricClock);
metricsPrediction.generation_runtime_s = predictionRuntime(bundle.generator_manifest);
metricClock = tic;
metricsPersistence = computeMetrics(reference, baselinePersistence, ...
    original, struct(), target, config, axisName);
metricsPersistence.evaluation_runtime_s = persistenceBuildRuntime + toc(metricClock);
metricsPersistence.generation_runtime_s = NaN;
metricClock = tic;
metricsLinear = computeMetrics(reference, baselineLinear, ...
    original, struct(), target, config, axisName);
metricsLinear.evaluation_runtime_s = linearBuildRuntime + toc(metricClock);
metricsLinear.generation_runtime_s = NaN;
perTarget = perTargetMetrics(reference, prediction, ...
    baselinePersistence, baselineLinear, target, axisValues, axisName);
perLink = perLinkMetrics(reference, prediction, ...
    baselinePersistence, baselineLinear);

baselineValues = [metricsPersistence.complex_nmse, metricsLinear.complex_nmse];
[bestBaselineValue, bestIndex] = min(baselineValues);
baselineNames = ["Persistence", "Linear"];
tolerance = double(config.comparison_tolerance);
if metricsPrediction.complex_nmse < bestBaselineValue - tolerance
    comparison = "BETTER_THAN_BASELINE";
elseif metricsPrediction.complex_nmse > bestBaselineValue + tolerance
    comparison = "WORSE_THAN_BASELINE";
else
    comparison = "SIMILAR_TO_BASELINE";
end
config = rmfield(config, "internal_frequency_hz");

result = struct( ...
    "schema_version", "v3.0-channel-benchmark-result.1", ...
    "created_utc", utcNow(), ...
    "comparability_status", alignment.status, ...
    "quality_label", comparison, ...
    "best_baseline", baselineNames(bestIndex), ...
    "alignment", alignment, ...
    "representation", representation, ...
    "metrics", struct("prediction", metricsPrediction, ...
        "persistence", metricsPersistence, "linear", metricsLinear), ...
    "per_target", perTarget, "per_link", perLink, ...
    "task", task, "config", config, "runtime_s", toc(clock), ...
    "provenance", struct("original_file", originalFile, ...
        "prediction_directory", predictionDirectory, ...
        "target_ground_truth_used_only_by_benchmark", true));
if logical(config.export_report)
    result.exports = export_channel_benchmark_report(result, config.output_root);
end
end

function [allReference, prediction, info] = comparableRepresentations(original, bundle, task, config)
if original.domain == "ctf" && ~isempty(fieldnames(bundle.ctf))
    referenceFrequency = double(original.axes.frequency_hz(:));
    predictedFrequency = double(bundle.ctf.axes.frequency_hz(:));
    if numel(referenceFrequency) ~= numel(predictedFrequency) || ...
            any(abs(referenceFrequency - predictedFrequency) > ...
            max(1, max(abs(referenceFrequency))) * 1e-10)
        error("run_channel_benchmark:FrequencyAxisMismatch", ...
            "Original and predicted CTF frequency axes differ.");
    end
    allReference = original.ctf.H;
    prediction = bundle.ctf.ctf.H;
    frequencyHz = referenceFrequency;
    source = "ctf";
else
    frequencyHz = comparisonFrequencyAxis(original, bundle.cir, config);
    allReference = datasetToCtf(original, frequencyHz);
    prediction = datasetToCtf(bundle.cir, frequencyHz);
    source = "cir_to_common_ctf";
end
info = struct("domain", source, "frequency_hz", frequencyHz, ...
    "shape", size5(prediction), ...
    "explanation", "Both channels are compared on one common complex frequency grid.");
end

function reference = extractTargetRepresentation(allReference, task)
% v3.2-4b: extract the TARGET region along the task axis so time/frequency/
% sample/space tasks compare the exact predicted targets against truth.
target = double(task.target_indices(:));
axisName = lower(string(task.axis));
if axisName == "position"
    axisName = "space";
end
switch axisName
    case "time"
        % Targets are snapshots (dim 4); predicted CIR carries one snapshot
        % per target sample (dim 5); align both to [.., 1, T].
        reference = allReference(:, :, :, target, 1);
        reference = reshape(reference, ...
            [size(reference, 1), size(reference, 2), ...
            size(reference, 3), 1, numel(target)]);
    case "frequency"
        % Targets are subcarriers (dim 3); keep the frequency dimension.
        reference = reshape(allReference(:, :, target, 1, 1), ...
            [size(allReference, 1), size(allReference, 2), numel(target), 1, 1]);
    otherwise
        % sample/space: targets are samples (dim 5).
        reference = allReference(:, :, :, :, target);
end
end

function frequencyHz = comparisonFrequencyAxis(original, predicted, config)
capabilities = infer_channel_capabilities(original);
if ~capabilities.pdp
    frequencyHz = 0;
    return;
end
count = max(8, round(double(config.frequency_bin_count)));
bandwidth = metadataNumber(original.metadata, "bandwidth_hz", NaN);
if ~isfinite(bandwidth)
    spacing = metadataNumber(original.metadata, "subcarrier_spacing_hz", NaN);
    countHint = metadataNumber(original.metadata, "frequency_count", count);
    if isfinite(spacing), bandwidth = spacing * max(countHint, count); end
end
if ~isfinite(bandwidth)
    delays = [validDelays(original); validDelays(predicted)];
    if isempty(delays) || max(delays) <= min(delays)
        bandwidth = 20e6;
    else
        bandwidth = max(20e6, 2 / (max(delays) - min(delays)));
    end
end
frequencyHz = linspace(-bandwidth / 2, bandwidth / 2, count).';
end

function values = validDelays(dataset)
values = zeros(0, 1);
if dataset.domain == "cir"
    mask = logical(expandField(dataset.cir.path_valid, size5(dataset.cir.coefficient)));
    delay = expandField(dataset.cir.delay_s, size5(dataset.cir.coefficient));
    values = double(delay(mask & isfinite(delay)));
end
end

function H = datasetToCtf(dataset, frequencyHz)
if dataset.domain == "ctf"
    H = dataset.ctf.H;
    return;
end
coefficient = dataset.cir.coefficient;
valid = expandField(dataset.cir.path_valid, size5(coefficient));
coefficient(~valid) = 0;
H = cir_to_ctf(coefficient, dataset.cir.delay_s, frequencyHz);
end

function axisValues = resolveTaskAxis(original, task)
% v3.2-4b: axis-aware coordinate values for baseline construction.
axisName = lower(string(task.axis));
if axisName == "position"
    axisName = "space";
end
switch axisName
    case "time"
        axisValues = taskAxisValues(task, original.dimensions.Nt);
        if isempty(axisValues) && isfield(original.axes, "time_s")
            axisValues = double(original.axes.time_s(:));
        end
    case "frequency"
        axisValues = taskAxisValues(task, original.dimensions.Nf);
        if isempty(axisValues) && isfield(original.axes, "frequency_hz")
            axisValues = double(original.axes.frequency_hz(:));
        end
    case "space"
        axisValues = taskAxisValues(task, original.dimensions.N_sample);
        if isempty(axisValues) && isfield(original.axes, "sample_position_m")
            position = double(original.axes.sample_position_m);
            if size(position, 2) == 1
                axisValues = position(:);
            else
                axisValues = [0; cumsum(vecnorm(diff(position, 1, 1), 2, 2))];
            end
        end
    otherwise
        axisValues = taskAxisValues(task, original.dimensions.N_sample);
        if isempty(axisValues) && isfield(original.axes, "sample_index")
            axisValues = double(original.axes.sample_index(:));
        end
end
if isempty(axisValues)
    axisValues = (1:original.dimensions.N_sample).';
end
if any(~isfinite(axisValues)) || numel(unique(axisValues)) ~= numel(axisValues)
    error("run_channel_benchmark:InvalidTaskAxis", ...
        "Task-axis values must be finite and unique for baseline construction.");
end
end

function values = taskAxisValues(task, expectedLength)
values = [];
if isfield(task, "axis_values") && ...
        numel(task.axis_values) == expectedLength
    values = double(task.axis_values(:));
end
end

function estimate = baselineRepresentation(allReference, x, known, target, method, axisName)
% Builds a persistence/linear baseline from the FULL reference along the
% task axis, then returns an estimate on the TARGET positions with the same
% layout as extractTargetRepresentation.
shape = size5(allReference);
switch axisName
    case "frequency"
        matrix = reshape(allReference, shape(1) * shape(2), shape(3));
        result = baselineMatrix(matrix, x, known, target, method);
        estimate = reshape(result, ...
            [shape(1), shape(2), numel(target), 1, 1]);
    case "time"
        matrix = reshape(allReference, [], shape(4));
        result = baselineMatrix(matrix, x, known, target, method);
        estimate = reshape(result, ...
            [shape(1), shape(2), shape(3), 1, numel(target)]);
    otherwise
        matrix = reshape(allReference, [], shape(5));
        result = baselineMatrix(matrix, x, known, target, method);
        estimate = reshape(result, ...
            [shape(1), shape(2), shape(3), shape(4), numel(target)]);
end
end

function estimate = baselineMatrix(matrix, x, known, target, method)
estimate = complex(zeros(size(matrix, 1), numel(target)));
if method == "persistence"
    for index = 1:numel(target)
        [~, nearest] = min(abs(x(known) - x(target(index))));
        estimate(:, index) = matrix(:, known(nearest));
    end
else
    [knownX, order] = sort(x(known));
    knownMatrix = matrix(:, known(order)).';
    estimate = interp1(knownX, knownMatrix, x(target), "linear", "extrap").';
end
end

function metrics = computeMetrics(reference, estimate, original, predictedCir, target, config, axisName)
delta = estimate - reference;
referencePower = sum(abs(reference(:)).^2);
metrics = struct();
metrics.complex_nmse = sum(abs(delta(:)).^2) / max(referencePower, eps);
metrics.complex_nrmse = sqrt(metrics.complex_nmse);
metrics.magnitude_nrmse = norm(abs(estimate(:)) - abs(reference(:))) / ...
    max(norm(abs(reference(:))), eps);
powerFloor = max(abs(reference(:))) * double(config.phase_power_floor_ratio);
phaseMask = abs(reference(:)) >= powerFloor;
phaseDelta = angle(estimate(phaseMask) .* conj(reference(phaseMask)));
metrics.phase_mae_rad = mean(abs(phaseDelta), "omitnan");
metrics.complex_correlation = abs(sum(conj(reference(:)) .* estimate(:))) / ...
    max(sqrt(sum(abs(reference(:)).^2) * sum(abs(estimate(:)).^2)), eps);
capabilities = infer_channel_capabilities(original);
% v3.2-4b: on a Frequency task the compared region is the missing
% subcarriers only, which has no uniform grid, so PDP/spatial/time
% capability metrics are not meaningful there and stay NaN.
metrics.pdp_nrmse = NaN;
metrics.rms_delay_spread_abs_error_s = NaN;
if capabilities.pdp && axisName ~= "frequency"
    [referencePdp, delayS] = pdpFromCtf(reference, config.internal_frequency_hz);
    [estimatePdp, ~] = pdpFromCtf(estimate, config.internal_frequency_hz);
    metrics.pdp_nrmse = norm(estimatePdp - referencePdp) / ...
        max(norm(referencePdp), eps);
    metrics.rms_delay_spread_abs_error_s = abs( ...
        weightedSpread(delayS, estimatePdp) - weightedSpread(delayS, referencePdp));
end
metrics.spatial_correlation_nrmse = NaN;
if capabilities.spatial_correlation && axisName ~= "frequency"
    metrics.spatial_correlation_nrmse = spatialCorrelationError(reference, estimate);
end
metrics.time_autocorrelation_nrmse = NaN;
if capabilities.time_autocorrelation && axisName ~= "frequency"
    metrics.time_autocorrelation_nrmse = timeCorrelationError(reference, estimate);
end
metrics.doppler_spectrum_nrmse = NaN;
if capabilities.doppler_power_spectrum
    metrics.doppler_spectrum_nrmse = dopplerError(reference, estimate);
end
metrics.angular_spectrum_nrmse = NaN;
if capabilities.angular_power_spectrum && ...
        isstruct(predictedCir) && ~isempty(fieldnames(predictedCir)) && ...
        original.domain == "cir"
    metrics.angular_spectrum_nrmse = angularError(original, predictedCir, target, config);
end
end

function rows = perTargetMetrics(reference, estimate, persistence, linear, target, x, axisName)
rows = repmat(struct("target_index", 0, "axis_value", 0, ...
    "prediction_complex_nmse", 0, "persistence_complex_nmse", 0, ...
    "linear_complex_nmse", 0, "prediction_correlation", 0), numel(target), 1);
for index = 1:numel(target)
    [ref, est, per, lin] = targetSlice( ...
        reference, estimate, persistence, linear, index, axisName);
    a = computeBasic(ref, est);
    b = computeBasic(ref, per);
    c = computeBasic(ref, lin);
    rows(index) = struct("target_index", target(index), ...
        "axis_value", x(target(index)), "prediction_complex_nmse", a.nmse, ...
        "persistence_complex_nmse", b.nmse, ...
        "linear_complex_nmse", c.nmse, ...
        "prediction_correlation", a.correlation);
end
end

function [ref, est, per, lin] = targetSlice( ...
        reference, estimate, persistence, linear, index, axisName)
if axisName == "frequency"
    ref = reference(:, :, index, 1, 1);
    est = estimate(:, :, index, 1, 1);
    per = persistence(:, :, index, 1, 1);
    lin = linear(:, :, index, 1, 1);
else
    ref = reference(:, :, :, :, index);
    est = estimate(:, :, :, :, index);
    per = persistence(:, :, :, :, index);
    lin = linear(:, :, :, :, index);
end
end

function rows = perLinkMetrics(reference, estimate, persistence, linear)
txCount = size(reference, 1); rxCount = size(reference, 2);
rows = repmat(struct("tx", 0, "rx", 0, ...
    "prediction_complex_nmse", 0, "persistence_complex_nmse", 0, ...
    "linear_complex_nmse", 0, "prediction_correlation", 0), txCount * rxCount, 1);
row = 0;
for tx = 1:txCount
    for rx = 1:rxCount
        row = row + 1;
        ref = reference(tx, rx, :, :, :);
        a = computeBasic(ref, estimate(tx, rx, :, :, :));
        b = computeBasic(ref, persistence(tx, rx, :, :, :));
        c = computeBasic(ref, linear(tx, rx, :, :, :));
        rows(row) = struct("tx", tx, "rx", rx, ...
            "prediction_complex_nmse", a.nmse, ...
            "persistence_complex_nmse", b.nmse, ...
            "linear_complex_nmse", c.nmse, ...
            "prediction_correlation", a.correlation);
    end
end
end

function value = computeBasic(reference, estimate)
value.nmse = sum(abs(estimate(:) - reference(:)).^2) / ...
    max(sum(abs(reference(:)).^2), eps);
value.correlation = abs(sum(conj(reference(:)) .* estimate(:))) / ...
    max(sqrt(sum(abs(reference(:)).^2) * sum(abs(estimate(:)).^2)), eps);
end

function [pdp, delayS] = pdpFromCtf(H, frequencyHz)
impulse = ifft(H, [], 3);
pdp = squeeze(mean(abs(impulse).^2, [1, 2, 4, 5]));
pdp = pdp(:);
if numel(frequencyHz) > 1
    bandwidth = abs(median(diff(double(frequencyHz(:))))) * numel(frequencyHz);
else
    bandwidth = 1;
end
delayS = (0:numel(pdp) - 1).' / max(bandwidth, eps);
end

function value = spatialCorrelationError(reference, estimate)
if size(reference, 1) * size(reference, 2) <= 1
    value = NaN; return;
end
ref = reshape(reference, size(reference, 1) * size(reference, 2), []);
est = reshape(estimate, size(estimate, 1) * size(estimate, 2), []);
refCorr = normalizedCorr(ref); estCorr = normalizedCorr(est);
value = norm(estCorr - refCorr, "fro") / max(norm(refCorr, "fro"), eps);
end

function value = timeCorrelationError(reference, estimate)
if size(reference, 4) <= 1
    value = NaN; return;
end
ref = squeeze(mean(reference, [1, 2, 3, 5]));
est = squeeze(mean(estimate, [1, 2, 3, 5]));
refAcf = manualAcf(ref); estAcf = manualAcf(est);
value = norm(estAcf - refAcf) / max(norm(refAcf), eps);
end

function value = dopplerError(reference, estimate)
if size(reference, 4) <= 1
    value = NaN; return;
end
ref = squeeze(mean(abs(fftshift(fft(reference, [], 4), 4)).^2, [1, 2, 3, 5]));
est = squeeze(mean(abs(fftshift(fft(estimate, [], 4), 4)).^2, [1, 2, 3, 5]));
value = norm(est(:) - ref(:)) / max(norm(ref(:)), eps);
end

function value = angularError(original, predicted, target, config)
fields = ["aoa_rad", "aod_rad"];
values = zeros(0, 1);
for field = fields
    if isfield(original.cir, field) && isfield(predicted.cir, field)
        originalAngle = original.cir.(field);
        originalShape = size5(original.cir.coefficient);
        originalAngle = expandField(originalAngle, originalShape);
        originalValid = expandField(original.cir.path_valid, originalShape);
        refAngle = originalAngle(:, :, :, :, target);
        refPower = abs(original.cir.coefficient(:, :, :, :, target)).^2;
        refPower(~originalValid(:, :, :, :, target)) = 0;
        predictedShape = size5(predicted.cir.coefficient);
        estAngle = expandField(predicted.cir.(field), predictedShape);
        estPower = abs(predicted.cir.coefficient).^2;
        predictedValid = expandField(predicted.cir.path_valid, predictedShape);
        estPower(~predictedValid) = 0;
        edges = linspace(-pi, pi, round(config.angle_bin_count) + 1);
        refHist = weightedHist(refAngle, refPower, edges);
        estHist = weightedHist(estAngle, estPower, edges);
        values(end + 1, 1) = norm(estHist - refHist) / max(norm(refHist), eps); %#ok<AGROW>
    end
end
if isempty(values), value = NaN; else, value = mean(values); end
end

function values = weightedHist(angleValue, power, edges)
angleValue = double(angleValue(:)); power = double(power(:));
valid = isfinite(angleValue) & isfinite(power) & power >= 0;
angleValue = angleValue(valid); power = power(valid);
bins = discretize(angleValue, edges);
accepted = isfinite(bins);
values = accumarray(double(bins(accepted)), power(accepted), ...
    [numel(edges) - 1, 1], @sum, 0);
end

function values = manualAcf(sequence)
sequence = sequence(:);
count = numel(sequence);
values = complex(zeros(count, 1));
for lag = 0:count - 1
    values(lag + 1) = sum(sequence(1:count-lag) .* ...
        conj(sequence(1+lag:count)));
end
values = values / max(abs(values(1)), eps);
end

function matrix = normalizedCorr(observations)
matrix = observations * observations' / max(size(observations, 2), 1);
diagonal = max(real(diag(matrix)), 0);
scale = sqrt(diagonal * diagonal.');
matrix(scale > 0) = matrix(scale > 0) ./ scale(scale > 0);
matrix(scale == 0) = 0;
end

function value = weightedSpread(x, w)
w = double(w(:)); x = double(x(:)); total = sum(w);
if total <= 0, value = NaN; return; end
center = sum(x .* w) / total;
value = sqrt(max(0, sum((x - center).^2 .* w) / total));
end

function expanded = expandField(value, targetSize)
sourceSize = size5(value);
if ~all(sourceSize == 1 | sourceSize == targetSize)
    error("run_channel_benchmark:CannotExpand", ...
        "A CIR field cannot expand to coefficient dimensions.");
end
expanded = repmat(reshape(value, sourceSize), targetSize ./ sourceSize);
end

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), size(value, 4), size(value, 5)];
end

function value = metadataNumber(metadata, name, fallback)
value = fallback;
if isfield(metadata, name) && isnumeric(metadata.(name)) && ...
        isscalar(metadata.(name)) && isfinite(metadata.(name))
    value = double(metadata.(name));
end
end

function output = mergeStruct(defaults, supplied)
output = defaults;
for item = string(fieldnames(supplied)).', output.(item) = supplied.(item); end
end

function value = utcNow()
value = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
end

function value = predictionRuntime(manifest)
value = NaN;
if isfield(manifest, "target_diagnostics") && ...
        isstruct(manifest.target_diagnostics) && ...
        isfield(manifest.target_diagnostics, "elapsed_s")
    values = double([manifest.target_diagnostics.elapsed_s]);
    if any(isfinite(values)), value = sum(values(isfinite(values))); end
end
end
