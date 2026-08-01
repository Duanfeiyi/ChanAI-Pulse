function figureHandle = step11_module3_demo(options)
%STEP11_MODULE3_DEMO Formal-style module-three prediction CIR demo.
%   The page runs the real Step 10 Predictor Adapter followed by the Step
%   11 prediction-generation service. It shows channel characteristics,
%   never target ground truth or accuracy plots.

arguments
    options.Visible (1, 1) string = "on"
    options.PythonExecutable (1, 1) string = "python"
    options.TaskType (1, 1) string = "extrapolation"
    options.Backend (1, 1) string = "lite_6gpcm"
    options.EngineRoot (1, 1) string = ""
    options.AutoRun (1, 1) logical = true
end

root = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(root, "core")));
addpath(genpath(fullfile(root, "app")));

blue = [0.04, 0.29, 0.56];
blue2 = [0.10, 0.43, 0.78];
orange = [0.93, 0.53, 0.09];
green = [0.08, 0.50, 0.25];
muted = [0.40, 0.44, 0.49];
border = [0.62, 0.74, 0.86];

figureHandle = uifigure( ...
    "Name", "ChanAI Pulse v3 - 模块三：信道预测", ...
    "Position", [20, 25, 1540, 920], ...
    "Color", [0.96, 0.97, 0.985], ...
    "Visible", options.Visible);
main = uigridlayout(figureHandle, [5, 1], ...
    "RowHeight", {58, 128, 235, "1x", 30}, ...
    "Padding", [10, 8, 10, 8], "RowSpacing", 8);

header = uipanel(main, "BackgroundColor", "white", ...
    "BorderColor", border);
headerGrid = uigridlayout(header, [1, 3], ...
    "ColumnWidth", {300, "1x", 430}, "Padding", [16, 5, 16, 5]);
uilabel(headerGrid, "Text", "● ChanAI Pulse", ...
    "FontName", "Microsoft YaHei UI", "FontSize", 18, ...
    "FontWeight", "bold", "FontColor", blue);
uilabel(headerGrid, "Text", "3. 信道预测", ...
    "HorizontalAlignment", "center", "FontSize", 21, ...
    "FontWeight", "bold", "FontColor", blue);
uilabel(headerGrid, ...
    "Text", "已知参数 → 模型预测 → 6GPCM → CIR/CTF → 信道特性", ...
    "HorizontalAlignment", "right", "FontColor", muted);

controls = uipanel(main, "Title", "任务与运行策略", ...
    "FontWeight", "bold", "BackgroundColor", [0.985, 0.99, 1], ...
    "BorderColor", border);
controlGrid = uigridlayout(controls, [2, 12], ...
    "RowHeight", {40, 42}, ...
    "ColumnWidth", {70, 145, 80, 160, 72, 105, 72, 140, ...
    110, "1x", 135, 145}, ...
    "Padding", [12, 10, 12, 8], "ColumnSpacing", 8);
uilabel(controlGrid, "Text", "预测任务", "HorizontalAlignment", "right");
taskDrop = uidropdown(controlGrid, ...
    "Items", ["外推：历史 → 未来", "内插：两侧 → 中间"], ...
    "ItemsData", ["extrapolation", "interpolation"], ...
    "Value", options.TaskType);
uilabel(controlGrid, "Text", "模型选择", "HorizontalAlignment", "right");
selectionDrop = uidropdown(controlGrid, ...
    "Items", ["普通用户：系统自动", "高级用户：手动选择"], ...
    "ItemsData", ["auto", "manual"], "Value", "auto", ...
    "ValueChangedFcn", @selectionChanged);
uilabel(controlGrid, "Text", "模型", "HorizontalAlignment", "right");
modelDrop = uidropdown(controlGrid, ...
    "Items", ["GRU", "LSTM", "TCN"], ...
    "ItemsData", ["gru", "lstm", "tcn"], ...
    "Value", "tcn", "Enable", "off");
uilabel(controlGrid, "Text", "已知区适配", "HorizontalAlignment", "right");
adaptDrop = uidropdown(controlGrid, ...
    "Items", ["关闭", "自动判断", "强制（高级）"], ...
    "ItemsData", ["off", "auto", "force"], "Value", "off");
