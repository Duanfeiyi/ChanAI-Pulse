function outputPath = render_step6_adapter_review(outputDirectory, options)
%RENDER_STEP6_ADAPTER_REVIEW Render a reproducible Step 6 review sheet.

arguments
    outputDirectory (1, 1) string
    options.Visible (1, 1) string = "off"
    options.EngineRoot (1, 1) string = ""
end

root = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(root, "core")));
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

mockConfig = withCtf(default_generator_config("mock"), 24);
mockConfig.dimensions.N_sample = 4;
mock = run_generator_adapter(mockConfig);

liteConfig = withCtf(default_generator_config("lite_6gpcm"), 24);
liteConfig.dimensions.N_sample = 3;
liteConfig.dimensions.Nt = 4;
lite = run_generator_adapter(liteConfig);

fullConfig = withCtf(default_generator_config("full_6gpcm"), 24);
fullConfig.dimensions.N_sample = 1;
if options.EngineRoot ~= "" && isfolder(options.EngineRoot)
    fullConfig.engine_root = options.EngineRoot;
    fullLabel = "Full 6GPCM（真实外置引擎）";
else
    fullConfig.engine_root = fullfile(root, "tests", "fixtures", ...
        "mock_full_6gpcm");
    fullConfig.engine.id = "full_6gpcm_test_double";
    fullConfig.engine.version = "test-only";
    fullConfig.engine.source_package_name = "project_owned_test_double";
    fullConfig.engine.source_package_sha256 = "";
    fullConfig.engine.expected_tree_sha256 = "";
    fullConfig.engine.test_only = true;
    fullConfig.model.num_clusters = 2;
    fullConfig.model.num_rays = 3;
    fullLabel = "Full Adapter（项目自有测试替身）";
end
full = run_generator_adapter(fullConfig);

figureHandle = figure("Visible", options.Visible, "Color", "white", ...
    "Position", [40, 40, 1500, 860]);
cleanup = onCleanup(@() closeIfValid(figureHandle));
layout = tiledlayout(figureHandle, 2, 2, ...
    "TileSpacing", "compact", "Padding", "compact");

overviewAxes = nexttile(layout);
axis(overviewAxes, "off");
summary = [ ...
    "统一接口：GeneratorConfig → Generator Adapter → GenerationResult"; ...
    ""; ...
    resultLine("Mock（仅测试）", mock); ...
    resultLine("6GPCM-lite", lite); ...
    resultLine(fullLabel, full); ...
    ""; ...
    "安全规则：Full 缺失或配置不支持时明确 FAIL，不自动改用 Lite"; ...
    "后台规则：Mock/Lite 可按样本取消；Full 核心调用只能前后检查取消"; ...
    "输出规则：复数 CIR + delay + 可选 CTF，尺寸遵循 Tx/Rx/Npath/Nt/N_sample"];
text(overviewAxes, 0.03, 0.96, summary, ...
    "Units", "normalized", "VerticalAlignment", "top", ...
    "FontName", "Microsoft YaHei UI", "FontSize", 12, ...
    "Interpreter", "none");
title(overviewAxes, "Step 6 状态与边界", ...
    "FontName", "Microsoft YaHei UI", "FontWeight", "bold");

liteAxes = nexttile(layout);
renderPdp(liteAxes, lite, "6GPCM-lite · 平均 PDP");

fullAxes = nexttile(layout);
renderPdp(fullAxes, full, fullLabel + " · 平均 PDP");

ctfAxes = nexttile(layout);
renderCtf(ctfAxes, full, fullLabel + " · CTF");

title(layout, "ChanAI Pulse v3 Step 6 · 共享 Generator Adapter 审阅图", ...
    "FontName", "Microsoft YaHei UI", "FontWeight", "bold");
outputPath = fullfile(outputDirectory, "step6_generator_adapter_review.png");
exportgraphics(figureHandle, outputPath, "Resolution", 150);
clear cleanup
end

function config = withCtf(config, frequencyCount)
halfBandwidth = config.scenario.bandwidth_hz / 2;
config.ctf.enabled = true;
config.ctf.frequency_hz = linspace( ...
    config.scenario.center_frequency_hz - halfBandwidth, ...
    config.scenario.center_frequency_hz + halfBandwidth, ...
    frequencyCount).';
end

function line = resultLine(label, result)
if result.success
    d = result.dataset.dimensions;
    line = sprintf("● %-24s %s / %s · CIR %d×%d×%d×%d×%d", ...
        label, result.status, result.outcome, ...
        d.Tx, d.Rx, d.Npath, d.Nt, d.N_sample);
else
    line = sprintf("● %-24s %s / %s · %s", ...
        label, result.status, result.outcome, ...
        strjoin(result.errors, " | "));
end
end

function renderPdp(axesHandle, result, titleText)
if ~result.success
    renderFailure(axesHandle, result, titleText);
    return;
end
coefficient = result.dataset.cir.coefficient;
delay = result.dataset.cir.delay_s;
power = squeeze(mean(abs(coefficient).^2, [1, 2, 4, 5]));
delayNs = squeeze(mean(delay, [1, 2, 4, 5])) * 1e9;
powerDb = 10 * log10(power / max(power) + eps);
stem(axesHandle, delayNs, powerDb, ".", ...
    "Color", [0.04, 0.36, 0.70], "LineWidth", 1);
xlabel(axesHandle, "时延 (ns)");
ylabel(axesHandle, "归一化功率 (dB)");
title(axesHandle, titleText, "FontName", "Microsoft YaHei UI");
grid(axesHandle, "on");
end

function renderCtf(axesHandle, result, titleText)
if ~result.success || isempty(fieldnames(result.ctf_dataset))
    renderFailure(axesHandle, result, titleText);
    return;
end
H = result.ctf_dataset.ctf.H;
power = squeeze(mean(abs(H).^2, [1, 2, 4]));
if isvector(power)
    power = power(:);
end
powerDb = 10 * log10(power / max(power(:)) + eps);
imagesc(axesHandle, 1:size(powerDb, 2), ...
    result.ctf_dataset.axes.frequency_hz / 1e9, powerDb);
axis(axesHandle, "xy");
colorbar(axesHandle);
xlabel(axesHandle, "样本");
ylabel(axesHandle, "频率 (GHz)");
title(axesHandle, titleText, "FontName", "Microsoft YaHei UI");
end

function renderFailure(axesHandle, result, titleText)
axis(axesHandle, "off");
message = "无可用结果";
if ~isempty(result.errors)
    message = strjoin(result.errors, newline);
end
text(axesHandle, 0.5, 0.5, message, "Units", "normalized", ...
    "HorizontalAlignment", "center", "Color", [0.75, 0.12, 0.12], ...
    "Interpreter", "none");
title(axesHandle, titleText, "FontName", "Microsoft YaHei UI");
end

function closeIfValid(figureHandle)
if isvalid(figureHandle)
    close(figureHandle);
end
end
