function analysis = analyze_channel_characteristics(dataset, options)
%ANALYZE_CHANNEL_CHARACTERISTICS Compute Step 5 channel characteristics.
%   Calculations are GUI-independent and capability-driven. Unsupported
%   characteristics return an explicit reason instead of placeholder data.

arguments
    dataset (1, 1) struct
    options.Task (1, 1) struct = struct()
    options.Region (1, 1) string ...
        {mustBeMember(options.Region, ["known", "all"])} = "known"
    options.ModuleRole (1, 1) string ...
        {mustBeMember(options.ModuleRole, ...
        ["input", "prediction", "review"])} = "input"
    options.CdfRecommendedCount (1, 1) double ...
        {mustBeInteger, mustBePositive} = 20
end

analysis = emptyAnalysis(options);
validation = validate_channel_dataset(dataset);
analysis.validation = validation;
if validation.status == "FAIL"
    analysis.status = "FAIL";
    analysis.errors = validation.errors;
    analysis.warnings = validation.warnings;
    return;
end

[selected, selection, selectionReport] = ...
    select_channel_task_region(dataset, options.Task, options.Region);
analysis.selection = selection;
if selectionReport.status == "FAIL"
    analysis.status = "FAIL";
    analysis.errors = selectionReport.errors;
    analysis.warnings = [validation.warnings; selectionReport.warnings];
    return;
end

try
    context = buildAnalysisContext(selected);
catch exception
    analysis.status = "FAIL";
    analysis.errors(end + 1, 1) = ...
        "Step 5 could not prepare the dataset: " + string(exception.message);
    analysis.warnings = validation.warnings;
    return;
end

baseCapabilities = infer_channel_capabilities(selected);
analysis.classification = baseCapabilities.classification;
analysis.dataset_summary = summarizeDataset(selected, context);

metrics = struct();
metrics.power = computePowerMetric(context);
metrics.pdp = computePdpMetric(context);
metrics.frequency_autocorrelation = computeFrequencyCorrelationMetric(context);
[metrics.delay_spread_cdf, delaySpreadValues] = ...
    computeDelaySpreadMetric(context, options.CdfRecommendedCount);
[metrics.angular_power_spectrum, angularSpreadData] = ...
    computeAngularSpectrumMetric(context);
metrics.spatial_correlation = computeSpatialCorrelationMetric(context);
metrics.angular_spread_cdf = computeAngularSpreadMetric( ...
    angularSpreadData, options.CdfRecommendedCount);
[metrics.doppler_power_spectrum, dopplerSpreadValues] = ...
    computeDopplerMetric(context);
metrics.time_autocorrelation = computeTimeCorrelationMetric(context);
metrics.doppler_spread_cdf = computeDopplerSpreadMetric( ...
    dopplerSpreadValues, options.CdfRecommendedCount);
metrics.delay_sample_heatmap = computeDelaySampleHeatmapMetric(context);

analysis.metrics = metrics;
analysis.registry = build_channel_plot_registry( ...
    analysis.classification, metrics);
analysis.warnings = unique([validation.warnings; ...
    selectionReport.warnings; collectMetricWarnings(metrics)], "stable");
if isempty(analysis.warnings)
    analysis.status = "PASS";
else
    analysis.status = "WARNING";
