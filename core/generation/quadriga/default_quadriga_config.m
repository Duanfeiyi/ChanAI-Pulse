function config = default_quadriga_config()
%DEFAULT_QUADRIGA_CONFIG Return default QuaDRiGa generation configuration.
%   config = default_quadriga_config() returns a struct with all parameters
%   needed for quadriga_adapter(). Users can override any field.

config = struct();

% --- Core simulation parameters ---
config.scenario = "3GPP_38.901_UMi";
config.carrier_freq_ghz = 3.5;
config.bandwidth_mhz = 100;
config.num_subcarriers = 64;
config.snapshots = 100;
config.snapshot_interval_s = 0.01;
config.random_seed = 42;

% --- Mobility ---
config.ue_speed_mps = 3;
config.bs_height_m = [];
config.ue_height_m = [];
config.ue_trajectory = [];
config.trajectory_type = '';  % 'linear','random','circular','zigzag' or '' for random

% --- Antenna (SISO for v2.0) ---
config.bs_antenna_elements = 1;
config.ue_antenna_elements = 1;

% --- QuaDRiGa version requirement ---
config.quadriga_version = "2.6";

% --- Output control ---
config.output_format = "complex_h";
config.save_path_coefficients = true;
config.save_trajectory = true;
end
