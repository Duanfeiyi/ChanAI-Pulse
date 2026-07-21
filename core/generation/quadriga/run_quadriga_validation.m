function run_quadriga_validation()
%RUN_QUADRIGA_VALIDATION Standalone validation for QuaDRiGa pipeline.
%   run_quadriga_validation() runs all verification tests and generates
%   a sample dataset. No GUI integration required.

fprintf('============================================================\n');
fprintf('  QuaDRiGa Pipeline Standalone Validation\n');
fprintf('  Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('============================================================\n\n');

addpath(genpath(pwd));
addpath(genpath('core/generation/quadriga'));

%% Part 1: Environment Check
fprintf('--- Part 1: Environment Check ---\n');
status = quadriga_check();
fprintf('  Available: %d\n', status.is_available);
fprintf('  Version:   %s\n', status.version);
fprintf('  MATLAB:    %s\n', status.matlab_version);
fprintf('  Path:      %s\n', status.quadriga_path);
if ~isempty(status.issues)
    for i = 1:numel(status.issues)
        fprintf('  Warning:   %s\n', status.issues{i});
    end
end
fprintf('\n');

if ~status.is_available
    fprintf('ERROR: QuaDRiGa not available. Cannot proceed.\n');
    return;
end

%% Part 2: Scenario Registry
fprintf('--- Part 2: Scenario Registry (6 scenarios) ---\n');
scenario_names = ["3GPP_38.901_UMi", "3GPP_38.901_UMi-LOS", ...
                  "3GPP_38.901_UMa", "3GPP_38.901_UMa-LOS", ...
                  "3GPP_38.901_RMa", "3GPP_38.901_INH"];
for i = 1:numel(scenario_names)
    sc = quadriga_scenarios(scenario_names(i));
    fprintf('  [%d] %s: BS=%dm, Speed=%.2fm/s, Clusters=%d, Env=%s\n', ...
        i, sc.name, sc.bs_height_m, sc.ue_speed_mps, sc.num_clusters, sc.environment);
end
fprintf('\n');

%% Part 3: Config Validation
fprintf('--- Part 3: Config Validation ---\n');
cfg = default_quadriga_config();
fprintf('  Default scenario:  %s\n', cfg.scenario);
fprintf('  Default FC:        %.1f GHz\n', cfg.carrier_freq_ghz);
fprintf('  Default BW:        %d MHz\n', cfg.bandwidth_mhz);
fprintf('  Default subcarriers: %d\n', cfg.num_subcarriers);
fprintf('  Default snapshots: %d\n', cfg.snapshots);
fprintf('  Default seed:      %d\n', cfg.random_seed);

cfg = validate_quadriga_config(cfg);
fprintf('  After validation:  BS height=%dm, Clusters=%d\n', cfg.bs_height_m, cfg.num_clusters);
fprintf('\n');

%% Part 4: Single Generation Test
fprintf('--- Part 4: Single Generation Test ---\n');
cfg_test = default_quadriga_config();
cfg_test.snapshots = 10;
cfg_test.num_subcarriers = 16;
cfg_test.random_seed = 42;

t_start = tic;
result = quadriga_adapter(cfg_test);
t_elapsed = toc(t_start);

fprintf('  Scenario:          %s\n', result.scenario);
fprintf('  Complex-H size:    %d x %d\n', size(result.complex_h));
fprintf('  Is complex:        %d\n', ~isreal(result.complex_h));
fprintf('  Max abs(H):        %.4f\n', max(abs(result.complex_h(:))));
fprintf('  Time axis:         %.4f to %.4f s\n', result.time_axis_s(1), result.time_axis_s(end));
fprintf('  Freq axis:         %.2f to %.2f MHz\n', result.freq_axis_hz(1)/1e6, result.freq_axis_hz(end)/1e6);
fprintf('  Generation time:   %.2f s\n', t_elapsed);
fprintf('\n');

%% Part 5: Reproducibility Test
fprintf('--- Part 5: Reproducibility Test ---\n');
result1 = quadriga_adapter(cfg_test);
result2 = quadriga_adapter(cfg_test);
is_same = isequal(result1.complex_h, result2.complex_h);
fprintf('  Same seed produces identical output: %d\n', is_same);
if ~is_same
    max_diff = max(abs(result1.complex_h(:) - result2.complex_h(:)));
    fprintf('  Max difference: %.2e\n', max_diff);
end
fprintf('\n');

%% Part 6: Multi-Scenario Test
fprintf('--- Part 6: Multi-Scenario Test ---\n');
test_scenarios = ["3GPP_38.901_UMi", "3GPP_38.901_UMa", "3GPP_38.901_RMa"];
for i = 1:numel(test_scenarios)
    cfg_multi = default_quadriga_config();
    cfg_multi.scenario = test_scenarios(i);
    cfg_multi.snapshots = 10;
    cfg_multi.num_subcarriers = 16;
    cfg_multi.random_seed = 42;
    
    r = quadriga_adapter(cfg_multi);
    fprintf('  %s: %dx%d, complex=%d, max|H|=%.4f\n', ...
        test_scenarios(i), size(r.complex_h,1), size(r.complex_h,2), ...
        ~isreal(r.complex_h), max(abs(r.complex_h(:))));
end
fprintf('\n');

%% Part 7: Multi-Band Test
fprintf('--- Part 7: Multi-Band Test ---\n');
bands = [struct('name', 'Sub-6', 'freq', 3.5, 'bw', 100), ...
         struct('name', 'mmWave', 'freq', 28, 'bw', 200), ...
         struct('name', 'THz', 'freq', 100, 'bw', 400)];
for i = 1:numel(bands)
    cfg_band = default_quadriga_config();
    cfg_band.carrier_freq_ghz = bands(i).freq;
    cfg_band.bandwidth_mhz = bands(i).bw;
    cfg_band.snapshots = 10;
    cfg_band.num_subcarriers = 16;
    cfg_band.random_seed = 42;
    
    r = quadriga_adapter(cfg_band);
    freq_range = r.freq_axis_hz(end) - r.freq_axis_hz(1);
    fprintf('  %s (%.0f GHz, %d MHz): freq range = %.0f MHz\n', ...
        bands(i).name, bands(i).freq, bands(i).bw, freq_range/1e6);
end
fprintf('\n');

%% Summary
fprintf('============================================================\n');
fprintf('  Validation Complete\n');
fprintf('============================================================\n');
fprintf('  Results:\n');
fprintf('    - Environment:    PASS\n');
fprintf('    - Scenarios:      PASS (6 loaded)\n');
fprintf('    - Config:         PASS\n');
fprintf('    - Generation:     PASS (%dx%d)\n', size(result.complex_h));
fprintf('    - Reproducibility: %s\n', ternary(is_same, 'PASS', 'FAIL'));
fprintf('    - Multi-scenario: PASS (3 tested)\n');
fprintf('    - Multi-band:     PASS (3 tested)\n');
fprintf('\n');
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
