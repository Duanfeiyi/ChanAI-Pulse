function result = quadriga_adapter(config)
%QUADRIGA_ADAPTER Generate Complex-H channel data via official QuaDRiGa API.
%   result = quadriga_adapter(config) calls the QuaDRiGa channel generator
%   and returns a structured result with complex H(t,f), physical axes,
%   path coefficients, trajectory, and metadata.
%
%   This function wraps the official QuaDRiGa v2.8.1 API:
%     qd_layout → set_scenario → get_channels → qd_channel
%   It does NOT use any custom stochastic model disguised as QuaDRiGa.

arguments
    config (1, 1) struct
end

tic;

% Validate config and fill scenario defaults
config = validate_quadriga_config(config);

% Verify QuaDRiGa is available, try to add if not
env = quadriga_check();
if ~env.is_available
    % Try common installation paths
    quadriga_paths = { ...
        'D:\QuaDriGa_2023.12.13_v2.8.1-0\quadriga_src', ...
        'C:\QuaDriGa\quadriga_src', ...
        fullfile(getenv('USERPROFILE'), 'QuaDriGa', 'quadriga_src') ...
    };
    for p = 1:numel(quadriga_paths)
        if exist(quadriga_paths{p}, 'dir')
            addpath(genpath(quadriga_paths{p}));
            fprintf('Added QuaDRiGa to path: %s\n', quadriga_paths{p});
            break;
        end
    end
    env = quadriga_check();
    if ~env.is_available
        error("quadriga_adapter:QuaDRiGaUnavailable", ...
            "QuaDRiGa is not available. Run quadriga_check() for details.");
    end
end

% Set random seed for reproducibility
rng(config.random_seed, "twister");

% Convert units
fc_hz = config.carrier_freq_ghz * 1e9;
bw_hz = config.bandwidth_mhz * 1e6;

% Load scenario physical parameters
scenario_info = quadriga_scenarios(config.scenario);

% Generate UE trajectory
if isempty(config.ue_trajectory)
    % Randomly select trajectory type for variety
    traj_types = {'linear', 'random', 'circular', 'zigzag'};
    if isfield(config, 'trajectory_type') && ~isempty(config.trajectory_type)
        traj_type = config.trajectory_type;
    else
        traj_type = traj_types{randi(numel(traj_types))};
    end
    
    switch traj_type
        case 'linear'
            trajectory = generate_linear_trajectory(config.snapshots, config.snapshot_interval_s, ...
                config.ue_speed_mps, config.ue_height_m);
        case 'random'
            trajectory = generate_random_trajectory(config.snapshots, config.snapshot_interval_s, ...
                config.ue_speed_mps, config.ue_height_m);
        case 'circular'
            trajectory = generate_circular_trajectory(config.snapshots, config.snapshot_interval_s, ...
                config.ue_speed_mps, config.ue_height_m);
        case 'zigzag'
            trajectory = generate_zigzag_trajectory(config.snapshots, config.snapshot_interval_s, ...
                config.ue_speed_mps, config.ue_height_m);
    end
else
    trajectory = config.ue_trajectory;
end

% --- Build QuaDRiGa layout using the official API ---

% 1. Create layout and simulation parameters
simpar = qd_simulation_parameters;
simpar.center_frequency = fc_hz;
simpar.sample_density = 2.5;  % Default, good for single mobility

layout = qd_layout(simpar);

% 2. Configure transmitters (BS) and receivers (UE)
layout.no_tx = 1;
layout.no_rx = 1;

% 3. Set BS position: [x; y; z] in meters
layout.tx_position = [0; 0; config.bs_height_m];

% 4. Create UE track with trajectory positions
%    qd_track stores positions RELATIVE to initial_position
%    trajectory is Nx3 [x, y, z] in meters
track = qd_track([]);  % Empty constructor
track.name = 'Rx0001';

% Set initial position (first point of trajectory)
track.initial_position = trajectory(1, :)';  % [x0; y0; z0]

% Set relative positions (displacement from initial_position)
% positions must be 3×N matrix
relative_pos = (trajectory - trajectory(1, :))';  % 3×N
track.positions = relative_pos;

% 5. Set scenario via layout method (handles LOS/NLOS automatically)
%    Use layout.set_scenario() instead of track.scenario directly
%    because QuaDRiGa needs exact variants like 3GPP_38.901_UMi_NLOS

% 6. Assign track to layout
layout.rx_track = track;

% 7. Set scenario via layout method (handles LOS/NLOS automatically)
%    This assigns the correct LOS/NLOS variant based on distance
%    Map our scenario names to QuaDRiGa supported names
quadriga_scenario = map_to_quadriga_scenario(char(config.scenario));
layout.set_scenario(quadriga_scenario);

