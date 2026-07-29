function artifacts = generate_full_6gpcm_step3_review( ...
        engineRoot, outputDirectory, reviewImagePath)
%GENERATE_FULL_6GPCM_STEP3_REVIEW Create small Step 3 review artifacts.
%   The HDF5 and JSON outputs contain one fixed-seed technical probe. The
%   PNG is a quality-control preview, not a channel-accuracy figure.

arguments
    engineRoot (1, 1) string
    outputDirectory (1, 1) string
    reviewImagePath (1, 1) string = ""
end
repositoryRoot = fileparts(fileparts(string(mfilename("fullpath"))));
addpath(genpath(fullfile(repositoryRoot, "core")));
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
if strlength(reviewImagePath) == 0
    reviewImagePath = fullfile(outputDirectory, ...
        "full_6gpcm_probe_review.png");
end

hdf5Path = fullfile(outputDirectory, "full_6gpcm_probe_cir.h5");
summaryPath = fullfile(outputDirectory, "full_6gpcm_probe_summary.json");
assertNewFile(hdf5Path);
assertNewFile(summaryPath);
assertNewFile(reviewImagePath);

config = default_full_6gpcm_probe_config(engineRoot);
config.sample_count = 3;
result = run_full_6gpcm_probe(config);
write_channel_dataset_hdf5(hdf5Path, result.dataset);

summary = result.report;
summary.explanation = struct( ...
    "raw_shape", ...
        "Raw engine order is Tx x Rx x Nt x Npath.", ...
    "canonical_shape", ...
        "Platform CIR order is Tx x Rx x Npath x Nt x N_sample.", ...
    "sample_meaning", ...
        "Samples are independent realizations, not route positions.", ...
    "accuracy_scope", ...
        "This probe checks the interface, not scientific accuracy.");
writelines(string(jsonencode(summary, "PrettyPrint", true)), ...
    summaryPath, "Encoding", "UTF-8");

figureHandle = renderReviewFigure(result);
cleanup = onCleanup(@() close(figureHandle));
exportgraphics(figureHandle, reviewImagePath, "Resolution", 180);

artifacts = struct( ...
    "hdf5_path", string(hdf5Path), ...
    "summary_path", string(summaryPath), ...
    "review_image_path", string(reviewImagePath), ...
    "report", result.report);
clear cleanup
end

function figureHandle = renderReviewFigure(result)
dataset = result.dataset;
coefficient = dataset.cir.coefficient;
delayS = dataset.cir.delay_s;
valid = dataset.cir.path_valid;
figureHandle = figure( ...
    "Visible", "off", ...
    "Color", "white", ...
    "Position", [100, 100, 1500, 900]);
layout = tiledlayout(figureHandle, 2, 2, ...
    "TileSpacing", "compact", "Padding", "compact");
title(layout, ...
    "ChanAI Pulse v3 Step 3 — Full 6GPCM headless probe", ...
    "FontSize", 18, "FontWeight", "bold");

drawPdp(nexttile(layout), coefficient, delayS, valid, 1, 1, ...
    "Independent sample 1 — internal snapshot 1");
drawPdp(nexttile(layout), coefficient, delayS, valid, 2, 1, ...
    "Independent sample 1 — internal snapshot 2");

axisHandle = nexttile(layout);
totalPower = squeeze(sum(abs(coefficient).^2, [1, 2, 3]));
totalPowerDb = 10 * log10(max(totalPower, realmin));
imagesc(axisHandle, 1:size(totalPowerDb, 1), ...
    1:size(totalPowerDb, 2), totalPowerDb.');
axisHandle.YDir = "normal";
axisHandle.XTick = 1:size(totalPowerDb, 1);
axisHandle.YTick = 1:size(totalPowerDb, 2);
xlabel(axisHandle, "Internal snapshot Nt");
ylabel(axisHandle, "Independent sample ID");
title(axisHandle, "Total channel power (dB)");
colorbar(axisHandle);
grid(axisHandle, "on");

axisHandle = nexttile(layout);
axis(axisHandle, "off");
shape = result.report.canonical_shape;
lines = [
    "RESULT: PASS"
    ""
    "Raw output:       2 × 2 × 2 × 240"
    "Raw order:        Tx × Rx × Nt × Npath"
    ""
    "Platform CIR:    " + join(string(shape), " × ")
    "Platform order:   Tx × Rx × Npath × Nt × N_sample"
    ""
    "240 paths = 12 clusters × 20 rays"
    "N_sample = 3 independent realizations"
    "Delay range: " + sprintf("%.3f–%.3f ns", ...
        result.report.delay_min_s * 1e9, ...
        result.report.delay_max_s * 1e9)
    "Fixed seed: " + string(result.report.random_seed)
    "Core unchanged: YES"
    ""
    "Scope: interface/shape/repeatability only"
    "Not an accuracy or ground-truth comparison"
    ];
text(axisHandle, 0.03, 0.98, lines, ...
    "Units", "normalized", ...
    "VerticalAlignment", "top", ...
    "FontName", "Consolas", ...
    "FontSize", 12, ...
    "Interpreter", "none");
end

function drawPdp(axisHandle, coefficient, delayS, valid, ...
        timeIndex, sampleIndex, plotTitle)
H = coefficient(:, :, :, timeIndex, sampleIndex);
tau = delayS(:, :, :, timeIndex, sampleIndex);
mask = valid(:, :, :, timeIndex, sampleIndex);
pathPower = squeeze(sum(abs(H).^2, [1, 2]));
pathDelay = squeeze(sum(tau .* mask, [1, 2]) ./ ...
    max(sum(mask, [1, 2]), 1));
pathMask = squeeze(any(mask, [1, 2]));
pathPower = pathPower(pathMask);
pathDelay = pathDelay(pathMask);
pathPowerDb = 10 * log10(max(pathPower / max(pathPower), realmin));
scatter(axisHandle, pathDelay * 1e9, pathPowerDb, ...
    15, pathPowerDb, "filled");
xlabel(axisHandle, "Path delay (ns)");
ylabel(axisHandle, "Relative path power (dB)");
title(axisHandle, plotTitle);
grid(axisHandle, "on");
ylim(axisHandle, [-80, 3]);
colorbar(axisHandle);
end

function assertNewFile(filePath)
parent = fileparts(filePath);
if strlength(string(parent)) > 0 && ~isfolder(parent)
    mkdir(parent);
end
if isfile(filePath)
    error("generate_full_6gpcm_step3_review:FileExists", ...
        "Refusing to overwrite existing review artifact: %s", filePath);
end
end
