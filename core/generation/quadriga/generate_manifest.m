function manifest = generate_manifest(demoDir)
%GENERATE_MANIFEST Write an auditable manifest for generated QuaDRiGa data.
%   MANIFEST = GENERATE_MANIFEST(DEMODIR) records standard SHA-256 hashes,
%   physical axes, mobility, geometry, representation, and source revision
%   for every generated MAT file in DEMODIR.

if nargin < 1
    demoDir = fullfile(pwd, 'demo_data', 'quadriga_datasets');
end

matFiles = dir(fullfile(demoDir, '*.mat'));
if isempty(matFiles)
    error('generate_manifest:NoMatFiles', 'No .mat files found in %s', demoDir);
end
[~, order] = sort({matFiles.name});
matFiles = matFiles(order);

sourceRevision = get_repository_revision();
manifest = struct();
manifest.schema_version = 2;
manifest.generated_at = string(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ssXXX'));
manifest.generator = "QuaDRiGa v2.8.1";
manifest.adapter_version = "v2.0-step-v2-1";
manifest.adapter_git_commit = sourceRevision;
manifest.frequency_grid = "DFT: delta_f = B/N, (-N/2:N/2-1)*delta_f";
metadataPath = fullfile(demoDir, 'metadata.json');
if exist(metadataPath, 'file') == 2
    manifest.metadata_sha256 = compute_file_sha256(string(metadataPath));
else
    manifest.metadata_sha256 = "not_present";
end
manifest.datasets = struct([]);

for k = 1:numel(matFiles)
    filePath = fullfile(demoDir, matFiles(k).name);
    loaded = load(filePath, 'result');
    assert(isfield(loaded, 'result'), 'Missing result struct in %s', matFiles(k).name);
    result = loaded.result;

    entry = struct();
    entry.filename = matFiles(k).name;
    entry.sha256 = compute_file_sha256(string(filePath));
    entry.size_bytes = matFiles(k).bytes;
    entry.scenario = result.scenario;
    entry.quadriga_exact_scenario = result.quadriga_exact_scenario;
    entry.trajectory_type = result.trajectory_type;
    entry.carrier_freq_hz = result.carrier_freq_hz;
    entry.bandwidth_hz = result.bandwidth_hz;
    entry.delta_f_hz = result.delta_f_hz;
    entry.num_subcarriers = result.num_subcarriers;
    entry.num_snapshots = result.num_snapshots;
    entry.snapshot_interval_s = result.effective_snapshot_interval_s;
    entry.time_start_s = result.time_axis_s(1);
    entry.time_end_s = result.time_axis_s(end);
    entry.requested_snapshot_interval_s = result.requested_snapshot_interval_s;
    entry.effective_snapshot_interval_s = result.effective_snapshot_interval_s;
    entry.sampling_interval_adjusted = result.sampling_interval_adjusted;
    entry.ue_speed_mps = result.config.ue_speed_mps;
    entry.bs_antenna_elements = result.config.bs_antenna_elements;
    entry.ue_antenna_elements = result.config.ue_antenna_elements;
    entry.bs_position_m = result.bs_position_m;
    entry.ue_start_position_m = result.ue_trajectory_m(1, :);
    entry.ue_end_position_m = result.ue_trajectory_m(end, :);
    entry.complex_representation = "MATLAB complex double";
    entry.axis_order = "complex_h[T,F]";
    entry.random_seed = result.random_seed;
    entry.adapter_version = result.adapter_version;
    entry.adapter_git_commit = sourceRevision;
    entry.generation_time_s = result.generation_time_s;
    manifest.datasets(k) = entry;

    fprintf('[%d] %s  SHA-256: %s\n', ...
        k, matFiles(k).name, entry.sha256);
end

outputPath = fullfile(demoDir, 'manifest.json');
fid = fopen(outputPath, 'w', 'n', 'UTF-8');
if fid < 0
    error('generate_manifest:FileOpenFailed', ...
        'Unable to write manifest: %s', outputPath);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', jsonencode(manifest, 'PrettyPrint', true));
fprintf('\nManifest written: %s (%d files)\n', outputPath, numel(matFiles));
end

function revision = get_repository_revision()
sourceDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(fileparts(sourceDir)));
[status, output] = system(sprintf('git -C "%s" rev-parse HEAD', repoRoot));
if status == 0
    revision = string(strtrim(output));
else
    revision = "unknown";
end
end
