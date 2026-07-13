function result = generate_6gpcm_lite(config)
%GENERATE_6GPCM_LITE Generate clustered synthetic CIR snapshots.
%   result = generate_6gpcm_lite(config) implements a compact, independent
%   geometry-inspired stochastic model with configurable delay spread,
%   clusters, rays, Rician factor, Doppler, and shadowing. It produces
%   synthetic data only and does not read, copy, or retain measured data.

arguments
    config (1, 1) struct
end

config = validateConfig(config);
if ~isempty(config.random_seed)
    rng(config.random_seed, "twister");
end

delayBins = round(config.delay_max_ns / config.delay_grid_step_ns) + 1;
delayAxisSeconds = (0:delayBins - 1) / config.bandwidth_hz;
frequencyAxis = (-floor(delayBins / 2):ceil(delayBins / 2) - 1) * ...
    (config.bandwidth_hz / delayBins);

cir = complex(zeros(1, 1, config.snapshots, delayBins));
delayTensor = zeros(1, 1, config.snapshots, delayBins);
delaySpreadNs = zeros(config.snapshots, 1);
clusterDelays = zeros(config.snapshots, config.clusters);
clusterPowers = zeros(config.snapshots, config.clusters);
preview = struct();

for snapshotIdx = 1:config.snapshots
    rmsDelay = 10 ^ (randn * config.ds_sigma + config.ds_mu);
    delays = sort(-rmsDelay * config.r_ds * log(max(rand(1, config.clusters), realmin)));
    delays = delays - min(delays);

    shadowingDb = config.lns_ksi_db * randn(1, config.clusters);
    powers = exp(-delays / max(rmsDelay, realmin)) .* 10 .^ (-shadowingDb / 10);
    kLinear = 10 ^ ((config.kf_mu_db + config.kf_sigma_db * randn) / 10);
    powers(1) = powers(1) + kLinear * sum(powers);
    powers = powers / sum(powers);

    rayAngles = 2 * pi * rand(config.clusters, config.rays);
    rayPhases = 2 * pi * rand(config.clusters, config.rays);
    rayDopplers = config.doppler_hz * cos(rayAngles);
    snapshotTime = (snapshotIdx - 1) * config.sample_interval_s;
    fading = mean(exp(1i * (2 * pi * rayDopplers * snapshotTime + rayPhases)), 2).';
    clusterGains = sqrt(powers) .* fading;

    frequencyResponse = zeros(1, delayBins);
    for clusterIdx = 1:config.clusters
        frequencyResponse = frequencyResponse + clusterGains(clusterIdx) .* ...
            exp(-1i * 2 * pi * frequencyAxis * delays(clusterIdx));
    end
    snapshotCir = ifft(ifftshift(frequencyResponse));

    cir(1, 1, snapshotIdx, :) = snapshotCir;
    delayTensor(1, 1, snapshotIdx, :) = delayAxisSeconds;
    delaySpreadNs(snapshotIdx) = compute_delay_spread(delayAxisSeconds, abs(snapshotCir(:)).^2) * 1e9;
    clusterDelays(snapshotIdx, :) = delays;
    clusterPowers(snapshotIdx, :) = powers;

    if snapshotIdx == 1
        preview.cir = snapshotCir;
        preview.cluster_delays_s = delays;
        preview.cluster_gains = clusterGains;
        preview.delay_axis_ns = delayAxisSeconds * 1e9;
    end
end

result = struct();
result.engine = "6GPCM-lite";
result.data_source = "synthetic_generated";
result.config = config;
result.cir = cir;
result.delay = delayTensor;
result.delay_axis_seconds = delayAxisSeconds;
result.delay_spread_ns = delaySpreadNs;
result.cluster_delays_s = clusterDelays;
result.cluster_powers = clusterPowers;
result.preview = preview;
end

function config = validateConfig(config)
defaults = default_6gpcm_lite_config();
defaultFields = fieldnames(defaults);
for idx = 1:numel(defaultFields)
    name = defaultFields{idx};
    if ~isfield(config, name) || isempty(config.(name))
        config.(name) = defaults.(name);
    end
end

positiveFields = ["bandwidth_hz", "delay_grid_step_ns", "delay_max_ns", ...
    "r_ds", "clusters", "rays", "snapshots", "sample_interval_s"];
for idx = 1:numel(positiveFields)
    name = positiveFields(idx);
    value = config.(name);
    if ~isscalar(value) || ~isfinite(value) || value <= 0
        error("generate_6gpcm_lite:InvalidConfig", "%s must be a positive finite scalar.", name);
    end
end

integerFields = ["clusters", "rays", "snapshots"];
for idx = 1:numel(integerFields)
    name = integerFields(idx);
    config.(name) = round(config.(name));
end
end