backendLabel = uilabel(controlGrid, ...
    "Text", backendDisplay(options.Backend), ...
    "HorizontalAlignment", "center", ...
    "FontWeight", "bold", "FontColor", blue);
backendLabel.Layout.Column = 9;
workflow = uilabel(controlGrid, ...
    "Text", "模块二参数标定在后台复用，无需用户进入第二页操作", ...
    "FontColor", muted, "HorizontalAlignment", "center");
workflow.Layout.Column = 10;
runButton = uibutton(controlGrid, "push", ...
    "Text", "开始预测并生成 CIR", "BackgroundColor", blue, ...
    "FontColor", "white", "FontWeight", "bold", ...
    "ButtonPushedFcn", @runPipeline);
runButton.Layout.Column = 11;
statusBadge = uilabel(controlGrid, "Text", "准备就绪", ...
    "HorizontalAlignment", "center", "FontWeight", "bold", ...
    "BackgroundColor", [0.91, 0.93, 0.95], "FontColor", muted);
statusBadge.Layout.Column = 12;

stages = ["① 读取已知参数", "② 自动/手选模型", ...
    "③ 预测 DS/KF", "④ 逐目标生成 CIR"];
for index = 1:4
    badge = uilabel(controlGrid, "Text", stages(index), ...
        "HorizontalAlignment", "center", "FontWeight", "bold", ...
        "BackgroundColor", [0.92, 0.96, 1], "FontColor", blue);
    badge.Layout.Row = 2;
    badge.Layout.Column = [3 * index - 2, 3 * index];
end

middle = uigridlayout(main, [1, 3], ...
    "ColumnWidth", {"1x", "1x", 390}, ...
    "ColumnSpacing", 8, "Padding", [0, 0, 0, 0]);
dsPanel = uipanel(middle, "Title", "DS_mu：已知与预测参数", ...
    "FontWeight", "bold", "BackgroundColor", "white", ...
    "BorderColor", border);
dsAxes = uiaxes(uigridlayout(dsPanel, [1, 1], ...
    "Padding", [8, 4, 8, 8]));
kfPanel = uipanel(middle, "Title", "KF_mu：已知与预测参数", ...
    "FontWeight", "bold", "BackgroundColor", "white", ...
    "BorderColor", border);
kfAxes = uiaxes(uigridlayout(kfPanel, [1, 1], ...
    "Padding", [8, 4, 8, 8]));
summaryPanel = uipanel(middle, "Title", "本次正式结果说明", ...
    "FontWeight", "bold", "BackgroundColor", "white", ...
    "BorderColor", border);
summaryGrid = uigridlayout(summaryPanel, [7, 2], ...
    "RowHeight", repmat({25}, 1, 7), ...
    "ColumnWidth", {125, "1x"}, "Padding", [8, 6, 8, 6]);
summaryNames = ["任务", "实际模型", "推理方式", "生成后端", ...
    "CIR 维度", "合法特性图", "连续性"];
summaryValues = gobjects(numel(summaryNames), 1);
for index = 1:numel(summaryNames)
    uilabel(summaryGrid, "Text", summaryNames(index), ...
        "HorizontalAlignment", "right", "FontColor", muted);
    summaryValues(index) = uilabel(summaryGrid, "Text", "—", ...
        "FontWeight", "bold");
end

featurePanel = uipanel(main, ...
    "Title", "预测后信道特性（与模块一共用 1/3/6/9 能力规则；此处不显示准确度）", ...
    "FontWeight", "bold", "BackgroundColor", "white", ...
    "BorderColor", border);
renderWaiting();

footerGrid = uigridlayout(main, [1, 3], ...
    "ColumnWidth", {"1x", 220, 170}, "Padding", [0, 0, 0, 0]);
uilabel(footerGrid, ...
    "Text", "独立目标不会冒充连续路线：多普勒、时间相关和路线热力图会自动禁用。", ...
    "FontColor", muted, "BackgroundColor", "white", ...
    "HorizontalAlignment", "center");
exportButton = uibutton(footerGrid, "push", ...
    "Text", "导出 CIR/CTF/Manifest", "Enable", "off", ...
    "ButtonPushedFcn", @exportBundle);
uibutton(footerGrid, "push", ...
    "Text", "关闭 Demo", "ButtonPushedFcn", @(~, ~) close(figureHandle));

