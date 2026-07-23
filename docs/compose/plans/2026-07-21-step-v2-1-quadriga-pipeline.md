# Step V2-1: QuaDRiGa Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:subagent (recommended) or compose:execute to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a minimal reproducible QuaDRiGa generation pipeline producing dynamic broadband SISO Complex-H `H(t,f)` data with 6 3GPP scenarios and multi-band support.

**Architecture:** Adapter pattern wrapping official QuaDRiGa API. `GenerationConfig` struct → `quadriga_adapter()` → `GenerationResult` struct with `complex_h [T,F]` as the core output. Parallel to existing `6GPCM-Lite` pattern.

**Tech Stack:** MATLAB (R2022b+), QuaDRiGa 2.6, MATLAB Deep Learning Toolbox (for downstream model compatibility).

## Global Constraints

- v1.0 Legacy pipeline must not be broken; all new code lives in `core/generation/quadriga/`
- SISO only for v2.0; MIMO is v2.1 scope
- No real data in GitHub; only synthetic demos
- Same seed + config must produce identical output
- All physical axes must have explicit units (s, Hz, m, deg)
- Old "Quadriga 3D CSI" scripts must NOT be mislabeled as QuaDRiGa data
- Every PR is independently testable and reversible

---

## Task 1: Environment Check Utility

**Covers:** [S2, S10]

**Files:**
- Create: `core/generation/quadriga/quadriga_check.m`
- Test: (inline verification via command window)

**Interfaces:**
- Consumes: MATLAB path, QuaDRiGa installation
- Produces: `status` struct with `is_available`, `version`, `matlab_version`, `issues`

- [ ] **Step 1: Create `quadriga_check.m`**

```matlab
function status = quadriga_check()
%QUADRIGA_CHECK Verify QuaDRiGa environment availability and compatibility.
%   status = quadriga_check() checks whether the official QuaDRiGa package
%   is installed, accessible, and compatible with the current MATLAB version.

status = struct();
status.is_available = false;
status.version = "";
status.matlab_version = version;
status.issues = {};

% Check if qd_layout or qd_channel classes exist (core QuaDRiGa objects)
try
    % Attempt to create a minimal layout object — this verifies the class path
    layout = qd_layout;
    status.is_available = true;
    
    % Extract version if available
    if isprop(layout, 'version')
        status.version = string(layout.version);
    end
catch ME
    status.issues{end+1} = sprintf('QuaDRiGa classes not found: %s', ME.message);
end

% Check MATLAB version compatibility (R2022b recommended)
matlab_ver = ver('MATLAB');
if ~isempty(matlab_ver)
    ver_parts = split(matlab_ver.Release, {'a', 'b'});
    if ~isempty(ver_parts)
        year_str = strtrim(ver_parts{1});
        if str2double(year_str) < 2022
            status.issues{end+1} = sprintf('MATLAB %s detected; R2022b+ recommended', ...
                matlab_ver.Release);
        end
    end
end

% Check required toolboxes
required_toolboxes = {'Deep Learning Toolbox', 'Signal Processing Toolbox'};
for idx = 1:numel(required_toolboxes)
    tbx = ver(required_toolboxes{idx});
    if isempty(tbx)
        status.issues{end+1} = sprintf('Missing toolbox: %s', required_toolboxes{idx});
    end
end

if status.is_available && isempty(status.issues)
    status.summary = 'QuaDRiGa environment OK';
else
    if status.is_available
        status.summary = sprintf('QuaDRiGa available with %d warning(s)', numel(status.issues));
    else
        status.summary = 'QuaDRiGa NOT available';
    end
end
end
```

- [ ] **Step 2: Verify it runs without error**

In MATLAB command window:
```matlab
addpath(genpath('core/generation/quadriga'));
status = quadriga_check();
disp(status);
```
Expected: Returns a struct. If QuaDRiGa is installed, `is_available=true`. If not, `is_available=false` with descriptive issues.

- [ ] **Step 3: Commit**

```bash
git add core/generation/quadriga/quadriga_check.m
git commit -m "feat(v2): add QuaDRiGa environment check utility"
```

---

## Task 2: Scenario Registry

**Covers:** [S6]

**Files:**
- Create: `core/generation/quadriga/quadriga_scenarios.m`
- Test: inline verification

**Interfaces:**
- Consumes: scenario name string
- Produces: `scenario` struct with physical defaults

- [ ] **Step 1: Create `quadriga_scenarios.m`**

