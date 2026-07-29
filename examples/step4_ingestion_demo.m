function figureHandle = step4_ingestion_demo(options)
%STEP4_INGESTION_DEMO Standalone visual shell for the Step 4 core.
%   This demo is intentionally isolated from ChannelSimulatorApp. It lets a
%   reviewer choose one standard v3 HDF5 file, configure a task, and inspect
%   the validation/capability result. Formal UI integration remains Step 12.
%
%   Example:
%     step4_ingestion_demo

arguments
    options.Visible (1, 1) string = "on"
    options.InitialFile (1, 1) string = ""
    options.AutoRun (1, 1) logical = false
end

scriptPath = string(mfilename("fullpath"));
repoRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repoRoot, "core")));

figureHandle = uifigure( ...
    "Name", "ChanAI Pulse v3 - Step 4 输入体验 Demo", ...
    "Position", [80, 60, 1220, 760], ...
    "Color", [0.96, 0.97, 0.99], ...
    "Visible", options.Visible);

state = struct("file_path", "", "result", struct());

uilabel(figureHandle, ...
    "Position", [30, 710, 1160, 32], ...
    "Text", "模块一 · 信道数据输入与任务设置（独立体验 Demo）", ...
    "FontSize", 22, "FontWeight", "bold", ...
    "FontColor", [0.04, 0.20, 0.42]);
uilabel(figureHandle, ...
    "Position", [32, 680, 1140, 24], ...
    "Text", "只读取一个 v3 标准 HDF5；本 Demo 不修改正式平台界面。", ...
    "FontSize", 13, "FontColor", [0.32, 0.38, 0.47]);

inputPanel = uipanel(figureHandle, ...
    "Title", "1. 文件与任务", ...
    "Position", [25, 430, 1170, 235], ...
    "FontSize", 14, "FontWeight", "bold");

uibutton(inputPanel, "push", ...
    "Text", "选择 v3 HDF5", ...
    "Position", [20, 160, 145, 34], ...
    "ButtonPushedFcn", @chooseFile);
fileLabel = uilabel(inputPanel, ...
    "Position", [180, 160, 960, 34], ...
    "Text", "尚未选择文件", ...
    "FontColor", [0.35, 0.39, 0.45]);

uilabel(inputPanel, "Position", [20, 112, 80, 24], ...
    "Text", "任务类型");
modeDropDown = uidropdown(inputPanel, ...
    "Items", ["内插", "外推"], ...
    "ItemsData", ["interpolation", "extrapolation"], ...
    "Value", "interpolation", ...
    "Position", [100, 108, 145, 30]);

uilabel(inputPanel, "Position", [275, 112, 80, 24], ...
    "Text", "预测方向");
axisDropDown = uidropdown(inputPanel, ...
    "Items", ["样本 sample", "位置 position", ...
              "时间 time", "频率 frequency"], ...
    "ItemsData", ["sample", "position", "time", "frequency"], ...
    "Value", "sample", ...
    "Position", [355, 108, 170, 30]);

uilabel(inputPanel, "Position", [555, 112, 80, 24], ...
    "Text", "区域设置");
presetDropDown = uidropdown(inputPanel, ...
    "Items", ["80/20 快速预设", "手动索引"], ...
    "ItemsData", ["80_20", "manual"], ...
    "Value", "80_20", ...
    "Position", [635, 108, 170, 30], ...
    "ValueChangedFcn", @toggleManualInputs);

runButton = uibutton(inputPanel, "push", ...
    "Text", "运行输入流水线", ...
    "Position", [925, 106, 190, 34], ...
    "FontWeight", "bold", ...
    "BackgroundColor", [0.10, 0.40, 0.78], ...
    "FontColor", [1, 1, 1], ...
    "ButtonPushedFcn", @runPipeline);

knownLabel = uilabel(inputPanel, ...
    "Position", [20, 62, 100, 24], ...
    "Text", "已知索引");
knownField = uieditfield(inputPanel, "text", ...
    "Position", [100, 58, 425, 30], ...
    "Placeholder", "例如：1:40,61:100", ...
    "Enable", "off");
targetLabel = uilabel(inputPanel, ...
    "Position", [555, 62, 100, 24], ...
    "Text", "目标索引");
targetField = uieditfield(inputPanel, "text", ...
    "Position", [635, 58, 480, 30], ...
    "Placeholder", "例如：41:60", ...
    "Enable", "off");

statusPanel = uipanel(figureHandle, ...
    "Title", "2. 检查结果", ...
    "Position", [25, 25, 560, 385], ...
    "FontSize", 14, "FontWeight", "bold");
statusLamp = uilamp(statusPanel, ...
    "Position", [22, 326, 24, 24], ...
    "Color", [0.55, 0.58, 0.62]);
