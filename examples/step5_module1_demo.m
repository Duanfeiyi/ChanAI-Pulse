function figureHandle = step5_module1_demo(options)
%STEP5_MODULE1_DEMO High-fidelity standalone preview of v3 module one.
%   This demo calls the real Step 4 input pipeline and Step 5
%   characteristics engine. It does not modify ChannelSimulatorApp.

arguments
    options.Visible (1, 1) string = "on"
    options.InitialFile (1, 1) string = ""
    options.AutoRun (1, 1) logical = false
end

root = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(root, "core")));
addpath(genpath(fullfile(root, "app")));

blue = [0.04, 0.29, 0.56];
lightBlue = [0.94, 0.97, 1.00];
borderBlue = [0.55, 0.70, 0.86];
textDark = [0.12, 0.15, 0.19];
muted = [0.42, 0.46, 0.51];
panelBackground = [0.985, 0.99, 1.00];

figureHandle = uifigure( ...
    "Name", "ChanAI Pulse — 模块一：信道数据与特性（Step 5 Demo）", ...
    "Position", [30, 35, 1510, 900], ...
    "Color", [0.96, 0.97, 0.985], ...
    "Visible", options.Visible);

mainGrid = uigridlayout(figureHandle, [4, 1], ...
    "RowHeight", {50, 222, "1x", 28}, ...
    "Padding", [10, 8, 10, 8], ...
    "RowSpacing", 8);

%% Header
headerPanel = uipanel(mainGrid, ...
    "BackgroundColor", [1, 1, 1], ...
    "BorderColor", borderBlue);
headerPanel.Layout.Row = 1;
headerGrid = uigridlayout(headerPanel, [1, 3], ...
    "ColumnWidth", {190, "1x", 280}, ...
    "Padding", [16, 4, 16, 4]);
uilabel(headerGrid, "Text", "〽  ChanAI Pulse", ...
    "FontName", "Microsoft YaHei UI", "FontSize", 18, ...
    "FontWeight", "bold", "FontColor", blue);
pageTitle = uilabel(headerGrid, ...
    "Text", "1. 信道数据与特性", ...
    "HorizontalAlignment", "center", ...
    "FontName", "Microsoft YaHei UI", "FontSize", 18, ...
    "FontWeight", "bold", "FontColor", blue);
pageTitle.Layout.Column = 2;
uilabel(headerGrid, ...
    "Text", "Step 5 独立功能体验 · 未接入模块二/三", ...
    "HorizontalAlignment", "right", ...
    "FontName", "Microsoft YaHei UI", "FontSize", 11, ...
    "FontColor", muted);

%% Import, task, summary and capabilities
controlPanel = uipanel(mainGrid, ...
    "Title", "数据导入、任务设置与能力识别", ...
    "FontName", "Microsoft YaHei UI", ...
    "FontWeight", "bold", ...
    "BackgroundColor", panelBackground, ...
    "BorderColor", borderBlue);
controlPanel.Layout.Row = 2;
controlGrid = uigridlayout(controlPanel, [4, 12], ...
    "RowHeight", {36, 36, 52, 36}, ...
    "ColumnWidth", {72, 110, "1x", 88, 122, 72, 112, ...
    72, 118, 82, 120, 160}, ...
    "Padding", [12, 8, 12, 8], ...
    "RowSpacing", 7, "ColumnSpacing", 8);

fileButton = uibutton(controlGrid, "push", ...
    "Text", "浏览文件", "ButtonPushedFcn", @browseFile, ...
    "FontName", "Microsoft YaHei UI");
fileButton.Layout.Row = 1;
fileButton.Layout.Column = [1, 2];
fileLabel = uilabel(controlGrid, ...
    "Text", "尚未选择 v3 HDF5", ...
    "BackgroundColor", [1, 1, 1], ...
    "FontName", "Consolas", "FontColor", muted);
fileLabel.Layout.Row = 1;
fileLabel.Layout.Column = [3, 7];
runButton = uibutton(controlGrid, "push", ...
    "Text", "▶  加载、验证并分析", ...
    "BackgroundColor", blue, "FontColor", [1, 1, 1], ...
    "FontWeight", "bold", ...
    "FontName", "Microsoft YaHei UI", ...
    "ButtonPushedFcn", @runAnalysis);