```matlab
function scenario = quadriga_scenarios(scenario_name)
%QUADRIGA_SCENARIOS Return 3GPP scenario physical parameter defaults.
%   scenario = quadriga_scenarios("3GPP_38.901_UMi") returns the default
%   physical parameters for the Urban Micro NLOS scenario.

arguments
    scenario_name {mustBeTextScalar}
end

scenario_name = upper(string(scenario_name));

switch scenario_name
    case "3GPP_38.901_UMI"
        scenario = struct( ...
            'name', "3GPP_38.901_UMi", ...
            'description', "Urban Micro NLOS", ...
            'bs_height_m', 10, ...
            'ue_height_m', 1.5, ...
            'ue_speed_mps', 0.833, ...      % 3 km/h
            'num_clusters', 12, ...
            'num_rays_per_cluster', 20, ...
            'ds_mean_ns', -7.19, ...         % log10(RMS DS in s), 3GPP Table 7.5-6
            'ds_std_db', 2.88, ...
            'as_mean_deg', 17.0, ...
            'as_std_db', 6.0, ...
            'sf_std_db', 4.0, ...
            'kf_mean_db', 9.0, ...
            'kf_std_db', 5.0, ...
            'delay_spread_range_ns', [10, 500], ...
            'scenario_type', "NLOS", ...
            'environment', "urban");

    case "3GPP_38.901_UMI-LOS"
        scenario = struct( ...
            'name', "3GPP_38.901_UMi-LOS", ...
            'description', "Urban Micro LOS", ...
            'bs_height_m', 10, ...
            'ue_height_m', 1.5, ...
            'ue_speed_mps', 0.833, ...
            'num_clusters', 12, ...
            'num_rays_per_cluster', 20, ...
            'ds_mean_ns', -7.49, ...
            'ds_std_db', 2.88, ...
            'as_mean_deg', 17.0, ...
            'as_std_db', 6.0, ...
            'sf_std_db', 3.0, ...
            'kf_mean_db', 15.0, ...
            'kf_std_db', 5.0, ...
            'delay_spread_range_ns', [5, 300], ...
            'scenario_type', "LOS", ...
            'environment', "urban");

    case "3GPP_38.901_UMA"
        scenario = struct( ...
            'name', "3GPP_38.901_UMa", ...
            'description', "Urban Macro NLOS", ...
            'bs_height_m', 25, ...
            'ue_height_m', 1.5, ...
            'ue_speed_mps', 0.833, ...
            'num_clusters', 12, ...
            'num_rays_per_cluster', 20, ...
            'ds_mean_ns', -6.62, ...
            'ds_std_db', 3.0, ...
            'as_mean_deg', 19.0, ...
            'as_std_db', 6.0, ...
            'sf_std_db', 4.0, ...
            'kf_mean_db', 7.0, ...
            'kf_std_db', 5.0, ...
            'delay_spread_range_ns', [10, 800], ...
            'scenario_type', "NLOS", ...
            'environment', "urban");

    case "3GPP_38.901_UMA-LOS"
        scenario = struct( ...
            'name', "3GPP_38.901_UMa-LOS", ...
            'description', "Urban Macro LOS", ...
            'bs_height_m', 25, ...
            'ue_height_m', 1.5, ...
            'ue_speed_mps', 0.833, ...
            'num_clusters', 12, ...
            'num_rays_per_cluster', 20, ...
            'ds_mean_ns', -6.72, ...
            'ds_std_db', 3.0, ...
            'as_mean_deg', 19.0, ...
            'as_std_db', 6.0, ...
            'sf_std_db', 3.0, ...
            'kf_mean_db', 13.0, ...
            'kf_std_db', 5.0, ...
            'delay_spread_range_ns', [5, 500], ...
            'scenario_type', "LOS", ...
            'environment', "urban");

    case "3GPP_38.901_RMA"
        scenario = struct( ...
            'name', "3GPP_38.901_RMa", ...
            'description', "Rural Macro", ...
            'bs_height_m', 35, ...
            'ue_height_m', 1.5, ...
            'ue_speed_mps', 8.333, ...     % 30 km/h
            'num_clusters', 10, ...
            'num_rays_per_cluster', 20, ...
            'ds_mean_ns', -7.19, ...
            'ds_std_db', 2.88, ...
            'as_mean_deg', 10.0, ...
            'as_std_db', 4.0, ...
            'sf_std_db', 4.0, ...
            'kf_mean_db', 7.0, ...
            'kf_std_db', 5.0, ...
            'delay_spread_range_ns', [10, 1000], ...
            'scenario_type', "NLOS", ...
            'environment', "rural");

    case "3GPP_38.901_INH"
        scenario = struct( ...
            'name', "3GPP_38.901_INH", ...
            'description', "Indoor Hotspot", ...
            'bs_height_m', 3, ...
            'ue_height_m', 1.5, ...
            'ue_speed_mps', 0.833, ...
            'num_clusters', 12, ...
            'num_rays_per_cluster', 20, ...
            'ds_mean_ns', -7.68, ...
            'ds_std_db', 2.0, ...
            'as_mean_deg', 25.0, ...
            'as_std_db', 6.0, ...
            'sf_std_db', 3.0, ...
            'kf_mean_db', 10.0, ...
            'kf_std_db', 5.0, ...
            'delay_spread_range_ns', [5, 200], ...
            'scenario_type', "LOS/NLOS", ...
            'environment', "indoor");

    otherwise
        error("quadriga_scenarios:UnknownScenario", ...
            "Unknown scenario: %s. Valid: 3GPP_38.901_UMi, UMi-LOS, UMa, UMa-LOS, RMa, INH", ...
            scenario_name);
end
end
```