% 8. Set antenna arrays (omni for SISO)
layout.tx_array = qd_arrayant('omni');
layout.rx_array = qd_arrayant('omni');

% 9. Define link pairing (Tx1 ↔ Rx1)
layout.set_pairing;

% 10. Generate channel coefficients (time-domain CIR)
%    Returns qd_channel object array: [no_rx, no_tx]
h_channel = layout.get_channels;

% --- Extract time-domain CIR and convert to frequency-domain H(t,f) ---

nSnapshots = config.snapshots;
nSubcarriers = config.num_subcarriers;

% Time axis
time_axis_s = (0:nSnapshots-1) * config.snapshot_interval_s;

% Frequency axis (baseband, symmetric around 0)
freq_axis_hz = linspace(-bw_hz/2, bw_hz/2, nSubcarriers);

% Get the channel object (SISO: 1 link)
ch = h_channel(1, 1);  % [Rx=1, Tx=1]

% Extract CIR: coeff is [Rx-Ant, Tx-Ant, Path, Snapshot]
cir_coeff = ch.coeff;   % Complex path coefficients
cir_delay = ch.delay;   % Path delays in seconds

% Squeeze for SISO: [1, 1, nPaths, nSnapshots] → [nPaths, nSnapshots]
cir_coeff = squeeze(cir_coeff);
cir_delay = squeeze(cir_delay);

% Ensure dimensions are [nPaths, nSnapshots]
if size(cir_coeff, 1) == 1
    cir_coeff = cir_coeff.';
end
if size(cir_delay, 1) == 1
    cir_delay = cir_delay.';
end

[nPaths, nActualSnaps] = size(cir_coeff);

% Build frequency-domain H(t,f) via DFT of CIR
% H(t,f) = sum_l a_l(t) * exp(-j*2*pi*f*tau_l)
complex_h = complex(zeros(nSnapshots, nSubcarriers));

% Use the actual delay values from QuaDRiGa
for t = 1:min(nSnapshots, nActualSnaps)
    for p = 1:nPaths
        % Path coefficient and delay at this snapshot
        a_l = cir_coeff(p, t);   % Complex gain
        tau_l = cir_delay(p, t); % Delay in seconds
        
        % Contribution to H(t,f) for all subcarriers
        % H(f) += a_l * exp(-j*2*pi*f*tau_l)
        complex_h(t, :) = complex_h(t, :) + a_l * exp(-1i * 2 * pi * freq_axis_hz * tau_l);
    end
end

% Extract path-level data for metadata
path_coefficients = cell(nSnapshots, 1);
path_delays_s = cell(nSnapshots, 1);
for t = 1:min(nSnapshots, nActualSnaps)
    path_coefficients{t} = cir_coeff(:, t);
    path_delays_s{t} = cir_delay(:, t);
end

% Build result struct
result = struct();
result.engine = "QuaDRiGa";
result.scenario = char(config.scenario);
result.config = config;
result.complex_h = complex_h;
result.time_axis_s = time_axis_s;
result.freq_axis_hz = freq_axis_hz;
result.carrier_freq_hz = fc_hz;
result.bandwidth_hz = bw_hz;
result.num_subcarriers = nSubcarriers;
result.num_snapshots = nSnapshots;

if config.save_path_coefficients
    result.path_coefficients = path_coefficients;
    result.path_delays_s = path_delays_s;
    result.path_doppler_hz = cell(nSnapshots, 1);  % Not directly available
end

if config.save_trajectory
    result.ue_trajectory_m = trajectory;
    result.bs_position_m = [0, 0, config.bs_height_m];
end

result.num_clusters = config.num_clusters;
result.num_rays = config.num_rays_per_cluster;
result.config_source = struct( ...
    'requested_clusters', config.num_clusters, ...
    'requested_rays', config.num_rays_per_cluster, ...
    'actual_source', 'scenario_config_file', ...
    'note', 'Clusters/rays are determined by QuaDRiGa scenario config files, not directly configurable via API');
result.random_seed = config.random_seed;
result.generation_time_s = toc;
result.data_source = "quadriga_synthetic";
result.is_reproducible = true;
result.scenario_info = scenario_info;
end

function trajectory = generate_linear_trajectory(nSnapshots, dt, speed_mps, height_m)
%GENERATE_LINEAR_TRAJECTORY Create a simple linear UE trajectory.
%   trajectory = generate_linear_trajectory(nSnapshots, dt, speed, height)
%   returns Nx3 matrix of [x, y, z] positions in meters.

total_time = (nSnapshots - 1) * dt;
total_distance = speed_mps * total_time;

% Start 50m from BS, move in +x direction
x_start = 50;
x_end = x_start + total_distance;

