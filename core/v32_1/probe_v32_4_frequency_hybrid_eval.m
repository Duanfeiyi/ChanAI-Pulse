function report = probe_v32_4_frequency_hybrid_eval()
%PROBE_V32_4_FREQUENCY_HYBRID_EVAL v3.2-4a 1A hybrid acceptance evaluation.
%   Runs the EXACT shipped recovery chain (recover_inband_ctf_hybrid ->
%   delay-domain OMP / complex linear) over the full exported Frequency
%   corpus, per missing pattern, and reports complex NMSE (v3.2-2b
%   protocol), the dispatcher's per-pattern choice, and the per-sequence
%   win rate of the hybrid against the previous product method (complex
%   linear). This is offline research on the Git-external corpus; it never
%   touches the product UI or Full 6GPCM.

repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(repoRoot, "core"));
addpath(genpath(fullfile(repoRoot, "core")));

corpusFile = "D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\" + ...
    "chanaipulse-v3.2-corpus.1\frequency_inband_ctf.h5";

realAll = h5read(corpusFile, "/ctf_real");   % [Tx, Rx, Nf, N]
imagAll = h5read(corpusFile, "/ctf_imag");
knownAll = h5read(corpusFile, "/known_index");
targetAll = h5read(corpusFile, "/target_index");
patternBytes = h5read(corpusFile, "/pattern");
nSpectra = size(realAll, 4);
nf = size(realAll, 3);

% Pattern label per spectrum (MATLAB reads the exported [N, W] logical as
% [W, N] column-major; each spectrum occupies one column).
patterns = strings(nSpectra, 1);
for index = 1:nSpectra
    raw = char(patternBytes(:, index).');
    raw = strtrim(raw);
    raw(raw == char(0)) = [];
    patterns(index) = string(raw);
end

patternNames = unique(patterns);
accum = struct();
for pattern = patternNames.'
    accum.(pattern) = struct( ...
        "sequences", 0, ...
        "chosen_sparse", 0, ...
        "chosen_linear", 0, ...
        "magRmseHybrid", [], "phaseRmseHybrid", [], "complexNmseHybrid", [], ...
        "complexNmseLinear", [], "winHybrid", []);
end

for spectrumIndex = 1:nSpectra
    pattern = patterns(spectrumIndex);
    H = squeeze(realAll(:, :, :, spectrumIndex)) + ...
        1j * squeeze(imagAll(:, :, :, spectrumIndex));   % [Tx, Rx, Nf]
    known = knownAll(:, spectrumIndex);
    known = known(~isnan(known));
    target = targetAll(:, spectrumIndex);
    target = target(~isnan(target));
    known = double(known(:));
    target = double(target(:));

    [HHybrid, method] = recover_inband_ctf_hybrid(H, known, target);
    HLinear = recover_inband_ctf_spectrum(H, known);

    for tx = 1:size(H, 1)
        for rx = 1:size(H, 2)
            truth = squeeze(H(tx, rx, target));
            predHybrid = squeeze(HHybrid(tx, rx, target));
            predLinear = squeeze(HLinear(tx, rx, target));
            accum.(pattern).sequences = accum.(pattern).sequences + 1;
            if method == "delay_domain_sparse"
                accum.(pattern).chosen_sparse = ...
                    accum.(pattern).chosen_sparse + 1;
            else
                accum.(pattern).chosen_linear = ...
                    accum.(pattern).chosen_linear + 1;
            end
            accum.(pattern).magRmseHybrid(end + 1, 1) = ...
                sqrt(mean((abs(predHybrid) - abs(truth)).^2)); %#ok<AGROW>
            accum.(pattern).phaseRmseHybrid(end + 1, 1) = ...
                sqrt(mean((angle(predHybrid) - angle(truth)).^2)); %#ok<AGROW>
            accum.(pattern).complexNmseHybrid(end + 1, 1) = ...
                sqrt(mean(abs(predHybrid - truth).^2)); %#ok<AGROW>
            accum.(pattern).complexNmseLinear(end + 1, 1) = ...
                sqrt(mean(abs(predLinear - truth).^2)); %#ok<AGROW>
            accum.(pattern).winHybrid(end + 1, 1) = ...
                accum.(pattern).complexNmseHybrid(end) < ...
                accum.(pattern).complexNmseLinear(end); %#ok<AGROW>
        end
    end
end

report = struct("schema_version", "v3.2-4a-frequency-hybrid-eval.1");
for pattern = patternNames.'
    p = pattern;
    a = accum.(p);
    meanHybrid = mean(a.complexNmseHybrid);
    meanLinear = mean(a.complexNmseLinear);
    improvement = 1 - meanHybrid / max(meanLinear, eps);
    winRate = mean(a.winHybrid);
    report.(p) = struct( ...
        "sequences", a.sequences, ...
        "chosen_sparse", a.chosen_sparse, ...
        "chosen_linear", a.chosen_linear, ...
        "hybrid_complex_nmse", meanHybrid, ...
        "linear_complex_nmse", meanLinear, ...
        "hybrid_mag_rmse", mean(a.magRmseHybrid), ...
        "hybrid_phase_rmse", mean(a.phaseRmseHybrid), ...
        "relative_improvement_vs_linear", improvement, ...
        "hybrid_win_rate_vs_linear", winRate);
    fprintf("%-12s seq=%d sparse=%d linear=%d  hybridNMSE=%.4f  " + ...
        "linearNMSE=%.4f  improvement=%+.1f%%  winRate=%.1f%%\n", ...
        p, a.sequences, a.chosen_sparse, a.chosen_linear, ...
        meanHybrid, meanLinear, 100 * improvement, 100 * winRate);
end

outFile = "D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\" + ...
    "chanaipulse-v3.2-corpus.1\v32_4a_frequency_hybrid_eval.json";
jsonText = jsonencode(report, "PrettyPrint", true);
fid = fopen(outFile, "w", "n", "UTF-8");
fwrite(fid, jsonText, "char");
fclose(fid);
fprintf("report: %s\n", outFile);
end