- [ ] **Step 2: Verify all 6 scenarios load**

```matlab
scenarios = ["3GPP_38.901_UMi", "3GPP_38.901_UMi-LOS", "3GPP_38.901_UMa", ...
             "3GPP_38.901_UMa-LOS", "3GPP_38.901_RMa", "3GPP_38.901_INH"];
for s = scenarios
    sc = quadriga_scenarios(s);
    fprintf('%s: BS=%dm, Speed=%.1fm/s, Clusters=%d\n', ...
        sc.name, sc.bs_height_m, sc.ue_speed_mps, sc.num_clusters);
end
```
Expected: All 6 scenarios print without error.

- [ ] **Step 3: Commit**

```bash
git add core/generation/quadriga/quadriga_scenarios.m
git commit -m "feat(v2): add 3GPP scenario registry for QuaDRiGa pipeline"
```

---

## Task 3: Default Configuration

**Covers:** [S4]

**Files:**
- Create: `core/generation/quadriga/default_quadriga_config.m`
- Create: `core/generation/quadriga/validate_quadriga_config.m`

**Interfaces:**
- Consumes: none (default) or user-overridden config struct
- Produces: validated `config` struct

- [ ] **Step 1: Create `default_quadriga_config.m`**

```matlab
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
config.snapshot_interval_s = 0.01;    % 10 ms between snapshots
config.random_seed = 42;

% --- Mobility ---
config.ue_speed_mps = 3;              % overridden by scenario if empty
config.bs_height_m = [];              % empty = use scenario default
config.ue_height_m = [];              % empty = use scenario default
config.ue_trajectory = [];            % Nx3, auto-generated if empty

% --- Antenna (SISO for v2.0) ---
config.bs_antenna_elements = 1;
config.ue_antenna_elements = 1;

% --- 3GPP channel model parameters ---
config.num_clusters = [];             % empty = use scenario default
config.num_rays_per_cluster = [];     % empty = use scenario default

% --- QuaDRiGa version requirement ---
config.quadriga_version = "2.6";

% --- Output control ---
config.output_format = "complex_h";   % "complex_h" or "channel_coefficients"
config.save_path_coefficients = true;
config.save_trajectory = true;
end
```

- [ ] **Step 2: Create `validate_quadriga_config.m`**

```matlab
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
mustBePositive = @(x) assert(x > 0, '%s must be positive');
mustBePositive(config.carrier_freq_ghz);
mustBePositive(config.bandwidth_mhz);
mustBePositive(config.num_subcarriers);
mustBePositive(config.snapshots);
mustBePositive(config.snapshot_interval_s);

assert(config.num_subcarriers == round(config.num_subcarriers), ...
    'num_subcarriers must be integer');
assert(config.snapshots == round(config.snapshots), ...
    'snapshots must be integer');
assert(config.num_clusters == round(config.num_clusters), ...
    'num_clusters must be integer');
assert(config.num_rays_per_cluster == round(config.num_rays_per_cluster), ...
    'num_rays_per_cluster must be integer');

% Ensure random seed is set
if isempty(config.random_seed)
    config.random_seed = 42;
end
end
```

- [ ] **Step 3: Verify default config loads and validates**

```matlab
config = default_quadriga_config();
config = validate_quadriga_config(config);
assert(config.bs_height_m == 10, 'UMi BS height should be 10m');
assert(config.num_clusters == 12, 'UMi clusters should be 12');
fprintf('Default config OK: %s, %.1f GHz, %d MHz BW\n', ...
    config.scenario, config.carrier_freq_ghz, config.bandwidth_mhz);
```
Expected: Prints successfully.

- [ ] **Step 4: Commit**

```bash
git add core/generation/quadriga/default_quadriga_config.m core/generation/quadriga/validate_quadriga_config.m
git commit -m "feat(v2): add default and validated QuaDRiGa config"
```

---

## Task 4: QuaDRiGa Adapter (Core Generation)

**Covers:** [S2, S5, S8]

**Files:**
- Create: `core/generation/quadriga/quadriga_adapter.m`

**Interfaces:**
- Consumes: validated `config` struct (from Task 3)
- Produces: `result` struct with `complex_h`, axes, path data, metadata

