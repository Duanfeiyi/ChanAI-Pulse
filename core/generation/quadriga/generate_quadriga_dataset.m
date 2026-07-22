function datasets = generate_quadriga_dataset(varargin)
%GENERATE_QUADRIGA_DATASET Generate QuaDRiGa channel datasets in batch.
%   datasets = generate_quadriga_dataset() generates a default dataset set.
%   datasets = generate_quadriga_dataset('Scenarios', {...}) customizes scenarios.
%   datasets = generate_quadriga_dataset('OutputDir', 'path') sets output directory.
%
%   Examples:
%     generate_quadriga_dataset()                          % Default: 3 scenarios × 3 bands
%     generate_quadriga_dataset('Snapshots', 200)          % More snapshots
%     generate_quadriga_dataset('Scenarios', {'3GPP_38.901_UMi'})  % Single scenario

p = inputParser;
addParameter(p, 'Scenarios', {"3GPP_38.901_UMi", "3GPP_38.901_UMi-LOS", "3GPP_38.901_UMa"});
addParameter(p, 'CarrierFreqs_GHz', [3.5]);
addParameter(p, 'Bandwidths_MHz', [100]);
addParameter(p, 'Snapshots', 100);
addParameter(p, 'Subcarriers', 64);
addParameter(p, 'Seeds', [42]);
addParameter(p, 'OutputDir', fullfile(pwd, 'demo_data', 'quadriga_datasets'));
addParameter(p, 'SavePlots', false);
parse(p, varargin{:});

scenarios = string(p.Results.Scenarios);
if iscell(scenarios), scenarios = string(scenarios); end
freqs = p.Results.CarrierFreqs_GHz;
bws = p.Results.Bandwidths_MHz;
nSnaps = p.Results.Snapshots;
nSub = p.Results.Subcarriers;
seeds = p.Results.Seeds;
outputDir = p.Results.OutputDir;
savePlots = p.Results.SavePlots;

% Create output directory
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

fprintf('============================================================\n');
fprintf('  QuaDRiGa Dataset Batch Generator\n');
fprintf('  Scenarios: %d | Bands: %d | Snaps: %d | Seeds: %d\n', ...
    numel(scenarios), numel(freqs), nSnaps, numel(seeds));
fprintf('  Output: %s\n', outputDir);
fprintf('============================================================\n\n');

datasets = {};
idx = 0;

for s = 1:numel(scenarios)
    for f = 1:numel(freqs)
        for r = 1:numel(seeds)
            idx = idx + 1;
            
            cfg = default_quadriga_config();
            cfg.scenario = scenarios(s);
            cfg.carrier_freq_ghz = freqs(f);
            cfg.bandwidth_mhz = bws(f);
            cfg.snapshots = nSnaps;
            cfg.num_subcarriers = nSub;
            cfg.random_seed = seeds(r);
            
            % Generate
            fprintf('[%03d] %s @ %.1f GHz (seed=%d, traj=%s) ... ', idx, scenarios(s), freqs(f), seeds(r), result.trajectory_type);
            t_start = tic;
            result = quadriga_adapter(cfg);
            t_elapsed = toc(t_start);
            fprintf('%.1f s, %dx%d, traj=%s\n', t_elapsed, size(result.complex_h, 1), size(result.complex_h, 2), result.trajectory_type);
            
            % Save
            filename = sprintf('quadriga_%s_%.1fGHz_seed%d.mat', ...
                strrep(char(scenarios(s)), '.', ''), freqs(f), seeds(r));
            filepath = fullfile(outputDir, filename);
            save(filepath, 'result', '-v7.3');
            
            % Store metadata
            datasets{idx} = struct( ...
                'filename', filename, ...
                'scenario', char(scenarios(s)), ...
                'carrier_freq_ghz', freqs(f), ...
                'bandwidth_mhz', bws(f), ...
                'snapshots', nSnaps, ...
                'subcarriers', nSub, ...
                'seed', seeds(r), ...
                'trajectory_type', result.trajectory_type, ...
                'complex_h_size', size(result.complex_h), ...
                'generation_time_s', t_elapsed);
            
            % Optional: save visualization
            if savePlots
                fig = figure('Visible', 'off');
                
                subplot(2,2,1);
                imagesc(abs(result.complex_h));
                colorbar; title('|H(t,f)|');
                xlabel('Subcarrier'); ylabel('Snapshot');
                
                subplot(2,2,2);
                imagesc(angle(result.complex_h));
                colorbar; title('Phase H(t,f)');
                xlabel('Subcarrier'); ylabel('Snapshot');
                
                subplot(2,2,3);
                h_freq = result.complex_h(1,:);
                h_time = ifft(ifftshift(h_freq));
                plot(10*log10(abs(h_time).^2 + 1e-20));
                title('PDP (Snap 1)'); xlabel('Delay bin'); ylabel('dB');
                
                subplot(2,2,4);
                plot(result.ue_trajectory_m(:,1), result.ue_trajectory_m(:,2), '-o');
                hold on;
                plot(result.bs_position_m(1), result.bs_position_m(2), 'r^', 'MarkerSize', 10);
                legend('UE', 'BS'); title('Trajectory');
                xlabel('X (m)'); ylabel('Y (m)');
                
                sgtitle(sprintf('%s @ %.0f GHz', scenarios(s), freqs(f)));
                saveas(fig, fullfile(outputDir, strrep(filename, '.mat', '.png')));
                close(fig);
            end
        end
    end
end

% Write metadata.json
metadata = struct();
metadata.dataset_name = "ChanAI Pulse QuaDRiGa Dataset";
metadata.version = "1.0";
metadata.generated_at = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
metadata.generator = "QuaDRiGa v2.8.1";
metadata.total_files = numel(datasets);
metadata.scenarios = cellstr(scenarios);
metadata.carrier_freqs_ghz = freqs;
metadata.bandwidths_mhz = bws;
metadata.snapshots = nSnaps;
metadata.subcarriers = nSub;
metadata.seeds = seeds;
metadata.datasets = {datasets};

jsonStr = jsonencode(metadata, 'PrettyPrint', true);
jsonPath = fullfile(outputDir, 'metadata.json');
fid = fopen(jsonPath, 'w', 'n', 'UTF-8');
fprintf(fid, '%s', jsonStr);
fclose(fid);

fprintf('\n============================================================\n');
fprintf('  Generation Complete\n');
fprintf('  Total files: %d\n', numel(datasets));
fprintf('  Metadata: %s\n', jsonPath);
fprintf('============================================================\n');
end