lastServiceResult = struct();
lastPrediction = struct();
if options.AutoRun
    drawnow;
    runPipeline();
end

    function selectionChanged(~, ~)
        modelDrop.Enable = onOff(selectionDrop.Value == "manual");
    end

    function runPipeline(varargin)
        runButton.Enable = "off";
        exportButton.Enable = "off";
        setStatus("参数预测中…", [1, 0.93, 0.75], [0.55, 0.32, 0.05]);
        drawnow;
        try
            task = string(taskDrop.Value);
            requestPath = fullfile(root, "demo_data", "v3_step10", ...
                "requests", task + "_request.json");
            registryPath = fullfile(root, "demo_data", "v3_step10", ...
                "models", task, task + "_model_registry.json");
            predictorConfig = default_predictor_adapter_config();
            predictorConfig.python_executable = options.PythonExecutable;
            predictorConfig.selection_mode = string(selectionDrop.Value);
            predictorConfig.requested_model = string(modelDrop.Value);
            predictorConfig.adaptation_mode = string(adaptDrop.Value);
            predictorConfig.device = "cpu";
            if predictorConfig.adaptation_mode ~= "off"
                predictorConfig.adaptation_data_path = fullfile(root, ...
                    "demo_data", "v3_step9", ...
                    "step9_" + task + "_standard.h5");
            end
            lastPrediction = run_predictor_request_adapter( ...
                requestPath, registryPath, predictorConfig);

            generationConfig = demoGenerationConfig(options.Backend);
            generationConfig.engine_root = options.EngineRoot;
            generationConfig.prediction_example_index = 1;
            generationRequest = create_prediction_generation_request( ...
                lastPrediction, generationConfig);
            setStatus("逐目标生成 CIR…", [1, 0.93, 0.75], ...
                [0.55, 0.32, 0.05]);
            lastServiceResult = run_prediction_generation( ...
                generationRequest, ...
                struct("progress_callback", @progressChanged));
            if ~lastServiceResult.success
                error("step11_module3_demo:GenerationFailed", ...
                    "%s", strjoin(lastServiceResult.errors, newline));
            end
            renderParameters(requestPath, lastPrediction);
            renderFeatures(lastServiceResult.prediction_result.analysis);
            updateSummary(lastServiceResult.prediction_result);
            exportButton.Enable = "on";
            setStatus("预测 CIR 已完成", [0.84, 0.95, 0.88], green);
        catch exception
            setStatus("运行失败", [1, 0.84, 0.84], [0.65, 0.10, 0.10]);
            renderWaiting("失败：" + string(exception.message));
            if options.Visible == "on"
                uialert(figureHandle, exception.message, ...
                    "Step 11 模块三");
            end
        end
        runButton.Enable = "on";
    end

    function progressChanged(event)
        setStatus(sprintf("目标 %d/%d", ...
            event.target_number, event.target_count), ...
            [1, 0.93, 0.75], [0.55, 0.32, 0.05]);
        drawnow limitrate;
    end

    function renderParameters(requestPath, prediction)
        productRequest = jsondecode(fileread(requestPath));
        context = squeeze(productRequest.input_parameters(1, :, :));
        inputIndex = squeeze( ...
            productRequest.input_parameter_sample_index(1, :));
        predicted = squeeze(prediction.prediction_parameters(1, :, :));
        targetIndex = squeeze( ...
            prediction.target_parameter_sample_index(1, :));
        renderParameter(dsAxes, inputIndex, context(:, 1), ...
            targetIndex, predicted(:, 1), blue2, orange, "log10(s)");
        renderParameter(kfAxes, inputIndex, context(:, 2), ...
            targetIndex, predicted(:, 2), blue2, orange, "dB");
    end

    function renderFeatures(analysis)
        delete(featurePanel.Children);
        entries = select_channel_plot_entries(analysis.registry);
        plotCount = numel(entries);
        columns = min(3, max(1, plotCount));
        rows = max(1, ceil(plotCount / columns));
        gridLayout = uigridlayout(featurePanel, [rows, columns], ...
            "Padding", [8, 5, 8, 8], ...
            "RowSpacing", 7, "ColumnSpacing", 7);
        if plotCount == 0
            uilabel(gridLayout, ...
                "Text", "当前预测 CIR 没有可合法展示的特性图", ...
                "HorizontalAlignment", "center", "FontColor", muted);
            return;
        end
        for entry = entries.'
            axesHandle = uiaxes(gridLayout);
            render_channel_characteristic( ...
                axesHandle, analysis, entry.id);
        end
    end

    function renderWaiting(message)
        if nargin == 0
            message = "等待真实 Predictor Adapter 和生成器输出";
        end
        delete(featurePanel.Children);
        gridLayout = uigridlayout(featurePanel, [1, 1]);
        uilabel(gridLayout, "Text", message, ...
            "HorizontalAlignment", "center", ...
            "FontSize", 15, "FontWeight", "bold", "FontColor", muted);
    end

    function updateSummary(result)
        summaryValues(1).Text = taskChinese(result.task_type);
        summaryValues(2).Text = upper(string( ...
            result.prediction_manifest.selection.selected_model));
        if logical(result.prediction_manifest.adaptation.accepted)
            summaryValues(3).Text = "ADAPTED";
        else
            summaryValues(3).Text = "DIRECT";
        end
        summaryValues(4).Text = backendDisplay( ...
            result.generator_manifest.backend);
        dims = result.dimensions.cir_actual;
        summaryValues(5).Text = sprintf("%d×%d×%d×%d×%d", ...
            dims.Tx, dims.Rx, dims.Npath, dims.Nt, dims.N_sample);
        registry = result.analysis.registry;
        summaryValues(6).Text = sprintf("%d 张", ...
            registry.available_standard_plot_count + ...
            registry.available_additional_plot_count);
        summaryValues(7).Text = "独立目标（已限制跨点图）";
    end

    function exportBundle(~, ~)
        target = uigetdir(pwd, "选择 Step 11 导出目录");
        if isequal(target, 0)
            return;
        end
        files = export_prediction_result_bundle( ...
            lastServiceResult.prediction_result, string(target));
        screenshot = fullfile(target, "module3_prediction_page.png");
        exportapp(figureHandle, screenshot);
        uialert(figureHandle, ...
            "已导出：" + newline + files.cir_hdf5 + newline + screenshot, ...
            "导出完成", "Icon", "success");
    end

    function setStatus(textValue, background, foreground)
        statusBadge.Text = textValue;
        statusBadge.BackgroundColor = background;
        statusBadge.FontColor = foreground;
    end
