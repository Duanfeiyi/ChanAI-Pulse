function figureHandle = step10_module3_demo(options)
%STEP10_MODULE3_DEMO Reusable formal-page skeleton for prediction module.
%   This page calls the real Step 10 parameter Predictor Adapter. It does
%   not display ground truth or accuracy. CIR and channel-characteristic
%   plots stay disabled until Step 11.

arguments
    options.Visible (1, 1) string = "on"
    options.PythonExecutable (1, 1) string = "python"
    options.TaskType (1, 1) string = "extrapolation"
    options.AutoRun (1, 1) logical = true
end

root = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(root, "core")));

blue = [0.04, 0.29, 0.56];
blue2 = [0.12, 0.42, 0.76];
lightBlue = [0.93, 0.97, 1.00];
borderBlue = [0.55, 0.70, 0.86];
textDark = [0.12, 0.15, 0.19];
muted = [0.42, 0.46, 0.51];
green = [0.08, 0.50, 0.25];
orange = [0.93, 0.53, 0.09];

figureHandle = uifigure( ...
    "Name", "ChanAI Pulse v3 - 模块三：信道预测", ...
    "Position", [25, 30, 1530, 900], ...
    "Color", [0.96, 0.97, 0.985], ...
    "Visible", options.Visible);
main = uigridlayout(figureHandle, [4, 1], ...
    "RowHeight", {56, 168, "1x", 30}, ...
    "Padding", [10, 8, 10, 8], "RowSpacing", 8);

header = uipanel(main, "BackgroundColor", "white", "BorderColor", borderBlue);
headerGrid = uigridlayout(header, [1, 3], ...
    "ColumnWidth", {250, "1x", 360}, "Padding", [16, 5, 16, 5]);
uilabel(headerGrid, "Text", "◉  ChanAI Pulse", ...
    "FontName", "Microsoft YaHei UI", "FontSize", 18, ...
    "FontWeight", "bold", "FontColor", blue);
uilabel(headerGrid, "Text", "3. 信道预测", ...
    "HorizontalAlignment", "center", ...
    "FontName", "Microsoft YaHei UI", "FontSize", 20, ...
    "FontWeight", "bold", "FontColor", blue);
uilabel(headerGrid, "Text", "Step 10：真实参数预测 · Step 11：生成预测 CIR", ...
    "HorizontalAlignment", "right", "FontName", "Microsoft YaHei UI", ...
    "FontColor", muted);

controls = uipanel(main, "Title", "任务与预测策略", ...
    "FontName", "Microsoft YaHei UI", "FontWeight", "bold", ...
    "BackgroundColor", [0.985, 0.99, 1], "BorderColor", borderBlue);
controlGrid = uigridlayout(controls, [3, 12], ...
    "RowHeight", {35, 42, 38}, ...
    "ColumnWidth", {78, 145, 86, 170, 86, 140, 86, 140, ...
    "1x", 145, 125, 145}, ...
    "Padding", [12, 8, 12, 8], "RowSpacing", 6, "ColumnSpacing", 8);

uilabel(controlGrid, "Text", "预测任务", "HorizontalAlignment", "right");
taskDrop = uidropdown(controlGrid, ...
    "Items", ["外推：历史16→未来4", "内插：左8+右8→中间4"], ...
    "ItemsData", ["extrapolation", "interpolation"], ...
    "Value", options.TaskType, "ValueChangedFcn", @taskChanged);
uilabel(controlGrid, "Text", "使用方式", "HorizontalAlignment", "right");
modeDrop = uidropdown(controlGrid, ...
    "Items", ["普通用户：系统自动", "高级用户：手动选择"], ...
    "ItemsData", ["auto", "manual"], ...
    "Value", "auto", "ValueChangedFcn", @modeChanged);
uilabel(controlGrid, "Text", "预测模型", "HorizontalAlignment", "right");
modelDrop = uidropdown(controlGrid, ...
    "Items", ["GRU", "LSTM", "TCN"], ...
    "ItemsData", ["gru", "lstm", "tcn"], ...
    "Value", "tcn", "Enable", "off");