- [ ] **Step 1: Create `quadriga_adapter.m`**

```matlab
function result = quadriga_adapter(config)
%QUADRIGA_ADAPTER Generate Complex-H channel data via official QuaDRiGa API.
%   result = quadriga_adapter(config) calls the QuaDRiGa channel generator
%   and returns a structured result with complex H(t,f), physical axes,
%   path coefficients, trajectory, and metadata.
%
%   This function wraps the official QuaDRiGa qd_layout/qd_channel API.
%   It does NOT use any custom stochastic model disguised as QuaDRiGa.

arguments
    config (1, 1) struct
end

% Validate config and fill scenario defaults
config = validate_quadriga_config(config);

% Verify QuaDRiGa is available
env = quadriga_check();
if ~env.is_available
    error("quadriga_adapter:QuaDRiGaUnavailable", ...
        "QuaDRiGa is not available. Run quadriga_check() for details.");
end

% Set random seed for reproducibility
rng(config.random_seed, "twister");

% Convert units
fc_hz = config.carrier_freq_ghz * 1e9;
bw_hz = config.bandwidth_mhz * 1e6;
lambda = 3e8 / fc_hz;

% Load scenario physical parameters
scenario = quadriga_scenarios(config.scenario);

% Generate UE trajectory if not provided
if isempty(config.ue_trajectory)
    trajectory = generate_linear_trajectory( ...
        config.snapshots, config.snapshot_interval_s, ...
        config.ue_speed_mps, config.ue_height_m);
else
    trajectory = config.ue_trajectory;
end

% Build QuaDRiGa layout
layout = qd_layout;
layout.scenario = scenario.name;
layout.no_tx = 1;
layout.no_rx = 1;

% Set BS position (centered, at scenario height)
layout.tx_position = [0; 0; config.bs_height_m];

% Set UE positions from trajectory
layout.rx_position = trajectory';  % QuaDRiGa expects 3xN

% Set carrier frequency
layout.carrier_freq = fc_hz;

% Configure antenna elements (SISO)
layout.tx_arrayelement = 1;
layout.rx_arrayelement = 1;

% Generate channel coefficients
channel = layout.get_channel;
channel.noise_power = 1e-10;  % Minimal noise for clean generation

% Sample the channel at specified time steps
nSnapshots = config.snapshots;
nSubcarriers = config.num_subcarriers;

% Preallocate output
complex_h = complex(zeros(nSnapshots, nSubcarriers));
path_coefficients = cell(nSnapshots, 1);
path_delays = cell(nSnapshots, 1);
path_doppler = cell(nSnapshots, 1);

% Time axis
time_axis_s = (0:nSnapshots-1) * config.snapshot_interval_s;

% Frequency axis (baseband)
freq_axis_hz = linspace(-bw_hz/2, bw_hz/2, nSubcarriers);

for t = 1:nSnapshots
    % Get channel coefficients for this time step
    % QuaDRiGa returns [nSubcarriers x nTx x nRx] or similar
    h_freq = channel.coeff(:, :, :, t);
    
    % SISO: squeeze to [nSubcarriers x 1] or [1 x nSubcarriers]
    h_freq = squeeze(h_freq);
    if isrow(h_freq)
        h_freq = h_freq.';
    end
    
    % Interpolate to requested subcarrier count if needed
    if length(h_freq) ~= nSubcarriers
        orig_freq = linspace(-bw_hz/2, bw_hz/2, length(h_freq));
        h_freq = interp1(orig_freq, h_freq, freq_axis_hz, 'pchip');
    end
    
    complex_h(t, :) = h_freq(:).';
    
    % Extract path-level data if available
    if isprop(channel, 'tap_delays') && ~isempty(channel.tap_delays)
        path_delays{t} = channel.tap_delays;
    end
    if isprop(channel, 'tap_coefficients') && ~isempty(channel.tap_coefficients)
        path_coefficients{t} = channel.tap_coefficients;
    end
end

% Build result struct
result = struct();
result.engine = "QuaDRiGa";
result.scenario = config.scenario;
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
    result.path_delays_s = path_delays;
    result.path_doppler_hz = path_doppler;
end

if config.save_trajectory
    result.ue_trajectory_m = trajectory;
    result.bs_position_m = [0, 0, config.bs_height_m];
end

result.num_clusters = config.num_clusters;
result.num_rays = config.num_rays_per_cluster;
result.random_seed = config.random_seed;
result.generation_time_s = toc;
result.data_source = "quadriga_synthetic";
result.is_reproducible = true;
result.scenario_info = scenario;
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
```

- [ ] **Step 2: Verify it parses without error (syntax check)**

