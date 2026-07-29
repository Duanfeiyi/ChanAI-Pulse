%TEST_STEP5_CHARACTERISTICS_ENGINE Step 5 calculation and plotting tests.

root = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(root, "core")));
addpath(genpath(fullfile(root, "app")));
addpath(genpath(fullfile(root, "examples")));

scenarios = load_v3_standard_scenarios();
expectedCounts = [1, 3, 6, 9];

%% CIR and CTF standard families reach their ideal capability sets
for scenarioIndex = 1:numel(scenarios)
    pair = generate_v3_standard_pair(scenarios(scenarioIndex));
    datasets = {pair.cir, pair.ctf};
    for domainIndex = 1:numel(datasets)
        analysis = analyze_channel_characteristics( ...
            datasets{domainIndex}, Region="all", ModuleRole="review");
        assert(analysis.status == "PASS", ...
            "Standard fixture analysis should pass.");
        assert(analysis.registry.ideal_standard_plot_count == ...
            expectedCounts(scenarioIndex));
        assert(analysis.registry.available_standard_plot_count == ...
            expectedCounts(scenarioIndex));
        assert(analysis.metrics.delay_sample_heatmap.available == ...
            (scenarioIndex > 1));
        visibleEntries = select_channel_plot_entries(analysis.registry);
        visibleIds = string({visibleEntries.id}).';
        expectedVisibleIds = string(pair.expected.standard_plots(:));
        if pair.expected.delay_sample_heatmap
            expectedVisibleIds(end + 1, 1) = ...
                "delay_sample_heatmap"; %#ok<SAGROW>
        end
        assert(isequal(visibleIds, expectedVisibleIds), ...
            "UI-visible plots must exactly match the frozen standard set.");
        if pair.cir.dimensions.Tx == 1 && pair.cir.dimensions.Rx == 1
            assert(~analysis.metrics.angular_power_spectrum.available);
            assert(~analysis.metrics.angular_spread_cdf.available);
        end
        assert(allMetricOutputsFinite(analysis));
        assert(abs(max(analysis.metrics.power.y)) < 1e-10);
        if analysis.metrics.pdp.available
            assert(all(diff(analysis.metrics.pdp.x) >= 0));
            assert(abs(max(analysis.metrics.pdp.y)) < 1e-10);
        end
        if analysis.metrics.frequency_autocorrelation.available
            assert(abs(analysis.metrics.frequency_autocorrelation.y(1) - 1) ...
                < 1e-10);
        end
        if analysis.metrics.time_autocorrelation.available
            assert(abs(analysis.metrics.time_autocorrelation.y(1) - 1) ...
                < 1e-10);
        end
        if analysis.metrics.spatial_correlation.available
            assert(max(abs(diag( ...
                analysis.metrics.spatial_correlation.z) - 1)) < 1e-8);
        end
        assertCdfMonotonic(analysis.metrics.delay_spread_cdf);
        assertCdfMonotonic(analysis.metrics.angular_spread_cdf);
        assertCdfMonotonic(analysis.metrics.doppler_spread_cdf);
    end
end

%% Known task region excludes interpolation targets
dynamicPair = generate_v3_standard_pair(scenarios(4));
interpolation = create_channel_task_preset( ...
    dynamicPair.cir, "interpolation", "sample");
knownAnalysis = analyze_channel_characteristics(dynamicPair.cir, ...
    Task=interpolation, Region="known", ModuleRole="input");
assert(knownAnalysis.status == "PASS");
assert(knownAnalysis.selection.task_applied);
assert(knownAnalysis.dataset_summary.N_sample == ...
    numel(interpolation.known_indices));
assert(~any(ismember(knownAnalysis.selection.indices, ...
    interpolation.target_indices)));
targetChanged = dynamicPair.cir;
targetChanged.cir.coefficient(:, :, :, :, ...
    interpolation.target_indices) = ...
    targetChanged.cir.coefficient(:, :, :, :, ...
    interpolation.target_indices) * 1000;