runButton.Layout.Row = 1;
runButton.Layout.Column = [8, 9];
exportButton = uibutton(controlGrid, "push", ...
    "Text", "导出结果", ...
    "Enable", "off", ...
    "FontName", "Microsoft YaHei UI", ...
    "ButtonPushedFcn", @exportAnalysis);
exportButton.Layout.Row = 1;
exportButton.Layout.Column = 10;
statusBadge = uilabel(controlGrid, ...
    "Text", "等待数据", ...
    "HorizontalAlignment", "center", ...
    "BackgroundColor", [0.91, 0.93, 0.95], ...
    "FontWeight", "bold", "FontName", "Microsoft YaHei UI", ...
    "FontColor", muted);
statusBadge.Layout.Row = 1;
statusBadge.Layout.Column = [11, 12];

uilabel(controlGrid, "Text", "任务", ...
    "HorizontalAlignment", "right", "FontColor", textDark);
modeDropDown = uidropdown(controlGrid, ...
    "Items", ["内插", "外推"], ...
    "ItemsData", ["interpolation", "extrapolation"], ...
    "Value", "interpolation");
uilabel(controlGrid, "Text", "任务轴", ...
    "HorizontalAlignment", "right", "FontColor", textDark);
axisDropDown = uidropdown(controlGrid, ...
    "Items", ["样本", "位置", "时间", "频率"], ...
    "ItemsData", ["sample", "position", "time", "frequency"], ...
    "Value", "sample");
uilabel(controlGrid, "Text", "划分", ...
    "HorizontalAlignment", "right", "FontColor", textDark);
presetDropDown = uidropdown(controlGrid, ...
    "Items", ["80/20 快速预设", "手动索引"], ...
    "ItemsData", ["80_20", "manual"], ...
    "Value", "80_20", ...
    "ValueChangedFcn", @toggleManualFields);
uilabel(controlGrid, "Text", "已知(1起)", ...
    "HorizontalAlignment", "right", "FontColor", muted);
knownField = uieditfield(controlGrid, "text", ...
    "Value", "1:16,21:32", "Enable", "off");
uilabel(controlGrid, "Text", "目标(1起)", ...
    "HorizontalAlignment", "right", "FontColor", muted);
targetField = uieditfield(controlGrid, "text", ...
    "Value", "17:20", "Enable", "off");

summaryNames = ["数据域", "五维尺寸", "天线配置", ...
    "信道分类", "分析样本", "数据来源"];
summaryValues = repmat(gobjects(1), 1, 6);
for cardIndex = 1:6
    card = uipanel(controlGrid, ...
        "BackgroundColor", [1, 1, 1], ...
        "BorderColor", borderBlue);
    card.Layout.Row = 3;
    card.Layout.Column = [2 * cardIndex - 1, 2 * cardIndex];
    cardGrid = uigridlayout(card, [2, 1], ...
        "RowHeight", {18, 24}, "Padding", [4, 2, 4, 2], ...
        "RowSpacing", 0);
    uilabel(cardGrid, "Text", summaryNames(cardIndex), ...
        "HorizontalAlignment", "center", ...
        "FontName", "Microsoft YaHei UI", ...
        "FontSize", 9, "FontColor", muted);
    summaryValues(cardIndex) = uilabel(cardGrid, "Text", "—", ...
        "HorizontalAlignment", "center", ...
        "FontName", "Microsoft YaHei UI", ...
        "FontWeight", "bold", "FontColor", textDark);
end

capabilityTitle = uilabel(controlGrid, ...
    "Text", "能力标签", "FontWeight", "bold", ...
    "FontColor", textDark, "HorizontalAlignment", "right");
capabilityTitle.Layout.Row = 4;
capabilityTitle.Layout.Column = 1;
capabilityLabel = uilabel(controlGrid, ...
    "Text", "加载数据后自动生成，不依据文件名猜测", ...
    "BackgroundColor", lightBlue, ...
    "FontColor", blue, ...
    "FontName", "Microsoft YaHei UI");
capabilityLabel.Layout.Row = 4;
capabilityLabel.Layout.Column = [2, 12];