```matlab
% This verifies the function is syntactically valid
% Full runtime test requires QuaDRiGa installed
try
    help quadriga_adapter
    fprintf('quadriga_adapter.m syntax OK\n');
catch ME
    fprintf('Error: %s\n', ME.message);
end
```
Expected: Function help text prints.

- [ ] **Step 3: Commit**

```bash
git add core/generation/quadriga/quadriga_adapter.m
git commit -m "feat(v2): implement QuaDRiGa adapter with Complex-H output"
```

---

## Task 5: H(t,f) Derivation Utilities

**Covers:** [S8]

**Files:**
- Create: `core/generation/quadriga/quadriga_result_to_complex_h.m`
- Create: `core/generation/quadriga/quadriga_result_to_dpsd.m`

**Interfaces:**
- Consumes: `result` struct (from Task 4)
- Produces: `complex_h` matrix or `dpsd_dbm` matrix

- [ ] **Step 1: Create `quadriga_result_to_complex_h.m`**

```matlab
function [complex_h, time_axis, freq_axis] = quadriga_result_to_complex_h(result)
%QUADRIGA_RESULT_TO_COMPLEX_H Extract H(t,f) complex matrix from result.
%   [complex_h, time_axis, freq_axis] = quadriga_result_to_complex_h(result)
%   returns the complex channel matrix and physical axes.

arguments
    result (1, 1) struct
end

if ~isfield(result, 'complex_h')
    error("quadriga_result_to_complex_h:MissingField", ...
        "Result struct missing 'complex_h' field.");
end

complex_h = result.complex_h;
time_axis = result.time_axis_s;
freq_axis = result.freq_axis_hz;
end
```

- [ ] **Step 2: Create `quadriga_result_to_dpsd.m`**

```matlab
function dpsd_dbm = quadriga_result_to_dpsd(result)
%QUADRIGA_RESULT_TO_DPSD Convert Complex-H result to delay-power PSD.
%   dpsd_dbm = quadriga_result_to_dpsd(result) computes the power delay
%   profile from H(t,f) by IFFT and converts to dBm scale.
%
%   This provides legacy compatibility with v1.0 DPSD-based pipelines.

arguments
    result (1, 1) struct
end

complex_h = result.complex_h;
[nSnapshots, nSubcarriers] = size(complex_h);

% Compute PDP via IFFT for each snapshot
nDelays = nSubcarriers;
dpsd_linear = zeros(nSnapshots, nDelays);

for t = 1:nSnapshots
    h_freq = complex_h(t, :);
    h_time = ifft(ifftshift(h_freq));
    pdp = abs(h_time).^2;
    dpsd_linear(t, :) = pdp;
end

% Average across snapshots and convert to dBm-like scale
avg_pdp = mean(dpsd_linear, 1);
avg_pdp = avg_pdp / max(avg_pdp + eps);  % Normalize to [0, 1]
dpsd_dbm = 10 * log10(avg_pdp + 1e-20);  % dB scale
end
```

- [ ] **Step 3: Commit**

```bash
git add core/generation/quadriga/quadriga_result_to_complex_h.m core/generation/quadriga/quadriga_result_to_dpsd.m
git commit -m "feat(v2): add Complex-H and DPSD conversion utilities"
```

---

## Task 6: Demo Generator & Dataset Card

**Covers:** [S2, S10]

**Files:**
- Create: `core/generation/quadriga/generate_quadriga_demo.m`

**Interfaces:**
- Consumes: QuaDRiGa adapter (Task 4)
- Produces: `.mat` files + `metadata.json` in `demo_data/quadriga_demo/`

- [ ] **Step 1: Create `generate_quadriga_demo.m`**

