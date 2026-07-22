function results = test_quadriga_adapter()
%TEST_QUADRIGA_ADAPTER Run self-test suite for the QuaDRiGa pipeline.
%   results = test_quadriga_adapter() runs all tests and returns results.
%   Throws an error if any test fails (non-zero exit code).

fprintf('=== QuaDRiGa Adapter Test Suite ===\n\n');
results = struct();
results.passed = 0;
results.failed = 0;
results.skipped = 0;
results.details = {};

% Test 1: Environment check
[results, ~] = run_test(results, 'Environment Check', @test_env_check);

% Test 2: Scenario registry
[results, ~] = run_test(results, 'Scenario Registry (7 scenarios)', @test_scenarios);

% Test 3: Default config
[results, ~] = run_test(results, 'Default Config & Validation', @test_config);

% Test 4: QuaDRiGa adapter (requires QuaDRiGa)
[results, ~] = run_test(results, 'QuaDRiGa Adapter', @test_adapter);

% Test 5: Seed reproducibility
[results, ~] = run_test(results, 'Seed Reproducibility', @test_reproducibility);

% Test 6: Complex-valued output
[results, ~] = run_test(results, 'Complex-valued H(t,f)', @test_complex);

% Test 7: Dimension consistency
[results, ~] = run_test(results, 'Dimension Consistency', @test_dimensions);

% Test 8: Frequency axis correctness
[results, ~] = run_test(results, 'Frequency Axis Correctness', @test_freq_axis);

% Test 9: Time continuity
[results, ~] = run_test(results, 'Time Continuity', @test_time_continuity);

% Test 10: Coordinate completeness
[results, ~] = run_test(results, 'Coordinate Completeness', @test_coordinates);

% Test 11: Multi-band
[results, ~] = run_test(results, 'Multi-band Support', @test_multiband);

% Test 12: LOS/NLOS distinction
[results, ~] = run_test(results, 'LOS/NLOS Distinction', @test_los_nlos);

% Test 13: Sampling theorem compliance
[results, ~] = run_test(results, 'Sampling Theorem Compliance', @test_sampling_theorem);

% Summary
fprintf('\n=== Summary: %d passed, %d failed, %d skipped ===\n', ...
    results.passed, results.failed, results.skipped);

% Throw error if any test failed (non-zero exit code)
if results.failed > 0
    error('test_quadriga_adapter:TestFailed', ...
        '%d test(s) FAILED', results.failed);
end
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
         "3GPP_38.901_UMa-LOS", "3GPP_38.901_RMa", "3GPP_38.901_RMa-LOS", ...
         "3GPP_38.901_INH"];
for idx = 1:numel(names)
    sc = quadriga_scenarios(names(idx));
    assert(~isempty(sc.bs_height_m), 'Missing bs_height_m');
    assert(~isempty(sc.scenario_type), 'Missing scenario_type');
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
assert(isfield(result, 'freq_axis_hz'), 'Missing freq_axis_hz');
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
assert(~isreal(result.complex_h), 'complex_h is real (should have imaginary part)');
assert(any(imag(result.complex_h) ~= 0, 'all'), 'complex_h has no non-zero imaginary parts');
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

function test_freq_axis()
env = quadriga_check();
if ~env.is_available
    error('SKIP: QuaDRiGa not installed');
end
cfg = default_quadriga_config();
cfg.snapshots = 10;
cfg.num_subcarriers = 16;
cfg.bandwidth_mhz = 100;
result = quadriga_adapter(cfg);

% Frequency axis must use DFT grid: delta_f = B/N
bw_hz = cfg.bandwidth_mhz * 1e6;
expected_delta_f = bw_hz / cfg.num_subcarriers;
actual_delta_f = result.freq_axis_hz(2) - result.freq_axis_hz(1);
assert(abs(actual_delta_f - expected_delta_f) < 1e-6, ...
    sprintf('delta_f wrong: expected %.0f Hz, got %.0f Hz', expected_delta_f, actual_delta_f));

% Must have N points
assert(length(result.freq_axis_hz) == cfg.num_subcarriers, ...
    'Frequency axis length does not match num_subcarriers');

% Must be symmetric around 0 (for even N)
assert(abs(result.freq_axis_hz(1) + result.freq_axis_hz(end) + actual_delta_f) < 1e-6, ...
    'Frequency axis not symmetric around 0');

% Verify delta_f matches bandwidth / N
assert(abs(result.delta_f_hz - expected_delta_f) < 1e-6, ...
    'delta_f_hz field does not match B/N');