statusLabel = uilabel(statusPanel, ...
    "Position", [58, 320, 470, 34], ...
    "Text", "等待文件", ...
    "FontSize", 18, "FontWeight", "bold");
summaryArea = uitextarea(statusPanel, ...
    "Position", [20, 20, 520, 290], ...
    "Editable", "off", ...
    "FontName", "Consolas", ...
    "Value", "请选择一个标准 v3 HDF5 文件。");

capabilityPanel = uipanel(figureHandle, ...
    "Title", "3. 数据能力与任务区域", ...
    "Position", [605, 25, 590, 385], ...
    "FontSize", 14, "FontWeight", "bold");
capabilityTable = uitable(capabilityPanel, ...
    "Position", [15, 185, 255, 160], ...
    "ColumnName", ["能力", "可用"], ...
    "ColumnWidth", {170, 60}, ...
    "Data", cell(0, 2));
taskAxes = uiaxes(capabilityPanel, ...
    "Position", [285, 38, 285, 305]);
title(taskAxes, "已知区 / 目标区");
xlabel(taskAxes, "索引");
yticks(taskAxes, []);
grid(taskAxes, "on");

toggleManualInputs([], []);
if options.InitialFile ~= ""
    state.file_path = options.InitialFile;
    [~, initialName, initialExtension] = fileparts(state.file_path);
    fileLabel.Text = string(initialName) + string(initialExtension);
    fileLabel.Tooltip = state.file_path;
    if options.AutoRun
        runPipeline([], []);
    end