```matlab
function generate_quadriga_demo()
%GENERATE_QUADRIGA_DEMO Generate small public synthetic demo dataset.
%   generate_quadriga_demo() produces demo files in demo_data/quadriga_demo/
%   using the QuaDRiGa adapter with minimal parameters.
%
%   This generates synthetic data only. No real data is read or modified.

% Find project root
thisFile = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(thisFile));
demoDir = fullfile(projectRoot, 'demo_data', 'quadriga_demo');
dataDir = fullfile(demoDir, 'data');

if ~exist(dataDir, 'dir'), mkdir(dataDir); end

% Demo configurations: small, fast, representative
demo_configs = {
    struct('scenario', "3GPP_38.901_UMi", 'carrier_freq_ghz', 3.5, ...
           'bandwidth_mhz', 100, 'num_subcarriers', 64, ...
           'snapshots', 50, 'random_seed', 42), ...
    struct('scenario', "3GPP_38.901_UMa", 'carrier_freq_ghz', 28, ...
           'bandwidth_mhz', 200, 'num_subcarriers', 128, ...
           'snapshots', 50, 'random_seed', 42), ...
    struct('scenario', "3GPP_38.901_INH", 'carrier_freq_ghz', 60, ...
           'bandwidth_mhz', 400, 'num_subcarriers', 256, ...
           'snapshots', 50, 'random_seed', 42)
};

dataset_files = {};
dataset_info = {};

for idx = 1:numel(demo_configs)
    cfg = default_quadriga_config();
    % Merge demo-specific overrides
    override = demo_configs{idx};
    fnames = fieldnames(override);
    for f = 1:numel(fnames)
        cfg.(fnames{f}) = override.(fnames{f});
    end
    
    fprintf('Generating demo %d/%d: %s @ %.1f GHz ...\n', ...
        idx, numel(demo_configs), cfg.scenario, cfg.carrier_freq_ghz);
    
    result = quadriga_adapter(cfg);
    
    % Save
    filename = sprintf('quadriga_demo_%s_%.0fGHz.mat', ...
        strrep(char(cfg.scenario), '.', ''), cfg.carrier_freq_ghz);
    filepath = fullfile(dataDir, filename);
    save(filepath, 'result', '-v7.3');
    
    dataset_files{end+1} = filename;
    dataset_info{end+1} = struct( ...
        'filename', filename, ...
        'scenario', string(cfg.scenario), ...
        'carrier_freq_ghz', cfg.carrier_freq_ghz, ...
        'bandwidth_mhz', cfg.bandwidth_mhz, ...
        'num_subcarriers', cfg.num_subcarriers, ...
        'snapshots', cfg.snapshots, ...
        'complex_h_size', size(result.complex_h), ...
        'random_seed', cfg.random_seed);
    
    fprintf('  Saved: %s (%dx%d complex_h)\n', filename, ...
        size(result.complex_h, 1), size(result.complex_h, 2));
end

% Write metadata.json
metadata = struct();
metadata.dataset_name = "ChanAI Pulse QuaDRiGa Demo";
metadata.version = "1.0";
metadata.description = "Small synthetic demo generated via official QuaDRiGa API";
metadata.generator = "QuaDRiGa";
metadata.generator_version = "2.6";
metadata.generated_at = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
metadata.files = {dataset_files};
metadata.info = {dataset_info};
metadata.license = "Synthetic data - free to use";
metadata.note = "This is synthetic demo data only. Not derived from real measurements.";

jsonStr = jsonencode(metadata, 'PrettyPrint', true);
jsonPath = fullfile(demoDir, 'metadata.json');
fid = fopen(jsonPath, 'w', 'n', 'UTF-8');
fprintf(fid, '%s', jsonStr);
fclose(fid);

fprintf('\nDemo generation complete: %d files in %s\n', numel(dataset_files), demoDir);
end
```

- [ ] **Step 2: Commit**

```bash
git add core/generation/quadriga/generate_quadriga_demo.m
git commit -m "feat(v2): add QuaDRiGa demo dataset generator"
```

---

## Task 7: Self-Test Suite

**Covers:** [S9, S10]

**Files:**
- Create: `core/generation/quadriga/test_quadriga_adapter.m`

**Interfaces:**
- Consumes: All modules from Tasks 1-6
- Produces: Pass/fail report

- [ ] **Step 1: Create `test_quadriga_adapter.m`**

