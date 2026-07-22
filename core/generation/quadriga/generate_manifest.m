function generate_manifest(demoDir)
%GENERATE_MANIFEST Compute SHA-256 for each .mat file and write manifest.json.

if nargin < 1
    demoDir = fullfile(pwd, 'demo_data', 'quadriga_datasets');
end

matFiles = dir(fullfile(demoDir, '*.mat'));
if isempty(matFiles)
    error('No .mat files found in %s', demoDir);
end

manifest = struct();
manifest.generated_at = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
manifest.generator = "QuaDRiGa v2.8.1";
manifest.adapter_version = "v2.0-step-v2-1";
manifest.frequency_grid = "DFT: delta_f = B/N, (-N/2:N/2-1)*delta_f";
manifest.datasets = {};

md = java.security.MessageDigest.getInstance('SHA-256');

for k = 1:numel(matFiles)
    fPath = fullfile(demoDir, matFiles(k).name);
    fid = fopen(fPath, 'rb');
    raw = fread(fid, '*uint8');
    fclose(fid);
    md.reset();
    digest = md.digest(raw);
    sha = lower(char(join(string(dec2hex(uint8(digest))), '')));

    S = load(fPath, 'result');
    r = S.result;

    manifest.datasets(k).filename = matFiles(k).name;
    manifest.datasets(k).sha256 = sha;
    manifest.datasets(k).size_bytes = matFiles(k).bytes;
    manifest.datasets(k).scenario = r.scenario;
    manifest.datasets(k).quadriga_exact_scenario = r.quadriga_exact_scenario;
    manifest.datasets(k).trajectory_type = r.trajectory_type;
    manifest.datasets(k).carrier_freq_hz = r.carrier_freq_hz;
    manifest.datasets(k).bandwidth_hz = r.bandwidth_hz;
    manifest.datasets(k).delta_f_hz = r.delta_f_hz;
    manifest.datasets(k).num_subcarriers = r.num_subcarriers;
    manifest.datasets(k).num_snapshots = r.num_snapshots;
    manifest.datasets(k).random_seed = r.random_seed;
    manifest.datasets(k).adapter_version = r.adapter_version;

    fprintf('[%d] %s  SHA-256: %s\n', k, matFiles(k).name, sha);
end

outPath = fullfile(demoDir, 'manifest.json');
fid = fopen(outPath, 'w', 'n', 'UTF-8');
fprintf(fid, '%s', jsonencode(manifest, 'PrettyPrint', true));
fclose(fid);
fprintf('\nManifest written: %s (%d files)\n', outPath, numel(matFiles));
end
