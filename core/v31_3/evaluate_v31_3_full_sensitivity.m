function [rows, summary] = evaluate_v31_3_full_sensitivity(engineRoot, config)
%EVALUATE_V31_3_FULL_SENSITIVITY Full-6GPCM one-parameter sensitivity study.
%   The read-only public API uses fixed seeds. Each profile varies one P8
%   parameter; its configured speed and array dimensions are actually used.

arguments
    engineRoot (1, 1) string
    config (1, 1) struct = default_v31_3_evidence_config()
end
validateSensitivityConfig(config);
defaults = step11abc_versioned_generator_defaults(engineRoot);
rows = table();
for profileIndex = 1:numel(config.sensitivity.profile_scenarios)
    scenario = config.sensitivity.profile_scenarios(profileIndex);
    frequency = config.sensitivity.profile_frequencies_hz(profileIndex);
    profile = read_step11abc_full_profile(engineRoot, scenario, frequency, defaults);
    for seed = config.sensitivity.seed_values
        baseConfig = generatorConfig(profile, config, profileIndex, seed, engineRoot);
        baseline = requireSuccess(run_generator_adapter(baseConfig));
        for parameterIndex = 1:numel(config.parameter_names)
            name = config.parameter_names(parameterIndex);
            variedConfig = baseConfig;
            [value, direction] = perturbedValue(profile.values(parameterIndex), ...
                config.parameter_bounds(parameterIndex, :), name, config);
            variedConfig.model.(name) = value;
            varied = requireSuccess(run_generator_adapter(variedConfig));
            metrics = compareOutputs(baseline, varied, config.sensitivity.delay_bin_count);
            row = table(string(scenario), frequency, double(seed), name, ...
                string(direction), profile.values(parameterIndex), value, ...
                metrics.ctf_relative_nrmse, metrics.pdp_relative_nrmse, ...
                metrics.rms_delay_abs_error_s, metrics.spatial_correlation_delta, ...
                metrics.temporal_coherence_delta, ...
                'VariableNames', {'scenario_name', 'carrier_frequency_hz', ...
                'seed', 'parameter_name', 'direction', 'baseline_value', ...
                'perturbed_value', 'ctf_relative_nrmse', 'pdp_relative_nrmse', ...
                'rms_delay_abs_error_s', 'spatial_correlation_delta', ...
                'temporal_coherence_delta'});
            rows = [rows; row]; %#ok<AGROW>
        end
    end
end
summary = groupsummary(rows, 'parameter_name', 'mean', ...
    {'ctf_relative_nrmse', 'pdp_relative_nrmse', ...
    'rms_delay_abs_error_s', 'spatial_correlation_delta', ...
    'temporal_coherence_delta'});
summary.sensitivity_score = sensitivityScore(summary);
end

function validateSensitivityConfig(config)
s = config.sensitivity;
count = numel(s.profile_scenarios);
if count < 1 || numel(s.profile_frequencies_hz) ~= count || ...
        numel(s.profile_speeds_mps) ~= count || ...
        numel(s.profile_tx_counts) ~= count || numel(s.profile_rx_counts) ~= count
    error("evaluate_v31_3_full_sensitivity:InvalidProfiles", ...
        "Every sensitivity profile needs scenario, frequency, speed, Tx and Rx.");
end
end

function configOut = generatorConfig(profile, config, profileIndex, seed, engineRoot)
s = config.sensitivity;
configOut = default_generator_config("full_6gpcm");
configOut.mode = "formal";
configOut.engine_root = engineRoot;
configOut.backend_options.full_interface = "public_api";
configOut.backend_options.full_track_speed_mps = s.profile_speeds_mps(profileIndex);
configOut.dimensions = struct("Tx", s.profile_tx_counts(profileIndex), ...
    "Rx", s.profile_rx_counts(profileIndex), "Npath", 0, ...
    "Nt", s.snapshot_count, "N_sample", 1);
configOut.scenario.id = profile.scenario_name;
configOut.scenario.center_frequency_hz = profile.carrier_frequency_hz;
configOut.scenario.track_type = "linear";
configOut.scenario.snapshot_interval_s = 0.25;
bandwidth = 100e6;
configOut.scenario.bandwidth_hz = bandwidth;
configOut.ctf.enabled = true;
configOut.ctf.frequency_hz = linspace( ...
    profile.carrier_frequency_hz - bandwidth / 2, ...
    profile.carrier_frequency_hz + bandwidth / 2, ...
    s.ctf_frequency_count).';
