function figureHandle = step7_grid_search_demo(options)
%STEP7_GRID_SEARCH_DEMO Standalone review UI for true Grid Search.

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
red = [0.78, 0.16, 0.16];
muted = [0.42, 0.46, 0.51];

figureHandle = uifigure( ...
    "Name", "ChanAI Pulse v3 - Step 7 Grid Search Demo", ...
    "Position", [35, 40, 1500, 880], ...
    "Color", [0.96, 0.97, 0.985], ...
    "Visible", options.Visible);
main = uigridlayout(figureHandle, [4, 1], ...
    "RowHeight", {54, 172, "1x", 30}, ...
    "Padding", [12, 10, 12, 10], "RowSpacing", 8);

header = uipanel(main, "BackgroundColor", [1, 1, 1], ...
    "BorderColor", [0.55, 0.70, 0.86]);
header.Layout.Row = 1;
headerGrid = uigridlayout(header, [1, 3], ...
    "ColumnWidth", {230, "1x", 370}, "Padding", [14, 4, 14, 4]);
uilabel(headerGrid, "Text", "◉ ChanAI Pulse", ...
    "FontSize", 18, "FontWeight", "bold", "FontColor", blue);
titleLabel = uilabel(headerGrid, ...
    "Text", "Step 7 · 真正的笛卡尔积 Grid Search", ...
    "HorizontalAlignment", "center", "FontSize", 18, ...
    "FontWeight", "bold", "FontColor", blue);
titleLabel.Layout.Column = 2;
uilabel(headerGrid, ...
    "Text", "独立审阅Demo · 目标由已知参数确定性生成", ...
    "HorizontalAlignment", "right", "FontColor", muted);

controls = uipanel(main, "Title", "搜索配置（只拟合known区域）", ...
    "FontWeight", "bold", "BackgroundColor", [1, 1, 1]);
controls.Layout.Row = 2;
controlsGrid = uigridlayout(controls, [4, 10], ...
    "RowHeight", {28, 28, 28, 28}, ...
    "ColumnWidth", {70, 160, 80, 170, 70, 170, 80, 170, 105, "1x"}, ...
    "Padding", [12, 7, 12, 7], "ColumnSpacing", 7);

uilabel(controlsGrid, "Text", "生成后端", ...
    "HorizontalAlignment", "right");
backendDrop = uidropdown(controlsGrid, ...
    "Items", ["Mock（测试）", "6GPCM-lite", "Full 6GPCM（外置）"], ...
    "ItemsData", ["mock", "lite_6gpcm", "full_6gpcm"], ...
    "Value", canonicalBackend(options.Backend), ...
    "ValueChangedFcn", @backendChanged);
uilabel(controlsGrid, "Text", "DS_mu候选", ...
    "HorizontalAlignment", "right");
dsField = uieditfield(controlsGrid, "text", ...
    "ValueChangedFcn", @(~, ~) updateCandidateCount());
uilabel(controlsGrid, "Text", "KF_mu候选", ...
    "HorizontalAlignment", "right");
kfField = uieditfield(controlsGrid, "text", ...
    "ValueChangedFcn", @(~, ~) updateCandidateCount());
uilabel(controlsGrid, "Text", "簇数量候选", ...
    "HorizontalAlignment", "right");
clusterField = uieditfield(controlsGrid, "text", ...
    "ValueChangedFcn", @(~, ~) updateCandidateCount());
candidateLabel = uilabel(controlsGrid, "Text", "候选数：-", ...
    "FontWeight", "bold", "HorizontalAlignment", "center");
candidateLabel.Layout.Column = [9, 10];

uilabel(controlsGrid, "Text", "外置路径", ...
    "HorizontalAlignment", "right");
rootField = uieditfield(controlsGrid, "text", ...
    "Value", options.EngineRoot, ...
    "Placeholder", "仅Full使用，不进入公开Manifest");
