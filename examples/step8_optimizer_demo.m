function figureHandle = step8_optimizer_demo(options)
%STEP8_OPTIMIZER_DEMO Standalone UI for auto/Grid/SA review.

arguments
    options.Visible (1, 1) string = "on"
    options.AutoRun (1, 1) logical = false
    options.Backend (1, 1) string = "lite_6gpcm"
    options.EngineRoot (1, 1) string = ""
end

root = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(root, "core")));

blue = [0.04, 0.29, 0.56];
green = [0.10, 0.58, 0.30];
orange = [0.93, 0.57, 0.10];
muted = [0.42, 0.46, 0.51];

figureHandle = uifigure( ...
    "Name", "ChanAI Pulse v3 - Step 8 Optimizer Demo", ...
    "Position", [24, 32, 1540, 900], ...
    "Color", [0.96, 0.97, 0.985], ...
    "Visible", options.Visible);
main = uigridlayout(figureHandle, [4, 1], ...
    "RowHeight", {56, 194, "1x", 30}, ...
    "Padding", [12, 10, 12, 10], "RowSpacing", 8);

header = uipanel(main, "BackgroundColor", [1, 1, 1], ...
    "BorderColor", [0.55, 0.70, 0.86]);
header.Layout.Row = 1;
headerGrid = uigridlayout(header, [1, 3], ...
    "ColumnWidth", {235, "1x", 390}, "Padding", [14, 4, 14, 4]);
uilabel(headerGrid, "Text", "◉ ChanAI Pulse", ...
    "FontSize", 18, "FontWeight", "bold", "FontColor", blue);
uilabel(headerGrid, ...
    "Text", "Step 8 · 参数优化策略决策与模拟退火", ...
    "HorizontalAlignment", "center", "FontSize", 18, ...
    "FontWeight", "bold", "FontColor", blue);
uilabel(headerGrid, ...
    "Text", "独立审阅 Demo · 不改正式三页 UI", ...
    "HorizontalAlignment", "right", "FontColor", muted);

controls = uipanel(main, "Title", ...
    "模块二后台配置（只读取任务 known 区域）", ...
    "FontWeight", "bold", "BackgroundColor", [1, 1, 1]);
controls.Layout.Row = 2;
controlGrid = uigridlayout(controls, [5, 10], ...
    "RowHeight", {28, 28, 28, 28, 28}, ...
    "ColumnWidth", {82, 155, 82, 175, 82, 175, 82, 175, 110, "1x"}, ...
    "Padding", [12, 7, 12, 7], "ColumnSpacing", 7);

uilabel(controlGrid, "Text", "生成后端", "HorizontalAlignment", "right");
backendDrop = uidropdown(controlGrid, ...
    "Items", ["Mock（测试）", "6GPCM-lite", "Full 6GPCM（外置）"], ...
    "ItemsData", ["mock", "lite_6gpcm", "full_6gpcm"], ...
    "Value", canonicalBackend(options.Backend), ...
    "ValueChangedFcn", @backendChanged);
uilabel(controlGrid, "Text", "请求策略", "HorizontalAlignment", "right");
strategyDrop = uidropdown(controlGrid, ...
    "Items", ["自动选择（推荐）", "手动 Grid", "手动 SA"], ...
    "ItemsData", ["auto", "grid", "sa"], "Value", "auto");
uilabel(controlGrid, "Text", "DS_mu候选", "HorizontalAlignment", "right");
dsField = uieditfield(controlGrid, "text");
uilabel(controlGrid, "Text", "KF_mu候选", "HorizontalAlignment", "right");
kfField = uieditfield(controlGrid, "text");
runButton = uibutton(controlGrid, "push", ...
    "Text", "运行并比较", "FontWeight", "bold", ...
    "BackgroundColor", blue, "FontColor", [1, 1, 1], ...
    "ButtonPushedFcn", @runComparison);
cancelButton = uibutton(controlGrid, "push", ...
    "Text", "取消", "Enable", "off", ...
    "ButtonPushedFcn", @cancelRun);