targetChangedAnalysis = analyze_channel_characteristics(targetChanged, ...
    Task=interpolation, Region="known", ModuleRole="input");
assert(isequaln(knownAnalysis.metrics.pdp.raw, ...
    targetChangedAnalysis.metrics.pdp.raw), ...
    "Changing target values must not affect known-region characteristics.");

%% Same data and region are identical across module roles
inputAnalysis = analyze_channel_characteristics( ...
    dynamicPair.cir, Region="all", ModuleRole="input");
predictionAnalysis = analyze_channel_characteristics( ...
    dynamicPair.cir, Region="all", ModuleRole="prediction");
assert(isequaln(inputAnalysis.metrics.pdp.raw, ...
    predictionAnalysis.metrics.pdp.raw));
assert(isequaln(inputAnalysis.metrics.time_autocorrelation.raw, ...
    predictionAnalysis.metrics.time_autocorrelation.raw));
assert(isequaln(inputAnalysis.registry.entries, ...
    predictionAnalysis.registry.entries));

%% Export bundle is reusable and does not copy the source dataset
exportBundle = create_step5_export_bundle(inputAnalysis, interpolation);
assert(exportBundle.schema == "chanai-pulse-step5-export-v1");
assert(isequaln(exportBundle.task, interpolation));
assert(isequaln(exportBundle.dataset_summary, ...
    inputAnalysis.dataset_summary));
assert(~isfield(exportBundle, "dataset"));
assert(~isfield(exportBundle.analysis, "dataset"));

%% One known sample suppresses empirical CDFs
oneKnownTask = create_channel_task( ...
    "extrapolation", "sample", 1, 2:32);
oneSample = analyze_channel_characteristics(dynamicPair.cir, ...
    Task=oneKnownTask, Region="known");
assert(oneSample.status == "PASS");
assert(~oneSample.metrics.delay_spread_cdf.available);
assert(~oneSample.metrics.angular_spread_cdf.available);
assert(~oneSample.metrics.doppler_spread_cdf.available);

%% Two to nineteen samples produce empirical CDFs with a warning
tenKnownTask = create_channel_task( ...
    "extrapolation", "sample", 1:10, 11:32);
tenSamples = analyze_channel_characteristics(dynamicPair.cir, ...
    Task=tenKnownTask, Region="known");
assert(tenSamples.status == "WARNING");
assert(tenSamples.metrics.delay_spread_cdf.available);
assert(~isempty(tenSamples.metrics.delay_spread_cdf.warnings));

%% Ordered semantics gates the additional delay-sample heatmap
unordered = dynamicPair.cir;
unordered.metadata.sample_semantics = "independent";
unorderedAnalysis = analyze_channel_characteristics(unordered, Region="all");
assert(~unorderedAnalysis.metrics.delay_sample_heatmap.available);
assert(contains(unorderedAnalysis.metrics.delay_sample_heatmap.reason, ...
    "ordered"));

%% Missing time definition disables time-domain metrics without placeholders
noTime = dynamicPair.cir;
noTime.axes = rmfield(noTime.axes, "time_s");
noTime.metadata = rmfield(noTime.metadata, "snapshot_interval_s");
noTimeAnalysis = analyze_channel_characteristics(noTime, Region="all");
assert(~noTimeAnalysis.metrics.doppler_power_spectrum.available);
assert(~noTimeAnalysis.metrics.time_autocorrelation.available);
assert(~noTimeAnalysis.metrics.doppler_spread_cdf.available);
assert(isempty(noTimeAnalysis.metrics.doppler_power_spectrum.x));
assert(isempty(noTimeAnalysis.metrics.doppler_power_spectrum.y));