uilabel(controlGrid, "Text", "本次适配", "HorizontalAlignment", "right");
adaptDrop = uidropdown(controlGrid, ...
    "Items", ["关闭（直接使用）", "自动（验证后接受/回滚）"], ...
    "ItemsData", ["off", "auto"], "Value", "off");
runButton = uibutton(controlGrid, "push", ...
    "Text", "开始参数预测", "BackgroundColor", blue, ...
    "FontColor", "white", "FontWeight", "bold", ...
    "ButtonPushedFcn", @runPrediction);
runButton.Layout.Column = [10, 11];
statusBadge = uilabel(controlGrid, "Text", "准备就绪", ...
    "HorizontalAlignment", "center", "FontWeight", "bold", ...
    "BackgroundColor", [0.91, 0.93, 0.95], "FontColor", muted);
statusBadge.Layout.Column = 12;

workflowNames = ["① 已知参数输入", "② Predictor Adapter", ...
    "③ 预测参数输出", "④ 生成预测 CIR"];
for index = 1:4
    badge = uilabel(controlGrid, "Text", workflowNames(index), ...
        "HorizontalAlignment", "center", "FontWeight", "bold", ...
        "FontName", "Microsoft YaHei UI");
    badge.Layout.Row = 2;
    badge.Layout.Column = [3 * index - 2, 3 * index];
    if index <= 3
        badge.BackgroundColor = lightBlue;
        badge.FontColor = blue;
    else
        badge.BackgroundColor = [0.93, 0.93, 0.93];
        badge.FontColor = muted;
        badge.Text = workflowNames(index) + "（Step 11）";
    end
end
selectionText = uilabel(controlGrid, ...
    "Text", "普通模式只读取离线验证阶段冻结的 ModelRegistry，不读取本次目标真值。", ...
    "BackgroundColor", [1, 1, 1], "FontColor", muted);
selectionText.Layout.Row = 3;
selectionText.Layout.Column = [1, 9];
exportButton = uibutton(controlGrid, "push", ...
    "Text", "导出预测参数 JSON", "Enable", "off", ...
    "ButtonPushedFcn", @exportPrediction);
exportButton.Layout.Row = 3;
exportButton.Layout.Column = [10, 11];
cirButton = uibutton(controlGrid, "push", ...
    "Text", "导出 CIR（Step 11）", "Enable", "off");
cirButton.Layout.Row = 3;
cirButton.Layout.Column = 12;

body = uigridlayout(main, [1, 2], ...
    "ColumnWidth", {"1x", 440}, "ColumnSpacing", 8, ...
    "Padding", [0, 0, 0, 0]);
parameterPanel = uipanel(body, ...
    "Title", "预测后的信道参数（产品界面不展示 Ground Truth 或准确度）", ...
    "FontWeight", "bold", "BackgroundColor", "white", ...
    "BorderColor", borderBlue);
parameterGrid = uigridlayout(parameterPanel, [2, 1], ...
    "RowHeight", {"1x", "1x"}, "Padding", [10, 8, 10, 8]);
dsAxes = uiaxes(parameterGrid);
kfAxes = uiaxes(parameterGrid);
styleAxes(dsAxes, "DS_mu：时延扩展参数", "log10(s)");
styleAxes(kfAxes, "KF_mu：K 因子参数", "dB");

side = uigridlayout(body, [3, 1], ...
    "RowHeight", {205, 125, "1x"}, "RowSpacing", 8, ...
    "Padding", [0, 0, 0, 0]);
summaryPanel = uipanel(side, "Title", "本次运行状态", ...
    "FontWeight", "bold", "BackgroundColor", "white", ...
    "BorderColor", borderBlue);
summaryGrid = uigridlayout(summaryPanel, [5, 2], ...
    "RowHeight", {26, 26, 26, 26, 26}, ...
    "ColumnWidth", {140, "1x"}, "Padding", [10, 6, 10, 6]);