uilabel(controlGrid, "Text", "簇数量候选", "HorizontalAlignment", "right");
clusterField = uieditfield(controlGrid, "text");
uilabel(controlGrid, "Text", "SA评估预算", "HorizontalAlignment", "right");
budgetField = uieditfield(controlGrid, "numeric", ...
    "Limits", [2, 500], "RoundFractionalValues", "on", "Value", 18);
uilabel(controlGrid, "Text", "生成器种子", "HorizontalAlignment", "right");
uilabel(controlGrid, "Text", "3103（所有候选相同）", "FontColor", muted);
uilabel(controlGrid, "Text", "优化器种子", "HorizontalAlignment", "right");
uilabel(controlGrid, "Text", "8103（可复现）", "FontColor", muted);
candidateLabel = uilabel(controlGrid, "Text", "离散组合：-", ...
    "FontWeight", "bold", "HorizontalAlignment", "center");
candidateLabel.Layout.Column = [9, 10];

uilabel(controlGrid, "Text", "外置路径", "HorizontalAlignment", "right");
rootField = uieditfield(controlGrid, "text", ...
    "Value", options.EngineRoot, ...
    "Placeholder", "仅 Full 使用，不写入公开 Manifest");
rootField.Layout.Column = [2, 8];
statusBadge = uilabel(controlGrid, "Text", "等待运行", ...
    "HorizontalAlignment", "center", "FontWeight", "bold", ...
    "BackgroundColor", [0.91, 0.93, 0.95], "FontColor", muted);
statusBadge.Layout.Column = [9, 10];

uilabel(controlGrid, "Text", "实际选择", "HorizontalAlignment", "right");
selectedLabel = uilabel(controlGrid, "Text", "尚未运行", ...
    "FontWeight", "bold", "FontColor", blue);
selectedLabel.Layout.Column = [2, 3];
uilabel(controlGrid, "Text", "选择理由", "HorizontalAlignment", "right");
reasonLabel = uilabel(controlGrid, "Text", ...
    "运行前先验证配置，再给出可追溯理由", "FontColor", muted);
reasonLabel.Layout.Column = [5, 10];

progress = uigauge(controlGrid, "linear", ...
    "Limits", [0, 100], "Value", 0, ...
    "MajorTicks", [0, 25, 50, 75, 100], "MinorTicks", []);
progress.Layout.Row = 5;
progress.Layout.Column = [1, 7];
ruleLabel = uilabel(controlGrid, ...
    "Text", "Grid完整枚举 · SA允许按概率接受较差一步 · Top-5保留完整CIR", ...
    "HorizontalAlignment", "center", "FontColor", muted);
ruleLabel.Layout.Row = 5;
ruleLabel.Layout.Column = [8, 10];

body = uigridlayout(main, [2, 3], ...
    "RowHeight", {"1x", "1x"}, ...
    "ColumnWidth", {"1x", "1x", 430}, ...
    "Padding", [0, 0, 0, 0], "RowSpacing", 8, "ColumnSpacing", 8);
body.Layout.Row = 3;

convergenceAxes = panelAxes(body, 1, 1, ...
    "选中策略 · 分数与当前最佳");
temperatureAxes = panelAxes(body, 1, 2, ...
    "SA · 温度与接受率");
pdpAxes = panelAxes(body, 2, 1, ...
    "目标 known vs 选中策略最佳 · PDP");
dsAxes = panelAxes(body, 2, 2, ...
    "目标 known vs 选中策略最佳 · 时延扩展");

sidePanel = uipanel(body, "Title", ...
    "Grid / Random Greedy / SA 对照", ...
    "BackgroundColor", [1, 1, 1]);
sidePanel.Layout.Row = [1, 2];
sidePanel.Layout.Column = 3;
sideGrid = uigridlayout(sidePanel, [3, 1], ...
    "RowHeight", {205, 150, "1x"}, "Padding", [8, 8, 8, 8]);
