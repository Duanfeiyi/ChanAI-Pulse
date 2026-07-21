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
    override = demo_configs{idx};
    fnames = fieldnames(override);
    for f = 1:numel(fnames)
        cfg.(fnames{f}) = override.(fnames{f});
    end

    fprintf('Generating demo %d/%d: %s @ %.1f GHz ...\n', ...
        idx, numel(demo_configs), cfg.scenario, cfg.carrier_freq_ghz);

    result = quadriga_adapter(cfg);

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
