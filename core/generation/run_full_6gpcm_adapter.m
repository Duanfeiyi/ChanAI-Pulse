function payload = run_full_6gpcm_adapter(config, hooks)
%RUN_FULL_6GPCM_ADAPTER Wrap the read-only external full 6GPCM probe.
%   The historical generate_channel_v1 entry point is called without
%   editing or copying any external core file.

arguments
    config (1, 1) struct
    hooks (1, 1) struct
end

if hooks.is_cancelled()
    error("run_full_6gpcm_adapter:Cancelled", ...
        "Full 6GPCM generation was cancelled before the external call.");
end
hooks.emit("external_core", 0.20, ...
    "Calling the read-only full 6GPCM entry point");

probeConfig = default_full_6gpcm_probe_config(string(config.engine_root));
probeConfig.DS_mu = config.model.DS_mu;
probeConfig.DS_sigma = config.model.DS_sigma;
probeConfig.r_DS = config.model.r_DS;
probeConfig.num_clusters = config.model.num_clusters;
probeConfig.num_rays = config.model.num_rays;
probeConfig.LNS_ksi = config.model.LNS_ksi;
probeConfig.KF_mu = config.model.KF_mu;
probeConfig.KF_sigma = config.model.KF_sigma;
probeConfig.sample_count = config.dimensions.N_sample;
probeConfig.random_seed = config.random_seed;
probeConfig.snapshot_interval_s = config.scenario.snapshot_interval_s;
probeConfig.engine_id = string(config.engine.id);
probeConfig.source_package_name = string(config.engine.source_package_name);
probeConfig.source_version = string(config.engine.version);
probeConfig.source_package_sha256 = ...
    string(config.engine.source_package_sha256);
probeConfig.expected_tree_sha256 = ...
    string(config.engine.expected_tree_sha256);

probe = run_full_6gpcm_probe(probeConfig);
if hooks.is_cancelled()
    error("run_full_6gpcm_adapter:Cancelled", ...
        "Full 6GPCM generation completed, but the result was discarded because cancellation was requested.");
end
hooks.emit("canonicalize", 0.86, ...
    "Validating the canonical full 6GPCM CIR");

dataset = probe.dataset;
dataset.metadata.source = "full_6gpcm_adapter";
dataset.metadata.generator = string(config.engine.id);
dataset.metadata.generator_version = string(config.engine.version);
dataset.metadata.scenario_id = string(config.scenario.id);
dataset.metadata.config = sanitize_generator_config(config);
validation = validate_channel_dataset(dataset);
if ~validation.is_valid
    error("run_full_6gpcm_adapter:InvalidDataset", ...
        "Full 6GPCM adapter output failed the v3 contract: %s", ...
        strjoin(validation.errors, " | "));
end

warnings = strings(0, 1);
if logical(config.engine.test_only)
    warnings(end + 1, 1) = ...
        "The configured full_6gpcm backend is a test double, not the external full engine.";
end
payload = struct( ...
    "dataset", dataset, ...
    "warnings", warnings, ...
    "backend_manifest", struct( ...
        "adapter", "Full6GPCMAdapter", ...
        "adapter_version", "v3.0-step6.1", ...
        "test_only", logical(config.engine.test_only), ...
        "core_unchanged", probe.report.core_unchanged, ...
        "tree_file_count", probe.report.tree_file_count, ...
        "tree_total_bytes", probe.report.tree_total_bytes, ...
        "tree_sha256_before", probe.report.tree_sha256_before, ...
        "tree_sha256_after", probe.report.tree_sha256_after, ...
        "entrypoint", probe.report.entrypoint, ...
        "raw_shapes", probe.report.raw_shapes, ...
        "limitations", ...
            "Current external entry point fixes scenario, arrays, trajectory, and Nt; only exposed model parameters are configurable."));
end