compareAxes = uiaxes(sideGrid);
grid(compareAxes, "on");
comparisonTable = uitable(sideGrid, ...
    "ColumnName", {"算法", "最佳分数", "评估", "接受较差", "停止原因"}, ...
    "ColumnWidth", {94, 75, 52, 65, 105}, "RowName", []);
summaryArea = uitextarea(sideGrid, "Editable", "off", ...
    "FontName", "Microsoft YaHei UI", ...
    "Value", ["本页检查算法选择、SA过程和公平对照。"; ...
    "分数是拟合距离，不是预测准确率。"]);

footer = uilabel(main, ...
    "Text", "Step 8属于模块二后台参数拟合；不训练预测模型，不产生模块三预测结果，也不修改完整版6GPCM核心。", ...
    "BackgroundColor", [1, 1, 1], "FontColor", muted);
footer.Layout.Row = 4;

state = struct("cancel_requested", false);
backendChanged([], []);
if options.AutoRun
    drawnow;
    runComparison([], []);
end

    function backendChanged(~, ~)
        backend = string(backendDrop.Value);
        switch backend
            case "full_6gpcm"
                dsField.Value = "-7.925,-7.825";
                kfField.Value = "-0.39";
                clusterField.Value = "12";
                budgetField.Value = 2;
            otherwise
                dsField.Value = "-8.025,-7.925";
                kfField.Value = "-0.39,0.11";
                clusterField.Value = "9,12";
                budgetField.Value = 18;
        end
        rootField.Enable = onOff(backend == "full_6gpcm");
        if backend == "full_6gpcm" && ...
                strlength(strtrim(string(rootField.Value))) == 0
            rootField.Value = getenv("CHANAI_FULL_6GPCM_ROOT");
        end
        updateCandidateCount();
    end

    function updateCandidateCount()
        try
            count = numel(parseValues(dsField.Value)) * ...
                numel(parseValues(kfField.Value)) * ...
                numel(parseValues(clusterField.Value));
            candidateLabel.Text = sprintf("离散组合：%d", count);
        catch
            candidateLabel.Text = "离散组合：输入有误";
        end
    end

    function runComparison(~, ~)
        state.cancel_requested = false;
        runButton.Enable = "off";
        cancelButton.Enable = "on";
        progress.Value = 0;
        setStatus("RUNNING", "正在生成统一目标");
        drawnow;
        try
            backend = string(backendDrop.Value);
            targetConfig = demoTargetConfig( ...
                backend, string(rootField.Value));
            target = run_generator_adapter(targetConfig, struct( ...
                "cancel_check", @() state.cancel_requested));
            if ~target.success
                error("step8_optimizer_demo:TargetFailed", ...
                    "目标信道生成失败：%s", ...
                    strjoin(target.errors, " | "));
            end
            config = demoOptimizationConfig(targetConfig);
            selected = run_parameter_optimization(target.dataset, ...
                config, struct( ...
                    "progress_callback", @showProgress, ...
                    "cancel_check", @() state.cancel_requested));
            if selected.cancelled
                renderFailure(selected);
                restoreButtons();
                return;
            end

            gridConfig = config;
            gridConfig.requested_strategy = "grid";
            gridResult = run_parameter_optimization( ...
                target.dataset, gridConfig, ...
                struct("cancel_check", @() state.cancel_requested));
            saConfig = config;
            saConfig.requested_strategy = "sa";
            saResult = run_simulated_annealing( ...
                target.dataset, saConfig, ...
                struct("cancel_check", @() state.cancel_requested));
            greedyResult = run_random_greedy_search( ...
                target.dataset, saConfig, ...
                struct("cancel_check", @() state.cancel_requested));

            bundle = struct( ...
                "selected", selected, ...
                "grid", gridResult, ...
                "random_greedy", greedyResult, ...
                "sa", saResult, ...
                "target_config", targetConfig);
            renderBundle(bundle);
            figureHandle.UserData = bundle;
        catch exception
            setStatus("FAIL", "Demo执行失败");
            summaryArea.Value = cellstr( ...
                "Demo执行失败：" + string(exception.message));
            figureHandle.UserData = struct( ...
                "success", false, ...
                "exception_identifier", string(exception.identifier), ...
                "exception_message", string(exception.message), ...
                "exception_stack", exception.stack);
        end
        restoreButtons();
    end

    function config = demoOptimizationConfig(targetConfig)
        config = default_optimization_config(targetConfig.backend);
        config.requested_strategy = string(strategyDrop.Value);
        config.generator_config = targetConfig;
        config.variables = struct( ...
            "DS_mu", discreteDescriptor( ...
                parseValues(dsField.Value), targetConfig.model.DS_mu + 0.1), ...
            "KF_mu", discreteDescriptor( ...
                parseValues(kfField.Value), targetConfig.model.KF_mu + 0.5), ...
            "num_clusters", discreteDescriptor( ...
                parseValues(clusterField.Value), ...
                targetConfig.model.num_clusters - 3));
        config.limits.max_evaluations = budgetField.Value;
        config.sa.no_improvement_limit = max(12, budgetField.Value);
        config.sa.proposals_per_temperature = 6;
    end

    function cancelRun(~, ~)
        state.cancel_requested = true;
        cancelButton.Text = "正在取消…";
        drawnow;
    end

    function showProgress(event)
        progress.Value = event.progress * 100;
        statusBadge.Text = event.message;
        drawnow;
    end

    function renderBundle(bundle)
        selected = bundle.selected;
        setStatus(selected.status, ...
            selected.status + " / " + selected.outcome);
        selectedLabel.Text = upper(selected.selected_strategy) + ...
            "（" + selected.selection_source + "）";
        reasonLabel.Text = selected.selection_reason;
        renderConvergence(selected);
        renderTemperature(bundle.sa);
        renderComparison(bundle);
        renderFeatureComparison(selected.best.score);
        summaryArea.Value = cellstr([ ...
            "请求策略：" + selected.requested_strategy; ...
            "实际策略：" + selected.selected_strategy; ...
            "选择理由：" + selected.selection_reason; ...
            sprintf("最佳拟合距离：%.6f（越小越接近）", ...
                selected.best.total_score); ...
            "目标真实参数（仅Demo已知）：" + ...
                parameterText(bundle.target_config.model); ...
            "选中策略最佳参数：" + ...
                parameterText(selected.best.parameters); ...
            ""; ...
            "Random Greedy只接受不变或更好的移动；"; ...
            "SA还可按Metropolis概率接受较差移动，用于跳出局部低谷；"; ...
            "本结果是模块二参数拟合，不是模块三预测准确率。"]);
    end

    function renderFailure(result)
        setStatus(result.status, result.outcome);
        selectedLabel.Text = "不可用";
        reasonLabel.Text = strjoin(result.errors, " | ");
        summaryArea.Value = cellstr([ ...
            "状态：" + result.status + " / " + result.outcome; ...
            "错误：" + strjoin(result.errors, " | "); ...
            "提示：" + strjoin(result.warnings, " | ")]);
    end

    function renderConvergence(selected)
        cla(convergenceAxes);
        axis(convergenceAxes, "on");
        if selected.selected_strategy == "grid"
            ranking = selected.details.ranking;
            successful = ranking([ranking.success]);
            [~, order] = sort([successful.index]);
            successful = successful(order);
            x = [successful.index];
            scores = [successful.total_score];
        else
            history = selected.details.history;
            successful = history([history.success]);
            x = [successful.proposal_index];
            scores = [successful.total_score];
        end
        displayScores = max(scores, 1e-12);
        plot(convergenceAxes, x, displayScores, "o-", ...
            "Color", [0.55, 0.62, 0.70], "DisplayName", "候选分数");
        hold(convergenceAxes, "on");
        plot(convergenceAxes, x, cummin(displayScores), "-", ...
            "Color", green, "LineWidth", 2, "DisplayName", "当前最佳");
        hold(convergenceAxes, "off");
        axis(convergenceAxes, "auto");
        set(convergenceAxes, "YScale", "log");
        xlabel(convergenceAxes, "候选/提案序号");
        ylabel(convergenceAxes, "拟合距离（越小越好）");
        legend(convergenceAxes, "Location", "best");
        grid(convergenceAxes, "on");
    end

    function renderTemperature(saResult)
        cla(temperatureAxes);
        axis(temperatureAxes, "on");
        levels = saResult.temperature_history;
        if isempty(levels)
            renderEmpty(temperatureAxes, "SA没有完整温度层");
            return;
        end
        yyaxis(temperatureAxes, "left");
        plot(temperatureAxes, [levels.level], [levels.temperature], ...
            "o-", "Color", orange, "LineWidth", 1.8);
        ylabel(temperatureAxes, "温度");
        yyaxis(temperatureAxes, "right");
        plot(temperatureAxes, [levels.level], [levels.acceptance_rate], ...
            "s-", "Color", blue, "LineWidth", 1.5);
        ylabel(temperatureAxes, "本层接受率");
        xlabel(temperatureAxes, "温度层");
        axis(temperatureAxes, "auto");
        grid(temperatureAxes, "on");
    end

    function renderComparison(bundle)
        labels = categorical(["Grid", "Random Greedy", "SA"]);
        labels = reordercats(labels, ["Grid", "Random Greedy", "SA"]);
        scores = [bundle.grid.best.total_score, ...
            bundle.random_greedy.best.total_score, ...
            bundle.sa.best.total_score];
        cla(compareAxes);
        evaluationCounts = [ ...
            bundle.grid.counts.objective_evaluations, ...
            bundle.random_greedy.objective_evaluations, ...
            bundle.sa.objective_evaluations];
        bar(compareAxes, labels, evaluationCounts, ...
            "FaceColor", [0.30, 0.55, 0.78]);
        ylabel(compareAxes, "实际生成与评分次数");
        title(compareAxes, "三算法成本（最佳分数见下表）");
        grid(compareAxes, "on");
        algorithms = ["Grid"; "Random Greedy"; "SA"];
        bestScores = double(scores(:));
        evaluations = double([ ...
            bundle.grid.counts.objective_evaluations; ...
            bundle.random_greedy.objective_evaluations; ...
            bundle.sa.objective_evaluations]);
        worseAccepted = double([ ...
            0; bundle.random_greedy.worse_accepted_proposals; ...
            bundle.sa.worse_accepted_proposals]);
        stopReasons = ["complete_grid"; ...
            string(bundle.random_greedy.stop_reason); ...
            string(bundle.sa.stop_reason)];
        comparisonTable.Data = table(algorithms, bestScores, ...
            evaluations, worseAccepted, stopReasons);
    end

    function renderFeatureComparison(score)
        f = score.features;
        cla(pdpAxes);
        axis(pdpAxes, "on");
        plot(pdpAxes, f.pdp_centers_s * 1e9, ...
            f.target_pdp_probability, "Color", blue, ...
            "LineWidth", 1.8, "DisplayName", "目标known");
        hold(pdpAxes, "on");
        plot(pdpAxes, f.pdp_centers_s * 1e9, ...
            f.candidate_pdp_probability, "--", "Color", orange, ...
            "LineWidth", 1.8, "DisplayName", "最佳候选");
        hold(pdpAxes, "off");
        axis(pdpAxes, "auto");
        xlabel(pdpAxes, "时延 (ns)");
        ylabel(pdpAxes, "归一化概率");
        legend(pdpAxes, "Location", "best");
        grid(pdpAxes, "on");

        cla(dsAxes);
        axis(dsAxes, "on");
        plot(dsAxes, f.quantile_probability, ...
            f.target_delay_spread_quantile_s * 1e9, ...
            "Color", blue, "LineWidth", 1.8, ...
            "DisplayName", "目标known");
        hold(dsAxes, "on");
        plot(dsAxes, f.quantile_probability, ...
            f.candidate_delay_spread_quantile_s * 1e9, "--", ...
            "Color", orange, "LineWidth", 1.8, ...
            "DisplayName", "最佳候选");
        hold(dsAxes, "off");
        axis(dsAxes, "auto");
        xlabel(dsAxes, "分位概率");
        ylabel(dsAxes, "RMS时延扩展 (ns)");
        legend(dsAxes, "Location", "best");
        grid(dsAxes, "on");
    end

    function setStatus(status, text)
        statusBadge.Text = text;
        switch string(status)
            case "PASS"
                statusBadge.BackgroundColor = [0.84, 0.95, 0.88];
                statusBadge.FontColor = green;
            case "WARNING"
                statusBadge.BackgroundColor = [1.00, 0.94, 0.78];
                statusBadge.FontColor = [0.65, 0.38, 0.02];
            case "FAIL"
                statusBadge.BackgroundColor = [0.98, 0.86, 0.86];
                statusBadge.FontColor = [0.75, 0.12, 0.12];
            otherwise
                statusBadge.BackgroundColor = [0.91, 0.93, 0.95];
                statusBadge.FontColor = muted;
        end
    end

    function restoreButtons()
        if isvalid(runButton)
            runButton.Enable = "on";
            cancelButton.Enable = "off";
            cancelButton.Text = "取消";
        end
    end