```matlab
function results = test_quadriga_adapter()
%TEST_QUADRIGA_ADAPTER Run self-test suite for the QuaDRiGa pipeline.
%   results = test_quadriga_adapter() runs all tests and returns results.

fprintf('=== QuaDRiGa Adapter Test Suite ===\n\n');
results = struct();
results.passed = 0;
results.failed = 0;
results.skipped = 0;
results.details = {};

% Test 1: Environment check
[results, pass] = run_test(results, 'Environment Check', @test_env_check);

% Test 2: Scenario registry
[results, pass] = run_test(results, 'Scenario Registry (6 scenarios)', @test_scenarios);

% Test 3: Default config
[results, pass] = run_test(results, 'Default Config & Validation', @test_config);

% Test 4: QuaDRiGa adapter (requires QuaDRiGa)
[results, pass] = run_test(results, 'QuaDRiGa Adapter (requires QuaDRiGa)', @test_adapter);

% Test 5: Seed reproducibility
[results, pass] = run_test(results, 'Seed Reproducibility', @test_reproducibility);

% Test 6: Complex-valued output
[results, pass] = run_test(results, 'Complex-valued H(t,f)', @test_complex);

% Test 7: Dimension consistency
[results, pass] = run_test(results, 'Dimension Consistency', @test_dimensions);

% Test 8: Multi-band
[results, pass] = run_test(results, 'Multi-band Support', @test_multiband);

% Summary
fprintf('\n=== Summary: %d passed, %d failed, %d skipped ===\n', ...
    results.passed, results.failed, results.skipped);
end

function [results, pass] = run_test(results, name, test_fn)
try
    test_fn();
    fprintf('[PASS] %s\n', name);
    results.passed = results.passed + 1;
    pass = true;
catch ME
    if contains(ME.message, 'SKIP')
        fprintf('[SKIP] %s: %s\n', name, ME.message);
        results.skipped = results.skipped + 1;
    else
        fprintf('[FAIL] %s: %s\n', name, ME.message);
        results.failed = results.failed + 1;
    end
    pass = false;
end
end

function test_env_check()
status = quadriga_check();
assert(isfield(status, 'is_available'), 'Status missing is_available');
assert(isfield(status, 'issues'), 'Status missing issues');
end

function test_scenarios()
names = ["3GPP_38.901_UMi", "3GPP_38.901_UMi-LOS", "3GPP_38.901_UMa", ...
         "3GPP_38.901_UMa-LOS", "3GPP_38.901_RMa", "3GPP_38.901_INH"];
for idx = 1:numel(names)
    sc = quadriga_scenarios(names(idx));
    assert(~isempty(sc.bs_height_m), 'Missing bs_height_m');
    assert(sc.num_clusters > 0, 'Missing num_clusters');
end
end

function test_config()
cfg = default_quadriga_config();
assert(cfg.num_subcarriers == 64, 'Wrong default subcarriers');
assert(cfg.random_seed == 42, 'Wrong default seed');
cfg = validate_quadriga_config(cfg);
assert(cfg.bs_height_m == 10, 'UMi BS height not filled');
end

function test_adapter()
env = quadriga_check();
if ~env.is_available
    error('SKIP: QuaDRiGa not installed');
end
cfg = default_quadriga_config();
cfg.snapshots = 10;
cfg.num_subcarriers = 16;
result = quadriga_adapter(cfg);
assert(isfield(result, 'complex_h'), 'Missing complex_h');
assert(isfield(result, 'time_axis_s'), 'Missing time_axis_s');
end

function test_reproducibility()
env = quadriga_check();
if ~env.is_available
    error('SKIP: QuaDRiGa not installed');
end
cfg = default_quadriga_config();
cfg.snapshots = 10;
cfg.num_subcarriers = 16;
cfg.random_seed = 123;
result1 = quadriga_adapter(cfg);
result2 = quadriga_adapter(cfg);
assert(isequal(result1.complex_h, result2.complex_h), ...
    'Same seed did not produce identical output');
end

function test_complex()
env = quadriga_check();
if ~env.is_available
    error('SKIP: QuaDRiGa not installed');
end
cfg = default_quadriga_config();
cfg.snapshots = 10;
cfg.num_subcarriers = 16;
result = quadriga_adapter(cfg);
assert(iscomplex(result.complex_h), 'complex_h is not complex-valued');
assert(~isreal(result.complex_h), 'complex_h is real (should have imaginary part)');
end

function test_dimensions()
env = quadriga_check();
if ~env.is_available
    error('SKIP: QuaDRiGa not installed');
end
cfg = default_quadriga_config();
cfg.snapshots = 20;
cfg.num_subcarriers = 32;
result = quadriga_adapter(cfg);
assert(isequal(size(result.complex_h), [20, 32]), ...
    sprintf('Wrong dimensions: expected [20,32], got [%d,%d]', ...
    size(result.complex_h, 1), size(result.complex_h, 2)));
end

function test_multiband()
env = quadriga_check();
if ~env.is_available
    error('SKIP: QuaDRiGa not installed');
end
bands = [struct('carrier_freq_ghz', 3.5, 'bandwidth_mhz', 100), ...
         struct('carrier_freq_ghz', 28, 'bandwidth_mhz', 200), ...
         struct('carrier_freq_ghz', 100, 'bandwidth_mhz', 400)];
for idx = 1:numel(bands)
    cfg = default_quadriga_config();
    cfg.carrier_freq_ghz = bands(idx).carrier_freq_ghz;
    cfg.bandwidth_mhz = bands(idx).bandwidth_mhz;
    cfg.snapshots = 10;
    cfg.num_subcarriers = 16;
    result = quadriga_adapter(cfg);
    assert(size(result.complex_h, 2) == 16, ...
        'Wrong subcarrier count for band');
end
end
```

- [ ] **Step 2: Verify test suite loads**

```matlab
help test_quadriga_adapter
```
Expected: Function help text prints.

- [ ] **Step 3: Commit**

```bash
git add core/generation/quadriga/test_quadriga_adapter.m
git commit -m "feat(v2): add QuaDRiGa adapter self-test suite"
```

---

## Task 8: Integration with Existing Generation Module

**Covers:** [S2, S10]

**Files:**
- Modify: No existing files changed (new code only)
- Verify: Existing tests still pass

