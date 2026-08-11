function config = default_v31_2_corpus_config()
%DEFAULT_V31_2_CORPUS_CONFIG Public synthetic-corpus defaults for v3.1-2.
%   The generated corpus is a local experiment asset. It is deliberately
%   separate from the tracked small fixtures and never changes the frozen
%   v3.0 predictor-data contracts.

base = default_step11abc_config();
config = base;
config.schema_version = "v3.1-2-corpus-config.1";
config.corpus_id = "chanaipulse-v3.1-corpus.1";
config.description = "Public Full 6GPCM-derived route-group corpus for reproducible v3.1 experiments";
config.route.group_count = 120;
config.route.samples_per_group = 120;
config.route.seed = 31120;
config.route.speed_mps_cycle = [0.5, 1.0, 3.0, 8.0, 0.5, 1.0, ...
    3.0, 8.0, 1.0, 3.0, 5.0, 12.0];
config.route.tx_count_cycle = [1, 1, 2, 2, 1, 2, 1, 2, 1, 2, 2, 2];
config.route.rx_count_cycle = [1, 2, 2, 4, 2, 4, 1, 2, 2, 4, 4, 4];
config.route.route_duration_s = 24;
config.route.label_source = "generator_truth";
config.data.split_fractions = [0.70, 0.15, 0.15];
config.data.split_group_counts = [84, 18, 18];
config.asset_policy = struct( ...
    "storage", "git_external_local_asset_root", ...
    "allow_private_measurements", false, ...
    "allow_large_artifacts_in_git", false, ...
    "tracked_content", ["code", "config", "manifest_schema", "small_fixture", "summary"]);
end