%% Plot workspace and quality panel
bodyGrid = uigridlayout(mainGrid, [1, 2], ...
    "ColumnWidth", {"1x", 345}, ...
    "ColumnSpacing", 8, "Padding", [0, 0, 0, 0]);
bodyGrid.Layout.Row = 3;

plotPanel = uipanel(bodyGrid, ...
    "Title", "可信信道特性 · 2×2 主视图（下拉框可切换全部合法图表）", ...
    "FontName", "Microsoft YaHei UI", ...
    "FontWeight", "bold", ...
    "BackgroundColor", [1, 1, 1], ...
    "BorderColor", borderBlue);
plotPanel.Layout.Column = 1;
plotGrid = uigridlayout(plotPanel, [4, 2], ...
    "RowHeight", {30, "1x", 30, "1x"}, ...
    "Padding", [8, 5, 8, 8], ...
    "RowSpacing", 4, "ColumnSpacing", 8);

plotDrops = gobjects(4, 1);
plotAxes = gobjects(4, 1);
for initialSlot = 1:4
    dropRow = 1 + 2 * floor((initialSlot - 1) / 2);
    column = 1 + mod(initialSlot - 1, 2);
    plotDrops(initialSlot) = uidropdown(plotGrid, ...
        "Items", "暂无合法图表", ...
        "ItemsData", "none", ...
        "Value", "none", ...
        "Enable", "off", ...
        "FontName", "Microsoft YaHei UI", ...
        "ValueChangedFcn", @plotSelectionChanged);
    plotDrops(initialSlot).Layout.Row = dropRow;
    plotDrops(initialSlot).Layout.Column = column;
    plotAxes(initialSlot) = uiaxes(plotGrid);
    plotAxes(initialSlot).Layout.Row = dropRow + 1;
    plotAxes(initialSlot).Layout.Column = column;
    plotAxes(initialSlot).Color = [0.99, 0.995, 1];
    plotAxes(initialSlot).FontName = "Microsoft YaHei UI";
    renderEmptyAxes(plotAxes(initialSlot), "等待信道分析");
end

detailsPanel = uipanel(bodyGrid, ...
    "Title", "数据质量与图表能力", ...
    "FontName", "Microsoft YaHei UI", ...
    "FontWeight", "bold", ...
    "BackgroundColor", [1, 1, 1], ...
    "BorderColor", borderBlue);
detailsPanel.Layout.Column = 2;
tabGroup = uitabgroup(detailsPanel, ...
    "Position", [8, 8, 326, 505]);
qualityTab = uitab(tabGroup, "Title", "数据质量");
qualityText = uitextarea(qualityTab, ...
    "Position", [8, 8, 302, 460], ...
    "Editable", "off", ...
    "FontName", "Microsoft YaHei UI", ...
    "Value", ["等待数据。"; ...
    "平台不会用占位图制造功能真实性。"]);
capabilityTab = uitab(tabGroup, "Title", "图表能力");
capabilityTable = uitable(capabilityTab, ...
    "Position", [5, 5, 307, 463], ...
    "ColumnName", {"图表", "可用", "说明"}, ...
    "ColumnWidth", {96, 42, 155}, ...
    "RowName", []);

%% Status bar
statusBar = uilabel(mainGrid, ...
    "Text", "Step 5 Demo 已就绪｜请选择 v3 标准 HDF5", ...
    "BackgroundColor", [1, 1, 1], ...
    "FontName", "Microsoft YaHei UI", ...
    "FontColor", muted);
statusBar.Layout.Row = 4;

state = struct("file", "", "input", struct(), ...
    "analysis", struct());

if options.InitialFile ~= ""
    setSelectedFile(options.InitialFile);
    if options.AutoRun
        drawnow;
        runAnalysis([], []);
    end
