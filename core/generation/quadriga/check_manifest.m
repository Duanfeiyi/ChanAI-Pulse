function check_manifest(demoDir)
%CHECK_MANIFEST Verify hashes and provenance fields in manifest.json.

if nargin < 1
    demoDir = fullfile(pwd, 'demo_data', 'quadriga_datasets');
end

manifestPath = fullfile(demoDir, 'manifest.json');
assert(exist(manifestPath, 'file') == 2, 'manifest.json not found in %s', demoDir);
manifest = jsondecode(fileread(manifestPath));
assert(manifest.schema_version == 2, 'Unsupported manifest schema version');
assert(~isempty(regexp(manifest.adapter_git_commit, ...
    '^([0-9a-f]{40}|unknown)$', 'once')), 'Invalid adapter Git revision');

matFiles = dir(fullfile(demoDir, '*.mat'));
actualNames = sort(string({matFiles.name}));
manifestNames = sort(string({manifest.datasets.filename}));
assert(isequal(actualNames, manifestNames), ...
    'Manifest file set does not match the MAT files in the directory');

metadataPath = fullfile(demoDir, 'metadata.json');
assert(exist(metadataPath, 'file') == 2, 'metadata.json is missing');
assert(compute_file_sha256(string(metadataPath)) == string(manifest.metadata_sha256), ...
    'metadata.json SHA-256 mismatch');

for k = 1:numel(manifest.datasets)
    entry = manifest.datasets(k);
    matPath = fullfile(demoDir, entry.filename);
    fileInfo = dir(matPath);
    assert(~isempty(fileInfo), 'Missing: %s', entry.filename);
    assert(fileInfo.bytes == entry.size_bytes, 'File size mismatch for %s', entry.filename);
    assert(~isempty(regexp(entry.sha256, '^[0-9a-f]{64}$', 'once')), ...
        'Invalid SHA-256 format for %s', entry.filename);
    assert(compute_file_sha256(string(matPath)) == string(entry.sha256), ...
        'SHA-256 mismatch for %s', entry.filename);

    loaded = load(matPath, 'result');
    result = loaded.result;
    assert_text(result.scenario, entry.scenario, 'scenario', entry.filename);
    assert_text(result.quadriga_exact_scenario, entry.quadriga_exact_scenario, ...
        'exact scenario', entry.filename);
    assert_text(result.trajectory_type, entry.trajectory_type, ...
        'trajectory type', entry.filename);
    assert_number(result.carrier_freq_hz, entry.carrier_freq_hz, ...
        'carrier frequency', entry.filename);
    assert_number(result.bandwidth_hz, entry.bandwidth_hz, ...
        'bandwidth', entry.filename);
    assert_number(result.delta_f_hz, entry.delta_f_hz, ...
        'delta_f', entry.filename);
    assert(result.num_subcarriers == entry.num_subcarriers, ...
        'Subcarrier mismatch for %s', entry.filename);
    assert(result.num_snapshots == entry.num_snapshots, ...
        'Snapshot mismatch for %s', entry.filename);
    assert_number(result.effective_snapshot_interval_s, entry.snapshot_interval_s, ...
        'snapshot interval', entry.filename);
    assert_number(result.time_axis_s(1), entry.time_start_s, ...
        'time start', entry.filename);
    assert_number(result.time_axis_s(end), entry.time_end_s, ...
        'time end', entry.filename);
    assert_number(result.requested_snapshot_interval_s, ...
        entry.requested_snapshot_interval_s, 'requested interval', entry.filename);
    assert_number(result.effective_snapshot_interval_s, ...
        entry.effective_snapshot_interval_s, 'effective interval', entry.filename);
    assert(logical(result.sampling_interval_adjusted) == ...
        logical(entry.sampling_interval_adjusted), ...
        'Sampling-adjustment flag mismatch for %s', entry.filename);
    assert_number(result.config.ue_speed_mps, entry.ue_speed_mps, ...
        'UE speed', entry.filename);
    assert(result.config.bs_antenna_elements == entry.bs_antenna_elements, ...
        'BS antenna mismatch for %s', entry.filename);
    assert(result.config.ue_antenna_elements == entry.ue_antenna_elements, ...
        'UE antenna mismatch for %s', entry.filename);
    assert_vector(result.bs_position_m, entry.bs_position_m, ...
        'BS position', entry.filename);
    assert_vector(result.ue_trajectory_m(1, :), entry.ue_start_position_m, ...
        'UE start position', entry.filename);
    assert_vector(result.ue_trajectory_m(end, :), entry.ue_end_position_m, ...
        'UE end position', entry.filename);
    assert_text(entry.complex_representation, 'MATLAB complex double', ...
        'complex representation', entry.filename);
    assert_text(entry.axis_order, 'complex_h[T,F]', 'axis order', entry.filename);
    assert(result.random_seed == entry.random_seed, ...
        'Random-seed mismatch for %s', entry.filename);
    assert_text(result.adapter_version, entry.adapter_version, ...
        'adapter version', entry.filename);

    fprintf('[PASS] %s\n', entry.filename);
end
fprintf('All %d manifest entries verified.\n', numel(manifest.datasets));
end

function assert_text(actual, expected, label, filename)
assert(string(actual) == string(expected), '%s mismatch for %s', label, filename);
end

function assert_number(actual, expected, label, filename)
tolerance = max(1e-12, eps(max(abs([double(actual), double(expected)]))) * 8);
assert(abs(double(actual) - double(expected)) <= tolerance, ...
    '%s mismatch for %s', label, filename);
end

function assert_vector(actual, expected, label, filename)
actual = double(actual(:));
expected = double(expected(:));
assert(isequal(size(actual), size(expected)), '%s shape mismatch for %s', label, filename);
tolerance = max(1e-12, eps(max(abs([actual; expected]))) * 8);
assert(all(abs(actual - expected) <= tolerance), '%s mismatch for %s', label, filename);
end
