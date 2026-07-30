function outputPath = render_step7_grid_search_review(outputDirectory, options)
%RENDER_STEP7_GRID_SEARCH_REVIEW Render a reproducible Step 7 review sheet.

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

mock = runCase("mock", "");
lite = runCase("lite_6gpcm", "");
full = struct();
if options.EngineRoot ~= "" && isfolder(options.EngineRoot)
    full = runCase("full_6gpcm", options.EngineRoot);
end

figureHandle = figure("Visible", options.Visible, "Color", "white", ...
    "Position", [35, 40, 1500, 880]);
cleanup = onCleanup(@() closeIfValid(figureHandle));
layout = tiledlayout(figureHandle, 2, 2, ...
    "TileSpacing", "compact", "Padding", "compact");

overviewAxes = nexttile(layout);
axis(overviewAxes, "off");
lines = [ ...
    "冻结链路：known区域 → Step 5目标特性 → 笛卡尔积 → Step 6候选CIR → Step 5评分 → 排名"; ...
    ""; ...
    resultLine("Mock标准答案", mock); ...
    resultLine("6GPCM-lite工程搜索", lite)];
if ~isempty(fieldnames(full))
    lines(end + 1) = resultLine("真实Full两候选", full);
else
    lines(end + 1) = "● 真实Full两候选：本次未配置外置引擎";
end
lines = [lines; ""; ...
    "评分：PDP概率距离50% + RMS时延扩展分布距离50%"; ...
    "公平：全部候选共用同一随机种子；失败记录并继续"; ...
    "边界：这里只证明Grid Search完整、可复现，不证明物理参数唯一"];
text(overviewAxes, 0.03, 0.96, lines, ...
    "Units", "normalized", "VerticalAlignment", "top", ...
    "FontName", "Microsoft YaHei UI", "FontSize", 11.5, ...
    "Interpreter", "none");
title(overviewAxes, "Step 7状态与边界", ...
    "FontName", "Microsoft YaHei UI", "FontWeight", "bold");

scoreAxes = nexttile(layout);
renderBestSoFar(scoreAxes, lite.ranking, ...
    "6GPCM-lite · 候选分数与当前最佳");

pdpAxes = nexttile(layout);
renderPdpComparison(pdpAxes, lite.best.score, ...
    "6GPCM-lite · 目标 vs 最佳 PDP");

dsAxes = nexttile(layout);
renderDsComparison(dsAxes, lite.best.score, ...
    "6GPCM-lite · 目标 vs 最佳时延扩展");

title(layout, "ChanAI Pulse v3 Step 7 · 真正的笛卡尔积 Grid Search 审阅图", ...
    "FontName", "Microsoft YaHei UI", "FontWeight", "bold");
outputPath = fullfile(outputDirectory, ...
    "step7_grid_search_review.png");
exportgraphics(figureHandle, outputPath, "Resolution", 150);
clear cleanup
end

function result = runCase(backend, engineRoot)
targetConfig = default_generator_config(backend);
targetConfig.random_seed = 3103;
switch backend
    case "mock"
        targetConfig.dimensions = struct( ...
            "Tx", 1, "Rx", 1, "Npath", 10, ...
            "Nt", 2, "N_sample", 6);
        space = struct( ...
            "DS_mu", [targetConfig.model.DS_mu - 0.1, ...
                targetConfig.model.DS_mu], ...
            "KF_mu", [targetConfig.model.KF_mu, ...
                targetConfig.model.KF_mu + 0.5], ...
            "num_clusters", [9, targetConfig.model.num_clusters]);
    case "lite_6gpcm"
        targetConfig.dimensions.Nt = 3;
        targetConfig.dimensions.N_sample = 4;
        space = struct( ...
            "DS_mu", [targetConfig.model.DS_mu - 0.1, ...
                targetConfig.model.DS_mu], ...
            "KF_mu", [targetConfig.model.KF_mu, ...
                targetConfig.model.KF_mu + 0.5], ...
            "num_clusters", [9, targetConfig.model.num_clusters]);
    case "full_6gpcm"
        targetConfig.engine_root = engineRoot;
        targetConfig.dimensions.N_sample = 1;
        space = struct("DS_mu", ...
            [targetConfig.model.DS_mu, ...
            targetConfig.model.DS_mu + 0.1]);
end
target = run_generator_adapter(targetConfig);
if ~target.success
    error("render_step7_grid_search_review:TargetFailed", ...
        "Target generation failed for %s.", backend);
end
config = default_grid_search_config(backend);
config.generator_config = targetConfig;
config.parameter_space = space;
result = run_grid_search(target.dataset, config);
if ~result.success
    error("render_step7_grid_search_review:SearchFailed", ...
        "Grid Search failed for %s.", backend);
end
end

function line = resultLine(label, result)
line = sprintf("● %s：%s / %s · %d候选 · 最佳分数 %.6f", ...
    label, result.status, result.outcome, result.total_candidates, ...
    result.best.total_score);
end

function renderBestSoFar(axesHandle, ranking, titleText)
successful = ranking([ranking.success]);
[~, order] = sort([successful.index]);
successful = successful(order);
scores = [successful.total_score].';
plot(axesHandle, [successful.index], scores, "o-", ...
    "Color", [0.55, 0.62, 0.70], ...
    "DisplayName", "候选分数");
hold(axesHandle, "on");
plot(axesHandle, [successful.index], cummin(scores), "-", ...
    "Color", [0.10, 0.58, 0.30], "LineWidth", 2, ...
    "DisplayName", "当前最佳");
hold(axesHandle, "off");
xlabel(axesHandle, "候选执行序号");
ylabel(axesHandle, "总分（越小越好）");
title(axesHandle, titleText, "FontName", "Microsoft YaHei UI");
legend(axesHandle, "Location", "best");
grid(axesHandle, "on");
end

function renderPdpComparison(axesHandle, score, titleText)
f = score.features;
plot(axesHandle, f.pdp_centers_s * 1e9, ...
    f.target_pdp_probability, "LineWidth", 1.8, ...
    "DisplayName", "目标known");
hold(axesHandle, "on");
plot(axesHandle, f.pdp_centers_s * 1e9, ...
    f.candidate_pdp_probability, "--", "LineWidth", 1.8, ...
    "DisplayName", "最佳候选");
hold(axesHandle, "off");
xlabel(axesHandle, "时延 (ns)");
ylabel(axesHandle, "归一化概率");
title(axesHandle, titleText, "FontName", "Microsoft YaHei UI");
legend(axesHandle, "Location", "best");
grid(axesHandle, "on");
end

function renderDsComparison(axesHandle, score, titleText)
f = score.features;
plot(axesHandle, f.quantile_probability, ...
    f.target_delay_spread_quantile_s * 1e9, ...
    "LineWidth", 1.8, "DisplayName", "目标known");
hold(axesHandle, "on");
plot(axesHandle, f.quantile_probability, ...
    f.candidate_delay_spread_quantile_s * 1e9, "--", ...
    "LineWidth", 1.8, "DisplayName", "最佳候选");
hold(axesHandle, "off");
xlabel(axesHandle, "分位概率");
ylabel(axesHandle, "RMS时延扩展 (ns)");
title(axesHandle, titleText, "FontName", "Microsoft YaHei UI");
legend(axesHandle, "Location", "best");
grid(axesHandle, "on");
end

function closeIfValid(figureHandle)
if isvalid(figureHandle)
    close(figureHandle);
end
end