rootField.Layout.Column = [2, 8];
runButton = uibutton(controlsGrid, "push", ...
    "Text", "生成目标并搜索", ...
    "FontWeight", "bold", "BackgroundColor", blue, ...
    "FontColor", [1, 1, 1], "ButtonPushedFcn", @runSearch);
runButton.Layout.Column = 9;
cancelButton = uibutton(controlsGrid, "push", "Text", "取消", ...
    "Enable", "off", "ButtonPushedFcn", @cancelSearch);
cancelButton.Layout.Column = 10;

uilabel(controlsGrid, "Text", "评分权重", ...
    "HorizontalAlignment", "right");
uilabel(controlsGrid, "Text", "PDP 50% + 时延扩展 50%", ...
    "FontColor", muted);
uilabel(controlsGrid, "Text", "随机规则", ...
    "HorizontalAlignment", "right");
uilabel(controlsGrid, "Text", "全部候选共用固定种子3103", ...
    "FontColor", muted);
uilabel(controlsGrid, "Text", "保存规则", ...
    "HorizontalAlignment", "right");
uilabel(controlsGrid, "Text", "全部分数 + Top-5完整CIR", ...
    "FontColor", muted);
uilabel(controlsGrid, "Text", "执行方式", ...
    "HorizontalAlignment", "right");
uilabel(controlsGrid, "Text", "顺序、可取消、失败继续", ...
    "FontColor", muted);
statusBadge = uilabel(controlsGrid, "Text", "等待搜索", ...
    "HorizontalAlignment", "center", "FontWeight", "bold", ...
    "BackgroundColor", [0.91, 0.93, 0.95], "FontColor", muted);
statusBadge.Layout.Column = [9, 10];

progress = uigauge(controlsGrid, "linear", ...
    "Limits", [0, 100], "Value", 0, ...
    "MajorTicks", [0, 25, 50, 75, 100], ...
    "MinorTicks", []);
progress.Layout.Row = 4;
progress.Layout.Column = [1, 8];
bestLabel = uilabel(controlsGrid, ...
    "Text", "最佳结果：尚未运行", ...
    "HorizontalAlignment", "center", "FontWeight", "bold");
bestLabel.Layout.Row = 4;
bestLabel.Layout.Column = [9, 10];

body = uigridlayout(main, [2, 3], ...
    "RowHeight", {"1x", "1x"}, ...
    "ColumnWidth", {"1x", "1x", 420}, ...
    "Padding", [0, 0, 0, 0], ...
    "RowSpacing", 8, "ColumnSpacing", 8);
body.Layout.Row = 3;

scorePanel = uipanel(body, "Title", "候选顺序 · 最佳分数变化", ...
    "BackgroundColor", [1, 1, 1]);
scorePanel.Layout.Row = 1;
scorePanel.Layout.Column = 1;
scoreAxes = uiaxes(scorePanel, "Position", [58, 45, 395, 205]);
grid(scoreAxes, "on");
renderEmpty(scoreAxes, "等待Grid Search");

pdpPanel = uipanel(body, "Title", "目标 vs 最佳候选 · PDP概率", ...
    "BackgroundColor", [1, 1, 1]);
pdpPanel.Layout.Row = 1;
pdpPanel.Layout.Column = 2;
pdpAxes = uiaxes(pdpPanel, "Position", [58, 45, 395, 205]);
grid(pdpAxes, "on");
renderEmpty(pdpAxes, "等待最佳候选");

dsPanel = uipanel(body, "Title", "目标 vs 最佳候选 · 时延扩展分位数", ...
    "BackgroundColor", [1, 1, 1]);
dsPanel.Layout.Row = 2;
dsPanel.Layout.Column = 1;
dsAxes = uiaxes(dsPanel, "Position", [58, 45, 395, 205]);
grid(dsAxes, "on");
renderEmpty(dsAxes, "等待最佳候选");

