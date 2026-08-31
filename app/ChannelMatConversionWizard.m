classdef ChannelMatConversionWizard < handle
    %CHANNELMATCONVERSIONWIZARD Formal, source-preserving MAT import wizard.

    properties (SetAccess = private)
        UIFigure matlab.ui.Figure
    end

    properties (Access = private)
        RootPath string
        CurrentLanguage string = "zh"
        SourcePath string = ""
        OutputPath string = ""
        Inspection struct = struct()
        LastResult struct = struct()
        OnConverted = []
        Localized = cell(0, 4)

        LanguageDropDown
        TabGroup
        SourceTab
        MappingTab
        ConvertTab
        SourceField
        InspectionStatus
        VariableTable
        AdapterLabel
        RepresentationDropDown
        DomainDropDown
        ComplexDropDown
        RealDropDown
        ImagDropDown
        DimensionOrderField
        DelayDropDown
        FrequencyDropDown
        TimeDropDown
        SampleDropDown
        PositionDropDown
        DelayUnitDropDown
        FrequencyUnitDropDown
        TimeUnitDropDown
        PositionUnitDropDown
        DelaySpacingField
        CenterFrequencyField
        SubcarrierSpacingField
        SnapshotIntervalField
        SemanticsDropDown
        ConfirmCheckBox
        MappingStatus
        OutputField
        ProgressBar struct = struct()
        ProgressDetail
        ConvertButton
    end

    methods
        function app = ChannelMatConversionWizard(options)
            arguments
                options.RootPath (1, 1) string = ""
                options.Language (1, 1) string = "zh"
                options.SourcePath (1, 1) string = ""
                options.OnConverted = []
                options.Visible (1, 1) string = "on"
            end
            if options.RootPath == ""
                options.RootPath = string(fileparts(fileparts(mfilename("fullpath"))));
            end
            app.RootPath = options.RootPath;
            app.CurrentLanguage = normalizeLanguage(options.Language);
            app.OnConverted = options.OnConverted;
            app.createComponents();
            app.applyLanguage();
            app.UIFigure.Visible = options.Visible;
            if options.SourcePath ~= ""
                app.inspectSource(options.SourcePath);
            end
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end

        function report = inspectSource(app, sourcePath)
            %INSPECTSOURCE Public hook used by UI and repeatable smoke tests.
            app.SourcePath = string(sourcePath);
            app.SourceField.Value = app.SourcePath;
            app.setProgress(0.08, "running", ...
                app.text("正在只读检查源数据…", "Inspecting source metadata…"));
            drawnow;
            try
                report = inspect_mat_channel_source(app.SourcePath);
                app.Inspection = report;
                app.populateInspection(report);
                app.OutputPath = defaultOutputPath(app.SourcePath);
                app.OutputField.Value = app.OutputPath;
                if report.is_convertible
                    app.setProgress(0.20, "success", ...
                        app.text("检查完成；请确认映射。", ...
                        "Inspection complete; confirm the mapping."));
                else
                    app.setProgress(0, "error", ...
                        app.text("该数据暂不能转换。", ...
                        "This source is not convertible."));
                end
            catch exception
                report = struct("status", "FAIL", "is_convertible", false, ...
                    "errors", string(exception.message), "warnings", strings(0, 1));
                app.Inspection = report;
                app.InspectionStatus.Value = string(exception.message);
                app.ConvertButton.Enable = "off";
                app.setProgress(0, "error", string(exception.message));
            end
        end

        function result = convertCurrent(app)
            %CONVERTCURRENT Convert with the currently visible explicit mapping.
            if isempty(fieldnames(app.Inspection))
                error("ChannelMatConversionWizard:InspectFirst", ...
                    "Inspect a source before conversion.");
            end
            if ~isfield(app.Inspection, "is_convertible") || ...
                    ~app.Inspection.is_convertible
                error("ChannelMatConversionWizard:NotConvertible", ...
                    "The inspected source is not convertible.");
            end
            mapping = app.collectMapping();
            if isfield(app.Inspection, "requires_mapping") && ...
                    app.Inspection.requires_mapping && ~mapping.advanced_mapping_confirmed
                error("ChannelMatConversionWizard:MappingNotConfirmed", ...
                    "Confirm the advanced dimension mapping before conversion.");
            end
            outputPath = strtrim(string(app.OutputField.Value));
            if outputPath == ""
                error("ChannelMatConversionWizard:MissingOutput", ...
                    "Choose a new output H5 path.");
            end
            app.OutputPath = outputPath;
            app.ConvertButton.Enable = "off";
            app.setProgress(0.02, "running", ...
                app.text("正在准备转换…", "Preparing conversion…"));
            drawnow;
            cleanup = onCleanup(@() app.enableConvert());
            try
                result = convert_channel_source_to_v3( ...
                    app.SourcePath, outputPath, mapping, ...
                    ProgressCallback=@app.conversionProgress);
                app.LastResult = result;
                app.setProgress(1, "success", app.text( ...
                    "转换成功：已生成标准 H5，原文件未改动。", ...
                    "Conversion complete: standard H5 created; source unchanged."));
                app.MappingStatus.Value = app.text([ ...
                    "转换成功"; "输出：" + outputPath; ...
                    "Manifest：" + string(result.manifest_file)], [ ...
                    "Conversion succeeded"; "Output: " + outputPath; ...
                    "Manifest: " + string(result.manifest_file)]);
                if ~isempty(app.OnConverted)
                    app.OnConverted(outputPath, result);
                end
            catch exception
                app.setProgress(get_filled_progress_value(app.ProgressBar), ...
                    "error", string(exception.message));
                app.MappingStatus.Value = string(exception.message);
                rethrow(exception);
            end
            clear cleanup
        end

        function state = getReviewState(app)
            state = struct( ...
                "source_path", app.SourcePath, ...
                "output_path", string(app.OutputField.Value), ...
                "language", app.CurrentLanguage, ...
                "inspection", app.Inspection, ...
                "has_result", ~isempty(fieldnames(app.LastResult)), ...
                "progress", get_filled_progress_value(app.ProgressBar));
        end
    end

    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure("Name", "ChanAI Pulse · MAT Conversion Wizard", ...
                "Position", [160, 80, 1120, 760], "Visible", "off", ...
                "Color", [0.96, 0.975, 0.99], ...
                "CloseRequestFcn", @(~, ~) delete(app));
            root = uigridlayout(app.UIFigure, [3, 1], ...
                "RowHeight", {52, "1x", 30}, "Padding", [12, 10, 12, 10]);
            header = uigridlayout(root, [1, 3], ...
                "ColumnWidth", {"1x", 90, 155}, "Padding", [8, 4, 8, 4]);
            titleLabel = uilabel(header, "Text", "MAT 数据转换向导", ...
                "FontSize", 21, "FontWeight", "bold", ...
                "FontColor", [0.03, 0.28, 0.55]);
            app.register(titleLabel, "Text", "MAT 数据转换向导", ...
                "MAT Data Conversion Wizard");
            languageLabel = uilabel(header, "Text", "语言", ...
                "HorizontalAlignment", "right");
            app.register(languageLabel, "Text", "语言", "Language");
            app.LanguageDropDown = uidropdown(header, ...
                "Items", ["中文", "English"], "ItemsData", ["zh", "en"], ...
                "Value", app.CurrentLanguage, ...
                "ValueChangedFcn", @(~, ~) app.changeLanguage());

            app.TabGroup = uitabgroup(root);
            app.SourceTab = uitab(app.TabGroup, "Title", "1. 检查源数据");
            app.MappingTab = uitab(app.TabGroup, "Title", "2. 确认数据映射");
            app.ConvertTab = uitab(app.TabGroup, "Title", "3. 另存并转换");
            app.register(app.SourceTab, "Title", "1. 检查源数据", "1. Inspect Source");
            app.register(app.MappingTab, "Title", "2. 确认数据映射", "2. Confirm Mapping");
            app.register(app.ConvertTab, "Title", "3. 另存并转换", "3. Save & Convert");
            app.createSourceTab();
            app.createMappingTab();
            app.createConvertTab();
            note = uilabel(root, "Text", ...
                "原则：只读源文件、禁止覆盖、模糊维度必须由用户确认。", ...
                "HorizontalAlignment", "center", "FontColor", [0.35, 0.40, 0.47]);
            app.register(note, "Text", ...
                "原则：只读源文件、禁止覆盖、模糊维度必须由用户确认。", ...
                "Policy: source is read-only, overwrite is forbidden, ambiguous dimensions require confirmation.");
        end

        function createSourceTab(app)
            grid = uigridlayout(app.SourceTab, [5, 3], ...
                "RowHeight", {28, 36, 100, "1x", 36}, ...
                "ColumnWidth", {130, "1x", 165}, "Padding", [16, 14, 16, 14]);
            label = uilabel(grid, "Text", "源文件或文件夹");
            app.register(label, "Text", "源文件或文件夹", "Source file or folder");
            app.SourceField = uieditfield(grid, "text", "Editable", "off");
            app.SourceField.Layout.Column = 2;
            inspectButton = uibutton(grid, "push", "Text", "重新检查", ...
                "ButtonPushedFcn", @(~, ~) app.inspectField());
            inspectButton.Layout.Column = 3;
            app.register(inspectButton, "Text", "重新检查", "Inspect again");
            fileButton = uibutton(grid, "push", "Text", "选择 MAT/H5 文件…", ...
                "ButtonPushedFcn", @(~, ~) app.browseFile());
            fileButton.Layout.Row = 2; fileButton.Layout.Column = 2;
            app.register(fileButton, "Text", "选择 MAT/H5 文件…", "Choose MAT/H5 file…");
            folderButton = uibutton(grid, "push", "Text", "选择 SAGE 文件夹…", ...
                "ButtonPushedFcn", @(~, ~) app.browseFolder());
            folderButton.Layout.Row = 2; folderButton.Layout.Column = 3;
            app.register(folderButton, "Text", "选择 SAGE 文件夹…", "Choose SAGE folder…");
            app.InspectionStatus = uitextarea(grid, "Editable", "off", ...
                "Value", "请选择源数据；软件只读取元数据，不会修改原文件。", ...
                "BackgroundColor", [0.97, 0.985, 1]);
            app.register(app.InspectionStatus, "Value", ...
                "请选择源数据；软件只读取元数据，不会修改原文件。", ...
                "Choose a source. Only metadata is read; the source is never modified.");
            app.InspectionStatus.Layout.Row = 3;
            app.InspectionStatus.Layout.Column = [1, 3];
            app.VariableTable = uitable(grid, ...
                "ColumnName", {"变量", "尺寸", "类型", "复数", "建议角色"}, ...
                "ColumnWidth", {180, 180, 100, 70, "auto"});
            app.VariableTable.Layout.Row = 4;
            app.VariableTable.Layout.Column = [1, 3];
            next = uibutton(grid, "push", "Text", "下一步：确认映射 →", ...
                "ButtonPushedFcn", @(~, ~) app.selectTab(app.MappingTab));
            next.Layout.Row = 5; next.Layout.Column = [2, 3];
            app.register(next, "Text", "下一步：确认映射 →", "Next: confirm mapping →");
        end

        function createMappingTab(app)
            grid = uigridlayout(app.MappingTab, [17, 4], ...
                "RowHeight", repmat({30}, 1, 17), ...
                "ColumnWidth", {170, "1x", 170, "1x"}, ...
                "Padding", [18, 12, 18, 12], "RowSpacing", 5);
            app.AdapterLabel = uilabel(grid, "Text", "适配器：等待检查", ...
                "FontWeight", "bold", "FontColor", [0.03, 0.28, 0.55]);
            app.AdapterLabel.Layout.Column = [1, 4];
            app.register(app.AdapterLabel, "Text", "适配器：等待检查", "Adapter: awaiting inspection");
            [app.RepresentationDropDown, ~] = app.addDropDownRow(grid, 2, 1, ...
                "复数表示", "Complex representation", ["单个复数变量", "实部 + 虚部变量"], ...
                ["complex", "pair"]);
            [app.DomainDropDown, ~] = app.addDropDownRow(grid, 2, 3, ...
                "数据域", "Channel domain", ["CIR（时延域）", "CTF（频域）"], ["cir", "ctf"]);
            [app.ComplexDropDown, ~] = app.addVariableRow(grid, 3, 1, "复数变量", "Complex variable");
            [app.RealDropDown, ~] = app.addVariableRow(grid, 4, 1, "实部变量", "Real variable");
            [app.ImagDropDown, ~] = app.addVariableRow(grid, 4, 3, "虚部变量", "Imaginary variable");
            orderLabel = uilabel(grid, "Text", "源维度顺序"); orderLabel.Layout.Row = 5;
            app.register(orderLabel, "Text", "源维度顺序", "Source dimension order");
            app.DimensionOrderField = uieditfield(grid, "text", ...
                "Placeholder", "例如 Tx,Rx,Npath,Nt,N_sample");
            app.register(app.DimensionOrderField, "Placeholder", ...
                "例如 Tx,Rx,Npath,Nt,N_sample", ...
                "e.g. Tx,Rx,Npath,Nt,N_sample");
            app.DimensionOrderField.Layout.Row = 5; app.DimensionOrderField.Layout.Column = [2, 4];
            [app.DelayDropDown, ~] = app.addVariableRow(grid, 6, 1, "时延轴变量", "Delay-axis variable");
            [app.FrequencyDropDown, ~] = app.addVariableRow(grid, 6, 3, "频率轴变量", "Frequency-axis variable");
            [app.TimeDropDown, ~] = app.addVariableRow(grid, 7, 1, "时间轴变量", "Time-axis variable");
            [app.SampleDropDown, ~] = app.addVariableRow(grid, 7, 3, "样本编号变量", "Sample-index variable");
            [app.PositionDropDown, ~] = app.addVariableRow(grid, 8, 1, "位置变量", "Position variable");
            [app.DelayUnitDropDown, ~] = app.addDropDownRow(grid, 9, 1, "时延单位", "Delay unit", ...
                ["s", "ms", "us", "ns"], ["s", "ms", "us", "ns"]);
            [app.FrequencyUnitDropDown, ~] = app.addDropDownRow(grid, 9, 3, "频率单位", "Frequency unit", ...
                ["Hz", "kHz", "MHz", "GHz"], ["Hz", "kHz", "MHz", "GHz"]);
            [app.TimeUnitDropDown, ~] = app.addDropDownRow(grid, 10, 1, "时间单位", "Time unit", ...
                ["s", "ms", "us", "ns"], ["s", "ms", "us", "ns"]);
            [app.PositionUnitDropDown, ~] = app.addDropDownRow(grid, 10, 3, "位置单位", "Position unit", ...
                ["m", "cm", "mm", "km"], ["m", "cm", "mm", "km"]);
            [app.DelaySpacingField, ~] = app.addNumericRow(grid, 11, 1, ...
                "时延间隔（秒）", "Delay-bin spacing (s)");
            [app.CenterFrequencyField, ~] = app.addNumericRow(grid, 11, 3, ...
                "中心频率（Hz）", "Center frequency (Hz)");
            [app.SubcarrierSpacingField, ~] = app.addNumericRow(grid, 12, 1, ...
                "子载波间隔（Hz）", "Subcarrier spacing (Hz)");
            [app.SnapshotIntervalField, ~] = app.addNumericRow(grid, 12, 3, ...
                "快拍间隔（秒）", "Snapshot interval (s)");
            [app.SemanticsDropDown, ~] = app.addDropDownRow(grid, 13, 1, ...
                "样本语义", "Sample semantics", ...
                ["独立样本", "有序路线", "时间序列"], ...
                ["independent", "ordered_route", "time_series"]);
            app.SemanticsDropDown.Layout.Column = [2, 4];
            app.ConfirmCheckBox = uicheckbox(grid, ...
                "Text", "我已确认模糊数据的变量、维度顺序和单位映射", "Value", false);
            app.ConfirmCheckBox.Layout.Row = 14; app.ConfirmCheckBox.Layout.Column = [1, 4];
            app.register(app.ConfirmCheckBox, "Text", ...
                "我已确认模糊数据的变量、维度顺序和单位映射", ...
                "I confirm the variable, dimension-order, and unit mapping for ambiguous data");
            validateButton = uibutton(grid, "push", "Text", "验证当前映射", ...
                "ButtonPushedFcn", @(~, ~) app.validateVisibleMapping());
            validateButton.Layout.Row = 15; validateButton.Layout.Column = [1, 2];
            app.register(validateButton, "Text", "验证当前映射", "Validate current mapping");
            next = uibutton(grid, "push", "Text", "下一步：选择输出 →", ...
                "ButtonPushedFcn", @(~, ~) app.selectTab(app.ConvertTab));
            next.Layout.Row = 15; next.Layout.Column = [3, 4];
            app.register(next, "Text", "下一步：选择输出 →", "Next: choose output →");
            app.MappingStatus = uitextarea(grid, "Editable", "off", ...
                "Value", "检查源数据后会自动填写高置信度项目。", ...
                "BackgroundColor", [0.97, 0.985, 1]);
            app.register(app.MappingStatus, "Value", ...
                "检查源数据后会自动填写高置信度项目。", ...
                "High-confidence fields are filled after source inspection.");
            app.MappingStatus.Layout.Row = [16, 17]; app.MappingStatus.Layout.Column = [1, 4];
            app.RepresentationDropDown.ValueChangedFcn = @(~, ~) app.updateRepresentationControls();
        end

        function createConvertTab(app)
            grid = uigridlayout(app.ConvertTab, [8, 3], ...
                "RowHeight", {28, 36, 28, 42, 110, 40, "1x", 36}, ...
                "ColumnWidth", {150, "1x", 170}, "Padding", [18, 18, 18, 18]);
            label = uilabel(grid, "Text", "新 H5 输出位置");
            app.register(label, "Text", "新 H5 输出位置", "New H5 output path");
            app.OutputField = uieditfield(grid, "text"); app.OutputField.Layout.Column = 2;
            browse = uibutton(grid, "push", "Text", "选择另存位置…", ...
                "ButtonPushedFcn", @(~, ~) app.browseOutput());
            browse.Layout.Column = 3;
            app.register(browse, "Text", "选择另存位置…", "Choose save location…");
            warning = uilabel(grid, "Text", ...
                "不会覆盖源 MAT，也不会覆盖已存在的 H5 或 Manifest。", ...
                "FontColor", [0.70, 0.30, 0.05]);
            warning.Layout.Row = 2; warning.Layout.Column = [1, 3];
            app.register(warning, "Text", ...
                "不会覆盖源 MAT，也不会覆盖已存在的 H5 或 Manifest。", ...
                "The source MAT and existing H5/Manifest files will never be overwritten.");
            progressLabel = uilabel(grid, "Text", "转换进度", "FontWeight", "bold");
            progressLabel.Layout.Row = 3; progressLabel.Layout.Column = [1, 3];
            app.register(progressLabel, "Text", "转换进度", "Conversion progress");
            app.ProgressBar = create_filled_progress_bar(grid, Value=0, Text="0%", ShowText=true);
            app.ProgressBar.Track.Layout.Row = 4; app.ProgressBar.Track.Layout.Column = [1, 3];
            app.ProgressDetail = uitextarea(grid, "Editable", "off", ...
                "Value", "等待转换。", "BackgroundColor", [0.97, 0.985, 1]);
            app.register(app.ProgressDetail, "Value", "等待转换。", "Waiting for conversion.");
            app.ProgressDetail.Layout.Row = 5; app.ProgressDetail.Layout.Column = [1, 3];
            app.ConvertButton = uibutton(grid, "push", ...
                "Text", "转换为标准 v3 H5 并自动加载", ...
                "Enable", "off", ...
                "BackgroundColor", [0.03, 0.34, 0.64], ...
                "FontColor", "white", "FontWeight", "bold", ...
                "ButtonPushedFcn", @(~, ~) app.convertFromButton());
            app.ConvertButton.Layout.Row = 6; app.ConvertButton.Layout.Column = [1, 3];
            app.register(app.ConvertButton, "Text", ...
                "转换为标准 v3 H5 并自动加载", ...
                "Convert to standard v3 H5 and load automatically");
            notes = uitextarea(grid, "Editable", "off", "Value", [ ...
                "转换输出包含：标准 CIR/CTF、物理轴、元数据、校验结果与独立 Manifest。"; ...
                "缺少可选物理轴时会降级图表能力，不会伪造物理时间或位置。"; ...
                "只有功率而没有相位的数据不能恢复成完整复数信道。"]);
            app.register(notes, "Value", [ ...
                "转换输出包含：标准 CIR/CTF、物理轴、元数据、校验结果与独立 Manifest。"; ...
                "缺少可选物理轴时会降级图表能力，不会伪造物理时间或位置。"; ...
                "只有功率而没有相位的数据不能恢复成完整复数信道。"], [ ...
                "Output contains standard CIR/CTF, physical axes, metadata, validation, and a Manifest."; ...
                "Missing optional axes reduce plot capability; physical time or position is never fabricated."; ...
                "Power without phase cannot be restored as a complete complex channel."]);
            notes.Layout.Row = 7; notes.Layout.Column = [1, 3];
            back = uibutton(grid, "push", "Text", "← 返回检查映射", ...
                "ButtonPushedFcn", @(~, ~) app.selectTab(app.MappingTab));
            back.Layout.Row = 8; back.Layout.Column = [1, 3];
            app.register(back, "Text", "← 返回检查映射", "← Back to mapping");
        end

        function [control, label] = addVariableRow(app, grid, row, column, zh, en)
            label = uilabel(grid, "Text", zh); label.Layout.Row = row; label.Layout.Column = column;
            app.register(label, "Text", zh, en);
            control = uidropdown(grid, "Items", "（无）", "ItemsData", "");
            control.Layout.Row = row; control.Layout.Column = column + 1;
        end

        function [control, label] = addDropDownRow(app, grid, row, column, zh, en, items, data)
            label = uilabel(grid, "Text", zh); label.Layout.Row = row; label.Layout.Column = column;
            app.register(label, "Text", zh, en);
            control = uidropdown(grid, "Items", items, "ItemsData", data, "Value", data(1));
            control.Layout.Row = row; control.Layout.Column = column + 1;
        end

        function [control, label] = addNumericRow(app, grid, row, column, zh, en)
            label = uilabel(grid, "Text", zh); label.Layout.Row = row; label.Layout.Column = column;
            app.register(label, "Text", zh, en);
            control = uieditfield(grid, "text", "Value", "", ...
                "Placeholder", "可选；留空表示未知");
            app.register(control, "Placeholder", ...
                "可选；留空表示未知", "Optional; leave blank if unknown");
            control.Layout.Row = row; control.Layout.Column = column + 1;
        end

        function browseFile(app)
            [name, folder] = uigetfile({"*.mat;*.h5;*.hdf5", ...
                "MAT/HDF5 (*.mat, *.h5, *.hdf5)"}, ...
                app.text("选择信道源文件", "Choose channel source file"));
            if isequal(name, 0), return; end
            app.inspectSource(string(fullfile(folder, name)));
        end

        function browseFolder(app)
            folder = uigetdir(pwd, app.text("选择 SAGE 数据文件夹", "Choose SAGE data folder"));
            if isequal(folder, 0), return; end
            app.inspectSource(string(folder));
        end

        function inspectField(app)
            source = strtrim(string(app.SourceField.Value));
            if source == "", return; end
            app.inspectSource(source);
        end

        function browseOutput(app)
            suggested = string(app.OutputField.Value);
            if suggested == "", suggested = "converted_channel_v3.h5"; end
            [folder, name, extension] = fileparts(suggested);
            if folder == "", folder = pwd; end
            [selected, selectedFolder] = uiputfile({"*.h5", "v3 HDF5 (*.h5)"}, ...
                app.text("另存标准 v3 H5", "Save standard v3 H5"), ...
                fullfile(folder, name + extension));
            if isequal(selected, 0), return; end
            app.OutputField.Value = string(fullfile(selectedFolder, selected));
        end

        function populateInspection(app, report)
            warningText = string(report.warnings(:));
            errorText = string(report.errors(:));
            app.InspectionStatus.Value = [ ...
                "Status: " + string(report.status); ...
                "Source kind: " + string(report.source_kind); ...
                "MAT version: " + string(report.mat_version); ...
                warningText; errorText];
            if isfield(report, "variables") && ~isempty(report.variables)
                count = numel(report.variables);
                data = cell(count, 5);
                for index = 1:count
                    variable = report.variables(index);
                    data{index, 1} = char(variable.name);
                    data{index, 2} = char(join(string(variable.size), " × "));
                    data{index, 3} = char(variable.class);
                    data{index, 4} = logical(variable.is_complex);
                    data{index, 5} = char(variable.role);
                end
                app.VariableTable.Data = data;
            else
                app.VariableTable.Data = cell(0, 5);
            end
            app.populateMapping(report.suggested_mapping, report);
            app.ConvertButton.Enable = onOff(report.is_convertible);
            app.TabGroup.SelectedTab = app.SourceTab;
        end

        function populateMapping(app, mapping, report)
            app.AdapterLabel.Text = app.text( ...
                "适配器：" + string(mapping.adapter) + "；来源：" + string(report.source_kind), ...
                "Adapter: " + string(mapping.adapter) + "; source: " + string(report.source_kind));
            names = strings(0, 1);
            if isfield(report, "variables") && ~isempty(report.variables)
                names = string({report.variables.name}).';
            end
            variableControls = {app.ComplexDropDown, app.RealDropDown, app.ImagDropDown, ...
                app.DelayDropDown, app.FrequencyDropDown, app.TimeDropDown, ...
                app.SampleDropDown, app.PositionDropDown};
            values = [string(mapping.complex_variable), string(mapping.real_variable), ...
                string(mapping.imag_variable), string(mapping.delay_variable), ...
                string(mapping.frequency_variable), string(mapping.time_variable), ...
                string(mapping.sample_index_variable), string(mapping.position_variable)];
            for index = 1:numel(variableControls)
                setVariableItems(variableControls{index}, names, values(index), app.CurrentLanguage);
            end
            if string(mapping.complex_variable) ~= ""
                app.RepresentationDropDown.Value = "complex";
            elseif string(mapping.real_variable) ~= "" || string(mapping.imag_variable) ~= ""
                app.RepresentationDropDown.Value = "pair";
            end
            if ismember(string(mapping.domain), ["cir", "ctf"])
                app.DomainDropDown.Value = string(mapping.domain);
            end
            app.DimensionOrderField.Value = join(string(mapping.source_dimension_order), ",");
            app.DelayUnitDropDown.Value = string(mapping.delay_unit);
            app.FrequencyUnitDropDown.Value = string(mapping.frequency_unit);
            app.TimeUnitDropDown.Value = string(mapping.time_unit);
            app.PositionUnitDropDown.Value = string(mapping.position_unit);
            app.DelaySpacingField.Value = optionalNumberText(mapping.delay_bin_spacing_s);
            app.CenterFrequencyField.Value = optionalNumberText(mapping.center_frequency_hz);
            app.SubcarrierSpacingField.Value = optionalNumberText(mapping.subcarrier_spacing_hz);
            app.SnapshotIntervalField.Value = optionalNumberText(mapping.snapshot_interval_s);
            app.SemanticsDropDown.Value = string(mapping.sample_semantics);
            app.ConfirmCheckBox.Value = ~report.requires_mapping;
            app.updateRepresentationControls();
            app.validateVisibleMapping(false);
        end

        function mapping = collectMapping(app)
            mapping = default_mat_channel_mapping();
            if isfield(app.Inspection, "suggested_mapping")
                mapping.adapter = string(app.Inspection.suggested_mapping.adapter);
            end
            mapping.domain = string(app.DomainDropDown.Value);
            if app.RepresentationDropDown.Value == "complex"
                mapping.complex_variable = string(app.ComplexDropDown.Value);
            else
                mapping.real_variable = string(app.RealDropDown.Value);
                mapping.imag_variable = string(app.ImagDropDown.Value);
            end
            rawOrder = strip(split(string(app.DimensionOrderField.Value), ","));
            mapping.source_dimension_order = rawOrder(rawOrder ~= "").';
            mapping.delay_variable = string(app.DelayDropDown.Value);
            mapping.frequency_variable = string(app.FrequencyDropDown.Value);
            mapping.time_variable = string(app.TimeDropDown.Value);
            mapping.sample_index_variable = string(app.SampleDropDown.Value);
            mapping.position_variable = string(app.PositionDropDown.Value);
            mapping.delay_unit = string(app.DelayUnitDropDown.Value);
            mapping.frequency_unit = string(app.FrequencyUnitDropDown.Value);
            mapping.time_unit = string(app.TimeUnitDropDown.Value);
            mapping.position_unit = string(app.PositionUnitDropDown.Value);
            mapping.delay_bin_spacing_s = parseOptionalNumeric(app.DelaySpacingField.Value, "delay_bin_spacing_s");
            mapping.center_frequency_hz = parseOptionalNumeric(app.CenterFrequencyField.Value, "center_frequency_hz");
            mapping.subcarrier_spacing_hz = parseOptionalNumeric(app.SubcarrierSpacingField.Value, "subcarrier_spacing_hz");
            mapping.snapshot_interval_s = parseOptionalNumeric(app.SnapshotIntervalField.Value, "snapshot_interval_s");
            mapping.sample_semantics = string(app.SemanticsDropDown.Value);
            mapping.source_id = sourceName(app.SourcePath);
            mapping.advanced_mapping_confirmed = logical(app.ConfirmCheckBox.Value);
        end

        function report = validateVisibleMapping(app, showDialog)
            arguments
                app
                showDialog (1, 1) logical = true
            end
            try
                mapping = app.collectMapping();
                variables = struct([]);
                if isfield(app.Inspection, "variables"), variables = app.Inspection.variables; end
                report = validate_mat_channel_mapping(mapping, variables);
                lines = ["Mapping: " + report.status; string(report.warnings(:)); string(report.errors(:))];
                if isfield(app.Inspection, "source_kind") && ...
                        ismember(string(app.Inspection.source_kind), ["sage_folder", "legacy_wifo_hdf5"])
                    report.is_valid = true;
                    report.status = "PASS";
                    lines = app.text("已识别专用适配器；将按适配器规则转换。", ...
                        "Known adapter identified; adapter-specific conversion will be used.");
                end
                app.MappingStatus.Value = lines;
                if showDialog && report.is_valid
                    uialert(app.UIFigure, app.text("当前映射可以转换。", ...
                        "The current mapping is valid for conversion."), ...
                        app.text("映射通过", "Mapping valid"), "Icon", "success");
                end
            catch exception
                report = struct("is_valid", false, "status", "FAIL", ...
                    "errors", string(exception.message), "warnings", strings(0, 1));
                app.MappingStatus.Value = string(exception.message);
            end
        end

        function updateRepresentationControls(app)
            isComplex = app.RepresentationDropDown.Value == "complex";
            app.ComplexDropDown.Enable = onOff(isComplex);
            app.RealDropDown.Enable = onOff(~isComplex);
            app.ImagDropDown.Enable = onOff(~isComplex);
        end

        function conversionProgress(app, event)
            fraction = 0;
            if isfield(event, "fraction"), fraction = double(event.fraction); end
            detail = "";
            if isfield(event, "detail"), detail = string(event.detail); end
            phase = "";
            if isfield(event, "phase"), phase = string(event.phase); end
            app.setProgress(fraction, "running", ["Phase: " + phase; detail]);
            drawnow limitrate;
        end

        function setProgress(app, fraction, state, detail)
            update_filled_progress_bar(app.ProgressBar, fraction, ...
                Text=sprintf("%.0f%%", 100 * max(0, min(1, fraction))), State=state);
            app.ProgressDetail.Value = string(detail(:));
        end

        function convertFromButton(app)
            try
                app.convertCurrent();
            catch exception
                uialert(app.UIFigure, string(exception.message), ...
                    app.text("转换未完成", "Conversion not completed"), "Icon", "error");
            end
        end

        function enableConvert(app)
            if ~isempty(app.ConvertButton) && isvalid(app.ConvertButton)
                canConvert = ~isempty(fieldnames(app.Inspection)) && ...
                    isfield(app.Inspection, "is_convertible") && ...
                    app.Inspection.is_convertible;
                app.ConvertButton.Enable = onOff(canConvert);
            end
        end

        function selectTab(app, tab)
            app.TabGroup.SelectedTab = tab;
        end

        function changeLanguage(app)
            app.CurrentLanguage = string(app.LanguageDropDown.Value);
            app.applyLanguage();
        end

        function applyLanguage(app)
            column = 3;
            if app.CurrentLanguage == "en", column = 4; end
            for index = 1:size(app.Localized, 1)
                component = app.Localized{index, 1};
                if isempty(component) || ~isvalid(component), continue; end
                component.(app.Localized{index, 2}) = app.Localized{index, column};
            end
            if app.CurrentLanguage == "en"
                app.VariableTable.ColumnName = ...
                    {"Variable", "Size", "Class", "Complex", "Suggested role"};
                app.RepresentationDropDown.Items = ...
                    ["Single complex variable", "Real + imaginary variables"];
                app.DomainDropDown.Items = ["CIR (delay domain)", "CTF (frequency domain)"];
                app.SemanticsDropDown.Items = ...
                    ["Independent samples", "Ordered route", "Time series"];
            else
                app.VariableTable.ColumnName = {"变量", "尺寸", "类型", "复数", "建议角色"};
                app.RepresentationDropDown.Items = ["单个复数变量", "实部 + 虚部变量"];
                app.DomainDropDown.Items = ["CIR（时延域）", "CTF（频域）"];
                app.SemanticsDropDown.Items = ["独立样本", "有序路线", "时间序列"];
            end
            if ~isempty(fieldnames(app.Inspection)) && ...
                    isfield(app.Inspection, "source_kind") && ...
                    isfield(app.Inspection, "suggested_mapping")
                mapping = app.Inspection.suggested_mapping;
                app.AdapterLabel.Text = app.text( ...
                    "适配器：" + string(mapping.adapter) + ...
                    "；来源：" + string(app.Inspection.source_kind), ...
                    "Adapter: " + string(mapping.adapter) + ...
                    "; source: " + string(app.Inspection.source_kind));
            end
            variableControls = {app.ComplexDropDown, app.RealDropDown, ...
                app.ImagDropDown, app.DelayDropDown, app.FrequencyDropDown, ...
                app.TimeDropDown, app.SampleDropDown, app.PositionDropDown};
            for index = 1:numel(variableControls)
                control = variableControls{index};
                selected = string(control.Value);
                data = string(control.ItemsData(:));
                names = data(data ~= "");
                setVariableItems(control, names, selected, app.CurrentLanguage);
            end
        end

        function register(app, component, property, zh, en)
            app.Localized(end + 1, :) = {component, property, string(zh), string(en)};
        end

        function value = text(app, zh, en)
            if app.CurrentLanguage == "en"
                value = string(en);
            else
                value = string(zh);
            end
        end
    end