end

function config = demoGenerationConfig(backend)
config = default_prediction_generation_config(backend);
switch string(config.backend)
    case "lite_6gpcm"
        config.dimensions.Nt = 1;
        config.dimensions.Nf = 64;
    case "mock"
        config.dimensions.Nt = 4;
        config.dimensions.Nf = 64;
    case "full_6gpcm"
        config.mode = "formal";
        config.dimensions.Nf = 64;
end
config.ctf.frequency_hz = linspace( ...
    config.scenario.center_frequency_hz - ...
    config.scenario.bandwidth_hz / 2, ...
    config.scenario.center_frequency_hz + ...
    config.scenario.bandwidth_hz / 2, ...
    config.dimensions.Nf).';
end

function renderParameter(ax, inputX, inputY, outputX, outputY, ...
        blue, orange, unit)
cla(ax);
hold(ax, "on");
plot(ax, inputX, inputY, "-o", ...
    "Color", blue, "MarkerFaceColor", blue, ...
    "LineWidth", 1.5, "MarkerSize", 4, "DisplayName", "已知参数");
plot(ax, outputX, outputY, "-s", ...
    "Color", orange, "MarkerFaceColor", orange, ...
    "LineWidth", 2.0, "MarkerSize", 6, "DisplayName", "模型预测");
hold(ax, "off");
grid(ax, "on");
box(ax, "on");
xlabel(ax, "参数样本索引");
ylabel(ax, unit);
legend(ax, "Location", "best");
ax.FontName = "Microsoft YaHei UI";
end

function value = taskChinese(task)
if string(task) == "interpolation"
    value = "内插";
else
    value = "外推";
end
end

function value = backendDisplay(backend)
switch string(backend)
    case "mock"
        value = "Mock（仅测试）";
    case "lite_6gpcm"
        value = "Lite 预览";
    otherwise
        value = "Full 6GPCM 正式";
end
end

function value = onOff(condition)
if condition
    value = "on";
else
    value = "off";
end
end