end

    function chooseFile(~, ~)
        [fileName, folderName] = uigetfile( ...
            {"*.h5", "ChanAI Pulse v3 HDF5 (*.h5)"}, ...
            "选择一个 v3 标准 HDF5");
        if isequal(fileName, 0)
            return;
        end
        state.file_path = string(fullfile(folderName, fileName));
        fileLabel.Text = string(fileName);
        fileLabel.Tooltip = state.file_path;
    end

    function toggleManualInputs(~, ~)
        isManual = presetDropDown.Value == "manual";
        enabled = "off";
        if isManual
            enabled = "on";
        end
        knownField.Enable = enabled;
        targetField.Enable = enabled;
        knownLabel.FontColor = colorForEnabled(isManual);
        targetLabel.FontColor = colorForEnabled(isManual);
    end

    function runPipeline(~, ~)
        if state.file_path == ""
            uialert(figureHandle, ...
                "请先选择一个 HDF5 文件。", "尚未选择文件");
            return;
        end

        taskOptions = struct( ...
            "task_mode", string(modeDropDown.Value), ...
            "task_axis", string(axisDropDown.Value), ...
            "task_preset", string(presetDropDown.Value));
        if presetDropDown.Value == "manual"
            try
                taskOptions.known_indices = parseIndexText(knownField.Value);
                taskOptions.target_indices = parseIndexText(targetField.Value);
            catch exception
                uialert(figureHandle, exception.message, "索引格式错误");
                return;
            end
        end

        runButton.Enable = "off";
        runButton.Text = "正在检查...";
        drawnow;
        cleanup = onCleanup(@() restoreRunButton());
        state.result = import_channel_dataset(state.file_path, taskOptions);
        renderResult(state.result);
        clear cleanup
    end

    function restoreRunButton()
        if isvalid(runButton)
            runButton.Enable = "on";
            runButton.Text = "运行输入流水线";
        end
    end

    function renderResult(result)
        setStatus(result.status);
        lines = strings(0, 1);
        if ~isempty(fieldnames(result.dataset))
            dimensions = result.dataset.dimensions;
            if result.dataset.domain == "ctf"
                shapeText = sprintf("%d × %d × %d × %d × %d", ...
                    dimensions.Tx, dimensions.Rx, dimensions.Nf, ...
                    dimensions.Nt, dimensions.N_sample);
            else
                shapeText = sprintf("%d × %d × %d × %d × %d", ...
                    dimensions.Tx, dimensions.Rx, dimensions.Npath, ...
                    dimensions.Nt, dimensions.N_sample);
            end
            lines(end + 1) = "数据域：" + upper(result.dataset.domain);
            lines(end + 1) = "五维尺寸：" + shapeText;
            lines(end + 1) = "分类：" + ...
                string(result.capabilities.classification);
            lines(end + 1) = "来源：" + ...
                string(result.dataset.metadata.source);
            lines(end + 1) = "";
        end
        if isfield(result.validation, "errors") && ...
                ~isempty(result.validation.errors)
            lines(end + 1) = "错误：";
            lines = [lines; "  - " + string(result.validation.errors(:))];
        end
        if isfield(result.validation, "warnings") && ...
                ~isempty(result.validation.warnings)
            lines(end + 1) = "提示：";
            lines = [lines; "  - " + string(result.validation.warnings(:))];
        end
        if result.status == "PASS"
            lines(end + 1) = "文件和任务均符合 Step 4 规则。";
        end
        summaryArea.Value = cellstr(lines);
        renderCapabilities(result.capabilities);
        renderTask(result.task);
    end

    function setStatus(status)
        switch string(status)
            case "PASS"
                statusLamp.Color = [0.12, 0.65, 0.32];
                statusLabel.Text = "PASS · 可以进入后续模块";
                statusLabel.FontColor = [0.06, 0.45, 0.20];
            case "WARNING"
                statusLamp.Color = [0.95, 0.66, 0.12];
                statusLabel.Text = "WARNING · 可以继续，但需注意提示";
                statusLabel.FontColor = [0.70, 0.42, 0.03];
            otherwise
                statusLamp.Color = [0.82, 0.18, 0.18];
                statusLabel.Text = "FAIL · 已阻止进入后续模块";
                statusLabel.FontColor = [0.65, 0.08, 0.08];
        end
    end

    function renderCapabilities(capabilities)
        if isempty(fieldnames(capabilities))
            capabilityTable.Data = cell(0, 2);
            return;
        end
        fields = [ ...
            "pdp", "frequency_autocorrelation", ...
            "delay_spread_cdf", "angular_power_spectrum", ...
            "spatial_correlation", "angular_spread_cdf", ...
            "doppler_power_spectrum", "time_autocorrelation", ...
            "doppler_spread_cdf", "delay_sample_heatmap"];
        labels = [ ...
            "PDP", "频率自相关", "时延扩展 CDF", "角度功率谱", ...
            "空间相关", "角度扩展 CDF", "多普勒功率谱", ...
            "时间自相关", "多普勒扩展 CDF", "样本-时延热力图"];
        data = cell(numel(fields), 2);
        for index = 1:numel(fields)
            data{index, 1} = char(labels(index));
            if isfield(capabilities, fields(index)) && ...
                    capabilities.(fields(index))
                data{index, 2} = '是';
            else
                data{index, 2} = '否';
            end
        end
        capabilityTable.Data = data;
    end

    function renderTask(task)
        cla(taskAxes);
        title(taskAxes, "已知区 / 目标区");
        xlabel(taskAxes, "索引");
        yticks(taskAxes, []);
        grid(taskAxes, "on");
        if isempty(fieldnames(task))
            text(taskAxes, 0.5, 0.5, "尚无有效任务", ...
                "Units", "normalized", "HorizontalAlignment", "center");
            return;
        end
        known = double(task.known_indices(:));
        target = double(task.target_indices(:));
        scatter(taskAxes, known, ones(size(known)), 34, ...
            [0.12, 0.43, 0.82], "filled", ...
            "DisplayName", "已知");
        hold(taskAxes, "on");
        scatter(taskAxes, target, ones(size(target)), 48, ...
            [0.95, 0.48, 0.10], "filled", ...
            "DisplayName", "目标");
        hold(taskAxes, "off");
        ylim(taskAxes, [0.75, 1.25]);
        legend(taskAxes, "Location", "southoutside", ...
            "Orientation", "horizontal");
    end
end

function indices = parseIndexText(value)
textValue = strtrim(string(value));
if textValue == ""
    error("step4_ingestion_demo:EmptyIndices", ...
        "手动模式下，已知索引和目标索引都不能为空。");
end
tokens = regexp(char(textValue), '[,;\s]+', 'split');
indices = zeros(0, 1);
for tokenCell = tokens
    token = string(tokenCell{1});
    if token == ""
        continue;
    end
    parts = split(token, ":");
    numbers = str2double(parts);
    if any(~isfinite(numbers)) || ~ismember(numel(numbers), [1, 2, 3])
        error("step4_ingestion_demo:InvalidIndices", ...
            "索引格式应类似 1:40,61:100，且只能使用正整数。");
    end
    if isscalar(numbers)
        expanded = numbers;
    elseif numel(numbers) == 2
        expanded = numbers(1):numbers(2);
    else
        expanded = numbers(1):numbers(2):numbers(3);
    end
    if isempty(expanded) || any(expanded < 1) || ...
            any(mod(expanded, 1) ~= 0)
        error("step4_ingestion_demo:InvalidIndices", ...
            "索引必须展开为非空的正整数序列。");
    end
    indices = [indices; expanded(:)]; %#ok<AGROW>
end
indices = unique(indices, "stable");
end

function color = colorForEnabled(isEnabled)
if isEnabled
    color = [0.12, 0.15, 0.20];
else
    color = [0.55, 0.58, 0.62];
end
end