summaryLabels = ["任务", "实际使用模型", "模型选择依据", "微调/适配状态", "输出张量"];
summaryValues = gobjects(5, 1);
for index = 1:5
    uilabel(summaryGrid, "Text", summaryLabels(index), ...
        "FontColor", muted, "HorizontalAlignment", "right");
    summaryValues(index) = uilabel(summaryGrid, "Text", "—", ...
        "FontWeight", "bold", "FontColor", textDark);
end

notice = uipanel(side, "Title", "边界说明", ...
    "FontWeight", "bold", "BackgroundColor", [1, 0.985, 0.94], ...
    "BorderColor", [0.92, 0.72, 0.35]);
noticeGrid = uigridlayout(notice, [2, 1], ...
    "RowHeight", {42, 38}, "Padding", [10, 6, 10, 6]);
uilabel(noticeGrid, ...
    "Text", "当前已经预测 DS_mu / KF_mu；尚未生成 CIR 或 H 矩阵。", ...
    "FontWeight", "bold", "FontColor", [0.55, 0.32, 0.05]);
uilabel(noticeGrid, ...
    "Text", "Step 11 接入 6GPCM 后，才会按数据维度启用 1 / 3 / 6 / 9 张信道特性图。", ...
    "FontColor", [0.55, 0.32, 0.05]);

futurePanel = uipanel(side, "Title", "信道特性视图 · 等待 Step 11", ...
    "FontWeight", "bold", "BackgroundColor", [0.97, 0.97, 0.97], ...
    "BorderColor", [0.75, 0.75, 0.75]);
futureGrid = uigridlayout(futurePanel, [2, 2], ...
    "Padding", [8, 8, 8, 8], "RowSpacing", 8, "ColumnSpacing", 8);
futureNames = ["CIR / CTF", "PDP / 频率相关", ...
    "角度功率谱 / 空间相关", "多普勒谱 / 时间相关"];
for index = 1:4
    card = uipanel(futureGrid, "BackgroundColor", [0.94, 0.94, 0.94], ...
        "BorderColor", [0.78, 0.78, 0.78]);
    cardGrid = uigridlayout(card, [2, 1], ...
        "RowHeight", {"1x", 28}, "Padding", [6, 6, 6, 6]);
    placeholder = uiaxes(cardGrid);
    placeholder.XTick = [];
    placeholder.YTick = [];
    placeholder.Color = [0.92, 0.92, 0.92];
    placeholder.Box = "on";
    text(placeholder, 0.5, 0.5, "尚未生成预测 CIR", ...
        "HorizontalAlignment", "center", "Color", muted, ...
        "FontName", "Microsoft YaHei UI");
    placeholder.XLim = [0, 1];
    placeholder.YLim = [0, 1];
    uilabel(cardGrid, "Text", futureNames(index), ...
        "HorizontalAlignment", "center", "FontColor", muted, ...
        "FontWeight", "bold");
end

uilabel(main, ...
    "Text", "Step 10 Demo 使用真实 Predictor Adapter；准确度比较只存在于软件外部测试报告，不进入正式模块三界面。", ...
    "BackgroundColor", "white", "FontColor", muted, ...
    "HorizontalAlignment", "center");

lastResult = struct();
lastOutputPath = "";
if options.AutoRun
    drawnow;
    runPrediction();