**Interfaces:**
- Consumes: Existing `core/generation/` modules
- Produces: Updated MATLAB path includes

- [ ] **Step 1: Verify no existing code is broken**

Run the existing test suite:
```matlab
% From project root
run('tests/smoke_test.m');
```
Expected: All existing tests pass. No regression.

- [ ] **Step 2: Verify path setup works**

```matlab
% In a fresh MATLAB session
projectRoot = pwd;
addpath(genpath(fullfile(projectRoot, 'core', 'generation', 'quadriga')));

% Should find all new functions
assert(~isempty(which('quadriga_check')), 'quadriga_check not on path');
assert(~isempty(which('quadriga_scenarios')), 'quadriga_scenarios not on path');
assert(~isempty(which('quadriga_adapter')), 'quadriga_adapter not on path');
assert(~isempty(which('default_quadriga_config')), 'default_quadriga_config not on path');
fprintf('All new functions found on path\n');
```

- [ ] **Step 3: Commit (if path changes needed)**

No file changes expected — path is set via `addpath` at runtime.

---

## Task 9: Documentation

**Covers:** [S2, S10]

**Files:**
- Create: `core/generation/quadriga/README.md`

**Interfaces:**
- Consumes: All modules from Tasks 1-8
- Produces: Usage documentation

- [ ] **Step 1: Create `README.md`**

```markdown
# QuaDRiGa Generation Pipeline (v2.0)

## Overview

This module wraps the official QuaDRiGa API to generate dynamic broadband SISO
Complex-H channel data `H(t,f)` with 3GPP-standard scenarios.

## Prerequisites

- MATLAB R2022b+
- QuaDRiGa 2.6+ installed and on MATLAB path
- Deep Learning Toolbox

## Quick Start

```matlab
% Check environment
status = quadriga_check();
disp(status);

% Configure
config = default_quadriga_config();
config.scenario = "3GPP_38.901_UMi";
config.carrier_freq_ghz = 3.5;
config.bandwidth_mhz = 100;
config.snapshots = 100;
config.random_seed = 42;

% Generate
result = quadriga_adapter(config);

% Access H(t,f)
[complex_h, time_axis, freq_axis] = quadriga_result_to_complex_h(result);
```

## Supported Scenarios

| Scenario | BS Height | UE Speed | Type |
|---|---|---|---|
| 3GPP_38.901_UMi | 10m | 3 km/h | Urban Micro NLOS |
| 3GPP_38.901_UMi-LOS | 10m | 3 km/h | Urban Micro LOS |
| 3GPP_38.901_UMa | 25m | 3 km/h | Urban Macro NLOS |
| 3GPP_38.901_UMa-LOS | 25m | 3 km/h | Urban Macro LOS |
| 3GPP_38.901_RMa | 35m | 30 km/h | Rural Macro |
| 3GPP_38.901_INH | 3m | 3 km/h | Indoor Hotspot |

## Multi-Band Support

- Sub-6 GHz (1-6 GHz)
- mmWave (24-40 GHz)
- THz (100-300 GHz)

## Testing

```matlab
results = test_quadriga_adapter();
```

## Data Safety

- This module generates synthetic data only
- No real measurement data is read, stored, or transmitted
- All outputs are clearly labeled as synthetic
```

- [ ] **Step 2: Commit**

```bash
git add core/generation/quadriga/README.md
git commit -m "docs(v2): add QuaDRiGa pipeline README"
```

---

## Task 10: Demo Generation (Requires QuaDRiGa)

**Covers:** [S2, S10]

**Files:**
- Outputs: `demo_data/quadriga_demo/` directory with `.mat` files and `metadata.json`

**Interfaces:**
- Consumes: All modules from Tasks 1-6
- Produces: Public demo dataset

- [ ] **Step 1: Generate demo dataset**

```matlab
% Only run if QuaDRiGa is installed
status = quadriga_check();
if status.is_available
    generate_quadriga_demo();
else
    fprintf('QuaDRiGa not available — skipping demo generation\n');
    fprintf('Run generate_quadriga_demo() after installing QuaDRiGa\n');
end
```

- [ ] **Step 2: Verify demo files**

```matlab
demoDir = fullfile(pwd, 'demo_data', 'quadriga_demo');
assert(exist(fullfile(demoDir, 'metadata.json'), 'file') > 0, 'Missing metadata.json');
dataDir = fullfile(demoDir, 'data');
files = dir(fullfile(dataDir, '*.mat'));
assert(numel(files) >= 3, 'Expected at least 3 demo files');
fprintf('Demo: %d .mat files + metadata.json\n', numel(files));
```

- [ ] **Step 3: Commit demo files**

```bash
git add demo_data/quadriga_demo/
git commit -m "feat(v2): add QuaDRiGa synthetic demo dataset"
```