configOut.random_seed = seed;
for index = 1:numel(config.parameter_names)
    configOut.model.(config.parameter_names(index)) = profile.values(index);
end
end

function result = requireSuccess(result)
if ~result.success
    error("evaluate_v31_3_full_sensitivity:GenerationFailed", ...
        "%s", strjoin(result.errors, " | "));
end
end

function [value, direction] = perturbedValue(baseline, bounds, name, config)
delta = config.sensitivity.relative_bound_perturbation * (bounds(2) - bounds(1));
value = min(bounds(2), baseline + delta);
direction = "increase";
if value == baseline
    value = max(bounds(1), baseline - delta);
    direction = "decrease";
end
if any(name == ["num_clusters", "num_rays"])
    value = round(value);
end
if value == baseline
    error("evaluate_v31_3_full_sensitivity:NoPerturbation", ...
        "Cannot perturb %s within its configured bounds.", name);
end
end

function metrics = compareOutputs(baseline, varied, delayBinCount)
baselineH = baseline.ctf_dataset.ctf.H;
variedH = varied.ctf_dataset.ctf.H;
metrics.ctf_relative_nrmse = norm(variedH(:) - baselineH(:)) / ...
    max(eps, norm(baselineH(:)));
delay = [double(baseline.dataset.cir.delay_s(:)); ...
    double(varied.dataset.cir.delay_s(:))];
finiteMax = max(1e-9, max(delay) * 1.2);
edges = [linspace(0, finiteMax, delayBinCount + 1), Inf];
baseFeatures = compute_step11abc_cir_features(baseline.dataset, edges);
variedFeatures = compute_step11abc_cir_features(varied.dataset, edges);
metrics.pdp_relative_nrmse = norm(variedFeatures.pdp - baseFeatures.pdp) / ...
    max(eps, norm(baseFeatures.pdp));
metrics.rms_delay_abs_error_s = abs( ...
    variedFeatures.rms_delay_s - baseFeatures.rms_delay_s);
metrics.spatial_correlation_delta = spatialDelta( ...
    baseline.dataset.cir.coefficient, varied.dataset.cir.coefficient);
metrics.temporal_coherence_delta = temporalDelta( ...
    baseline.dataset.cir.coefficient, varied.dataset.cir.coefficient);
end

function value = spatialDelta(baseline, varied)
if size(baseline, 1) * size(baseline, 2) < 2
    value = NaN;
    return;
end
base = reshape(baseline, size(baseline, 1) * size(baseline, 2), []);
other = reshape(varied, size(varied, 1) * size(varied, 2), []);
baseR = base * base' / max(1, size(base, 2));
otherR = other * other' / max(1, size(other, 2));
baseR = baseR / max(eps, trace(baseR));
otherR = otherR / max(eps, trace(otherR));
value = norm(otherR - baseR, "fro") / max(eps, norm(baseR, "fro"));
end

function value = temporalDelta(baseline, varied)
if ndims(baseline) < 4 || size(baseline, 4) < 2
    value = NaN;
    return;
end
value = abs(temporalCoherence(varied) - temporalCoherence(baseline));
end

function value = temporalCoherence(H)
scores = zeros(size(H, 4) - 1, 1);
for index = 1:numel(scores)
    first = H(:, :, :, index);
    second = H(:, :, :, index + 1);
    scores(index) = abs(sum(conj(first(:)) .* second(:))) / ...
        max(eps, norm(first(:)) * norm(second(:)));
end
value = mean(scores);
end

function score = sensitivityScore(summary)
matrix = [double(summary.mean_ctf_relative_nrmse), ...
    double(summary.mean_pdp_relative_nrmse), ...
    normalizeColumn(summary.mean_rms_delay_abs_error_s), ...
    normalizeColumn(summary.mean_spatial_correlation_delta), ...
    normalizeColumn(summary.mean_temporal_coherence_delta)];
matrix(~isfinite(matrix)) = 0;
score = mean(matrix, 2);
end

function value = normalizeColumn(value)
value = double(value);
finite = value(isfinite(value));
if isempty(finite) || max(finite) <= 0
    value(:) = 0;
else
    value = value / max(finite);
end
end