end

    function taskChanged(~, ~)
        statusBadge.Text = "任务已切换";
        statusBadge.BackgroundColor = [0.91, 0.93, 0.95];
        statusBadge.FontColor = muted;
    end

    function modeChanged(~, ~)
        if string(modeDrop.Value) == "manual"
            modelDrop.Enable = "on";
            selectionText.Text = ...
                "高级模式尊重用户选择；若模型与任务/形状不兼容，系统明确拒绝，不会偷偷换模型。";
        else
            modelDrop.Enable = "off";
            selectionText.Text = ...
                "普通模式只读取离线验证阶段冻结的 ModelRegistry，不读取本次目标真值。";
        end
    end

    function runPrediction(varargin)
        statusBadge.Text = "预测中…";
        statusBadge.BackgroundColor = [1, 0.93, 0.75];
        statusBadge.FontColor = [0.55, 0.32, 0.05];
        runButton.Enable = "off";
        drawnow;
        try
            task = string(taskDrop.Value);
            requestPath = fullfile(root, "demo_data", "v3_step10", ...
                "requests", task + "_request.json");
            registryPath = fullfile(root, "demo_data", "v3_step10", ...
                "models", task, task + "_model_registry.json");
            config = default_predictor_adapter_config();
            config.python_executable = options.PythonExecutable;
            config.selection_mode = string(modeDrop.Value);
            config.requested_model = string(modelDrop.Value);
            config.adaptation_mode = string(adaptDrop.Value);
            if config.adaptation_mode ~= "off"
                config.adaptation_data_path = fullfile(root, ...
                    "demo_data", "v3_step9", ...
                    "step9_" + task + "_standard.h5");
            end
            config.device = "cpu";
            lastOutputPath = string(tempname) + ".json";
            config.output_path = lastOutputPath;
            lastResult = run_predictor_request_adapter( ...
                requestPath, registryPath, config);
            request = jsondecode(fileread(requestPath));
            renderParameters(request, lastResult);
            updateSummary(lastResult);
            exportButton.Enable = "on";
            statusBadge.Text = "参数预测完成";
            statusBadge.BackgroundColor = [0.84, 0.95, 0.88];
            statusBadge.FontColor = green;
        catch exception
            statusBadge.Text = "预测失败";
            statusBadge.BackgroundColor = [1, 0.84, 0.84];
            statusBadge.FontColor = [0.65, 0.10, 0.10];
            uialert(figureHandle, exception.message, "Predictor Adapter");
        end
        runButton.Enable = "on";
    end

    function renderParameters(request, result)
        context = squeeze(request.input_parameters(1, :, :));
        inputIndex = squeeze(request.input_parameter_sample_index(1, :));
        predictionIndex = double( ...
            result.target_parameter_sample_index(1, :));
        prediction = squeeze(result.prediction_parameters(1, :, :));
        renderOne(dsAxes, inputIndex, context(:, 1), ...
            predictionIndex, prediction(:, 1), blue2, orange);
        renderOne(kfAxes, inputIndex, context(:, 2), ...
            predictionIndex, prediction(:, 2), blue2, orange);
    end

    function updateSummary(result)
        summaryValues(1).Text = taskChinese(string(result.task_type));
        summaryValues(2).Text = upper(string(result.selection.selected_model));
        if string(result.selection.mode) == "auto"
            summaryValues(3).Text = "离线验证集自动冻结";
        else
            summaryValues(3).Text = "高级用户手动选择";
        end
        summaryValues(4).Text = string(result.adaptation.status);
        shape = double(result.prediction_shape(:));
        summaryValues(5).Text = sprintf("[%d, %d, %d]", shape);
    end

    function exportPrediction(~, ~)
        [file, path] = uiputfile("*.json", "导出预测参数", ...
            "predicted_channel_parameters.json");
        if isequal(file, 0)
            return;
        end
        copyfile(lastOutputPath, fullfile(path, file));
    end
end

function styleAxes(axesHandle, titleText, unitText)
axesHandle.Title.String = titleText;
axesHandle.Title.FontWeight = "bold";
axesHandle.FontName = "Microsoft YaHei UI";
axesHandle.Box = "on";
axesHandle.GridAlpha = 0.15;
grid(axesHandle, "on");
xlabel(axesHandle, "参数样本索引");
ylabel(axesHandle, unitText);
end

function renderOne(axesHandle, inputX, inputY, predictionX, predictionY, blue, orange)
cla(axesHandle);
hold(axesHandle, "on");
plot(axesHandle, inputX, inputY, "-o", ...
    "Color", blue, "MarkerFaceColor", blue, ...
    "LineWidth", 1.6, "MarkerSize", 4, "DisplayName", "已知参数");
plot(axesHandle, predictionX, predictionY, "-s", ...
    "Color", orange, "MarkerFaceColor", orange, ...
    "LineWidth", 2.2, "MarkerSize", 6, "DisplayName", "模型预测");
legend(axesHandle, "Location", "best");
hold(axesHandle, "off");
end

function value = taskChinese(task)
if task == "interpolation"
    value = "内插";
else
    value = "外推";
end
end