end

    function browseFile(~, ~)
        [name, folder] = uigetfile( ...
            {"*.h5;*.hdf5", "v3 HDF5 信道文件 (*.h5, *.hdf5)"});
        if isequal(name, 0)
            return;
        end
        setSelectedFile(string(fullfile(folder, name)));
    end

    function setSelectedFile(filePath)
        state.file = string(filePath);
        [~, name, extension] = fileparts(state.file);
        fileLabel.Text = name + extension;
        fileLabel.Tooltip = state.file;
        statusBar.Text = "已选择：" + name + extension + ...
            "｜等待加载、验证并分析";
    end

    function toggleManualFields(~, ~)
        manual = presetDropDown.Value == "manual";
        if manual
            enabled = "on";
        else
            enabled = "off";
        end
        knownField.Enable = enabled;
        targetField.Enable = enabled;
    end

    function runAnalysis(~, ~)
        if state.file == "" || ~isfile(state.file)
            setStatus("FAIL", "请选择存在的 v3 HDF5 文件。");
            return;
        end
        runButton.Enable = "off";
        runButton.Text = "正在计算…";
        drawnow;
        cleanup = onCleanup(@() restoreRunButtonState(runButton));
        taskOptions = struct( ...
            "task_mode", modeDropDown.Value, ...
            "task_axis", axisDropDown.Value, ...
            "task_preset", presetDropDown.Value);
        if presetDropDown.Value == "manual"
            try
                taskOptions.known_indices = parseIndexText(knownField.Value);
                taskOptions.target_indices = parseIndexText(targetField.Value);
            catch exception
                setStatus("FAIL", string(exception.message));
                return;
            end
        end
        state.input = import_channel_dataset(state.file, taskOptions);
        if state.input.status == "FAIL"
            setStatus("FAIL", "输入检查未通过");
            updateFailureDetails(state.input.validation);
            clearAnalysisDisplay();
            return;
        end
        state.analysis = analyze_channel_characteristics( ...
            state.input.dataset, Task=state.input.task, ...
            Region="known", ModuleRole="input");
        if state.analysis.status == "FAIL"
            setStatus("FAIL", "特性计算失败");
            updateFailureDetails(state.analysis);
            clearAnalysisDisplay();
            return;
        end
        updateSummary();
        updateDetails();
        updatePlotSelectors();
        exportButton.Enable = "on";
        registry = state.analysis.registry;
        if registry.is_standard_classification
            completionMessage = sprintf( ...
                "模块一分析完成：%d/%d 类标准图，附加图 %d", ...
                registry.available_standard_plot_count, ...
                registry.ideal_standard_plot_count, ...
                registry.available_additional_plot_count);
        else
            visibleEntries = select_channel_plot_entries(registry);
            completionMessage = sprintf( ...
                "模块一分析完成：非四类标准组合，共 %d 张合法图", ...
                numel(visibleEntries));
        end
        setStatus(state.analysis.status, ...
            completionMessage);
        clear cleanup
        restoreRunButtonState(runButton);
    end

    function exportAnalysis(~, ~)
        if isempty(fieldnames(state.analysis))
            setStatus("FAIL", "尚无可导出的 Step 5 分析结果。");
            return;
        end
        [name, folder] = uiputfile("*.mat", ...
            "导出 Step 5 信道特性结果", "step5_characteristics.mat");
        if isequal(name, 0)
            return;
        end
        outputPath = fullfile(folder, name);
        if isfile(outputPath)
            choice = uiconfirm(figureHandle, ...
                "目标文件已存在，是否覆盖这个导出文件？原始 HDF5 不受影响。", ...
                "确认覆盖导出结果", ...
                "Options", ["取消", "覆盖"], ...
                "DefaultOption", "取消", ...
                "CancelOption", "取消");
            if choice ~= "覆盖"
                return;
            end
        end
        exportBundle = create_step5_export_bundle( ...
            state.analysis, state.input.task);
        save(outputPath, "exportBundle", "-v7.3");
        setStatus(state.analysis.status, ...
            "Step 5 结果已导出：" + string(name) + ...
            "｜原始 HDF5 未修改");
    end

    function updateSummary()
        summary = state.analysis.dataset_summary;
        summaryValues(1).Text = summary.domain;
        if summary.domain == "CIR"
            third = summary.Npath;
        else
            third = summary.Nf;
        end
        summaryValues(2).Text = sprintf("%d×%d×%d×%d×%d", ...
            summary.Tx, summary.Rx, third, summary.Nt, summary.N_sample);
        summaryValues(3).Text = sprintf("%d Tx / %d Rx", ...
            summary.Tx, summary.Rx);
        summaryValues(4).Text = classificationZh( ...
            state.analysis.classification);
        summaryValues(5).Text = sprintf("%d（已知区）", ...
            state.analysis.selection.selected_length);
        source = string(summary.source);
        if strlength(source) > 23
            source = extractBefore(source, 21) + "…";
        end
        summaryValues(6).Text = source;

        tags = strings(0, 1);
        tags(end + 1) = "复数信道";
        if state.analysis.metrics.pdp.available
            tags(end + 1) = "宽带/多径";
        end
        if state.analysis.metrics.spatial_correlation.available
            tags(end + 1) = "MIMO/空间";
        end
        if state.analysis.metrics.doppler_power_spectrum.available
            tags(end + 1) = "连续时间";
        end
        if state.analysis.metrics.angular_power_spectrum.available
            tags(end + 1) = "可信角度";
        end
        if state.analysis.metrics.delay_sample_heatmap.available
            tags(end + 1) = "有序样本";
        end
        registry = state.analysis.registry;
        if registry.is_standard_classification
            tags(end + 1) = sprintf("标准图 %d/%d", ...
                registry.available_standard_plot_count, ...
                registry.ideal_standard_plot_count);
        else
            tags(end + 1) = sprintf("非标准组合·合法图 %d", ...
                numel(select_channel_plot_entries(registry)));
        end
        capabilityLabel.Text = "  " + strjoin("✓ " + tags, "    ");
    end

    function updateDetails()
        analysis = state.analysis;
        lines = [
            "总体状态：" + analysis.status
            "数据合同：" + analysis.validation.status
            "识别类型：" + classificationZh(analysis.classification)
            "分析区域：仅 known_indices（目标区隔离）"
            "已知数量：" + analysis.selection.selected_length
            "频率网格：" + yesNo(analysis.dataset_summary.has_frequency_grid)
            "时延网格：" + yesNo(analysis.dataset_summary.has_delay_grid)
            "均匀时间：" + yesNo(analysis.dataset_summary.has_uniform_time)
            "有序样本：" + yesNo(analysis.dataset_summary.ordered_samples)
            ""
            "计算原则："
            "• 不猜测缺失物理坐标"
            "• 不生成占位图"
            "• CDF 使用经验分布"
            "• 多普勒横轴使用 Hz"
            "• 相同引擎供模块一/三复用"
            ];
        if ~isempty(analysis.warnings)
            lines = [lines; ""; "提示："; "• " + analysis.warnings];
        end
        qualityText.Value = cellstr(lines);

        entries = analysis.registry.entries;
        tableData = cell(numel(entries), 3);
        for entryIndex = 1:numel(entries)
            tableData{entryIndex, 1} = ...
                char(entries(entryIndex).title_zh);
            if entries(entryIndex).available
                tableData{entryIndex, 2} = char("✓");
                tableData{entryIndex, 3} = char("可计算");
            else
                tableData{entryIndex, 2} = char("—");
                tableData{entryIndex, 3} = char( ...
                    shortReason(entries(entryIndex).reason));
            end
        end
        capabilityTable.Data = tableData;
    end

    function updatePlotSelectors()
        available = select_channel_plot_entries( ...
            state.analysis.registry);
        titles = string({available.title_zh});
        ids = string({available.id});
        for selectorSlot = 1:4
            if isempty(available)
                plotDrops(selectorSlot).Items = "暂无合法图表";
                plotDrops(selectorSlot).ItemsData = "none";
                plotDrops(selectorSlot).Value = "none";
                plotDrops(selectorSlot).Enable = "off";
                renderEmptyAxes(plotAxes(selectorSlot), ...
                    "当前数据没有可用图表");
            else
                plotDrops(selectorSlot).Items = titles;
                plotDrops(selectorSlot).ItemsData = ids;
                plotDrops(selectorSlot).Enable = "on";
                selectedIndex = min(selectorSlot, numel(ids));
                plotDrops(selectorSlot).Value = ids(selectedIndex);
                renderSlot(selectorSlot);
                if selectorSlot > numel(ids)
                    plotDrops(selectorSlot).Enable = "off";
                    renderEmptyAxes(plotAxes(selectorSlot), ...
                        sprintf("当前数据共有 %d 个合法图表", numel(ids)));
                end
            end
        end
    end

    function plotSelectionChanged(source, ~)
        selectedSlot = find(plotDrops == source, 1);
        if ~isempty(selectedSlot)
            renderSlot(selectedSlot);
        end
    end

    function renderSlot(slot)
        if isempty(fieldnames(state.analysis)) || ...
                plotDrops(slot).Value == "none"
            renderEmptyAxes(plotAxes(slot), "等待信道分析");
            return;
        end
        render_channel_characteristic(plotAxes(slot), ...
            state.analysis, string(plotDrops(slot).Value));
    end

    function clearAnalysisDisplay()
        for summaryIndex = 1:6
            summaryValues(summaryIndex).Text = "—";
        end
        capabilityLabel.Text = "输入未通过，未生成能力标签";
        exportButton.Enable = "off";
        for clearSlot = 1:4
            plotDrops(clearSlot).Enable = "off";
            renderEmptyAxes(plotAxes(clearSlot), "输入未通过");
        end
        capabilityTable.Data = {};
    end

    function updateFailureDetails(report)
        lines = ["输入或分析未通过。"; ""];
        if isfield(report, "errors") && ~isempty(report.errors)
            lines = [lines; "错误："; "• " + string(report.errors)];
        end
        if isfield(report, "warnings") && ~isempty(report.warnings)
            lines = [lines; ""; "提示："; ...
                "• " + string(report.warnings)];
        end
        qualityText.Value = cellstr(lines);
    end

    function setStatus(status, message)
        status = string(status);
        switch status
            case "PASS"
                statusBadge.Text = "✓ PASS";
                statusBadge.BackgroundColor = [0.88, 0.97, 0.90];
                statusBadge.FontColor = [0.05, 0.45, 0.18];
            case "WARNING"
                statusBadge.Text = "⚠ WARNING";
                statusBadge.BackgroundColor = [1.00, 0.96, 0.82];
                statusBadge.FontColor = [0.65, 0.40, 0.02];
            otherwise
                statusBadge.Text = "✕ FAIL";
                statusBadge.BackgroundColor = [1.00, 0.89, 0.88];
                statusBadge.FontColor = [0.70, 0.12, 0.10];
        end
        statusBar.Text = message;
    end