end

function axesHandle = panelAxes(parent, row, column, titleText)
panel = uipanel(parent, "Title", titleText, ...
    "BackgroundColor", [1, 1, 1]);
panel.Layout.Row = row;
panel.Layout.Column = column;
axesHandle = uiaxes(panel, "Position", [58, 43, 410, 220]);
grid(axesHandle, "on");
renderEmpty(axesHandle, "等待运行");
end

function descriptor = discreteDescriptor(values, initial)
descriptor = struct( ...
    "type", "discrete", ...
    "values", values, ...
    "initial", initial, ...
    "step_fraction", 1);
end

function config = demoTargetConfig(backend, engineRoot)
config = default_generator_config(backend);
config.random_seed = 3103;
switch backend
    case "mock"
        config.dimensions = struct( ...
            "Tx", 1, "Rx", 1, "Npath", 10, ...
            "Nt", 2, "N_sample", 6);
    case "lite_6gpcm"
        config.dimensions.Nt = 3;
        config.dimensions.N_sample = 4;
    case "full_6gpcm"
        config.engine_root = engineRoot;
        config.dimensions.N_sample = 1;
end
end

function values = parseValues(text)
tokens = split(replace(string(text), ["，", ";", " "], ","), ",");
tokens = tokens(strlength(strtrim(tokens)) > 0);
values = str2double(tokens).';
if isempty(values) || any(~isfinite(values))
    error("step8_optimizer_demo:InvalidValues", ...
        "候选列表必须是逗号分隔的有限数字。");
end
end

function backend = canonicalBackend(value)
value = lower(strtrim(string(value)));
if ismember(value, ["mock", "lite_6gpcm", "full_6gpcm"])
    backend = value;
else
    error("step8_optimizer_demo:UnsupportedBackend", ...
        "Unsupported backend: %s", value);
end
end

function value = onOff(condition)
value = "off";
if condition
    value = "on";
end
end

function text = parameterText(parameters)
names = string(fieldnames(parameters));
names = names(ismember(names, ...
    ["DS_mu", "KF_mu", "num_clusters"]));
parts = strings(numel(names), 1);
for index = 1:numel(names)
    parts(index) = names(index) + "=" + ...
        string(sprintf("%.6g", parameters.(names(index))));
end
text = strjoin(parts, "，");
end

function renderEmpty(axesHandle, message)
cla(axesHandle);
axis(axesHandle, [0, 1, 0, 1]);
axis(axesHandle, "off");
text(axesHandle, 0.5, 0.5, message, ...
    "HorizontalAlignment", "center", ...
    "Color", [0.45, 0.48, 0.52], ...
    "FontName", "Microsoft YaHei UI");
end
