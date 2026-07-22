function check_manifest(demoDir)
%CHECK_MANIFEST Verify manifest.json matches actual .mat files (SHA-256, content).

if nargin < 1
    demoDir = fullfile(pwd, 'demo_data', 'quadriga_datasets');
end

manifestPath = fullfile(demoDir, 'manifest.json');
assert(exist(manifestPath, 'file') == 2, 'manifest.json not found in %s', demoDir);

M = jsondecode(fileread(manifestPath));
md = java.security.MessageDigest.getInstance('SHA-256');

for k = 1:numel(M.datasets)
    d = M.datasets(k);
    matPath = fullfile(demoDir, d.filename);
    assert(exist(matPath, 'file') == 2, 'Missing: %s', d.filename);

    S = load(matPath, 'result');
    r = S.result;
    assert(r.num_subcarriers == d.num_subcarriers, 'Subcarrier mismatch for %s', d.filename);
    assert(r.num_snapshots == d.num_snapshots, 'Snapshot mismatch for %s', d.filename);
    assert(abs(r.delta_f_hz - d.delta_f_hz) < 1e-6, 'delta_f mismatch for %s', d.filename);

    fid = fopen(matPath, 'rb');
    raw = fread(fid, '*uint8');
    fclose(fid);
    md.reset();
    digest = md.digest(raw);
    sha = lower(char(join(string(dec2hex(uint8(digest))), '')));
    assert(strcmp(sha, d.sha256), 'SHA-256 mismatch for %s', d.filename);

    fprintf('[PASS] %s\n', d.filename);
end
fprintf('All %d manifest entries verified.\n', numel(M.datasets));
end