end

function test_time_continuity()
env = quadriga_check();
if ~env.is_available
    error('SKIP: QuaDRiGa not installed');
end
cfg = default_quadriga_config();
cfg.snapshots = 20;
cfg.num_subcarriers = 16;
result = quadriga_adapter(cfg);

% Time axis must be strictly increasing
assert(all(diff(result.time_axis_s) > 0), 'Time axis not strictly increasing');

% Time interval should match config
expected_dt = cfg.snapshot_interval_s;
actual_dt = result.time_axis_s(2) - result.time_axis_s(1);
assert(abs(actual_dt - expected_dt) < 1e-10, ...
    sprintf('Time interval wrong: expected %.4f, got %.4f', expected_dt, actual_dt));
end

function test_coordinates()
env = quadriga_check();
if ~env.is_available
    error('SKIP: QuaDRiGa not installed');
end
cfg = default_quadriga_config();
cfg.snapshots = 10;
cfg.num_subcarriers = 16;
result = quadriga_adapter(cfg);

% BS position must exist and be 3-element
assert(isfield(result, 'bs_position_m'), 'Missing bs_position_m');
assert(numel(result.bs_position_m) == 3, 'bs_position_m must be 3 elements');

% UE trajectory must exist and be Nx3
assert(isfield(result, 'ue_trajectory_m'), 'Missing ue_trajectory_m');
assert(size(result.ue_trajectory_m, 2) == 3, 'ue_trajectory_m must be Nx3');
assert(size(result.ue_trajectory_m, 1) == cfg.snapshots, ...
    'ue_trajectory_m rows must match snapshots');
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
    % Verify DFT frequency grid: range = (N-1)*delta_f = (N-1)*B/N
    N = cfg.num_subcarriers;
    B = bands(idx).bandwidth_mhz * 1e6;
    expected_range = (N - 1) * B / N;
    actual_range = result.freq_axis_hz(end) - result.freq_axis_hz(1);
    assert(abs(actual_range - expected_range) < 1e-6, ...
        sprintf('Freq range wrong for %.1f GHz band', bands(idx).carrier_freq_ghz));
    % Verify delta_f = B/N
    assert(abs(result.delta_f_hz - B/N) < 1e-6, ...
        'delta_f_hz does not match B/N');
end
end

function test_los_nlos()
env = quadriga_check();
if ~env.is_available
    error('SKIP: QuaDRiGa not installed');
end
% UMi and UMi-LOS should produce different outputs with same seed
cfg_nlos = default_quadriga_config();
cfg_nlos.scenario = "3GPP_38.901_UMi";
cfg_nlos.snapshots = 10;
cfg_nlos.num_subcarriers = 16;
cfg_nlos.random_seed = 42;

cfg_los = default_quadriga_config();
cfg_los.scenario = "3GPP_38.901_UMi-LOS";
cfg_los.snapshots = 10;
cfg_los.num_subcarriers = 16;
cfg_los.random_seed = 42;

result_nlos = quadriga_adapter(cfg_nlos);
result_los = quadriga_adapter(cfg_los);

assert(~isequal(result_nlos.complex_h, result_los.complex_h), ...
    'UMi and UMi-LOS produce identical output with same seed');
end

function test_sampling_theorem()
env = quadriga_check();
if ~env.is_available
    error('SKIP: QuaDRiGa not installed');
end
% Test that auto-adjustment satisfies sampling theorem
c_light = 3e8;
bands = [struct('freq', 3.5, 'bw', 100), ...
         struct('freq', 28, 'bw', 200), ...
         struct('freq', 100, 'bw', 400)];
for idx = 1:numel(bands)
    cfg = default_quadriga_config();
    cfg.carrier_freq_ghz = bands(idx).freq;
    cfg.bandwidth_mhz = bands(idx).bw;
    cfg.snapshots = 10;
    cfg.num_subcarriers = 16;
    cfg.snapshot_interval_s = 0.01;  % Intentionally large to trigger auto-adjust
    result = quadriga_adapter(cfg);
    
    % Verify the adapter auto-adjusted the interval
    fc_hz = bands(idx).freq * 1e9;
    lambda = c_light / fc_hz;
    max_allowed = lambda / (2 * cfg.ue_speed_mps);
    assert(result.config.snapshot_interval_s <= max_allowed, ...
        sprintf('Snapshot interval %.6f exceeds max %.6f for %.1f GHz', ...
        result.config.snapshot_interval_s, max_allowed, bands(idx).freq));
end
end