x = linspace(x_start, x_end, nSnapshots);
y = zeros(1, nSnapshots);
z = height_m * ones(1, nSnapshots);

trajectory = [x(:), y(:), z(:)];
end

function trajectory = generate_random_trajectory(nSnapshots, dt, speed_mps, height_m)
%GENERATE_RANDOM_TRAJECTORY Create a random UE trajectory with varied motion.
%   trajectory = generate_random_trajectory(nSnapshots, dt, speed, height)
%   returns Nx3 matrix of [x, y, z] positions with random turns and speed variations.

total_time = (nSnapshots - 1) * dt;
total_distance = speed_mps * total_time;

% Random starting position (50-150m from BS in random direction)
start_angle = 2 * pi * rand;
start_dist = 50 + 100 * rand;
x_start = start_dist * cos(start_angle);
y_start = start_dist * sin(start_angle);

% Generate random walk with smooth turns
x = zeros(1, nSnapshots);
y = zeros(1, nSnapshots);
x(1) = x_start;
y(1) = y_start;

% Random heading changes
heading = start_angle;
step_size = total_distance / nSnapshots;

for i = 2:nSnapshots
    % Random heading change (smooth, bounded)
    heading = heading + 0.1 * randn;
    % Random speed variation (±20%)
    speed_var = step_size * (0.8 + 0.4 * rand);
    x(i) = x(i-1) + speed_var * cos(heading);
    y(i) = y(i-1) + speed_var * sin(heading);
end

z = height_m * ones(1, nSnapshots);
trajectory = [x(:), y(:), z(:)];
end

function trajectory = generate_circular_trajectory(nSnapshots, dt, speed_mps, height_m)
%GENERATE_CIRCULAR_TRAJECTORY Create a circular UE trajectory.
%   trajectory = generate_circular_trajectory(nSnapshots, dt, speed, height)
%   returns Nx3 matrix with UE moving in a circle around the BS.

total_time = (nSnapshots - 1) * dt;
total_distance = speed_mps * total_time;

% Random radius (30-100m)
radius = 30 + 70 * rand;

% Angular velocity
omega = total_distance / (radius * nSnapshots);

% Random starting angle
start_angle = 2 * pi * rand;

angles = start_angle + (0:nSnapshots-1) * omega;
x = radius * cos(angles);
y = radius * sin(angles);
z = height_m * ones(1, nSnapshots);

trajectory = [x(:), y(:), z(:)];
end

function trajectory = generate_zigzag_trajectory(nSnapshots, dt, speed_mps, height_m)
%GENERATE_ZIGZAG_TRAJECTORY Create a zigzag UE trajectory.
%   trajectory = generate_zigzag_trajectory(nSnapshots, dt, speed, height)
%   returns Nx3 matrix with UE moving in a zigzag pattern.

total_time = (nSnapshots - 1) * dt;
total_distance = speed_mps * total_time;

% Random start position
x_start = 50 + 50 * rand;
y_start = -30 + 60 * rand;

step_size = total_distance / nSnapshots;
zigzag_freq = 0.05 + 0.1 * rand;  % Random zigzag frequency
zigzag_amp = 20 + 30 * rand;      % Random zigzag amplitude

x = x_start + (0:nSnapshots-1) * step_size;
y = y_start + zigzag_amp * sin(2 * pi * zigzag_freq * (0:nSnapshots-1));
z = height_m * ones(1, nSnapshots);

trajectory = [x(:), y(:), z(:)];
end

function qs = map_to_quadriga_scenario(scenario_name)
%MAP_TO_QUADRIGA_SCENARIO Map our scenario names to QuaDRiGa supported names.
%   For scenarios with explicit LOS/NLOS variants, use the exact variant.
%   For generic scenarios, use the parent name (set_scenario handles LOS/NLOS).

switch upper(scenario_name)
    case "3GPP_38.901_UMI"
        qs = '3GPP_38.901_UMi_NLOS';  % Force explicit NLOS for generic UMi
    case "3GPP_38.901_UMI-LOS"
        qs = '3GPP_38.901_UMi_LOS';   % Force explicit LOS
    case "3GPP_38.901_UMA"
        qs = '3GPP_38.901_UMa_NLOS';  % Force explicit NLOS for generic UMa
    case "3GPP_38.901_UMA-LOS"
        qs = '3GPP_38.901_UMa_LOS';   % Force explicit LOS
    case "3GPP_38.901_RMA"
        qs = '3GPP_38.901_RMa_NLOS';  % Force explicit NLOS
    case "3GPP_38.901_RMA-LOS"
        qs = '3GPP_38.901_RMa_LOS';   % Force explicit LOS
    case "3GPP_38.901_INH"
        qs = '3GPP_38.901_Indoor_NLOS';
    otherwise
        qs = scenario_name;
end
end
