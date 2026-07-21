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