end

function language = normalizeLanguage(value)
value = lower(strtrim(string(value)));
if any(value == ["en", "english", "en-us"])
    language = "en";
else
    language = "zh";
end
end

function setVariableItems(control, names, selected, language)
if language == "en", noneText = "(none)"; else, noneText = "（无）"; end
control.Items = [noneText; names(:)];
control.ItemsData = [""; names(:)];
if selected ~= "" && any(names == selected)
    control.Value = selected;
else
    control.Value = "";
end
end

function output = defaultOutputPath(source)
[parent, name] = fileparts(source);
output = string(fullfile(parent, name + "_v3.h5"));
end

function value = sourceName(path)
[~, name, extension] = fileparts(path);
value = string(name) + string(extension);
end

function value = optionalNumberText(value)
if isnumeric(value) && isscalar(value) && isfinite(value)
    value = string(value);
else
    value = "";
end
end

function value = parseOptionalNumeric(textValue, fieldName)
textValue = strtrim(string(textValue));
if textValue == ""
    value = NaN;
    return;
end
value = str2double(textValue);
if ~isscalar(value) || ~isfinite(value) || value <= 0
    error("ChannelMatConversionWizard:InvalidOptionalNumber", ...
        "%s must be a positive number or left blank.", fieldName);
end
end

function value = onOff(tf)
if tf, value = "on"; else, value = "off"; end
end