summaryPanel = uipanel(body, "Title", "搜索结论与边界", ...
    "BackgroundColor", [1, 1, 1]);
summaryPanel.Layout.Row = 2;
summaryPanel.Layout.Column = 2;
summaryArea = uitextarea(summaryPanel, ...
    "Position", [12, 12, 465, 245], ...
    "Editable", "off", "FontName", "Microsoft YaHei UI", ...
    "Value", ["本Demo验证真正笛卡尔积、评分、排名和失败边界。"; ...
    "它不是参数物理唯一性的证明，也不是预测准确度图。"]);

tablePanel = uipanel(body, "Title", "Top候选与后台事件", ...
    "BackgroundColor", [1, 1, 1]);
tablePanel.Layout.Row = [1, 2];
tablePanel.Layout.Column = 3;
tableGrid = uigridlayout(tablePanel, [2, 1], ...
    "RowHeight", {205, "1x"}, "Padding", [8, 8, 8, 8]);
topTable = uitable(tableGrid, ...
    "ColumnName", {"排名", "候选", "总分", "PDP", "DS"}, ...
    "ColumnWidth", {48, 80, 70, 70, 70}, "RowName", []);
eventTable = uitable(tableGrid, ...
    "ColumnName", {"阶段", "进度", "消息"}, ...
    "ColumnWidth", {100, 55, 220}, "RowName", []);

footer = uilabel(main, ...
    "Text", "Step 7只拟合已知区域；SA留到Step 8，预测模型留到Step 9～11，正式模块二UI留到Step 12。", ...
    "BackgroundColor", [1, 1, 1], "FontColor", muted);
footer.Layout.Row = 4;

state = struct("cancel_requested", false);
backendChanged([], []);
if options.AutoRun
    drawnow;
    runSearch([], []);
