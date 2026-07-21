function config = validate_quadriga_config(config)
%VALIDATE_QUADRIGA_CONFIG Validate and fill defaults for QuaDRiGa config.
%   config = validate_quadriga_config(config) merges user config with
%   scenario defaults and validates all fields.

% Load scenario defaults for empty fields
scenario = quadriga_scenarios(config.scenario);

if isempty(config.bs_height_m), config.bs_height_m = scenario.bs_height_m; end
if isempty(config.ue_height_m), config.ue_height_m = scenario.ue_height_m; end
if isempty(config.num_clusters), config.num_clusters = scenario.num_clusters; end
if isempty(config.num_rays_per_cluster), config.num_rays_per_cluster = scenario.num_rays_per_cluster; end

% Validate numeric fields
assert(config.carrier_freq_ghz > 0, 'carrier_freq_ghz must be positive');
assert(config.bandwidth_mhz > 0, 'bandwidth_mhz must be positive');
assert(config.num_subcarriers > 0, 'num_subcarriers must be positive');
assert(config.snapshots > 0, 'snapshots must be positive');
assert(config.snapshot_interval_s > 0, 'snapshot_interval_s must be positive');

assert(config.num_subcarriers == round(config.num_subcarriers), ...
    'num_subcarriers must be integer');
assert(config.snapshots == round(config.snapshots), ...
    'snapshots must be integer');
assert(config.num_clusters == round(config.num_clusters), ...
    'num_clusters must be integer');
assert(config.num_rays_per_cluster == round(config.num_rays_per_cluster), ...
    'num_rays_per_cluster must be integer');

if isempty(config.random_seed)
    config.random_seed = 42;
end
end