end

function indices = parseIndexText(value)
textValue = strtrim(string(value));
if textValue == ""
    error("step5_module1_demo:EmptyIndices", ...
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
        error("step5_module1_demo:InvalidIndices", ...
            "索引格式应类似 1:40,61:100，并且只能使用正整数。");
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
        error("step5_module1_demo:InvalidIndices", ...
            "索引必须展开为非空的正整数序列。");
    end
    indices = [indices; expanded(:)]; %#ok<AGROW>
end
indices = unique(indices, "stable");
end

function renderEmptyAxes(axesHandle, message)
cla(axesHandle, "reset");
axis(axesHandle, "off");
text(axesHandle, 0.5, 0.5, message, ...
    "Units", "normalized", ...
    "HorizontalAlignment", "center", ...
    "FontName", "Microsoft YaHei UI", ...
    "FontSize", 11, "Color", [0.45, 0.48, 0.52]);
end

function textValue = classificationZh(classification)
switch string(classification)
    case "narrowband_static_siso"
        textValue = "窄带静态 SISO";
    case "wideband_static_siso"
        textValue = "宽带静态 SISO";
    case "wideband_static_mimo"
        textValue = "宽带静态 MIMO";
    case "wideband_dynamic_mimo"
        textValue = "宽带动态 MIMO";
    case "dynamic_channel"
        textValue = "动态信道";
    otherwise
        textValue = "其他信道";
end
end

function value = yesNo(condition)
if condition
    value = "✓ 是";
else
    value = "— 否";
end
end

function value = shortReason(reason)
value = string(reason);
if strlength(value) > 30
    value = extractBefore(value, 28) + "…";
end
end

function restoreRunButtonState(button)
if isvalid(button)
    button.Enable = "on";
    button.Text = "▶  加载、验证并分析";
end
end
