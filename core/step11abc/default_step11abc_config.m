function config = default_step11abc_config()
%DEFAULT_STEP11ABC_CONFIG Frozen defaults for Step 11A--11C.
%   The P2/P4/P6/P8 bundles are prefixes of PARAMETER_NAMES. Keeping one
%   order prevents a model trained for P4 from silently swapping columns.

parameterNames = ["DS_mu", "KF_mu", "DS_sigma", "KF_sigma", ...
    "r_DS", "LNS_ksi", "num_clusters", "num_rays"];
% Rows are DS_mu, KF_mu, DS_sigma, KF_sigma, r_DS, LNS_ksi,
% num_clusters, and num_rays, respectively.
bounds = [ ...
    -9.0, -5.0; ...
    -20, 30; ...
    0.01, 2.0; ...
    0.0, 12.0; ...
    1.0, 6.0; ...
    0.1, 10.0; ...
    4, 30; ...
    4, 50];

config = struct();
config.schema_version = "v3.0-step11abc-config.1";
config.parameter_names = parameterNames;
config.parameter_bounds = bounds;
config.parameter_bundles = struct();
config.parameter_bundles.P2 = parameterNames(1:2);
config.parameter_bundles.P4 = parameterNames(1:4);
config.parameter_bundles.P6 = parameterNames(1:6);
config.parameter_bundles.P8 = parameterNames(1:8);
config.route = struct();
config.route.group_count = 40;
config.route.samples_per_group = 120;
config.route.seed = 11011;
config.route.route_duration_s = 24;
config.route.route_speed_mps = 1;
config.route.scenario_cycle = [ ...
    "sub-6 GHz_UMa_LoS", "sub-6 GHz_UMa_NLoS", ...
    "sub-6 GHz_UMi_LoS", "sub-6 GHz_UMi_NLoS", ...
    "sub-6 GHz_RMa_LoS", "sub-6 GHz_RMa_NLoS", ...
    "sub-6 GHz_Indoor_LoS", "sub-6 GHz_Indoor_NLoS", ...
    "cmWave_UMa_LoS", "cmWave_UMa_NLoS", ...
    "mmWave_UMi_LoS", "mmWave_UMi_NLoS"];
config.route.carrier_frequency_hz = [ ...
    3.5e9, 3.5e9, 3.5e9, 3.5e9, 3.5e9, 3.5e9, 3.5e9, 3.5e9, ...
    16e9, 16e9, 28e9, 28e9];
config.route.label_source = "generator_truth";
config.route.profile_source = "full_6gpcm_public_api";
config.data = struct();
config.data.context_length = 16;
config.data.target_length = 4;
config.data.split_fractions = [0.75, 0.125, 0.125];
config.data.split_group_counts = [30, 5, 5];
config.data.tasks = ["interpolation", "extrapolation"];
config.selection = struct();
config.selection.seed_count = 3;
config.selection.minimum_relative_nrmse_improvement = 0.10;
config.selection.minimum_validation_group_win_rate = 0.60;
config.selection.maximum_group_to_baseline_ratio = 2.0;
config.selection.smaller_bundle_end_to_end_tolerance = 0.05;
config.external_data = struct();
config.external_data.policy = "local_validation_only";
config.external_data.download_limit_per_item_gb = 2;
config.external_data.download_limit_total_gb = 5;
end