end

    function backendChanged(~, ~)
        backend = string(backendDrop.Value);
        switch backend
            case "full_6gpcm"
                dsField.Value = "-7.925,-7.825";
                kfField.Value = "-0.39";
                clusterField.Value = "12";
            otherwise
                dsField.Value = "-8.05,-7.925,-7.80";
                kfField.Value = "-0.80,-0.39,0";
                clusterField.Value = "8,12,16";
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
            candidateLabel.Text = sprintf("候选数：%d / 500", count);
        catch
            candidateLabel.Text = "候选数：输入有误";
        end
    end

    function runSearch(~, ~)
        state.cancel_requested = false;
        runButton.Enable = "off";
        cancelButton.Enable = "on";
        progress.Value = 0;
        setStatus("RUNNING", "正在构建目标与枚举候选");
        drawnow;
        try
            backend = string(backendDrop.Value);
            targetConfig = demoTargetConfig(backend, string(rootField.Value));
            targetGeneration = run_generator_adapter(targetConfig, struct( ...
                "cancel_check", @() state.cancel_requested));
            if ~targetGeneration.success
                error("step7_grid_search_demo:TargetGenerationFailed", ...
                    "目标信道生成失败：%s", ...
                    strjoin(targetGeneration.errors, " | "));
            end
            config = default_grid_search_config(backend);
            config.generator_config = targetConfig;
            config.parameter_space = struct( ...
                "DS_mu", parseValues(dsField.Value), ...
                "KF_mu", parseValues(kfField.Value), ...
                "num_clusters", parseValues(clusterField.Value));
            config.limits.retain_top_k = 5;
            result = run_grid_search(targetGeneration.dataset, ...
                config, struct( ...
                    "progress_callback", @showProgress, ...
                    "cancel_check", @() state.cancel_requested));
            renderResult(result, targetConfig);
            figureHandle.UserData = result;
        catch exception
            setStatus("FAIL", "Demo错误");
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

    function cancelSearch(~, ~)
        state.cancel_requested = true;
        cancelButton.Text = "正在取消…";
        drawnow;
    end

    function showProgress(event)
        progress.Value = event.progress * 100;
        statusBadge.Text = event.message;
        drawnow;
    end

    function restoreButtons()
        if isvalid(runButton)
            runButton.Enable = "on";
            cancelButton.Enable = "off";
            cancelButton.Text = "取消";
        end
    end

    function renderResult(result, targetConfig)
        setStatus(result.status, result.status + " / " + ...
            result.outcome);
        eventTable.Data = eventsToTable(result.events);
        if ~result.success
            bestLabel.Text = "最佳结果：不可用";
            topTable.Data = table();
            renderEmpty(scoreAxes, "搜索未完整成功");
            renderEmpty(pdpAxes, "没有正式最佳候选");
            renderEmpty(dsAxes, "没有正式最佳候选");
            summaryArea.Value = cellstr([ ...
                "状态：" + result.status + " / " + result.outcome; ...
                "错误：" + strjoin(result.errors, " | "); ...
                "提示：" + strjoin(result.warnings, " | ")]);
            return;
        end

        best = result.best;
        bestLabel.Text = sprintf("最佳：%s · %.5f", ...
            best.id, best.total_score);
        topTable.Data = rankingToTable(result.ranking);
        renderScoreCurve(result.ranking);
        renderComparison(best.score);
        lines = [ ...
            "后端：" + result.manifest.backend; ...
            sprintf("候选：总计%d，成功%d，失败%d", ...
                result.total_candidates, result.succeeded_candidates, ...
                result.failed_candidates); ...
            "目标真实参数（仅Demo已知）：" + ...
                parameterText(targetConfig.model); ...
            "搜索最佳参数：" + parameterText(best.parameters); ...
            sprintf("总分 %.6f = PDP %.6f × 50%% + DS %.6f × 50%%", ...
                best.total_score, best.component_scores.pdp, ...
                best.component_scores.delay_spread); ...
            "解释：分数越小越接近，0表示在当前两项评分下完全一致。"; ...
            "边界：最佳只针对当前网格、评分和固定种子，不证明物理参数唯一。"];
        if ~isempty(result.warnings)
            lines = [lines; ""; "提示："; ...
                compose("· %s", result.warnings(:))];
        end
        summaryArea.Value = cellstr(lines(:));
    end

    function renderScoreCurve(ranking)
        successful = ranking([ranking.success]);
        [~, order] = sort([successful.index]);
        successful = successful(order);
        scores = [successful.total_score].';
        bestSoFar = cummin(scores);
        cla(scoreAxes);
        plot(scoreAxes, [successful.index], scores, "o-", ...
            "Color", [0.55, 0.62, 0.70], ...
            "DisplayName", "候选分数");
        hold(scoreAxes, "on");
        plot(scoreAxes, [successful.index], bestSoFar, "-", ...
            "Color", green, "LineWidth", 2, ...
            "DisplayName", "当前最佳");
        hold(scoreAxes, "off");
        xlabel(scoreAxes, "候选执行序号");
        ylabel(scoreAxes, "总分（越小越好）");
        legend(scoreAxes, "Location", "best");
        grid(scoreAxes, "on");
    end

    function renderComparison(score)
        features = score.features;
        cla(pdpAxes);
        plot(pdpAxes, features.pdp_centers_s * 1e9, ...
            features.target_pdp_probability, ...
            "Color", blue, "LineWidth", 1.8, ...
            "DisplayName", "目标known");
        hold(pdpAxes, "on");
        plot(pdpAxes, features.pdp_centers_s * 1e9, ...
            features.candidate_pdp_probability, "--", ...
            "Color", orange, "LineWidth", 1.8, ...
            "DisplayName", "最佳候选");
        hold(pdpAxes, "off");
        xlabel(pdpAxes, "时延 (ns)");
        ylabel(pdpAxes, "归一化概率");
        legend(pdpAxes, "Location", "best");
        grid(pdpAxes, "on");

        cla(dsAxes);
        plot(dsAxes, features.quantile_probability, ...
            features.target_delay_spread_quantile_s * 1e9, ...
            "Color", blue, "LineWidth", 1.8, ...
            "DisplayName", "目标known");
        hold(dsAxes, "on");
        plot(dsAxes, features.quantile_probability, ...
            features.candidate_delay_spread_quantile_s * 1e9, "--", ...
            "Color", orange, "LineWidth", 1.8, ...
            "DisplayName", "最佳候选");
        hold(dsAxes, "off");
        xlabel(dsAxes, "分位概率");
        ylabel(dsAxes, "RMS时延扩展 (ns)");
        legend(dsAxes, "Location", "best");
        grid(dsAxes, "on");
    end

    function setStatus(status, textValue)
        statusBadge.Text = textValue;
        switch string(status)
            case "PASS"
                statusBadge.BackgroundColor = [0.86, 0.96, 0.89];
                statusBadge.FontColor = green;
            case "WARNING"
                statusBadge.BackgroundColor = [1.00, 0.94, 0.80];
                statusBadge.FontColor = orange;
            case "FAIL"
                statusBadge.BackgroundColor = [1.00, 0.86, 0.86];
                statusBadge.FontColor = red;
            otherwise
                statusBadge.BackgroundColor = [0.91, 0.93, 0.95];
                statusBadge.FontColor = muted;
        end
    end
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