%% Missing angles and array geometry disables angular metrics
noAngle = dynamicPair.cir;
noAngle.cir = rmfield(noAngle.cir, ["aoa_rad", "aod_rad"]);
noAngle.metadata = rmfield(noAngle.metadata, ["tx_array", "rx_array"]);
noAngleAnalysis = analyze_channel_characteristics(noAngle, Region="all");
assert(~noAngleAnalysis.metrics.angular_power_spectrum.available);
assert(~noAngleAnalysis.metrics.angular_spread_cdf.available);
assert(noAngleAnalysis.metrics.spatial_correlation.available);

%% A single MIMO observation cannot estimate spatial correlation
singleObservation = dynamicPair.cir;
singleObservation.cir.coefficient = ...
    singleObservation.cir.coefficient(:, 1, 1, 1, 1);
singleObservation.cir.delay_s = ...
    singleObservation.cir.delay_s(:, :, 1, 1, 1);
singleObservation.cir.path_valid = ...
    singleObservation.cir.path_valid(:, :, 1, 1, 1);
singleObservation.cir = rmfield(singleObservation.cir, ...
    ["aoa_rad", "aod_rad", "doppler_hz"]);
singleObservation.dimensions.Rx = 1;
singleObservation.dimensions.Npath = 1;
singleObservation.dimensions.Nt = 1;
singleObservation.dimensions.N_sample = 1;
singleObservation.axes = rmfield(singleObservation.axes, "time_s");
singleObservation.axes.sample_index = ...
    singleObservation.axes.sample_index(1);
singleObservation.axes.sample_position_m = ...
    singleObservation.axes.sample_position_m(1, :);
singleObservation.metadata = rmfield(singleObservation.metadata, ...
    ["center_frequency_hz", "subcarrier_spacing_hz", ...
    "snapshot_interval_s", "tx_array", "rx_array", "config"]);
singleObservation.metadata.sample_semantics = "independent";
singleObservationAnalysis = analyze_channel_characteristics( ...
    singleObservation, Region="all");
assert(~singleObservationAnalysis.metrics.spatial_correlation.available);
assert(singleObservationAnalysis.classification == "other_channel");
assert(~singleObservationAnalysis.registry.is_standard_classification);
assert(singleObservationAnalysis.registry.ideal_standard_plot_count == 0);
singleVisible = select_channel_plot_entries( ...
    singleObservationAnalysis.registry);
assert(isequal(string({singleVisible.id}), "power"));

%% Registered metrics render without changing scientific availability
clear step5Cleanup step5Figure step5Axes
step5Figure = feval("figure", "Visible", "off"); %#ok<FVAL>
step5Cleanup = onCleanup(@() closeIfValid(step5Figure));
step5Axes = feval("axes", step5Figure); %#ok<FVAL>
availableEntries = inputAnalysis.registry.entries( ...
    [inputAnalysis.registry.entries.available]);
for entry = availableEntries.'
    render_channel_characteristic(step5Axes, inputAnalysis, entry.id);
    drawnow;
end
clear step5Cleanup

fprintf("PASS: Step 5 unified characteristics, registry, and renderer.\n");

function tf = allMetricOutputsFinite(analysis)
tf = true;
fields = string(fieldnames(analysis.metrics)).';
for fieldName = fields
    metric = analysis.metrics.(fieldName);
    if ~metric.available
        continue;
    end
    values = {metric.x, metric.y, metric.z};
    for index = 1:numel(values)
        value = values{index};
        if isnumeric(value) && ...
                any(~isfinite(real(value(:))) | ~isfinite(imag(value(:))))
            tf = false;
            return;
        end
    end
end
end

function assertCdfMonotonic(metric)
if ~metric.available
    return;
end
if metric.kind == "multi_cdf"
    for item = metric.raw.series.'
        assert(all(diff(item.x) >= 0));
        assert(all(diff(item.y) >= 0));
        assert(item.y(end) == 1);
    end
else
    assert(all(diff(metric.x) >= 0));
    assert(all(diff(metric.y) >= 0));
    assert(metric.y(end) == 1);
end
end

function closeIfValid(figureHandle)
if isvalid(figureHandle)
    close(figureHandle);
end
end