end
analysis.provenance = struct( ...
    "engine", "ChanAI Pulse unified channel characteristics", ...
    "engine_version", "v3.0-step5.1", ...
    "module_role", options.ModuleRole, ...
    "region", options.Region, ...
    "source", string(selected.metadata.source), ...
    "computed_utc", string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'")));
analysis.raw = struct( ...
    "delay_spread_s", delaySpreadValues, ...
    "angular_spread_deg", angularSpreadData, ...
    "doppler_spread_hz", dopplerSpreadValues);
end

function analysis = emptyAnalysis(options)
analysis = struct( ...
    "status", "FAIL", ...
    "classification", "unknown", ...
    "dataset_summary", struct(), ...
    "selection", struct(), ...
    "validation", struct(), ...
    "metrics", struct(), ...
    "registry", struct(), ...
    "warnings", strings(0, 1), ...
    "errors", strings(0, 1), ...
    "provenance", struct( ...
        "module_role", options.ModuleRole, "region", options.Region), ...
    "raw", struct());
end

function context = buildAnalysisContext(dataset)
context = struct();
context.dataset = dataset;
context.domain = lower(string(dataset.domain));
context.dimensions = dataset.dimensions;
context.cir = struct("available", false, "source", "none");
context.ctf = struct("available", false, "source", "none");

if context.domain == "cir"
    coefficient = dataset.cir.coefficient;
    shape = size5(coefficient);
    context.cir.available = true;
    context.cir.source = "direct";
    context.cir.coefficient = coefficient;
    context.cir.delay_s = expandToShape(dataset.cir.delay_s, shape);
    context.cir.path_valid = logical(expandToShape( ...
        dataset.cir.path_valid, shape));
    optionalFields = ["aoa_rad", "aod_rad", "doppler_hz"];
    for fieldName = optionalFields
        if isfield(dataset.cir, fieldName)
            context.cir.(fieldName) = expandToShape( ...
                dataset.cir.(fieldName), shape);
        end
    end

    [frequencyHz, frequencyOffsetsHz, frequencyReason] = ...
        derivedFrequencyAxis(dataset);
    if ~isempty(frequencyHz)
        validCoefficient = coefficient;
        validCoefficient(~context.cir.path_valid) = 0;
        context.ctf.available = true;
        context.ctf.source = "derived_from_cir";
        context.ctf.H = cir_to_ctf(validCoefficient, ...
            context.cir.delay_s, frequencyOffsetsHz);
        context.ctf.frequency_hz = frequencyHz;
        context.ctf.frequency_reason = ...
            "Derived from explicit CIR delay and frequency metadata.";
    else
        context.ctf.frequency_reason = frequencyReason;
    end
else
    context.ctf.available = true;
    context.ctf.source = "direct";
    context.ctf.H = dataset.ctf.H;
    [frequencyHz, frequencyReason] = directFrequencyAxis(dataset);
    context.ctf.frequency_hz = frequencyHz;
    context.ctf.frequency_reason = frequencyReason;

    [derivedCir, cirReason] = ctfToDiscreteCir(dataset, frequencyHz);
    if derivedCir.available
        context.cir = derivedCir;
    else
        context.cir.reason = cirReason;
    end
end

context.time = resolveTime(dataset);
context.sample = resolveSamples(dataset);
context.time_channel = resolveTimeChannel(context);
context.metadata = dataset.metadata;
end

function summary = summarizeDataset(dataset, context)
dims = dataset.dimensions;
summary = struct( ...
    "domain", upper(string(dataset.domain)), ...
    "Tx", dims.Tx, ...
    "Rx", dims.Rx, ...
    "Nf", dims.Nf, ...
    "Npath", dims.Npath, ...
    "Nt", dims.Nt, ...
    "N_sample", dims.N_sample, ...
    "source", string(dataset.metadata.source), ...
    "sample_semantics", string(dataset.metadata.sample_semantics), ...
    "has_frequency_grid", context.ctf.available && ...
        ~isempty(context.ctf.frequency_hz), ...
    "has_delay_grid", context.cir.available, ...
    "has_uniform_time", context.time.available, ...
    "ordered_samples", context.sample.ordered);
end

function metric = computePowerMetric(context)
metric = newMetric("power", "信道功率", "line");
if context.domain == "ctf"
    power = abs(context.ctf.H).^2;
    perSample = squeeze(meanOverDimensions(power, [1, 2, 3, 4]));
else
    power = abs(context.cir.coefficient).^2;
    power(~context.cir.path_valid) = 0;
    power = sum(power, 3);
    perSample = squeeze(meanOverDimensions(power, [1, 2, 4]));
end
perSample = double(perSample(:));
metric.available = true;
metric.reason = "Complex channel coefficients are available.";
metric.x = context.sample.x(:);
metric.y = normalizeDb(perSample);
metric.x_unit = context.sample.unit;
metric.y_unit = "dB";
metric.raw = struct( ...
    "linear", perSample, ...
    "db", safeDb(perSample), ...
    "normalized_db", metric.y);
metric.aggregation = ...
    "Power is retained per sample and averaged over Tx/Rx/channel axes.";
metric.normalization = "Peak normalized to 0 dB for display.";
metric.summary = struct("sample_count", numel(perSample), ...
    "mean_linear_power", mean(perSample));
end

function metric = computePdpMetric(context)
metric = newMetric("pdp", "功率时延分布（PDP）", "line");
if ~context.cir.available || size(context.cir.coefficient, 3) <= 1
    metric.reason = delayUnavailableReason(context);
    return;
end

coefficient = context.cir.coefficient;
power = abs(coefficient).^2;
power(~context.cir.path_valid) = 0;
delay = context.cir.delay_s;
pathCount = size(coefficient, 3);
meanPower = zeros(pathCount, 1);
meanDelay = zeros(pathCount, 1);
for path = 1:pathCount
    pathPower = double(power(:, :, path, :, :));
    pathDelay = double(delay(:, :, path, :, :));
    valid = context.cir.path_valid(:, :, path, :, :) & ...
        isfinite(pathDelay);
    weights = pathPower(valid);
    values = pathDelay(valid);
    if isempty(weights) || sum(weights) <= 0
        meanPower(path) = 0;
        meanDelay(path) = NaN;
    else
        meanPower(path) = mean(weights);
        meanDelay(path) = sum(values .* weights) / sum(weights);
    end
end
validPaths = isfinite(meanDelay);
meanDelay = meanDelay(validPaths);
meanPower = meanPower(validPaths);
[meanDelay, order] = sort(meanDelay);
meanPower = meanPower(order);

metric.available = ~isempty(meanDelay);
if ~metric.available
    metric.reason = "No finite valid delay paths remain.";
    return;
end
metric.reason = "Valid complex paths and physical delay values are available.";
metric.x = meanDelay * 1e9;
metric.y = normalizeDb(meanPower);
metric.x_unit = "ns";
metric.y_unit = "dB";
metric.raw = struct("delay_s", meanDelay, ...
    "linear_power", meanPower, "db", safeDb(meanPower));
metric.aggregation = ...
    "Equal average over selected Tx/Rx/time/sample observations.";
metric.normalization = "Peak PDP normalized to 0 dB for display.";
metric.summary = struct("path_count", numel(meanDelay), ...
    "maximum_delay_ns", max(metric.x));
end

function [metric, spreadValues] = computeDelaySpreadMetric( ...
        context, recommendedCount)
metric = newMetric("delay_spread_cdf", ...
    "RMS 时延扩展经验 CDF", "cdf");
spreadValues = zeros(0, 1);
if ~context.cir.available || size(context.cir.coefficient, 3) <= 1
    metric.reason = delayUnavailableReason(context);
    return;
end

spreadValues = perSampleDelaySpread(context.cir);
distribution = compute_empirical_distribution( ...
    spreadValues * 1e9, "ns", recommendedCount);
if ~distribution.available
    metric.reason = distribution.warning;
    return;
end

metric.available = true;
metric.reason = "At least two finite per-sample RMS delay spreads exist.";
metric.x = distribution.x;
metric.y = distribution.y;
metric.x_unit = "ns";
metric.y_unit = "CDF";
metric.raw = struct("delay_spread_s", spreadValues, ...
    "distribution", distribution);
metric.aggregation = ...
    "RMS delay spread is computed per time snapshot, then averaged per sample.";
metric.normalization = "Empirical CDF without parametric fitting.";
metric.summary = struct( ...
    "sample_count", distribution.sample_count, ...
    "median_ns", distribution.median, ...
    "percentile_90_ns", distribution.percentile_90);
if distribution.warning ~= ""
    metric.warnings(end + 1, 1) = distribution.warning;
end
end

function metric = computeFrequencyCorrelationMetric(context)
metric = newMetric("frequency_autocorrelation", ...
    "频率自相关", "complex_correlation");
if ~context.ctf.available || isempty(context.ctf.frequency_hz) || ...
        size(context.ctf.H, 3) <= 1
    metric.reason = context.ctf.frequency_reason;
    return;
end
[uniform, spacing] = uniformSpacing(context.ctf.frequency_hz);
if ~uniform
    metric.reason = ...
        "Frequency autocorrelation requires a uniformly spaced frequency axis.";
    return;
end

H = context.ctf.H;
frequencyCount = size(H, 3);
sequences = reshape(permute(H, [3, 1, 2, 4, 5]), ...
    frequencyCount, []);
correlation = compute_normalized_channel_autocorrelation( ...
    sequences, spacing, "Hz");

metric.available = true;
metric.reason = "A uniform physical frequency grid is available.";
metric.x = correlation.lag;
metric.y = correlation.magnitude;
metric.x_unit = "Hz";
metric.y_unit = "|R_f|";
metric.raw = correlation;
metric.aggregation = ...
    "Complex correlation averaged over Tx/Rx/time/sample observations.";
metric.normalization = correlation.normalization;
metric.summary = struct("subcarrier_spacing_hz", spacing, ...
    "lag_count", numel(correlation.lag));
end

function [metric, spreadData] = computeAngularSpectrumMetric(context)
metric = newMetric("angular_power_spectrum", ...
    "角度功率谱", "multi_line");
spreadData = struct("labels", strings(0, 1), ...
    "values_deg", {cell(0, 1)});

if context.dimensions.Tx <= 1 && context.dimensions.Rx <= 1
    metric.reason = ...
        "Dimension-based angle plots require Tx > 1 or Rx > 1.";
    return;
end

if context.cir.available && ...
        (isfield(context.cir, "aoa_rad") || ...
        isfield(context.cir, "aod_rad"))
    [angleDeg, spectra, labels, spreads] = ...
        pathAngularCharacteristics(context.cir);
    sourceReason = "Explicit CIR AoA/AoD path angles are available.";
elseif context.ctf.available
    [angleDeg, spectra, labels, spreads, sourceReason] = ...
        beamspaceAngularCharacteristics(context);
else
    angleDeg = [];
    spectra = [];
    labels = strings(0, 1);
    spreads = cell(0, 1);
    sourceReason = ...
        "Need explicit AoA/AoD or a complex array response with ULA geometry.";
end

if isempty(labels)
    metric.reason = sourceReason;
    return;
end

metric.available = true;
metric.reason = sourceReason;
metric.x = angleDeg(:);
metric.y = spectra;
metric.x_unit = "deg";
metric.y_unit = "dB";
metric.series_labels = labels;
metric.raw = struct("linear_or_normalized_spectra_db", spectra);
metric.aggregation = ...
    "Path or beamspace power averaged over selected observations.";
metric.normalization = "Each angular spectrum peak is normalized to 0 dB.";
metric.summary = struct("series_count", numel(labels), ...
    "angle_min_deg", min(angleDeg), "angle_max_deg", max(angleDeg));
spreadData.labels = labels;
spreadData.values_deg = spreads;
end

function metric = computeSpatialCorrelationMetric(context)
metric = newMetric("spatial_correlation", ...
    "空间相关矩阵", "matrix");
if ~context.ctf.available
    channel = context.time_channel;
else
    channel = context.ctf.H;
end
txCount = size(channel, 1);
rxCount = size(channel, 2);
if txCount <= 1 && rxCount <= 1
    metric.reason = "Spatial correlation requires Tx > 1 or Rx > 1.";
    return;
end

raw = struct("tx", [], "rx", []);
if rxCount > 1
    observations = reshape(permute(channel, [2, 1, 3, 4, 5]), ...
        rxCount, []);
    if size(observations, 2) >= 2
        raw.rx = normalizedCorrelationMatrix(observations);
    end
end
if txCount > 1
    observations = reshape(channel, txCount, []);
    if size(observations, 2) >= 2
        raw.tx = normalizedCorrelationMatrix(observations);
    end
end

if isempty(raw.rx) && isempty(raw.tx)
    metric.reason = ...
        "Spatial correlation requires at least two channel observations.";
    return;
elseif ~isempty(raw.rx)
    matrix = raw.rx;
    label = "Rx";
else
    matrix = raw.tx;
    label = "Tx";
end
metric.available = true;
metric.reason = "Multiple antenna channels and at least two observations exist.";
metric.x = (1:size(matrix, 2)).';
metric.y = (1:size(matrix, 1)).';
metric.z = abs(matrix);
metric.x_unit = label + " antenna index";
metric.y_unit = label + " antenna index";
metric.z_unit = "|R|";
metric.raw = raw;
metric.aggregation = ...
    "Complex outer products averaged over all non-selected antenna dimensions.";
metric.normalization = "Unit diagonal complex correlation matrix.";
metric.summary = struct("display_matrix", label, ...
    "tx_count", txCount, "rx_count", rxCount);
end

function metric = computeAngularSpreadMetric(spreadData, recommendedCount)
metric = newMetric("angular_spread_cdf", ...
    "角度扩展经验 CDF", "multi_cdf");
if isempty(spreadData.labels)
    metric.reason = ...
        "Angular spread needs explicit path angles or valid beamspace spectra.";
    return;
end

series = repmat(struct("label", "", "x", [], "y", [], ...
    "distribution", struct()), 0, 1);
warnings = strings(0, 1);
for index = 1:numel(spreadData.labels)
    distribution = compute_empirical_distribution( ...
        spreadData.values_deg{index}, "deg", recommendedCount);
    if distribution.available
        item = struct("label", spreadData.labels(index), ...
            "x", distribution.x, "y", distribution.y, ...
            "distribution", distribution);
        series(end + 1, 1) = item; %#ok<AGROW>
        if distribution.warning ~= ""
            warnings(end + 1, 1) = ...
                spreadData.labels(index) + ": " + distribution.warning; %#ok<AGROW>
        end
    end
end
if isempty(series)
    metric.reason = ...
        "Angular spread CDF requires at least two finite samples.";
    return;
end

metric.available = true;
metric.reason = "At least one angular-spread series has two or more samples.";
metric.x_unit = "deg";
metric.y_unit = "CDF";
metric.series_labels = string({series.label}).';
metric.raw = struct("series", series);
metric.aggregation = "Angular spread is computed independently per sample.";
metric.normalization = "Empirical CDF without parametric fitting.";
metric.summary = struct("series_count", numel(series));
metric.warnings = warnings;
end

function [metric, spreadValues] = computeDopplerMetric(context)
metric = newMetric("doppler_power_spectrum", ...
    "多普勒功率谱", "line");
spreadValues = zeros(0, 1);
if ~context.time.available || size(context.time_channel, 4) <= 1
    metric.reason = context.time.reason;
    return;
end

channel = context.time_channel;
timeCount = size(channel, 4);
sampleCount = size(channel, 5);
sequences = reshape(permute(channel, [4, 1, 2, 3, 5]), ...
    timeCount, []);
[frequencyHz, averagePower, settings] = ...
    averagedDopplerSpectrum(sequences, context.time.spacing_s);

spreadValues = NaN(sampleCount, 1);
for sample = 1:sampleCount
    sampleSequences = reshape(permute(channel(:, :, :, :, sample), ...
        [4, 1, 2, 3, 5]), timeCount, []);
    [sampleFrequency, samplePower] = averagedDopplerSpectrum( ...
        sampleSequences, context.time.spacing_s);
    spreadValues(sample) = weightedSpread(sampleFrequency, samplePower);
end
spreadValues = spreadValues(isfinite(spreadValues));

metric.available = true;
metric.reason = "Uniform physical time samples are available.";
metric.x = frequencyHz;
metric.y = normalizeDb(averagePower);
metric.x_unit = "Hz";
metric.y_unit = "dB";
metric.raw = struct("linear_power", averagePower, ...
    "db", safeDb(averagePower), "settings", settings);
metric.aggregation = ...
    "Windowed periodograms averaged over Tx/Rx/channel/sample observations.";
metric.normalization = "Peak spectrum normalized to 0 dB for display.";
metric.summary = struct("sampling_rate_hz", settings.sampling_rate_hz, ...
    "nfft", settings.nfft, "window", settings.window);
end

function metric = computeTimeCorrelationMetric(context)
metric = newMetric("time_autocorrelation", ...
    "时间自相关", "complex_correlation");
if ~context.time.available || size(context.time_channel, 4) <= 1
    metric.reason = context.time.reason;
    return;
end

channel = context.time_channel;
timeCount = size(channel, 4);
sequences = reshape(permute(channel, [4, 1, 2, 3, 5]), ...
    timeCount, []);
correlation = compute_normalized_channel_autocorrelation( ...
    sequences, context.time.spacing_s, "s");

metric.available = true;
metric.reason = "Uniform physical time samples are available.";
metric.x = correlation.lag;
metric.y = correlation.magnitude;
metric.x_unit = "s";
metric.y_unit = "|R_t|";
metric.raw = correlation;
metric.aggregation = ...
    "Complex correlation averaged over Tx/Rx/channel/sample observations.";
metric.normalization = correlation.normalization;
metric.summary = struct("snapshot_interval_s", ...
    context.time.spacing_s, "lag_count", numel(correlation.lag));
end

function metric = computeDopplerSpreadMetric(values, recommendedCount)
metric = newMetric("doppler_spread_cdf", ...
    "多普勒扩展经验 CDF", "cdf");
distribution = compute_empirical_distribution( ...
    values, "Hz", recommendedCount);
if ~distribution.available
    metric.reason = distribution.warning;
    return;
end

metric.available = true;
metric.reason = "At least two finite per-sample Doppler spreads exist.";
metric.x = distribution.x;
metric.y = distribution.y;
metric.x_unit = "Hz";
metric.y_unit = "CDF";
metric.raw = struct("doppler_spread_hz", values, ...
    "distribution", distribution);
metric.aggregation = "Doppler spread is computed independently per sample.";
metric.normalization = "Empirical CDF without parametric fitting.";
metric.summary = struct("sample_count", distribution.sample_count, ...
    "median_hz", distribution.median, ...
    "percentile_90_hz", distribution.percentile_90);
if distribution.warning ~= ""
    metric.warnings(end + 1, 1) = distribution.warning;
end
end

function metric = computeDelaySampleHeatmapMetric(context)
metric = newMetric("delay_sample_heatmap", ...
    "时延—样本功率热力图", "heatmap");
if ~context.cir.available || size(context.cir.coefficient, 3) <= 1
    metric.reason = delayUnavailableReason(context);
    return;
end
if size(context.cir.coefficient, 5) <= 1
    metric.reason = "Heatmap requires N_sample > 1.";
    return;
end
if ~context.sample.ordered
    metric.reason = ...
        "Heatmap requires declared ordered sample semantics.";
    return;
end

[delayBinsS, linearPower] = binnedDelaySamplePower(context.cir);
if isempty(delayBinsS)
    metric.reason = "No finite delay-power samples are available.";
    return;
end
metric.available = true;
metric.reason = "Ordered samples and physical multipath delays are available.";
metric.x = context.sample.x(:);
metric.y = delayBinsS(:) * 1e9;
metric.z = normalizeDbMatrix(linearPower);
metric.x_unit = context.sample.unit;
metric.y_unit = "ns";
metric.z_unit = "dB";
metric.raw = struct("delay_s", delayBinsS, ...
    "linear_power", linearPower);
metric.aggregation = "Tx/Rx/time power is accumulated into common delay bins.";
metric.normalization = "Global heatmap peak normalized to 0 dB.";
metric.summary = struct("delay_bin_count", numel(delayBinsS), ...
    "sample_count", numel(metric.x));
end

function metric = newMetric(id, titleZh, kind)
metric = struct( ...
    "id", string(id), ...
    "title_zh", string(titleZh), ...
    "available", false, ...
    "reason", "", ...
    "kind", string(kind), ...
    "x", [], ...
    "y", [], ...
    "z", [], ...
    "x_unit", "", ...
    "y_unit", "", ...
    "z_unit", "", ...
    "series_labels", strings(0, 1), ...
    "raw", struct(), ...
    "aggregation", "", ...
    "normalization", "", ...
    "summary", struct(), ...
    "warnings", strings(0, 1));
end

function [frequencyHz, offsetsHz, reason] = derivedFrequencyAxis(dataset)
frequencyHz = [];
offsetsHz = [];
reason = "Need explicit frequency count, center frequency, and subcarrier spacing.";
metadata = dataset.metadata;
frequencyCount = metadataNumber(metadata, ["frequency_count", "Nf"]);
if ~isfinite(frequencyCount) && isfield(metadata, "config") && ...
        isstruct(metadata.config) && isfield(metadata.config, "Nf")
    frequencyCount = double(metadata.config.Nf);
end
centerHz = metadataNumber(metadata, "center_frequency_hz");
spacingHz = metadataNumber(metadata, "subcarrier_spacing_hz");
if ~isfinite(frequencyCount) || frequencyCount <= 1 || ...
        mod(frequencyCount, 1) ~= 0 || ~isfinite(centerHz) || ...
        ~isfinite(spacingHz) || spacingHz <= 0
    return;
end
offsetsHz = ((0:frequencyCount - 1).' - ...
    (frequencyCount - 1) / 2) * spacingHz;
frequencyHz = centerHz + offsetsHz;
reason = "";
end

function [frequencyHz, reason] = directFrequencyAxis(dataset)
frequencyCount = dataset.dimensions.Nf;
if isfield(dataset.axes, "frequency_hz") && ...
        numel(dataset.axes.frequency_hz) == frequencyCount
    frequencyHz = double(dataset.axes.frequency_hz(:));
    reason = "Direct physical frequency axis is available.";
    return;
end
centerHz = metadataNumber(dataset.metadata, "center_frequency_hz");
spacingHz = metadataNumber(dataset.metadata, "subcarrier_spacing_hz");
if isfinite(centerHz) && isfinite(spacingHz) && spacingHz > 0 && ...
        frequencyCount > 1
    offsets = ((0:frequencyCount - 1).' - ...
        (frequencyCount - 1) / 2) * spacingHz;
    frequencyHz = centerHz + offsets;
    reason = "Frequency axis derived from explicit center and spacing metadata.";
else
    frequencyHz = [];
    reason = "Need frequency_hz or explicit center/subcarrier spacing.";
end
end

function [cir, reason] = ctfToDiscreteCir(dataset, frequencyHz)
cir = struct("available", false, "source", "none");
reason = "A uniformly spaced frequency grid with Nf > 1 is required.";
H = dataset.ctf.H;
frequencyCount = size(H, 3);
if frequencyCount <= 1 || isempty(frequencyHz)
    return;
end
[uniform, spacingHz] = uniformSpacing(frequencyHz);
if ~uniform
    reason = "CTF-to-CIR conversion requires uniform frequency spacing.";
    return;
end
h = ifft(ifftshift(H, 3), [], 3);
delayS = reshape((0:frequencyCount - 1) / ...
    (frequencyCount * spacingHz), [1, 1, frequencyCount, 1, 1]);
cir.available = true;
cir.source = "derived_from_ctf";
cir.coefficient = h;
cir.delay_s = expandToShape(delayS, size5(h));
cir.path_valid = true(size(h));
cir.reason = "Discrete CIR derived by auditable IFFT of uniform CTF.";
reason = "";
end

function time = resolveTime(dataset)
time = struct("available", false, "axis_s", [], ...
    "spacing_s", NaN, "reason", ...
    "Need Nt > 1 plus time_s or snapshot_interval_s.");
timeCount = dataset.dimensions.Nt;
if timeCount <= 1
    return;
end
if isfield(dataset.axes, "time_s") && ...
        numel(dataset.axes.time_s) == timeCount
    axisS = double(dataset.axes.time_s(:));
elseif isfinite(metadataNumber(dataset.metadata, "snapshot_interval_s"))
    spacing = metadataNumber(dataset.metadata, "snapshot_interval_s");
    axisS = (0:timeCount - 1).' * spacing;
else
    return;
end
[uniform, spacing] = uniformSpacing(axisS);
if ~uniform
    time.reason = ...
        "Time axis must be strictly increasing and uniformly spaced.";
    return;
end
time.available = true;
time.axis_s = axisS;
time.spacing_s = spacing;
time.reason = "Uniform physical time samples are available.";
end

function sample = resolveSamples(dataset)
sampleCount = dataset.dimensions.N_sample;
sample = struct("x", (1:sampleCount).', "unit", "sample", ...
    "ordered", false);
semantics = lower(string(dataset.metadata.sample_semantics));
sample.ordered = ismember(semantics, ...
    ["ordered_route", "ordered_time", "ordered_frequency", "other_ordered"]);
if isfield(dataset.axes, "sample_position_m") && ...
        size(dataset.axes.sample_position_m, 1) == sampleCount
    position = double(dataset.axes.sample_position_m);
    if size(position, 2) == 1
        sample.x = position(:, 1);
    else
        delta = diff(position, 1, 1);
        sample.x = [0; cumsum(sqrt(sum(delta.^2, 2)))];
    end
    sample.unit = "m";
elseif isfield(dataset.axes, "sample_index") && ...
        numel(dataset.axes.sample_index) == sampleCount
    sample.x = double(dataset.axes.sample_index(:));
end
end

function channel = resolveTimeChannel(context)
if context.ctf.available
    channel = context.ctf.H;
elseif context.cir.available
    coefficient = context.cir.coefficient;
    coefficient(~context.cir.path_valid) = 0;
    channel = sum(coefficient, 3);
else
    channel = complex([]);
end
end

function values = perSampleDelaySpread(cir)
sampleCount = size(cir.coefficient, 5);
timeCount = size(cir.coefficient, 4);
values = NaN(sampleCount, 1);
power = abs(cir.coefficient).^2;
power(~cir.path_valid) = 0;
for sample = 1:sampleCount
    byTime = NaN(timeCount, 1);
    for time = 1:timeCount
        p = double(power(:, :, :, time, sample));
        d = double(cir.delay_s(:, :, :, time, sample));
        valid = cir.path_valid(:, :, :, time, sample) & ...
            isfinite(d) & isfinite(p) & p >= 0;
        byTime(time) = weightedSpread(d(valid), p(valid));
    end
    finite = byTime(isfinite(byTime));
    if ~isempty(finite)
        values(sample) = mean(finite);
    end
end
values = values(isfinite(values));
end

function [angleDeg, spectra, labels, spreads] = ...
        pathAngularCharacteristics(cir)
edges = (-180:2:180).';
angleDeg = (edges(1:end-1) + edges(2:end)) / 2;
spectra = zeros(numel(angleDeg), 2);
labels = strings(2, 1);
spreads = cell(2, 1);
seriesCount = 0;
power = abs(cir.coefficient).^2;
power(~cir.path_valid) = 0;
fields = ["aoa_rad", "aod_rad"];
displayNames = ["AoA（接收）", "AoD（发射）"];
for index = 1:numel(fields)
    if ~isfield(cir, fields(index))
        continue;
    end
    angle = double(cir.(fields(index))) * 180 / pi;
    histogram = weightedHistogram(angle(:), double(power(:)), edges);
    if sum(histogram) <= 0
        continue;
    end
    seriesCount = seriesCount + 1;
    spectra(:, seriesCount) = normalizeDb(histogram);
    labels(seriesCount, 1) = displayNames(index);
    spreads{seriesCount, 1} = perSampleCircularSpread( ...
        cir.(fields(index)), power, cir.path_valid) * 180 / pi;
end
spectra = spectra(:, 1:seriesCount);
labels = labels(1:seriesCount);
spreads = spreads(1:seriesCount);
end

function [angleDeg, spectra, labels, spreads, reason] = ...
        beamspaceAngularCharacteristics(context)
angleDeg = (-90:1:90).';
spectra = zeros(numel(angleDeg), 2);
labels = strings(2, 1);
spreads = cell(2, 1);
seriesCount = 0;
reason = ...
    "Need explicit AoA/AoD or complex array data with ULA geometry.";
metadata = context.metadata;
centerHz = metadataNumber(metadata, "center_frequency_hz");
if ~isfinite(centerHz) || centerHz <= 0
    return;
end
channel = context.ctf.H;
if size(channel, 2) > 1 && hasValidUla(metadata, "rx_array")
    spacing = double(metadata.rx_array.element_spacing_m);
    [spectrum, perSample] = beamspaceSpectrum( ...
        channel, 2, spacing, centerHz, angleDeg);
    seriesCount = seriesCount + 1;
    spectra(:, seriesCount) = normalizeDb(spectrum);
    labels(seriesCount, 1) = "Rx 波束空间";
    spreads{seriesCount, 1} = perSample;
end
if size(channel, 1) > 1 && hasValidUla(metadata, "tx_array")
    spacing = double(metadata.tx_array.element_spacing_m);
    [spectrum, perSample] = beamspaceSpectrum( ...
        channel, 1, spacing, centerHz, angleDeg);
    seriesCount = seriesCount + 1;
    spectra(:, seriesCount) = normalizeDb(spectrum);
    labels(seriesCount, 1) = "Tx 波束空间";
    spreads{seriesCount, 1} = perSample;
end
spectra = spectra(:, 1:seriesCount);
labels = labels(1:seriesCount);
spreads = spreads(1:seriesCount);
if seriesCount > 0
    reason = "Beamspace angle spectrum uses explicit ULA geometry and carrier.";
end
end

function [spectrum, perSampleSpread] = beamspaceSpectrum( ...
        channel, arrayDimension, spacingM, centerHz, angleDeg)
wavelength = 299792458 / centerHz;
elementCount = size(channel, arrayDimension);
elementIndex = (0:elementCount - 1).';
steering = exp(1i * 2 * pi * spacingM / wavelength .* ...
    elementIndex .* sind(angleDeg(:).')) / sqrt(elementCount);

if arrayDimension == 2
    observations = reshape(permute(channel, [2, 1, 3, 4, 5]), ...
        elementCount, []);
else
    observations = reshape(channel, elementCount, []);
end
response = steering' * observations;
spectrum = mean(abs(response).^2, 2);

sampleCount = size(channel, 5);
perSampleSpread = NaN(sampleCount, 1);
for sample = 1:sampleCount
    sampleChannel = channel(:, :, :, :, sample);
    if arrayDimension == 2
        sampleObservations = reshape(permute(sampleChannel, ...
            [2, 1, 3, 4, 5]), elementCount, []);
    else
        sampleObservations = reshape(sampleChannel, elementCount, []);
    end
    sampleResponse = steering' * sampleObservations;
    samplePower = mean(abs(sampleResponse).^2, 2);
    perSampleSpread(sample) = weightedSpread(angleDeg, samplePower);
end
perSampleSpread = perSampleSpread(isfinite(perSampleSpread));
end

function tf = hasValidUla(metadata, fieldName)
tf = isfield(metadata, fieldName) && isstruct(metadata.(fieldName)) && ...
    isfield(metadata.(fieldName), "type") && ...
    upper(string(metadata.(fieldName).type)) == "ULA" && ...
    isfield(metadata.(fieldName), "element_spacing_m") && ...
    isnumeric(metadata.(fieldName).element_spacing_m) && ...
    isscalar(metadata.(fieldName).element_spacing_m) && ...
    isfinite(metadata.(fieldName).element_spacing_m) && ...
    metadata.(fieldName).element_spacing_m > 0;
end

function values = perSampleCircularSpread(angleRad, power, validMask)
sampleCount = size(power, 5);
values = NaN(sampleCount, 1);
for sample = 1:sampleCount
    angle = double(angleRad(:, :, :, :, sample));
    weights = double(power(:, :, :, :, sample));
    valid = validMask(:, :, :, :, sample) & isfinite(angle) & ...
        isfinite(weights) & weights >= 0;
    angle = angle(valid);
    weights = weights(valid);
    if isempty(weights) || sum(weights) <= 0
        continue;
    end
    resultant = abs(sum(weights .* exp(1i * angle)) / sum(weights));
    resultant = min(max(resultant, eps), 1);
    values(sample) = sqrt(max(0, -2 * log(resultant)));
end
values = values(isfinite(values));
end

function matrix = normalizedCorrelationMatrix(observations)
observations = double(observations);
matrix = observations * observations' / max(size(observations, 2), 1);
diagonal = real(diag(matrix));
scale = sqrt(max(diagonal, 0) * max(diagonal, 0).');
matrix(scale > 0) = matrix(scale > 0) ./ scale(scale > 0);
matrix(scale == 0) = 0;
end

function [frequencyHz, averagePower, settings] = ...
        averagedDopplerSpectrum(sequences, spacingS)
sequences = double(sequences);
timeCount = size(sequences, 1);
if timeCount == 1
    window = 1;
else
    window = 0.5 - 0.5 * cos(2 * pi * (0:timeCount - 1).' / ...
        (timeCount - 1));
end
centered = sequences - mean(sequences, 1);
windowed = centered .* window;
nfft = 2 ^ nextpow2(timeCount);
spectrum = fftshift(fft(windowed, nfft, 1), 1);
power = abs(spectrum).^2 / max(sum(window.^2), eps);
averagePower = mean(power, 2);
samplingRate = 1 / spacingS;
frequencyHz = ((-floor(nfft / 2)):(ceil(nfft / 2) - 1)).' * ...
    samplingRate / nfft;
settings = struct("sampling_rate_hz", samplingRate, ...
    "nfft", nfft, "window", "hann");
end

function [delayBinsS, heatmap] = binnedDelaySamplePower(cir)
power = abs(cir.coefficient).^2;
power(~cir.path_valid) = 0;
delay = double(cir.delay_s);
valid = cir.path_valid & isfinite(delay) & isfinite(power);
allDelays = delay(valid);
if isempty(allDelays)
    delayBinsS = [];
    heatmap = [];
    return;
end
minimum = min(allDelays);
maximum = max(allDelays);
if maximum <= minimum
    padding = max(abs(minimum) * 1e-6, 1e-12);
    minimum = minimum - padding;
    maximum = maximum + padding;
end
binCount = min(max(size(cir.coefficient, 3), 64), 256);
edges = linspace(minimum, maximum, binCount + 1);
delayBinsS = (edges(1:end-1) + edges(2:end)).' / 2;
sampleCount = size(cir.coefficient, 5);
timeCount = size(cir.coefficient, 4);
heatmap = zeros(binCount, sampleCount);
for sample = 1:sampleCount
    accumulator = zeros(binCount, 1);
    for time = 1:timeCount
        d = delay(:, :, :, time, sample);
        p = double(power(:, :, :, time, sample));
        mask = valid(:, :, :, time, sample);
        d = d(mask);
        p = p(mask);
        bins = discretize(d, edges);
        accepted = isfinite(bins);
        if any(accepted)
            acceptedBins = double(full(bins(accepted)));
            acceptedPower = double(full(p(accepted)));
            accumulator = accumulator + accumarray( ...
                acceptedBins(:), acceptedPower(:), ...
                [binCount, 1], @sum, 0);
        end
    end
    heatmap(:, sample) = accumulator / max(timeCount, 1);
end
end

function values = weightedHistogram(data, weights, edges)
valid = isfinite(data) & isfinite(weights) & weights >= 0;
data = data(valid);
weights = weights(valid);
bins = discretize(data, edges);
accepted = isfinite(bins);
acceptedBins = double(full(bins(accepted)));
acceptedWeights = double(full(weights(accepted)));
values = accumarray(acceptedBins(:), acceptedWeights(:), ...
    [numel(edges) - 1, 1], @sum, 0);
end

function value = weightedSpread(coordinate, power)
coordinate = double(coordinate(:));
power = double(power(:));
valid = isfinite(coordinate) & isfinite(power) & power >= 0;
coordinate = coordinate(valid);
power = power(valid);
total = sum(power);
if isempty(power) || total <= 0
    value = NaN;
    return;
end
meanValue = sum(coordinate .* power) / total;
variance = sum(((coordinate - meanValue).^2) .* power) / total;
value = sqrt(max(variance, 0));
end

function reason = delayUnavailableReason(context)
if isfield(context.cir, "reason") && context.cir.reason ~= ""
    reason = context.cir.reason;
else
    reason = ...
        "Need more than one valid path/tap and a physical delay definition.";
end
end

function value = metadataNumber(metadata, names)
names = string(names);
value = NaN;
for name = names
    if isfield(metadata, name) && isnumeric(metadata.(name)) && ...
            isscalar(metadata.(name)) && isfinite(metadata.(name))
        value = double(metadata.(name));
        return;
    end
end
end

function [uniform, spacing] = uniformSpacing(axisValues)
axisValues = double(axisValues(:));
spacing = NaN;
uniform = false;
if numel(axisValues) < 2 || any(~isfinite(axisValues))
    return;
end
differences = diff(axisValues);
if any(differences <= 0)
    return;
end
spacing = median(differences);
tolerance = max(abs(spacing) * 1e-6, eps(max(abs(axisValues))));
uniform = all(abs(differences - spacing) <= tolerance);
end

function expanded = expandToShape(value, targetShape)
sourceShape = size5(value);
if ~all(sourceShape == 1 | sourceShape == targetShape)
    error("analyze_channel_characteristics:CannotExpand", ...
        "A CIR field cannot expand to coefficient dimensions.");
end
expanded = repmat(reshape(value, sourceShape), targetShape ./ sourceShape);
end

function result = meanOverDimensions(value, dimensions)
result = value;
for dimension = sort(dimensions, "descend")
    result = mean(result, dimension);
end
end

function db = safeDb(linear)
db = 10 * log10(max(double(linear), realmin("double")));
end

function db = normalizeDb(linear)
db = safeDb(linear);
finite = db(isfinite(db));
if isempty(finite)
    return;
end
db = db - max(finite);
db(db < -120) = -120;
end

function db = normalizeDbMatrix(linear)
db = safeDb(linear);
finite = db(isfinite(db));
if ~isempty(finite)
    db = db - max(finite);
end
db(db < -120) = -120;
end

function warnings = collectMetricWarnings(metrics)
warnings = strings(0, 1);
for fieldName = string(fieldnames(metrics)).'
    metricWarnings = metrics.(fieldName).warnings;
    if ~isempty(metricWarnings)
        warnings = [warnings; fieldName + ": " + metricWarnings]; %#ok<AGROW>
    end
end
end

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