function values = parseValues(textValue)
tokens = split(replace(string(textValue), ";", ","), ",");
tokens = strtrim(tokens);
tokens = tokens(strlength(tokens) > 0);
values = str2double(tokens).';
if isempty(values) || any(~isfinite(values))
    error("step7_grid_search_demo:InvalidCandidateList", ...
        "候选列表必须是用逗号分隔的有限数字。");
end
end

function data = rankingToTable(ranking)
ranking = ranking([ranking.success]);
count = min(5, numel(ranking));
data = table('Size', [count, 5], ...
    'VariableTypes', {'double', 'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'Rank', 'Candidate', 'Total', 'PDP', 'DS'});
for index = 1:count
    data.Rank(index) = ranking(index).rank;
    data.Candidate(index) = ranking(index).id;
    data.Total(index) = ranking(index).total_score;
    data.PDP(index) = ranking(index).pdp_score;
    data.DS(index) = ranking(index).delay_spread_score;
end
end

function data = eventsToTable(events)
count = numel(events);
data = table('Size', [count, 3], ...
    'VariableTypes', {'string', 'string', 'string'}, ...
    'VariableNames', {'Phase', 'Progress', 'Message'});
for index = 1:count
    data.Phase(index) = events(index).phase;
    data.Progress(index) = sprintf("%.0f%%", ...
        100 * events(index).progress);
    data.Message(index) = events(index).message;
end
end

function value = parameterText(parameters)
names = string(fieldnames(parameters));
parts = strings(numel(names), 1);
for index = 1:numel(names)
    parts(index) = sprintf("%s=%g", names(index), ...
        parameters.(names(index)));
end
value = strjoin(parts, ", ");
end

function renderEmpty(axesHandle, message)
cla(axesHandle);
axis(axesHandle, "off");
text(axesHandle, 0.5, 0.5, message, ...
    "Units", "normalized", "HorizontalAlignment", "center", ...
    "Color", [0.55, 0.58, 0.62], "Interpreter", "none");
end

function backend = canonicalBackend(value)
value = lower(strtrim(string(value)));
switch value
    case {"mock", "test"}
        backend = "mock";
    case {"lite", "lite_6gpcm", "6gpcm-lite"}
        backend = "lite_6gpcm";
    case {"full", "full_6gpcm", "6gpcm"}
        backend = "full_6gpcm";
    otherwise
        backend = "lite_6gpcm";
end
end

function value = onOff(condition)
if condition
    value = "on";
else
    value = "off";
end
end
