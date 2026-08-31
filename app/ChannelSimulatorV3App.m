classdef ChannelSimulatorV3App < handle
    %CHANNELSIMULATORV3APP Formal ChanAI Pulse v3.1 desktop interface.
    %   The App owns presentation, state and service orchestration only.
    %   Channel parsing, characterization, optimization, prediction and
    %   generation remain in the versioned core interfaces.

    properties (SetAccess = private)
        UIFigure matlab.ui.Figure
    end

    properties (Access = private)
        RootPath string
        RootGrid matlab.ui.container.GridLayout
        TabGroup matlab.ui.container.TabGroup
        ModuleOneTab matlab.ui.container.Tab
        ModuleTwoTab matlab.ui.container.Tab
        ModuleThreeTab matlab.ui.container.Tab
        LanguageDropDown matlab.ui.control.DropDown
        ModeDropDown matlab.ui.control.DropDown
        GlobalStatusLabel matlab.ui.control.Label
        ProgressOverlay matlab.ui.container.Panel
        ProgressTitleLabel matlab.ui.control.Label
        ProgressPercentLabel matlab.ui.control.Label
        ProgressBar struct = struct()
        ProgressDetailArea matlab.ui.control.TextArea
        ProgressElapsedLabel matlab.ui.control.Label
        ProgressDismissButton matlab.ui.control.Button

        FileLabel matlab.ui.control.Label
        MatConversionButton matlab.ui.control.Button
        TaskModeDropDown matlab.ui.control.DropDown
        TaskAxisDropDown matlab.ui.control.DropDown
        TaskPresetDropDown matlab.ui.control.DropDown
        CoordinateDropDown matlab.ui.control.DropDown
        MissingPatternDropDown matlab.ui.control.DropDown
        KnownRangeField matlab.ui.control.EditField
        TargetRangeField matlab.ui.control.EditField
        TaskPreviewLabel matlab.ui.control.TextArea
        LoadAnalyzeButton matlab.ui.control.Button
        StartButton matlab.ui.control.Button
        InputSummaryLabel matlab.ui.control.TextArea
        InputQualityLabel matlab.ui.control.TextArea
        DimensionCardLabels struct = struct()
        PlotCapabilityLabel matlab.ui.control.Label
        TaskRangeAxes matlab.ui.control.UIAxes
        InputFeatureTabs matlab.ui.container.TabGroup
        InputOverviewTab matlab.ui.container.Tab
        InputDelayTab matlab.ui.container.Tab
        InputSpatialTab matlab.ui.container.Tab
        InputTimeTab matlab.ui.container.Tab
        InputAdditionalTab matlab.ui.container.Tab

        BackendDropDown matlab.ui.control.DropDown
        EngineRootField matlab.ui.control.EditField
        OptimizerDropDown matlab.ui.control.DropDown
        ModuleTwoStatusArea matlab.ui.control.TextArea
        ModuleTwoManifestArea matlab.ui.control.TextArea
        ModuleTwoProgressBar struct = struct()
        ModuleTwoProgressFraction double = 0
        ModuleTwoParameterTable matlab.ui.control.Table
        ModuleTwoRunButton matlab.ui.control.Button
        ModuleTwoCancelButton matlab.ui.control.Button
        AdvancedPanels matlab.ui.container.Panel

        ModuleThreeSummaryArea matlab.ui.control.TextArea
        ModuleThreeStatusArea matlab.ui.control.TextArea
        ModelModeDropDown matlab.ui.control.DropDown
        ManualModelDropDown matlab.ui.control.DropDown
        AdaptationDropDown matlab.ui.control.DropDown
        DeviceDropDown matlab.ui.control.DropDown
        RunPredictionButton matlab.ui.control.Button
        OutputFeatureTabs matlab.ui.container.TabGroup
        OutputOverviewTab matlab.ui.container.Tab
        OutputDelayTab matlab.ui.container.Tab
        OutputSpatialTab matlab.ui.container.Tab
        OutputTimeTab matlab.ui.container.Tab
        OutputAdditionalTab matlab.ui.container.Tab
        DelayParameterAxes matlab.ui.control.UIAxes
        KFactorParameterAxes matlab.ui.control.UIAxes
        ExportButton matlab.ui.control.Button

        SelectedFile string = ""
        ImportResult struct = struct()
        InputAnalysis struct = struct()
        CalibrationResult struct = struct()
        ParameterPrediction struct = struct()
        PredictionResult struct = struct()
        BackendSelection struct = struct()
        BaseInputQualityValue string = "尚未分析图表能力"
        CancellationRequested logical = false
        IsRunning logical = false
        CurrentLanguage string = "zh"
        ProgressStartedAt uint64 = uint64(0)
        ProgressVisible logical = false
    end

    methods
        function app = ChannelSimulatorV3App(options)
            arguments
                options.Visible (1, 1) string = "on"
            end
            app.RootPath = string(fileparts(fileparts(mfilename("fullpath"))));
            app.createComponents();
            setappdata(app.UIFigure, "ChanAIPulseV3App", app);
            app.UIFigure.Visible = options.Visible;
            app.setGlobalStatus("等待导入信道数据", "neutral");
            app.updateTaskPreview();
            app.applyUserMode();
        end

        function delete(app)
            if isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end

        function loadChannelFile(app, filePath, options)
            %LOADCHANNELFILE Programmatic equivalent of the Module 1 flow.
            %   This keeps automated UI smoke tests on the same callbacks
            %   used by a person, without automating the operating-system
            %   file picker.
            arguments
                app
                filePath (1, 1) string
                options.TaskMode (1, 1) string = "extrapolation"
                options.TaskAxis (1, 1) string = "sample"
                options.TaskPreset (1, 1) string = "80_20"
            end
            if ~isfile(filePath)
                error("ChannelSimulatorV3App:FileNotFound", ...
                    "Channel file does not exist: %s", filePath);
            end
            app.TaskModeDropDown.Value = options.TaskMode;
            app.TaskAxisDropDown.Value = options.TaskAxis;
            app.TaskPresetDropDown.Value = options.TaskPreset;
            app.SelectedFile = filePath;
            app.resetLoadedState();
            app.FileLabel.Text = filePath;
            app.loadAndAnalyze();
        end

        function runCurrentTask(app)
            %RUNCURRENTTASK Programmatic equivalent of “开始预测”.
            app.startWorkflow();
        end

        function configurePrediction(app, options)
            %CONFIGUREPREDICTION Programmatic equivalent of model controls.
            arguments
                app
                options.SelectionMode (1, 1) string = "auto"
                options.Model (1, 1) string = "persistence"
                options.Adaptation (1, 1) string = "auto"
                options.Device (1, 1) string = "auto"
            end
            mustBeMember(options.SelectionMode, ["auto", "manual"]);
            mustBeMember(options.Model, ["persistence", "linear", ...
                "quadratic", "holt", "harmonic", "ar", "kalman", ...
                "gru", "lstm", "tcn", "dlinear", "nlinear"]);
            mustBeMember(options.Adaptation, ["auto", "off"]);
            mustBeMember(options.Device, ["auto", "cpu", "cuda"]);
            if options.SelectionMode == "manual" || ...
                    options.Adaptation ~= "auto" || options.Device ~= "auto"
                app.ModeDropDown.Value = "advanced";
                app.applyUserMode();
            end
            app.ModelModeDropDown.Value = options.SelectionMode;
            app.ManualModelDropDown.Value = options.Model;
            app.AdaptationDropDown.Value = options.Adaptation;
            app.DeviceDropDown.Value = options.Device;
            app.updateModelControls();
        end

        function setLanguage(app, language)
            %SETLANGUAGE Programmatic equivalent of the header selector.
            language = lower(strtrim(string(language)));
            if any(language == ["en", "english", "en-us"])
                app.LanguageDropDown.Value = "English";
            elseif any(language == ["zh", "chinese", "zh-cn", "中文"])
                app.LanguageDropDown.Value = "中文";
            else
                error("ChannelSimulatorV3App:UnsupportedLanguage", ...
                    "Supported UI languages are zh and en.");
            end
            app.switchLanguage();
        end

        function state = getReviewState(app)
            %GETREVIEWSTATE Return a read-only, compact UI/service snapshot.
            state = struct( ...
                "selected_file", app.SelectedFile, ...
                "input_dimensions", struct(), ...
                "backend_selection", app.BackendSelection, ...
                "calibration_success", false, ...
                "prediction_success", false, ...
                "prediction_dimensions", struct(), ...
                "prediction_standard_plot_count", 0, ...
                "prediction_additional_plot_count", 0, ...
                "model_selection_mode", string(app.ModelModeDropDown.Value), ...
                "requested_model", string(app.ManualModelDropDown.Value), ...
                "adaptation_mode", string(app.AdaptationDropDown.Value), ...
                "device", string(app.DeviceDropDown.Value), ...
                "selected_model", "", ...
                "model_registry", "", ...
                "known_context_parameters", zeros(0, 8), ...
                "prediction_parameters", zeros(0, 8), ...
                "prediction_safety", struct(), ...
                "language", app.CurrentLanguage, ...
                "progress_visible", app.ProgressVisible, ...
                "progress_style", "horizontal_fill", ...
                "progress_fraction", get_filled_progress_value(app.ProgressBar), ...
                "module_two_status", string(app.ModuleTwoStatusArea.Value(:)), ...
                "module_three_status", string(app.ModuleThreeStatusArea.Value(:)), ...
                "calibration_errors", strings(0, 1));
            if ~isempty(fieldnames(app.ImportResult)) && ...
                    isfield(app.ImportResult, "dataset")
                state.input_dimensions = app.ImportResult.dataset.dimensions;
            end
            if ~isempty(fieldnames(app.CalibrationResult)) && ...
                    isfield(app.CalibrationResult, "success")
                state.calibration_success = app.CalibrationResult.success;
                if isfield(app.CalibrationResult, "errors")
                    state.calibration_errors = ...
                        string(app.CalibrationResult.errors(:));
                end
            end
            if ~isempty(fieldnames(app.PredictionResult)) && ...
                    isfield(app.PredictionResult, "cir_dataset")
                state.prediction_success = true;
                state.prediction_dimensions = ...
                    app.PredictionResult.cir_dataset.dimensions;
                registry = app.PredictionResult.analysis.registry;
                state.prediction_standard_plot_count = ...
                    registry.available_standard_plot_count;
                state.prediction_additional_plot_count = ...
                    registry.available_additional_plot_count;
                manifest = app.PredictionResult.prediction_manifest;
                if isfield(manifest.selection, "selected_model")
                    state.selected_model = string( ...
                        manifest.selection.selected_model);
                elseif isfield(manifest.selection, "selected_model_type")
                    state.selected_model = string( ...
                        manifest.selection.selected_model_type);
                end
                if isfield(manifest.model, "registry")
                    state.model_registry = string(manifest.model.registry);
                end
            end
            if ~isempty(fieldnames(app.ParameterPrediction))
                prediction = app.ParameterPrediction;
                if isfield(prediction, "known_context_parameters")
                    state.known_context_parameters = ...
                        double(prediction.known_context_parameters);
                end
                if isfield(prediction, "prediction_parameters")
                    values = double(prediction.prediction_parameters);
                    state.prediction_parameters = reshape(values(1, :, :), ...
                        [size(values, 2), size(values, 3)]);
                end
                state.prediction_safety = ...
                    app.predictionSafetySummary(prediction);
            end
        end

        function files = exportCurrentPrediction(app, outputDirectory)
            %EXPORTCURRENTPREDICTION Programmatic equivalent of UI export.
            arguments
                app
                outputDirectory (1, 1) string
            end
            if isempty(fieldnames(app.PredictionResult))
                error("ChannelSimulatorV3App:NoPrediction", ...
                    "No completed prediction is available for export.");
            end
            files = export_prediction_result_bundle( ...
                app.PredictionResult, outputDirectory);
        end
    end

    methods (Access = private)
        function createComponents(app)
            blue = [0.04, 0.29, 0.56];
            muted = [0.35, 0.40, 0.46];
            border = [0.62, 0.74, 0.86];
            app.UIFigure = uifigure( ...
                "Name", "ChanAI Pulse v3.1.0", ...
                "Position", [30, 30, 1540, 920], ...
                "Color", [0.96, 0.97, 0.985], ...
                "Visible", "off", ...
                "AutoResizeChildren", "off", ...
                "SizeChangedFcn", @(~, ~) app.layoutApplication(), ...
                "CloseRequestFcn", @(~, ~) delete(app));
            app.RootGrid = uigridlayout(app.UIFigure, [2, 1], ...
                "RowHeight", {62, "1x"}, "Padding", [10, 8, 10, 8]);
            root = app.RootGrid;

            header = uipanel(root, "BackgroundColor", "white", ...
                "BorderColor", border);
            headerGrid = uigridlayout(header, [1, 5], ...
                "ColumnWidth", {260, "1x", 240, 145, 165}, ...
                "Padding", [16, 7, 16, 7], "ColumnSpacing", 9);
            uilabel(headerGrid, "Text", "●  ChanAI Pulse", ...
                "FontName", "Microsoft YaHei UI", "FontSize", 19, ...
                "FontWeight", "bold", "FontColor", blue);
            app.GlobalStatusLabel = uilabel(headerGrid, ...
                "Text", "", "HorizontalAlignment", "center", ...
                "FontWeight", "bold", "FontColor", muted);
            uilabel(headerGrid, "Text", "使用模式", ...
                "HorizontalAlignment", "right", "FontColor", muted);
            app.ModeDropDown = uidropdown(headerGrid, ...
                "Items", ["普通模式", "高级模式"], ...
                "ItemsData", ["normal", "advanced"], ...
                "Value", "normal", ...
                "ValueChangedFcn", @(~, ~) app.applyUserMode());
            app.LanguageDropDown = uidropdown(headerGrid, ...
                "Items", ["中文", "English"], "Value", "中文", ...
                "Tooltip", "切换界面、状态提示和图表说明的显示语言。", ...
                "ValueChangedFcn", @(~, ~) app.switchLanguage());

            app.TabGroup = uitabgroup(root);
            app.ModuleOneTab = uitab(app.TabGroup, "Title", "1. 数据与任务");
            app.ModuleTwoTab = uitab(app.TabGroup, "Title", "2. 运行详情");
            app.ModuleThreeTab = uitab(app.TabGroup, "Title", "3. 预测结果");
            app.createModuleOne(blue, border, muted);
            app.createModuleTwo(blue, border, muted);
            app.createModuleThree(blue, border, muted);
            app.createProgressOverlay(blue, border, muted);
            app.layoutApplication();
            app.localizeCurrentView();
        end

        function createModuleOne(app, blue, border, muted)
            layout = uigridlayout(app.ModuleOneTab, [1, 3], ...
                "ColumnWidth", {315, "1x", 285}, ...
                "Padding", [9, 9, 9, 9], "ColumnSpacing", 9);
            controls = uipanel(layout, "Title", "数据导入与任务设置", ...
                "FontWeight", "bold", "BackgroundColor", "white", ...
                "BorderColor", border);
            grid = uigridlayout(controls, [19, 1], ...
                "RowHeight", {31, 31, 42, 22, 30, 30, 30, 22, 30, 22, 30, ...
                22, 30, 22, 30, 92, 62, 38, 38}, ...
                "Padding", [12, 10, 12, 10], "RowSpacing", 5);
            uibutton(grid, "push", "Text", "浏览信道文件…", ...
                "ButtonPushedFcn", @(~, ~) app.browseFile());
            app.MatConversionButton = uibutton(grid, "push", ...
                "Text", "MAT 数据转换向导…", ...
                "ButtonPushedFcn", @(~, ~) app.openMatWizard());
            app.FileLabel = uilabel(grid, "Text", "尚未选择文件", ...
                "FontName", "Consolas", "FontColor", muted, ...
                "WordWrap", "on", "BackgroundColor", [0.97, 0.98, 1]);
            uilabel(grid, "Text", "任务类型");
            app.TaskModeDropDown = uidropdown(grid, ...
                "Items", ["外推：已知 → 未来", "内插：两侧 → 中间"], ...
                "ItemsData", ["extrapolation", "interpolation"], ...
                "Value", "extrapolation", ...
                "ValueChangedFcn", @(~, ~) app.updateTaskPreview());
            app.TaskAxisDropDown = uidropdown(grid, ...
                "Items", ["样本", "空间", "时间", "频率"], ...
                "ItemsData", ["sample", "space", "time", "frequency"], ...
                "Value", "sample", ...
                "ValueChangedFcn", @(~, ~) app.updateTaskPreview());
            app.TaskPresetDropDown = uidropdown(grid, ...
                "Items", ["自动 80/20", "精确手动区间"], ...
                "ItemsData", ["80_20", "manual"], "Value", "80_20", ...
                "ValueChangedFcn", @(~, ~) app.updateTaskPreview());
            uilabel(grid, "Text", "手动区间的输入依据");
            app.CoordinateDropDown = uidropdown(grid, ...
                "Items", ["原始样本编号（推荐）", "MATLAB 数组位置（高级）"], ...
                "ItemsData", ["original_sample", "matlab_index"], ...
                "Value", "original_sample", ...
                "ValueChangedFcn", @(~, ~) app.updateTaskPreview());
            uilabel(grid, "Text", "缺失子载波模式（仅频率轴）");
            app.MissingPatternDropDown = uidropdown(grid, ...
                "Items", ["均匀隔1挖1（缺50%）", "随机50%", "成块8"], ...
                "ItemsData", ["uniform_half", "random_half", "block_8"], ...
                "Value", "uniform_half", "Enable", "off", ...
                "ValueChangedFcn", @(~, ~) app.updateTaskPreview());
            uilabel(grid, "Text", "已知区（例：0:30,40:60）");
            app.KnownRangeField = uieditfield(grid, "text", ...
                "Value", "", "ValueChangedFcn", @(~, ~) app.updateTaskPreview());
            uilabel(grid, "Text", "目标区（例：31:39）");
            app.TargetRangeField = uieditfield(grid, "text", ...
                "Value", "", "ValueChangedFcn", @(~, ~) app.updateTaskPreview());
            app.TaskPreviewLabel = uitextarea(grid, "Editable", "off", ...
                "FontColor", muted, "BackgroundColor", [0.97, 0.98, 1]);
            app.TaskRangeAxes = uiaxes(grid, "Toolbar", [], ...
                "Box", "on", "Color", [0.985, 0.99, 1]);
            app.TaskRangeAxes.YTick = [];
            app.TaskRangeAxes.XGrid = "on";
            title(app.TaskRangeAxes, "任务区间：加载后显示已知区与目标区", ...
                "FontSize", 10, "FontWeight", "normal");
            app.LoadAnalyzeButton = uibutton(grid, "push", ...
                "Text", "加载、验证并分析", "BackgroundColor", blue, ...
                "FontColor", "white", "FontWeight", "bold", ...
                "ButtonPushedFcn", @(~, ~) app.loadAndAnalyze());
            app.StartButton = uibutton(grid, "push", ...
                "Text", "开始预测", "Enable", "off", ...
                "FontWeight", "bold", ...
                "ButtonPushedFcn", @(~, ~) app.startWorkflow());

            feature = uipanel(layout, "Title", "输入信道特性（能力驱动）", ...
                "FontWeight", "bold", "BackgroundColor", "white", ...
                "BorderColor", border);
            featureGrid = uigridlayout(feature, [2, 1], ...
                "RowHeight", {88, "1x"}, "Padding", [8, 6, 8, 8]);
            summaryPanel = uipanel(featureGrid, "BorderType", "none", ...
                "BackgroundColor", [0.965, 0.98, 1]);
            summaryGrid = uigridlayout(summaryPanel, [2, 8], ...
                "RowHeight", {34, 22}, "ColumnWidth", repmat({"1x"}, 1, 8), ...
                "Padding", [8, 7, 8, 5], "ColumnSpacing", 5);
            cardNames = ["classification", "N_sample", "Tx", "Rx", ...
                "Nf", "Nt", "Npath", "plots"];
            cardTitles = ["数据类型", "Nsample", "Tx", "Rx", ...
                "Nf", "Nt", "Npath", "图表"];
            for cardIndex = 1:numel(cardNames)
                app.DimensionCardLabels.(cardNames(cardIndex)) = uilabel( ...
                    summaryGrid, "Text", "—", "FontWeight", "bold", ...
                    "FontSize", 14, "HorizontalAlignment", "center", ...
                    "FontColor", blue);
                app.DimensionCardLabels.(cardNames(cardIndex)).Layout.Row = 1;
                app.DimensionCardLabels.(cardNames(cardIndex)).Layout.Column = cardIndex;
                titleLabel = uilabel(summaryGrid, "Text", cardTitles(cardIndex), ...
                    "HorizontalAlignment", "center", "FontColor", muted);
                titleLabel.Layout.Row = 2;
                titleLabel.Layout.Column = cardIndex;
            end
            app.PlotCapabilityLabel = app.DimensionCardLabels.plots;

            app.InputFeatureTabs = uitabgroup(featureGrid);
            app.InputOverviewTab = uitab(app.InputFeatureTabs, "Title", "全部概览（0）");
            app.InputDelayTab = uitab(app.InputFeatureTabs, "Title", "时延 / 频率（0）");
            app.InputSpatialTab = uitab(app.InputFeatureTabs, "Title", "空间 / 角度（0）");
            app.InputTimeTab = uitab(app.InputFeatureTabs, "Title", "时间 / 多普勒（0）");
            app.InputAdditionalTab = uitab(app.InputFeatureTabs, "Title", "附加可视化（0）");
            app.showWaitingPlots(app.InputOverviewTab, "导入后显示全部图表能力");
            app.showWaitingPlots(app.InputDelayTab, "导入数据后显示可用图表");
            app.showWaitingPlots(app.InputSpatialTab, "导入数据后显示可用图表");
            app.showWaitingPlots(app.InputTimeTab, "导入数据后显示可用图表");
            app.showWaitingPlots(app.InputAdditionalTab, "导入后显示热力图等附加可视化");

            status = uipanel(layout, "Title", "数据质量与能力", ...
                "FontWeight", "bold", "BackgroundColor", "white", ...
                "BorderColor", border);
            statusGrid = uigridlayout(status, [3, 1], ...
                "RowHeight", {190, 145, "1x"}, "Padding", [9, 8, 9, 8]);
            app.InputSummaryLabel = uitextarea(statusGrid, "Editable", "off", ...
                "Value", "尚未导入数据", "FontName", "Consolas");
            app.InputQualityLabel = uitextarea(statusGrid, "Editable", "off", ...
                "Value", "导入后显示 PASS / WARNING / FAIL 与图表能力。", ...
                "FontColor", muted);
            uitextarea(statusGrid, "Editable", "off", ...
                "Value", [ ...
                "阅读提示"; ...
                "• 顶部图表数字采用“标准图+附加图”。"; ...
                "• 全部概览说明每张图是否可用。"; ...
                "• 热力图单独放在附加可视化。"; ...
                "• 不支持的图不会生成伪造曲线。"], ...
                "BackgroundColor", [0.97, 0.98, 1], "FontColor", muted);
        end

        function createProgressOverlay(app, blue, border, muted)
            % A deliberately large, persistent progress card.  Full 6GPCM
            % calls can take tens of seconds, so a thin background gauge is
            % not sufficient feedback for a person operating the platform.
            app.ProgressOverlay = uipanel(app.UIFigure, ...
                "Title", "运行进度", "FontWeight", "bold", ...
                "FontSize", 15, "BackgroundColor", "white", ...
                "BorderColor", blue, ...
                "Position", [410, 275, 720, 312], "Visible", "off");
            grid = uigridlayout(app.ProgressOverlay, [6, 1], ...
                "RowHeight", {26, 40, 32, 92, 22, 28}, ...
                "Padding", [22, 12, 22, 10], "RowSpacing", 5);
            app.ProgressTitleLabel = uilabel(grid, "Text", "等待运行", ...
                "FontSize", 16, "FontWeight", "bold", "FontColor", blue);
            app.ProgressPercentLabel = uilabel(grid, "Text", "0%", ...
                "FontSize", 26, "FontWeight", "bold", ...
                "HorizontalAlignment", "center", "FontColor", blue);
            app.ProgressBar = create_filled_progress_bar(grid, ...
                Value=0, Text="0%", ShowText=true);
            app.ProgressDetailArea = uitextarea(grid, "Editable", "off", ...
                "Value", ["当前阶段：等待开始"; "详细信息将在运行时显示。"], ...
                "FontSize", 12, "BackgroundColor", [0.97, 0.985, 1]);
            app.ProgressElapsedLabel = uilabel(grid, "Text", "已用时间：0 秒", ...
                "FontColor", muted, "FontSize", 12);
            app.ProgressDismissButton = uibutton(grid, "push", ...
                "Text", "收起进度面板", "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.dismissProgress());
        end

        function layoutProgressOverlay(app)
            % Keep the large progress card fully inside the application
            % window.  It is a direct UIFigure child and therefore needs
            % explicit positioning when the window is resized.
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure) || ...
                    isempty(app.ProgressOverlay) || ~isvalid(app.ProgressOverlay)
                return;
            end
            figurePosition = app.UIFigure.Position;
            figureWidth = figurePosition(3);
            figureHeight = figurePosition(4);
            margin = 28;
            cardWidth = min(760, max(480, figureWidth - 2 * margin));
            cardHeight = min(312, max(286, figureHeight - 170));
            cardWidth = min(cardWidth, max(260, figureWidth - 2 * margin));
            cardHeight = min(cardHeight, max(230, figureHeight - 2 * margin));
            cardX = max(margin, floor((figureWidth - cardWidth) / 2));
            cardY = max(margin, floor((figureHeight - cardHeight) / 2));
            app.ProgressOverlay.Position = [cardX, cardY, cardWidth, cardHeight];
        end

        function layoutApplication(app)
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                return;
            end
            app.layoutProgressOverlay();
        end

        function createModuleTwo(app, blue, border, muted)
            layout = uigridlayout(app.ModuleTwoTab, [1, 3], ...
                "ColumnWidth", {315, "1x", 300}, ...
                "Padding", [9, 9, 9, 9], "ColumnSpacing", 9);
            normal = uipanel(layout, "Title", "后台标定状态", ...
                "FontWeight", "bold", "BackgroundColor", "white", ...
                "BorderColor", border);
            grid = uigridlayout(normal, [9, 1], ...
                "RowHeight", {24, 30, 30, 36, 30, 30, 30, 36, "1x"}, ...
                "Padding", [12, 10, 12, 10]);
            uilabel(grid, "Text", "普通用户无需在本页逐项操作。", "FontColor", muted);
            app.ModuleTwoRunButton = uibutton(grid, "push", ...
                "Text", "从模块一启动后自动运行", "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.runCalibration());
            app.ModuleTwoCancelButton = uibutton(grid, "push", ...
                "Text", "取消当前运行", "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.requestCancellation());
            app.ModuleTwoProgressBar = create_filled_progress_bar(grid, ...
                Value=0, Text="0%", ShowText=true);
            uilabel(grid, "Text", "阶段：准备数据");
            uilabel(grid, "Text", "阶段：提取参考特性");
            uilabel(grid, "Text", "阶段：参数标定与生成");
            uilabel(grid, "Text", "阶段：交给模块三预测", "FontColor", muted);
            app.ModuleTwoStatusArea = uitextarea(grid, "Editable", "off", ...
                "Value", "等待模块一提交有效任务。", "FontColor", muted);

            center = uipanel(layout, "Title", "运行进度与标定说明", ...
                "FontWeight", "bold", "BackgroundColor", "white", ...
                "BorderColor", border);
            centerGrid = uigridlayout(center, [3, 1], ...
                "RowHeight", {110, 210, "1x"}, "Padding", [10, 8, 10, 8]);
            explanation = uitextarea(centerGrid, "Editable", "off", ...
                "Value", [ ...
                "模块二使用已知区域的信道特性作为参考。"; ...
                "普通模式自动选择 Grid Search 或 SA，并把实际选择与理由写入 Manifest。"; ...
                "这里的标定对照只解释生成器配置，不是模块三预测准确度。"]);
            app.ModuleTwoParameterTable = uitable(centerGrid, ...
                "Data", table(strings(0, 1), zeros(0, 1), strings(0, 1), ...
                    'VariableNames', {'Parameter', 'Value', 'Source'}), ...
                "ColumnName", {"参数", "标定值", "来源"}, ...
                "RowName", {}, "ColumnWidth", {150, 120, "auto"});
            app.ModuleTwoManifestArea = uitextarea(centerGrid, "Editable", "off", ...
                "Value", "尚无标定 Manifest。", "FontName", "Consolas");

            app.AdvancedPanels = uipanel(layout, "Title", "高级设置", ...
                "FontWeight", "bold", "BackgroundColor", "white", ...
                "BorderColor", border);
            advancedGrid = uigridlayout(app.AdvancedPanels, [9, 1], ...
                "RowHeight", {22, 30, 22, 30, 22, 30, 22, 30, "1x"}, ...
                "Padding", [12, 10, 12, 10]);
            uilabel(advancedGrid, "Text", "生成后端");
            app.BackendDropDown = uidropdown(advancedGrid, ...
                "Items", ["自动选择（推荐）", "Lite 预览", "Full 6GPCM 正式"], ...
                "ItemsData", ["auto", "lite_6gpcm", "full_6gpcm"], ...
                "Value", "auto", ...
                "ValueChangedFcn", @(~, ~) app.refreshBackendCompatibility());
            uilabel(advancedGrid, "Text", "优化方法");
            app.OptimizerDropDown = uidropdown(advancedGrid, ...
                "Items", ["自动选择（推荐）", "Grid Search", "模拟退火 SA"], ...
                "ItemsData", ["auto", "grid", "sa"], "Value", "auto");
            uilabel(advancedGrid, "Text", "Full 6GPCM 根目录（高级覆盖，可留空）");
            app.EngineRootField = uieditfield(advancedGrid, "text", ...
                "Value", "", ...
                "ValueChangedFcn", @(~, ~) app.refreshBackendCompatibility());
            uilabel(advancedGrid, "Text", "安全边界");
            uilabel(advancedGrid, "Text", ...
                "手动模型性能较差时警告但仍运行；硬性不兼容才拒绝。Full 失败不会静默改用 Lite。", ...
                "WordWrap", "on", "FontColor", muted);
        end

        function createModuleThree(app, blue, border, muted)
            layout = uigridlayout(app.ModuleThreeTab, [1, 3], ...
                "ColumnWidth", {315, "1x", 285}, ...
                "Padding", [9, 9, 9, 9], "ColumnSpacing", 9);
            controls = uipanel(layout, "Title", "预测任务与模型", ...
                "FontWeight", "bold", "BackgroundColor", "white", ...
                "BorderColor", border);
            grid = uigridlayout(controls, [12, 1], ...
                "RowHeight", {22, 30, 22, 30, 22, 30, 22, 30, 130, 35, 35, "1x"}, ...
                "Padding", [12, 10, 12, 10]);
            uilabel(grid, "Text", "模型选择");
            app.ModelModeDropDown = uidropdown(grid, ...
                "Items", ["自动推荐", "高级用户手动选择"], ...
                "ItemsData", ["auto", "manual"], "Value", "auto", ...
                "ValueChangedFcn", @(~, ~) app.updateModelControls());
            uilabel(grid, "Text", "手动模型");
            app.ManualModelDropDown = uidropdown(grid, ...
                "Items", ["Persistence", "Linear", "Quadratic Trend", ...
                    "Holt Damped Trend", "Harmonic / Fourier", ...
                    "Adaptive AR", "Kalman", ...
                    "GRU（实验）", "LSTM（实验）", "TCN（实验）", ...
                    "DLinear（实验）", "NLinear（实验）"], ...
                "ItemsData", ["persistence", "linear", "quadratic", ...
                    "holt", "harmonic", "ar", "kalman", ...
                    "gru", "lstm", "tcn", "dlinear", "nlinear"], ...
                "Value", "persistence", ...
                "ValueChangedFcn", @(~, ~) app.updateModelControls());
            uilabel(grid, "Text", "上传数据适配");
            app.AdaptationDropDown = uidropdown(grid, ...
                "Items", ["自动安全适配（推荐）", "关闭适配 / 直接推理"], ...
                "ItemsData", ["auto", "off"], "Value", "auto");
            uilabel(grid, "Text", "预测设备");
            app.DeviceDropDown = uidropdown(grid, ...
                "Items", ["自动（推荐）", "CPU", "GPU（CUDA）"], ...
                "ItemsData", ["auto", "cpu", "cuda"], "Value", "auto");
            app.ModuleThreeSummaryArea = uitextarea(grid, "Editable", "off", ...
                "Value", [ ...
                "普通模式按上传已知区逐参数回测自动选择。"; ...
                "支持全历史任意长度外推和双向内插。"; ...
                "Registry 冻结推荐作为历史参考如实显示。"; ...
                "模型选择不读取目标区真值。"], ...
                "FontColor", muted);
            app.ExportButton = uibutton(grid, "push", ...
                "Text", "导出 CIR / CTF / Manifest", "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.exportPrediction());
            app.RunPredictionButton = uibutton(grid, "push", ...
                "Text", "执行预测并生成 CIR", "Enable", "off", ...
                "FontWeight", "bold", ...
                "ButtonPushedFcn", @(~, ~) app.runPredictionGeneration());

            features = uipanel(layout, "Title", ...
                "预测 CIR 特性（不显示准确度）", "FontWeight", "bold", ...
                "BackgroundColor", "white", "BorderColor", border);
            featureGrid = uigridlayout(features, [2, 1], ...
                "RowHeight", {190, "1x"}, "Padding", [8, 6, 8, 8]);
            parameterPanel = uipanel(featureGrid, ...
                "Title", "预测参数轨迹（蓝色：已知区局部 P8 观测；橙色：目标区预测）", ...
                "BackgroundColor", [0.985, 0.99, 1]);
            parameterGrid = uigridlayout(parameterPanel, [1, 2], ...
                "Padding", [7, 4, 7, 5], "ColumnSpacing", 8);
            app.DelayParameterAxes = uiaxes(parameterGrid, "Toolbar", []);
            title(app.DelayParameterAxes, "DS\_mu");
            xlabel(app.DelayParameterAxes, "任务轴");
            app.KFactorParameterAxes = uiaxes(parameterGrid, "Toolbar", []);
            title(app.KFactorParameterAxes, "KF\_mu");
            xlabel(app.KFactorParameterAxes, "任务轴");
            app.showWaitingParameterAxes();

            app.OutputFeatureTabs = uitabgroup(featureGrid);
            app.OutputOverviewTab = uitab(app.OutputFeatureTabs, "Title", "全部概览（0）");
            app.OutputDelayTab = uitab(app.OutputFeatureTabs, "Title", "时延 / 频率（0）");
            app.OutputSpatialTab = uitab(app.OutputFeatureTabs, "Title", "空间 / 角度（0）");
            app.OutputTimeTab = uitab(app.OutputFeatureTabs, "Title", "时间 / 多普勒（0）");
            app.OutputAdditionalTab = uitab(app.OutputFeatureTabs, "Title", "附加可视化（0）");
            app.showWaitingPlots(app.OutputOverviewTab, "预测完成后显示全部图表能力");
            app.showWaitingPlots(app.OutputDelayTab, "预测 CIR 完成后显示特性图");
            app.showWaitingPlots(app.OutputSpatialTab, "预测 CIR 完成后显示特性图");
            app.showWaitingPlots(app.OutputTimeTab, "预测 CIR 完成后显示特性图");
            app.showWaitingPlots(app.OutputAdditionalTab, "预测完成后显示热力图等附加可视化");

            status = uipanel(layout, "Title", "状态与导出", ...
                "FontWeight", "bold", "BackgroundColor", "white", ...
                "BorderColor", border);
            statusGrid = uigridlayout(status, [1, 1], ...
                "Padding", [9, 8, 9, 8]);
            app.ModuleThreeStatusArea = uitextarea(statusGrid, "Editable", "off", ...
                "Value", [ ...
                "等待模块一任务与模块二标定。"; ...
                "正式页面仅输出预测 CIR 与信道特性。"; ...
                "准确度验证请使用 Step 13 外部 Benchmark。"], ...
                "FontColor", muted);
            app.updateModelControls();
        end

        function browseFile(app)
            [name, folder] = uigetfile({ ...
                "*.h5;*.hdf5;*.mat", "信道数据 (*.h5, *.hdf5, *.mat)"; ...
                "*.h5;*.hdf5", "v3 信道 HDF5 (*.h5, *.hdf5)"; ...
                "*.mat", "MATLAB 数据 (*.mat)"}, ...
                "选择信道数据文件");
            if isequal(name, 0)
                app.restoreWindowFocus();
                return;
            end
            selected = string(fullfile(folder, name));
            [~, ~, extension] = fileparts(selected);
            if lower(string(extension)) == ".mat"
                app.restoreWindowFocus();
                app.openMatWizard(selected);
                return;
            end
            app.SelectedFile = selected;
            app.resetLoadedState();
            app.FileLabel.Text = app.SelectedFile;
            app.setGlobalStatus("已选择文件，等待加载", "neutral");
            app.restoreWindowFocus();
        end

        function openMatWizard(app, sourcePath)
            arguments
                app
                sourcePath (1, 1) string = ""
            end
            wizard = ChannelMatConversionWizard( ...
                RootPath=app.RootPath, ...
                Language=app.CurrentLanguage, ...
                SourcePath=sourcePath, ...
                OnConverted=@(outputPath, ~) app.acceptConvertedMatFile(outputPath));
            setappdata(app.UIFigure, "ChanAIPulseMatWizard", wizard);
        end

        function acceptConvertedMatFile(app, outputPath)
            outputPath = string(outputPath);
            if ~isfile(outputPath)
                uialert(app.UIFigure, ...
                    app.tr("转换结果文件不存在，无法自动加载。"), ...
                    app.tr("MAT 转换失败"));
                return;
            end
            app.SelectedFile = outputPath;
            app.resetLoadedState();
            app.FileLabel.Text = outputPath;
            app.setGlobalStatus("MAT 转换完成，正在自动加载", "running");
            app.restoreWindowFocus();
            app.loadAndAnalyze();
        end

        function updateTaskPreview(app)
            if app.TaskAxisDropDown.Value == "space"
                app.CoordinateDropDown.Items = [ ...
                    "原始空间坐标（推荐）", "MATLAB 数组位置（高级）"];
                app.CoordinateDropDown.ItemsData = ...
                    ["original_space", "matlab_index"];
            elseif app.TaskAxisDropDown.Value == "time"
                app.CoordinateDropDown.Items = [ ...
                    "原始时间坐标（推荐）", "MATLAB 数组位置（高级）"];
                app.CoordinateDropDown.ItemsData = ...
                    ["original_time", "matlab_index"];
            elseif app.TaskAxisDropDown.Value == "frequency"
                app.CoordinateDropDown.Items = [ ...
                    "原始频率坐标（推荐）", "MATLAB 数组位置（高级）"];
                app.CoordinateDropDown.ItemsData = ...
                    ["original_frequency", "matlab_index"];
            else
                app.CoordinateDropDown.Items = [ ...
                    "原始样本编号（推荐）", "MATLAB 数组位置（高级）"];
                app.CoordinateDropDown.ItemsData = ...
                    ["original_sample", "matlab_index"];
            end
            % v3.2-4a: missing-subcarrier pattern only applies to Frequency.
            if isprop(app, "MissingPatternDropDown")
                if app.TaskAxisDropDown.Value == "frequency"
                    app.MissingPatternDropDown.Enable = "on";
                else
                    app.MissingPatternDropDown.Enable = "off";
                end
            end
            if app.CoordinateDropDown.Value ~= "matlab_index"
                app.CoordinateDropDown.Value = app.CoordinateDropDown.ItemsData(1);
            end
            if app.TaskPresetDropDown.Value == "80_20"
                app.KnownRangeField.Enable = "off";
                app.TargetRangeField.Enable = "off";
                app.TaskPreviewLabel.Value = [ ...
                    "自动 80/20 任务：导入后由数据长度生成。"; ...
                    "普通用户不需要处理 MATLAB 从 1 开始的内部编号。"];
            else
                app.KnownRangeField.Enable = "on";
                app.TargetRangeField.Enable = "on";
                app.TaskPreviewLabel.Value = [ ...
                    "手动区间将在加载后检查并预览。"; ...
                    "原始编号 0:30,40:60 会自动转换为内部 1:31,41:61。"];
            end
            if strlength(app.SelectedFile) > 0 && ~app.IsRunning
                app.StartButton.Enable = "off";
                app.ModuleTwoRunButton.Enable = "off";
                cla(app.TaskRangeAxes);
                app.TaskRangeAxes.YTick = [];
                title(app.TaskRangeAxes, ...
                    "任务设置已改变，请重新点击“加载、验证并分析”", ...
                    "FontSize", 10, "FontWeight", "normal");
            end
            app.localizeCurrentView();
        end

        function loadAndAnalyze(app)
            if strlength(app.SelectedFile) == 0
                uialert(app.UIFigure, "请先选择一个 v3 HDF5 信道文件。", "未选择文件");
                return;
            end
            app.setBusy(true, "正在加载、验证并分析输入信道…");
            app.beginProgress("正在分析输入信道", ...
                "正在读取文件、验证数据合同并判断可视化能力。");
            app.updateProgress(0.03, "输入验证", ...
                "正在加载 HDF5 信道数据。", 0, 0, "");
            try
                options = app.buildImportOptions();
                app.ImportResult = import_channel_dataset(app.SelectedFile, options);
                if ~app.ImportResult.validation.is_valid
                    app.renderInputFailure(app.ImportResult.validation);
                    app.finishProgress(false, strjoin( ...
                        string(app.ImportResult.validation.errors(:)), newline));
                    app.setBusy(false, "");
                    app.restoreWindowFocus();
                    return;
                end
                % v3.2-4a: guide the task axis when the file domain does not
                % match the selected axis (a common user mistake that used
                % to surface as an opaque "axis too short" error).
                axisMismatch = app.axisDomainMismatchMessage();
                if strlength(axisMismatch) > 0
                    app.renderInputFailure(struct( ...
                        "errors", string(axisMismatch), ...
                        "warnings", strings(0, 1), "status", "FAIL"));
                    app.finishProgress(false, axisMismatch);
                    app.setBusy(false, "");
                    app.restoreWindowFocus();
                    return;
                end
                app.InputAnalysis = analyze_channel_characteristics( ...
                    app.ImportResult.dataset, Task=app.ImportResult.task, ...
                    Region="known", ModuleRole="input");
                if app.InputAnalysis.status == "FAIL"
                    error("ChannelSimulatorV3App:AnalysisFailed", "%s", ...
                        strjoin(app.InputAnalysis.errors, newline));
                end
                app.renderInputSummary();
                app.renderDimensionCards();
                app.renderTaskRange();
                app.renderAnalysisTabs(app.InputAnalysis, "input");
                app.updateProgress(0.15, "输入分析完成", ...
                    "数据、任务和图表能力已经验证。", 0, 0, "");
                app.finishProgress(true, ...
                    "输入数据已就绪。点击“开始预测”可继续完整流程。");
                app.ModuleTwoStatusArea.Value = [ ...
                    "模块一验证通过。"; ...
                    "用户可从模块一点击“开始预测”；模块二将自动开始标定。"];
                app.setGlobalStatus("输入数据与任务已验证", "success");
            catch exception
                app.renderInputFailure(struct("errors", string(exception.message), ...
                    "warnings", strings(0, 1), "status", "FAIL"));
                app.presentUserError(exception, "import");
                app.finishProgress(false, string(exception.message));
            end
            app.setBusy(false, "");
            app.refreshBackendCompatibility();
            app.restoreWindowFocus();
        end

        function options = buildImportOptions(app)
            options = struct( ...
                "task_mode", string(app.TaskModeDropDown.Value), ...
                "task_axis", string(app.TaskAxisDropDown.Value), ...
                "task_preset", string(app.TaskPresetDropDown.Value), ...
                "description", "Configured in formal ChanAI Pulse v3 UI.");
            if options.task_preset == "manual"
                sampleAxis = app.sampleAxisValues();
                options.known_indices = app.parseRange( ...
                    string(app.KnownRangeField.Value), sampleAxis);
                options.target_indices = app.parseRange( ...
                    string(app.TargetRangeField.Value), sampleAxis);
            end
        end

        function values = sampleAxisValues(app)
            if isempty(fieldnames(app.ImportResult)) || ...
                    ~isfield(app.ImportResult, "dataset") || ...
                    isempty(fieldnames(app.ImportResult.dataset))
                if strlength(app.SelectedFile) == 0
                    error("ChannelSimulatorV3App:NoSelectedFile", ...
                        "请先选择一个 HDF5 信道文件，再使用原始样本编号设置手动任务区间。");
                end
                % Read only the source contract here.  This lets a user enter
                % original sample IDs before the first full import, while the
                % actual task validation still happens in Module 1.
                dataset = read_channel_dataset_hdf5(app.SelectedFile);
            else
                dataset = app.ImportResult.dataset;
            end
            if app.TaskAxisDropDown.Value == "space" && ...
                    isfield(dataset.axes, "sample_position_m")
                positions = dataset.axes.sample_position_m;
                if isvector(positions)
                    values = double(positions(:));
                else
                    % N_sample-by-(1|2|3) route coordinates: along-track x.
                    values = double(positions(:, 1));
                end
            elseif app.TaskAxisDropDown.Value == "time" && ...
                    isfield(dataset.axes, "time_s")
                values = double(dataset.axes.time_s(:));
            elseif app.TaskAxisDropDown.Value == "frequency" && ...
                    isfield(dataset.axes, "frequency_hz")
                values = double(dataset.axes.frequency_hz(:));
            elseif isfield(dataset.axes, "sample_index")
                values = double(dataset.axes.sample_index(:));
            else
                values = 0:double(dataset.dimensions.N_sample) - 1;
            end
        end

        function indices = parseRange(app, expression, axisValues)
            expression = strtrim(expression);
            if strlength(expression) == 0
                error("ChannelSimulatorV3App:EmptyRange", "手动任务必须填写已知区和目标区。");
            end
            chunks = split(replace(expression, "，", ","), ",");
            values = zeros(0, 1);
            for chunk = chunks.'
                token = strtrim(chunk);
                parts = split(token, ":");
                if numel(parts) == 1
                    parsed = str2double(parts(1));
                    if ~isfinite(parsed)
                        error("ChannelSimulatorV3App:BadRange", "无法识别区间：%s", token);
                    end
                    values(end + 1, 1) = parsed; %#ok<AGROW>
                elseif numel(parts) == 2
                    first = str2double(strtrim(parts(1)));
                    last = str2double(strtrim(parts(2)));
                    if ~isfinite(first) || ~isfinite(last) || first ~= floor(first) || ...
                            last ~= floor(last) || last < first
                        error("ChannelSimulatorV3App:BadRange", "区间必须形如 0:30：%s", token);
                    end
                    values = [values; (first:last).']; %#ok<AGROW>
                else
                    error("ChannelSimulatorV3App:BadRange", "区间不能包含多个冒号：%s", token);
                end
            end
            values = unique(values, "stable");
            if app.CoordinateDropDown.Value == "matlab_index"
                indices = values;
                return;
            end
            if isempty(axisValues)
                error("ChannelSimulatorV3App:NoSampleAxis", ...
                    "请先加载数据，再按原始样本编号设置手动区间。");
            end
            indices = zeros(numel(values), 1);
            for index = 1:numel(values)
                match = find(axisValues == values(index), 1);
                if isempty(match)
                    error("ChannelSimulatorV3App:UnmappedCoordinate", ...
                        "原始样本编号 %g 无法映射到当前数据。", values(index));
                end
                indices(index) = match;
            end
        end

        function renderInputSummary(app)
            dataset = app.ImportResult.dataset;
            dimensions = dataset.dimensions;
            app.InputSummaryLabel.Value = [ ...
                "数据状态: " + string(app.ImportResult.validation.status); ...
                "域: " + string(dataset.domain); ...
                sprintf("N_sample=%d, Tx=%d, Rx=%d", dimensions.N_sample, dimensions.Tx, dimensions.Rx); ...
                sprintf("Nt=%d, Nf=%d, Npath=%d", dimensions.Nt, dimensions.Nf, dimensions.Npath); ...
                "分类: " + string(app.InputAnalysis.classification); ...
                sprintf("可用图: %d 标准 + %d 附加", ...
                app.InputAnalysis.registry.available_standard_plot_count, ...
                app.InputAnalysis.registry.available_additional_plot_count)];
            messages = [string(app.ImportResult.validation.warnings(:)); ...
                string(app.InputAnalysis.warnings(:))];
            if isempty(messages)
                messages = "PASS：数据、任务和可视化能力均通过。";
            end
            app.BaseInputQualityValue = messages;
            app.InputQualityLabel.Value = app.BaseInputQualityValue;
            if app.TaskPresetDropDown.Value == "manual"
                app.TaskPreviewLabel.Value = [ ...
                    "用户输入已转换为内部 MATLAB 一基数组位置。"; ...
                    "已知: " + app.formatIndices(app.ImportResult.task.known_indices); ...
                    "目标: " + app.formatIndices(app.ImportResult.task.target_indices); ...
                    "任务验证: PASS"];
            end
        end

        function renderDimensionCards(app)
            dimensions = app.ImportResult.dataset.dimensions;
            app.DimensionCardLabels.classification.Text = ...
                app.classificationDisplay(app.InputAnalysis.classification);
            app.DimensionCardLabels.classification.FontSize = 11;
            for name = ["N_sample", "Tx", "Rx", "Nf", "Nt", "Npath"]
                app.DimensionCardLabels.(name).Text = ...
                    string(dimensions.(name));
            end
            if string(app.ImportResult.dataset.domain) == "cir"
                app.DimensionCardLabels.Nf.Text = "—";
                app.DimensionCardLabels.Nf.Tooltip = ...
                    "CIR 文件存储多径时延和 Npath；Nf 属于频域 CTF/H。";
            else
                app.DimensionCardLabels.Npath.Tooltip = ...
                    "CTF/H 不一定保存显式多径列表；Npath 可能不可用。";
            end
            standardCount = app.InputAnalysis.registry. ...
                available_standard_plot_count;
            additionalCount = app.InputAnalysis.registry. ...
                available_additional_plot_count;
            app.PlotCapabilityLabel.Text = ...
                string(standardCount) + "+" + string(additionalCount);
            app.PlotCapabilityLabel.Tooltip = sprintf( ...
                "标准特性图 %d 张，附加可视化 %d 张", ...
                standardCount, additionalCount);
        end

        function renderTaskRange(app)
            task = app.ImportResult.task;
            sampleCount = numel(task.axis_values);
            codes = zeros(1, sampleCount);
            codes(double(task.known_indices)) = 1;
            codes(double(task.target_indices)) = 2;
            cla(app.TaskRangeAxes);
            % A two-row band keeps the known/target color strip visible even
            % when the axes height is modest.
            imagesc(app.TaskRangeAxes, 1:sampleCount, 1:2, [codes; codes]);
            colormap(app.TaskRangeAxes, [0.82, 0.84, 0.87; ...
                0.22, 0.67, 0.38; 0.95, 0.55, 0.16]);
            clim(app.TaskRangeAxes, [0, 2]);
            app.TaskRangeAxes.YLim = [0.5, 2.5];
            app.TaskRangeAxes.YTick = [];
            app.TaskRangeAxes.Box = "on";
            app.TaskRangeAxes.XLim = [0.5, sampleCount + 0.5];
            tickCount = min(5, sampleCount);
            tickPositions = unique(round(linspace(1, sampleCount, ...
                tickCount)));
            axisValues = double(task.axis_values(:));
            app.TaskRangeAxes.XTick = tickPositions;
            % Compact per-unit tick labels keep the axis readable for large
            % values (e.g. Hz) instead of overlapping scientific notation.
            tickValues = axisValues(tickPositions);
            if isfield(task, "axis_unit") && ...
                    string(task.axis_unit) == "Hz"
                tickLabels = strings(numel(tickValues), 1);
                for labelIndex = 1:numel(tickValues)
                    value = tickValues(labelIndex);
                    if abs(value) >= 1e9
                        tickLabels(labelIndex) = ...
                            sprintf("%.3f G", value / 1e9);
                    elseif abs(value) >= 1e6
                        tickLabels(labelIndex) = ...
                            sprintf("%.3f M", value / 1e6);
                    elseif abs(value) >= 1e3
                        tickLabels(labelIndex) = ...
                            sprintf("%.3f k", value / 1e3);
                    else
                        tickLabels(labelIndex) = sprintf("%.3g", value);
                    end
                end
            else
                tickLabels = compose("%.3g", tickValues);
            end
            app.TaskRangeAxes.XTickLabel = tickLabels;
            xlabel(app.TaskRangeAxes, app.tr(string(task.axis) + ...
                "（绿色：已知，橙色：目标，灰色：未使用）"));
            title(app.TaskRangeAxes, app.tr(sprintf( ...
                "%s：已知 %d，目标 %d", ...
                app.taskModeDisplay(task.mode), ...
                numel(task.known_indices), numel(task.target_indices))), ...
                "FontSize", 10, "FontWeight", "bold");
            app.TaskPreviewLabel.Value = [ ...
                "原始轴已知区: " + app.formatAxisValues( ...
                    axisValues(task.known_indices)); ...
                "原始轴目标区: " + app.formatAxisValues( ...
                    axisValues(task.target_indices)); ...
                "内部 MATLAB 已知索引: " + ...
                    app.formatIndices(task.known_indices); ...
                "内部 MATLAB 目标索引: " + ...
                    app.formatIndices(task.target_indices); ...
                "任务验证: PASS"];
        end

        function text = classificationDisplay(app, classification)
            switch string(classification)
                case "narrowband_static_siso"
                    text = app.tr("窄带静态 SISO");
                case "wideband_static_siso"
                    text = app.tr("宽带静态 SISO");
                case "wideband_static_mimo"
                    text = app.tr("宽带静态 MIMO");
                case "wideband_dynamic_mimo"
                    text = app.tr("宽带动态 MIMO");
                otherwise
                    text = replace(string(classification), "_", " ");
            end
        end

        function text = taskModeDisplay(app, mode)
            if string(mode) == "interpolation"
                text = app.tr("内插");
            else
                text = app.tr("外推");
            end
        end

        function renderInputFailure(app, report)
            app.StartButton.Enable = "off";
            app.ModuleTwoRunButton.Enable = "off";
            errors = strings(0, 1);
            warnings = strings(0, 1);
            if isfield(report, "errors")
                errors = string(report.errors(:));
            end
            if isfield(report, "warnings")
                warnings = string(report.warnings(:));
            end
            app.InputSummaryLabel.Value = ["数据或任务验证失败"; errors];
            app.InputQualityLabel.Value = [warnings; errors];
            app.showWaitingPlots(app.InputOverviewTab, "无法分析：请修正文件或任务设置");
            app.showWaitingPlots(app.InputDelayTab, "无法分析：请修正文件或任务设置");
            app.showWaitingPlots(app.InputSpatialTab, "无法分析：请修正文件或任务设置");
            app.showWaitingPlots(app.InputTimeTab, "无法分析：请修正文件或任务设置");
            app.showWaitingPlots(app.InputAdditionalTab, "无法分析：请修正文件或任务设置");
            app.setGlobalStatus("输入验证失败", "error");
        end

        function presentUserError(app, exception, step)
            % v3.2-4b: plain-language error presentation. Writes a
            % what/why/next-step summary to the active module status area,
            % opens a plain-language dialog, and keeps the raw technical
            % identifier/message copyable for support.
            guidance = user_error_guidance(exception, step);
            area = app.errorStatusArea(step);
            area.Value = [guidance.lines(:); ""; ...
                "技术编号：" + guidance.technical];
            uialert(app.UIFigure, ...
                strjoin([guidance.lines(:); "技术编号：" + guidance.technical], newline), ...
                guidance.title);
            app.setGlobalStatus(guidance.title, "error");
        end

        function area = errorStatusArea(app, step)
            switch step
                case {"import", "calibration"}
                    area = app.ModuleTwoStatusArea;
                otherwise
                    area = app.ModuleThreeStatusArea;
            end
        end

        function startWorkflow(app)
            app.TabGroup.SelectedTab = app.ModuleTwoTab;
            app.runCalibration();
        end

        function runCalibration(app)
            if isempty(fieldnames(app.ImportResult)) || ...
                    ~isfield(app.ImportResult, "validation") || ...
                    ~app.ImportResult.validation.is_valid
                uialert(app.UIFigure, "请先在模块一完成有效的数据导入和任务设置。", "缺少有效任务");
                return;
            end
            app.CancellationRequested = false;
            app.setBusy(true, "模块二正在标定生成器参数…");
            app.beginProgress("正在准备预测任务", ...
                "模块二将只使用已知区域进行标定。目标区域真值不会被读取。");
            app.updateProgress(0.03, "模块二：准备数据", ...
                "正在提取已知区域的参考特性。", 0, 0, "");
            app.ModuleTwoCancelButton.Enable = "on";
            app.ModuleTwoProgressFraction = 0.02;
            update_filled_progress_bar(app.ModuleTwoProgressBar, ...
                app.ModuleTwoProgressFraction, State="running");
            app.ModuleTwoStatusArea.Value = [ ...
                "准备数据…"; "提取已知区域参考特性…"; "正在选择优化策略…"];
            try
                selection = app.resolveBackendSelection();
                if ~selection.success
                    error("ChannelSimulatorV3App:NoCompatibleGenerator", "%s", ...
                        app.backendFailureMessage(selection));
                end
                app.BackendSelection = selection;
                backend = selection.selected_backend;
                app.updateProgress(0.08, "模块二：选择生成器", ...
                    "已选择 " + app.backendDisplayName(backend) + "。", ...
                    0, 0, backend);
                config = default_optimization_config(backend);
                config.requested_strategy = string(app.OptimizerDropDown.Value);
                config.target.task = app.ImportResult.task;
                config.generator_config.engine_root = app.fullEngineRoot();
                config.generator_config.backend_options.full_interface = ...
                    selection.selected_adapter_variant;
                config.generator_config.backend_options.output_profile = ...
                    app.generatorOutputProfile();
                inputDimensions = app.ImportResult.dataset.dimensions;
                config.generator_config.dimensions.Tx = inputDimensions.Tx;
                config.generator_config.dimensions.Rx = inputDimensions.Rx;
                config.generator_config.dimensions.Nt = inputDimensions.Nt;
                config.generator_config.dimensions.Npath = 0;
                config.generator_config.dimensions.N_sample = min( ...
                    3, numel(app.ImportResult.task.known_indices));
                if backend ~= "full_6gpcm" || ...
                        selection.selected_adapter_variant == "public_api"
                    config.generator_config.scenario = app.generatorScenario( ...
                        config.generator_config.scenario, inputDimensions);
                end
                if backend == "full_6gpcm" && ...
                        selection.selected_adapter_variant == "public_api"
                    config.limits.max_evaluations = 6;
                    config.sa.no_improvement_limit = 4;
                end
                if backend == "full_6gpcm"
                    config.generator_config.mode = "formal";
                end
                options = struct("progress_callback", @app.calibrationProgress, ...
                    "cancel_check", @() app.CancellationRequested);
                if app.currentAxisName() == "frequency"
                    % v3.2-4a: Frequency prediction is deterministic in-band
                    % recovery (linear interpolation); it never consumes
                    % generator-parameter calibration, and the hole-y known
                    % subcarrier grid cannot build a wideband PDP fit target.
                    % Skip the optimizer and record the honest reason.
                    app.CalibrationResult = create_frequency_axis_calibration();
                elseif string(app.InputAnalysis.classification) == ...
                        "narrowband_static_siso"
                    app.CalibrationResult = ...
                        create_capability_default_calibration( ...
                        app.InputAnalysis, config);
                else
                    app.CalibrationResult = run_parameter_optimization( ...
                        app.ImportResult.dataset, config, options);
                end
                app.renderCalibrationResult();
                if app.CalibrationResult.success
                    app.updateProgress(0.55, "模块二：标定完成", ...
                        "正在交给模块三预测并生成目标 CIR。", 0, 0, backend);
                    app.ModuleThreeStatusArea.Value = [ ...
                        "模块二标定完成。"; ...
                        "下一步：构造只包含已知区域参数的预测请求。"; ...
                        "不会读取目标区域 Ground Truth。"];
                    app.setGlobalStatus("模块二标定完成", "success");
                    app.TabGroup.SelectedTab = app.ModuleThreeTab;
                    app.RunPredictionButton.Enable = "on";
                    % The normal-user flow has no Module 2 action to make:
                    % once calibration is valid, continue directly to the
                    % safe frozen product baseline in Module 3.
                    app.runPredictionGeneration();
                elseif app.CalibrationResult.cancelled
                    app.setGlobalStatus("模块二已取消", "neutral");
                    app.finishProgress(false, "用户请求取消，当前运行已停止。");
                else
                    app.setGlobalStatus("模块二标定失败", "error");
                    app.finishProgress(false, strjoin(string(app.CalibrationResult.errors(:)), newline));
                end
            catch exception
                app.presentUserError(exception, "calibration");
                app.finishProgress(false, string(exception.message));
            end
            app.ModuleTwoCancelButton.Enable = "off";
            app.setBusy(false, "");
        end

        function calibrationProgress(app, event)
            if isfield(event, "progress")
                app.ModuleTwoProgressFraction = max(0, min(1, ...
                    double(event.progress)));
                update_filled_progress_bar(app.ModuleTwoProgressBar, ...
                    app.ModuleTwoProgressFraction, State="running");
            end
            phase = "运行中";
            message = "正在执行参数标定";
            if isfield(event, "phase")
                phase = string(event.phase);
            end
            if isfield(event, "message")
                message = string(event.message);
            end
            app.ModuleTwoStatusArea.Value = [ ...
                "参数标定运行中"; ...
                "阶段: " + phase; ...
                "进度: " + sprintf("%.0f%%", ...
                    100 * app.ModuleTwoProgressFraction); ...
                message];
            app.updateProgress(0.10 + 0.45 * app.ModuleTwoProgressFraction, ...
                "模块二：" + phase, message, 0, 0, "");
            drawnow limitrate;
        end

        function runPredictionGeneration(app)
            if isempty(fieldnames(app.CalibrationResult)) || ...
                    ~isfield(app.CalibrationResult, "success") || ...
                    ~app.CalibrationResult.success
                uialert(app.UIFigure, ...
                    "请先完成模块一验证和模块二标定，再执行预测。", ...
                    "缺少标定结果");
                return;
            end
            switch string(app.ImportResult.task.axis)
                case {"sample", "position", "space", "time", "frequency"}
                    % 已接入生成链路：sample 走 v3.1-7 链路；
                    % space/time/frequency 走 v3.2 统一三轴预测入口。
                otherwise
                    uialert(app.UIFigure, ...
                        "当前任务轴尚未接入生成链路：" + string(app.ImportResult.task.axis), ...
                        "当前任务轴尚未接入生成链路");
                    return;
            end

            app.CancellationRequested = false;
            % A rerun must never leave a previous successful model/CIR
            % visible after the new request is safety-blocked or fails.
            app.ParameterPrediction = struct();
            app.PredictionResult = struct();
            app.ExportButton.Enable = "off";
            app.ModuleThreeSummaryArea.Value = ...
                "等待本次模型回测与技术检查";
            app.showWaitingParameterAxes("正在验证本次模型");
            app.showWaitingPlots(app.OutputOverviewTab, "等待本次预测结果");
            app.showWaitingPlots(app.OutputDelayTab, "等待本次预测结果");
            app.showWaitingPlots(app.OutputSpatialTab, "等待本次预测结果");
            app.showWaitingPlots(app.OutputTimeTab, "等待本次预测结果");
            app.showWaitingPlots(app.OutputAdditionalTab, "等待本次预测结果");
            app.setBusy(true, "模块三正在根据已知区域标定结果生成预测 CIR…");
            app.beginProgress("正在生成预测 CIR", ...
                "模块三会将预测参数交给兼容的正式生成器。");
            app.RunPredictionButton.Enable = "off";
            try
                selection = app.resolveBackendSelection();
                if ~selection.success
                    error("ChannelSimulatorV3App:NoCompatibleGenerator", "%s", ...
                        app.backendFailureMessage(selection));
                end
                app.BackendSelection = selection;
                backend = selection.selected_backend;
                app.updateProgress(0.58, "模块三：构造预测请求", ...
                    "使用 " + app.backendDisplayName(backend) + " 生成目标 CIR。", ...
                    0, 0, backend);
                prediction = app.createProductParameterPrediction(backend);
                prediction.selection.generator_backend = selection;
                app.ParameterPrediction = prediction;
                if app.currentAxisName() == "frequency"
                    % v3.2-4a: Frequency generation is deterministic in-band
                    % CTF recovery (linear interpolation of known subcarriers;
                    % Full 6GPCM is not involved). Run the dedicated service.
                    generationConfig = struct("mode", "formal");
                    serviceResult = run_v32_frequency_generation( ...
                        app.ImportResult.dataset, prediction, struct( ...
                        "progress_callback", @app.predictionProgress, ...
                        "cancel_check", @() app.CancellationRequested));
                    targetCount = numel(prediction.target_parameter_sample_index);
                    backendLine = "后端：无（频率确定性恢复，不调用 Full 6GPCM）";
                else
                    generationConfig = app.buildPredictionGenerationConfig(backend);
                    generationConfig.generator_overrides.backend_options = struct( ...
                        "output_profile", app.generatorOutputProfile());
                    if backend == "full_6gpcm"
                        generationConfig.generator_overrides.backend_options.full_interface = ...
                            selection.selected_adapter_variant;
                        if ismember(app.currentAxisName(), ["time", "space"])
                            % v3.2-3a/3b probes used 8 m/s track speed.
                            generationConfig.generator_overrides.backend_options.full_track_speed_mps = 8.0;
                        end
                    end
                    request = create_prediction_generation_request( ...
                        prediction, generationConfig);
                    serviceResult = run_prediction_generation(request, struct( ...
                        "progress_callback", @app.predictionProgress, ...
                        "cancel_check", @() app.CancellationRequested));
                    targetCount = double(request.target_count);
                    backendLine = "后端：" + backend + ...
                        "（" + generationConfig.mode + "）";
                end
                if ~serviceResult.success
                    error("ChannelSimulatorV3App:PredictionGenerationFailed", ...
                        "%s", strjoin(string(serviceResult.errors(:)), newline));
                end
                app.PredictionResult = serviceResult.prediction_result;
                % Step 13 receives only the task partition and input shape.
                % It deliberately does not place target ground truth inside
                % PredictionResult, so module three remains leakage-free.
                app.PredictionResult.benchmark_context = struct( ...
                    "schema_version", "v3.0-benchmark-context.1", ...
                    "task", app.ImportResult.task, ...
                    "original_dimensions", app.ImportResult.dataset.dimensions, ...
                    "original_schema_version", ...
                        app.ImportResult.dataset.schema_version, ...
                    "original_file_sha256", ...
                        compute_benchmark_file_sha256(app.SelectedFile), ...
                    "target_ground_truth_read_by_prediction", false);
                app.renderParameterPrediction(prediction);
                app.renderAnalysisTabs(app.PredictionResult.analysis, "prediction");
                app.ExportButton.Enable = "on";
                app.ModuleThreeSummaryArea.Value = ...
                    app.modelResultSummary(prediction);
                warningLines = app.predictionWarningLines(prediction);
                displayStatus = string(serviceResult.status);
                if ~isempty(warningLines)
                    displayStatus = "WARNING";
                end
                app.ModuleThreeStatusArea.Value = [ ...
                    "状态：" + displayStatus; ...
                    "模型：" + app.selectedModelName(prediction); ...
                    "逐参数模型：" + app.parameterModelSummary(prediction); ...
                    "模型来源：" + app.modelSelectionBasis(prediction); ...
                    "适配：" + app.adaptationSummary(prediction); ...
                    "设备：" + app.deviceSummary(prediction); ...
                    backendLine; ...
                    "生成目标数：" + string(targetCount); ...
                    "可导出：CIR / CTF / Prediction Manifest"; ...
                    warningLines; ...
                    "说明：本页展示已知区回测，不把目标真值当作已知精度。"];
                if isempty(warningLines)
                    app.setGlobalStatus("预测 CIR 已生成，可查看特性图或导出", "success");
                else
                    app.setGlobalStatus("预测 CIR 已生成，但请查看模型警告", "warning");
                end
                app.finishProgress(true, "预测 CIR、可选 CTF 和特性图均已生成。");
            catch exception
                app.ExportButton.Enable = "off";
                app.showWaitingParameterAxes("预测未完成");
                app.presentUserError(exception, "prediction");
                app.finishProgress(false, string(exception.message));
            end
            app.setBusy(false, "");
            if ~isempty(fieldnames(app.CalibrationResult)) && ...
                    app.CalibrationResult.success
                app.RunPredictionButton.Enable = "on";
            end
        end

        function config = buildPredictionGenerationConfig(app, backend)
            config = default_prediction_generation_config(backend);
            if backend == "full_6gpcm"
                config.mode = "formal";
            else
                config.mode = "preview";
            end
            config.engine_root = app.fullEngineRoot();
            % Task layer uses "space"; the generation layer (request
            % validator) only accepts "position" — map once here.
            if string(app.ImportResult.task.axis) == "space"
                config.task_axis = "position";
            else
                config.task_axis = string(app.ImportResult.task.axis);
            end
            config.target_axis_values = app.targetAxisValues();
            dimensions = app.ImportResult.dataset.dimensions;
            config.dimensions.Tx = dimensions.Tx;
            config.dimensions.Rx = dimensions.Rx;
            if ismember(app.currentAxisName(), ["time", "space"])
                % v3.2-3a/3b chain semantics: each target is one static
                % snapshot at its target time/position, so Nt=1 per target
                % call. The target axis values (time_s / position) are
                % carried in target_axis_values.
                config.dimensions.Nt = 1;
            else
                config.dimensions.Nt = dimensions.Nt;
            end
            config.dimensions.Npath = dimensions.Npath;
            if backend ~= "full_6gpcm" || ...
                    (~isempty(fieldnames(app.BackendSelection)) && ...
                    app.BackendSelection.selected_adapter_variant == "public_api")
                config.scenario = app.generatorScenario(config.scenario, dimensions);
            end
            if app.generatorOutputProfile() == "narrowband"
                config.dimensions.Nf = 1;
                config.ctf.frequency_hz = config.scenario.center_frequency_hz;
            end
            config.parameter_sources.calibrated = ...
                app.CalibrationResult.best.parameters;
            config.parameter_sources.calibrated.calibration_version = ...
                app.CalibrationResult.manifest.schema_version;
        end

        function prediction = createProductParameterPrediction(app, backend)
            selectionMode = "auto";
            requestedModel = "";
            if app.ModeDropDown.Value == "advanced" && ...
                    app.ModelModeDropDown.Value == "manual"
                selectionMode = "manual";
                requestedModel = string(app.ManualModelDropDown.Value);
            end
            if app.currentAxisName() ~= "sample"
                % v3.2-4a: unified three-axis prediction entry for
                % time/space/frequency. All 12 registered models run on all
                % three axes: classical models in MATLAB; neural models
                % (gru/lstm/tcn/dlinear/nlinear) via Python online-fit
                % (experimental, no axis-sequence checkpoint). Automatic
                % mode keeps the studied recommendations / structure hybrid.
                if selectionMode == "manual" && ...
                        ismember(requestedModel, ["gru", "lstm", ...
                        "tcn", "dlinear", "nlinear"])
                    % Neural online-fit needs the Python runtime.
                    predictorConfig = struct( ...
                        "selection_mode", selectionMode, ...
                        "requested_model", requestedModel, ...
                        "adaptation_mode", "off", ...
                        "device", "cpu", ...
                        "fit_progress_callback", @app.p8ExtractionProgress, ...
                        "cancel_check", @() app.CancellationRequested, ...
                        "python_executable", app.resolvePredictorPython());
                else
                    predictorConfig = struct( ...
                        "selection_mode", selectionMode, ...
                        "requested_model", requestedModel, ...
                        "adaptation_mode", "off", ...
                        "device", "cpu", ...
                        "fit_progress_callback", @app.p8ExtractionProgress, ...
                        "cancel_check", @() app.CancellationRequested);
                end
                try
                    prediction = run_v32_axis_prediction( ...
                        app.ImportResult.dataset, app.CalibrationResult, ...
                        app.ImportResult.task, backend, predictorConfig);
                catch exception
                    error("ChannelSimulatorV3App:V32PredictionFailed", ...
                        "%s", string(exception.message));
                end
                return;
            end
            predictorConfig = struct( ...
                "selection_mode", selectionMode, ...
                "requested_model", requestedModel, ...
                "adaptation_mode", string(app.AdaptationDropDown.Value), ...
                "device", string(app.DeviceDropDown.Value), ...
                "fit_progress_callback", @app.p8ExtractionProgress, ...
                "cancel_check", @() app.CancellationRequested);
            predictorConfig.python_executable = app.resolvePredictorPython();
            try
                prediction = create_v31_registry_prediction( ...
                    app.ImportResult.dataset, app.CalibrationResult, ...
                    app.ImportResult.task, backend, predictorConfig);
            catch exception
                if predictorConfig.device == "cuda"
                    predictorConfig.device = "cpu";
                    try
                        prediction = create_v31_registry_prediction( ...
                            app.ImportResult.dataset, app.CalibrationResult, ...
                            app.ImportResult.task, backend, predictorConfig);
                        prediction.model.device_fallback = struct( ...
                            "requested", "cuda", "used", "cpu", ...
                            "reason", string(exception.message));
                        return;
                    catch cpuException
                        exception = cpuException;
                    end
                end
                if selectionMode == "manual"
                    reason = string(exception.message);
                    error("ChannelSimulatorV3App:ManualModelUnavailable", ...
                        "手动模型遇到硬性技术错误，系统没有静默替换模型。" + ...
                        "请检查任务索引、有效已知点、Python/PyTorch、" + ...
                        "checkpoint 和设备：%s", ...
                        reason);
                end
                error("ChannelSimulatorV3App:NoSafetyQualifiedModel", ...
                    "自动预测遇到硬性技术错误，未生成目标 CIR：%s", ...
                    string(exception.message));
            end
        end

        function p8ExtractionProgress(app, event)
            fraction = double(event.fraction);
            app.ModuleThreeStatusArea.Value = [ ...
                "正在从已知区域拟合真实 P8 参数序列"; ...
                sprintf("局部窗口 %d / %d", ...
                    event.completed_windows, event.total_windows); ...
                "目标区域 Ground Truth 未读取"];
            app.updateProgress(0.56 + 0.12 * fraction, ...
                "模块三：提取已知区 P8", ...
                sprintf("局部拟合窗口 %d / %d", ...
                    event.completed_windows, event.total_windows), ...
                0, 0, "");
            drawnow limitrate;
        end

        function executable = resolvePredictorPython(app)
            % Prefer an explicit user choice, then known local environments,
            % and only then a verified command on PATH.  This avoids the
            % Windows Store app-execution alias being mistaken for Python.
            configured = strip(string(getenv("CHANAI_STEP10_PYTHON")), ...
                "both", """");
            if strlength(configured) > 0
                if ~isfile(configured)
                    error("ChannelSimulatorV3App:InvalidPredictorPython", ...
                        "CHANAI_STEP10_PYTHON 指向的文件不存在：%s", ...
                        configured);
                end
                executable = configured;
                return;
            end

            parent = string(fileparts(app.RootPath));
            if ispc
                relativeExecutable = fullfile("Scripts", "python.exe");
            else
                relativeExecutable = fullfile("bin", "python");
            end
            candidates = [ ...
                fullfile(app.RootPath, ".venv", relativeExecutable); ...
                fullfile(parent, "ChanAI-Pulse-v3.1-assets", "runtime", ...
                    "v31_4", ".venv", relativeExecutable)];
            for candidate = candidates.'
                if isfile(candidate)
                    executable = candidate;
                    return;
                end
            end

            [status, ~] = system( ...
                "python -c ""import sys; print(sys.executable)""");
            if status == 0
                executable = "python";
                return;
            end
            error("ChannelSimulatorV3App:PredictorPythonNotFound", ...
                "未找到可运行的 Python。请先安装 requirements，随后在" + ...
                "启动 App 的同一个 MATLAB 会话中执行：" + ...
                "setenv('CHANAI_STEP10_PYTHON','<python.exe 完整路径>')。");
        end

        function value = registryRecommendation(app)
            % v3.2-4a: recommend per task axis. time/space/frequency use the
            % v3.2-2 studied methods; sample keeps the v3.1-7 policy.
            switch app.currentAxisName()
                case "time"
                    value = "ar";
                case "space"
                    value = "persistence";
                case "frequency"
                    % v3.2-4a 1A: structure-based hybrid (contiguous block ->
                    % delay-domain OMP sparse; otherwise complex linear).
                    value = "structure_hybrid";
                otherwise
                    if app.taskType() == "extrapolation"
                        value = "kalman";
                    else
                        value = "persistence";
                    end
            end
        end

        function value = currentAxisName(app)
            value = "sample";
            if isfield(app.ImportResult, "task") && ...
                    isfield(app.ImportResult.task, "axis")
                value = string(app.ImportResult.task.axis);
            end
            if value == "position"
                value = "space";  % v3.2 compatibility alias
            end
        end

        function message = axisDomainMismatchMessage(app)
            % v3.2-4a: give actionable guidance when the selected task axis
            % is impossible for the imported file domain. CTF + non-frequency
            % is intentionally NOT blocked (legacy sample-axis CTF flows).
            message = "";
            if isempty(fieldnames(app.ImportResult)) || ...
                    ~isfield(app.ImportResult, "dataset") || ...
                    isempty(fieldnames(app.ImportResult.dataset))
                return;
            end
            domain = lower(string(app.ImportResult.dataset.domain));
            axis = app.currentAxisName();
            if domain == "cir" && axis == "frequency"
                message = "该文件是 CIR 时域信道（无频率子载波轴）。" + ...
                    "“频率”任务轴需要 CTF 频谱文件；请将任务轴改为“样本”“时间”或“空间”后重新加载。";
            end
        end

        function value = taskType(app)
            if isfield(app.ImportResult.task, "task_type")
                value = string(app.ImportResult.task.task_type);
            else
                value = string(app.ImportResult.task.mode);
            end
        end

        function lines = modelResultSummary(app, prediction)
            selected = app.selectedModelName(prediction);
            recommendation = app.registryRecommendation();
            if ismember(app.currentAxisName(), ["time", "space", "frequency"])
                lines = app.v32ModelResultSummary(prediction, ...
                    selected, recommendation);
                return;
            end
            safety = app.predictionSafetySummary(prediction);
            lines = [ ...
                "正式预测已完成：" + selected; ...
                "Registry 冻结推荐：" + recommendation; ...
                "逐参数模型：" + app.parameterModelSummary(prediction); ...
                "已知区回测：" + string(safety.backtest_examples) + ...
                    " 个窗口，所选 NRMSE=" + sprintf("%.4f", ...
                    safety.selected_normalized_rmse); ...
                "本地最佳基线：" + safety.best_safe_baseline + ...
                    "（NRMSE=" + sprintf("%.4f", ...
                    safety.best_safe_baseline_normalized_rmse) + "）"; ...
                "连续性检查：" + safety.continuity_status + "（最大比值 " + ...
                    sprintf("%.3f", safety.maximum_continuity_ratio) + ...
                    " / 门限 " + sprintf("%.1f", ...
                    safety.continuity_threshold) + "）"; ...
                "参数包：P" + string(numel(prediction.parameter_names)); ...
                "局部观测参数：" + ...
                    strjoin(safety.fitted_parameter_names, ", "); ...
                "安全冻结参数：" + ...
                    strjoin(safety.frozen_parameter_names, ", "); ...
                "选择依据：" + app.modelSelectionBasis(prediction); ...
                "适配结果：" + app.adaptationSummary(prediction); ...
                "目标区域 Ground Truth：未读取"; ...
                "输出：预测 CIR、可选 CTF、特性图和可审计 Manifest"; ...
                app.predictionWarningLines(prediction)];
        end

        function lines = v32ModelResultSummary(app, prediction, selected, recommendation)
            axis = app.currentAxisName();
            knownCount = 0;
            if isfield(prediction, "known_context_parameter_sample_index")
                knownCount = numel( ...
                    prediction.known_context_parameter_sample_index);
            end
            targetCount = 0;
            if isfield(prediction, "target_parameter_sample_index")
                targetCount = numel(prediction.target_parameter_sample_index);
            end
            lines = [ ...
                "正式预测已完成：" + selected; ...
                "Registry 冻结推荐：" + recommendation; ...
                "逐参数模型：" + app.parameterModelSummary(prediction); ...
                "预测对象：" + app.v32PredictionObject(axis); ...
                "已知区观测点：" + string(knownCount) + ...
                    "（仅使用已知区，未读取目标区真值）"; ...
                "目标区预测点数：" + string(targetCount); ...
                "选择依据：" + app.modelSelectionBasis(prediction); ...
                "适配结果：" + app.adaptationSummary(prediction); ...
                "目标区域 Ground Truth：未读取"; ...
                "输出：" + app.v32OutputDescription(axis); ...
                app.predictionWarningLines(prediction)];
        end

        function value = v32PredictionObject(~, axis)
            switch axis
                case "time"
                    value = "沿时间轴的目标 DS_mu/KF_mu（AR(4) 外推，num_clusters 冻结）";
                case "space"
                    value = "沿空间轴的目标 DS_mu/KF_mu（Persistence 外推，num_clusters 冻结）";
                otherwise
                    value = "缺失带内子载波的 CTF 幅度/相位（结构分流恢复：连续块→延迟域稀疏，其余→线性插值）";
            end
        end

        function value = v32OutputDescription(~, axis)
            if axis == "frequency"
                value = "恢复 CTF、确定性 IFFT 导出的 CIR、特性图和可审计 Manifest";
            else
                value = "预测 CIR（Full 6GPCM 公共 API）、可选 CTF 和特性图";
            end
        end

        function lines = predictionWarningLines(app, prediction)
            lines = strings(0, 1);
            if isfield(prediction, "warnings") && ~isempty(prediction.warnings)
                values = app.trLines(string(prediction.warnings(:)));
                lines = app.tr("警告：") + values;
            end
        end

        function value = parameterModelSummary(app, prediction)
            value = app.selectedModelName(prediction);
            if ~isfield(prediction.selection, "selected_model_by_parameter")
                return;
            end
            mapping = prediction.selection.selected_model_by_parameter;
            preferred = ["DS_mu", "KF_mu", "num_clusters"];
            parts = strings(0, 1);
            for name = preferred
                if isfield(mapping, name)
                    parts(end + 1, 1) = name + "=" + ...
                        app.parameterModelName(prediction, name); %#ok<AGROW>
                end
            end
            if ~isempty(parts)
                value = strjoin(parts, ", ");
            end
        end

        function value = predictionSafetySummary(app, prediction)
            value = struct( ...
                "backtest_examples", 0, ...
                "selected_normalized_rmse", NaN, ...
                "best_safe_baseline", "", ...
                "best_safe_baseline_normalized_rmse", NaN, ...
                "maximum_continuity_ratio", NaN, ...
                "continuity_threshold", NaN, ...
                "continuity_status", "N/A", ...
                "fitted_parameter_names", strings(0, 1), ...
                "frozen_parameter_names", strings(0, 1));
            if ~isfield(prediction, "backtest") || ...
                    ~isfield(prediction, "continuity")
                return;
            end
            value.backtest_examples = double(prediction.backtest.example_count);
            if isfield(prediction.backtest, "selected_score") && ...
                    ~isempty(prediction.backtest.selected_score.normalized_rmse)
                value.selected_normalized_rmse = double( ...
                    prediction.backtest.selected_score.normalized_rmse);
            else
                selected = app.selectedModelName(prediction);
                value.selected_normalized_rmse = double( ...
                    prediction.backtest.scores.(selected).normalized_rmse);
            end
            value.best_safe_baseline = string( ...
                prediction.backtest.best_safe_baseline);
            value.best_safe_baseline_normalized_rmse = double( ...
                prediction.backtest.best_safe_baseline_score.normalized_rmse);
            value.maximum_continuity_ratio = double( ...
                prediction.continuity.maximum_ratio);
            value.continuity_threshold = double( ...
                prediction.continuity.threshold);
            if logical(prediction.continuity.passed)
                value.continuity_status = "PASS";
            else
                value.continuity_status = "WARNING";
            end
            value.fitted_parameter_names = string( ...
                prediction.backtest.evaluated_parameter_names(:));
            value.frozen_parameter_names = string( ...
                prediction.backtest.frozen_imputed_parameter_names(:));
        end

        function value = selectedModelName(~, prediction)
            value = "unknown";
            if isfield(prediction.selection, "selected_model")
                value = string(prediction.selection.selected_model);
            elseif isfield(prediction.selection, "selected_model_type")
                value = string(prediction.selection.selected_model_type);
            end
        end

        function value = modelSelectionBasis(~, prediction)
            value = "unspecified";
            if isfield(prediction.selection, "selection_basis")
                value = string(prediction.selection.selection_basis);
            elseif isfield(prediction.selection, "fallback_reason")
                value = "fallback: " + ...
                    string(prediction.selection.fallback_reason);
            elseif isfield(prediction.selection, "reason")
                value = string(prediction.selection.reason);
            end
        end

        function value = adaptationSummary(~, prediction)
            value = "off";
            if ~isfield(prediction, "adaptation")
                return;
            end
            if isfield(prediction.adaptation, "status")
                value = string(prediction.adaptation.status);
            elseif isfield(prediction.adaptation, "performed") && ...
                    logical(prediction.adaptation.performed)
                value = "accepted";
            end
            if isfield(prediction.adaptation, "reason")
                value = value + " (" + string(prediction.adaptation.reason) + ")";
            end
        end

        function value = deviceSummary(app, prediction)
            value = string(app.DeviceDropDown.Value);
            if isfield(prediction, "model") && ...
                    isfield(prediction.model, "device_fallback")
                fallback = prediction.model.device_fallback;
                value = string(fallback.requested) + " → " + ...
                    string(fallback.used) + "（GPU 不可用，已明确回退）";
            end
        end

        function values = targetAxisValues(app)
            task = app.ImportResult.task;
            indices = double(task.target_indices(:));
            dataset = app.ImportResult.dataset;
            if isfield(task, "axis_values") && ...
                    numel(task.axis_values) >= max(indices)
                values = double(task.axis_values(indices));
            elseif string(task.axis) == "position" && ...
                    isfield(dataset.axes, "sample_position_m")
                values = double(dataset.axes.sample_position_m(indices));
            elseif isfield(dataset.axes, "sample_index")
                values = double(dataset.axes.sample_index(indices));
            else
                values = indices;
            end
        end

        function predictionProgress(app, event)
            app.ModuleThreeStatusArea.Value = [ ...
                "模块三运行中：" + string(event.message); ...
                sprintf("目标 %d / %d", event.target_number, event.target_count)];
            progress = 0.58;
            if isfield(event, "progress")
                progress = 0.58 + 0.40 * max(0, min(1, double(event.progress)));
            end
            app.updateProgress(progress, "模块三：生成目标 CIR", ...
                string(event.message), event.target_number, event.target_count, "");
            drawnow limitrate;
        end

        function renderCalibrationResult(app)
            result = app.CalibrationResult;
            app.ModuleTwoStatusArea.Value = [ ...
                "状态: " + string(result.status); ...
                "实际策略: " + string(result.selected_strategy); ...
                "选择来源: " + string(result.selection_source); ...
                "理由: " + string(result.selection_reason)];
            if result.success
                app.ModuleTwoProgressFraction = 1;
                update_filled_progress_bar(app.ModuleTwoProgressBar, 1, ...
                    Text="100%", State="success");
                parameterNames = string(fieldnames(result.best.parameters));
                parameterValues = zeros(numel(parameterNames), 1);
                for parameterIndex = 1:numel(parameterNames)
                    parameterValues(parameterIndex) = double( ...
                        result.best.parameters.(parameterNames(parameterIndex)));
                end
                sourceLabel = app.calibrationSourceLabel();
                app.ModuleTwoParameterTable.Data = table( ...
                    parameterNames, parameterValues, ...
                    repmat(sourceLabel, numel(parameterNames), 1), ...
                    'VariableNames', {'Parameter', 'Value', 'Source'});
                app.ModuleTwoManifestArea.Value = [ ...
                    "优化 Manifest"; ...
                    "requested=" + string(result.requested_strategy); ...
                    "selected=" + string(result.selected_strategy); ...
                    "best_score=" + string(result.manifest.best_score); ...
                    "backend=" + string(result.config.generator_config.backend)];
            else
                app.ModuleTwoProgressFraction = 0;
                update_filled_progress_bar(app.ModuleTwoProgressBar, 0, ...
                    Text="0%", State="error");
                app.ModuleTwoParameterTable.Data = table( ...
                    strings(0, 1), zeros(0, 1), strings(0, 1), ...
                    'VariableNames', {'Parameter', 'Value', 'Source'});
                app.ModuleTwoManifestArea.Value = ["没有可用标定结果"; string(result.errors(:))];
            end
        end

        function requestCancellation(app)
            app.CancellationRequested = true;
            app.ModuleTwoStatusArea.Value = ["已请求取消。"; "当前候选返回后将停止运行。"];
        end

        function renderAnalysisTabs(app, analysis, role)
            entries = select_channel_plot_entries(analysis.registry);
            if role == "input"
                app.updatePlotTabTitles(entries, "input");
                app.renderPlotOverview(app.InputOverviewTab, analysis);
                app.renderAnalysisCategory(app.InputDelayTab, analysis, entries, "基础");
                app.renderAnalysisCategory(app.InputSpatialTab, analysis, entries, "空间与角度");
                app.renderAnalysisCategory(app.InputTimeTab, analysis, entries, "时间与多普勒");
                app.renderAnalysisCategory(app.InputAdditionalTab, analysis, entries, "附加");
            elseif role == "prediction"
                app.updatePlotTabTitles(entries, "prediction");
                app.renderPlotOverview(app.OutputOverviewTab, analysis);
                app.renderAnalysisCategory(app.OutputDelayTab, analysis, entries, "基础");
                app.renderAnalysisCategory(app.OutputSpatialTab, analysis, entries, "空间与角度");
                app.renderAnalysisCategory(app.OutputTimeTab, analysis, entries, "时间与多普勒");
                app.renderAnalysisCategory(app.OutputAdditionalTab, analysis, entries, "附加");
            end
        end

        function renderAnalysisCategory(app, tab, analysis, entries, category)
            delete(tab.Children);
            mask = string({entries.category}) == category;
            selected = entries(mask);
            if isempty(selected)
                app.showWaitingPlots(tab, "当前数据不支持这一组图表；请查看右侧能力说明。");
                return;
            end
            columns = min(2, numel(selected));
            rows = ceil(numel(selected) / columns);
            grid = uigridlayout(tab, [rows, columns], ...
                "Padding", [7, 7, 7, 7], "RowSpacing", 7, "ColumnSpacing", 7);
            for index = 1:numel(selected)
                axesHandle = uiaxes(grid);
                render_channel_characteristic(axesHandle, analysis, selected(index).id, ...
                    "Language", app.CurrentLanguage);
            end
        end

        function updatePlotTabTitles(app, entries, role)
            categories = string({entries.category});
            delayCount = sum(categories == "基础");
            spatialCount = sum(categories == "空间与角度");
            timeCount = sum(categories == "时间与多普勒");
            additionalCount = sum(categories == "附加");
            if role == "input"
                app.InputOverviewTab.Title = app.tabTitle("全部概览", numel(entries));
                app.InputDelayTab.Title = app.tabTitle("时延 / 频率", delayCount);
                app.InputSpatialTab.Title = app.tabTitle("空间 / 角度", spatialCount);
                app.InputTimeTab.Title = app.tabTitle("时间 / 多普勒", timeCount);
                app.InputAdditionalTab.Title = app.tabTitle("附加可视化", additionalCount);
            else
                app.OutputOverviewTab.Title = app.tabTitle("全部概览", numel(entries));
                app.OutputDelayTab.Title = app.tabTitle("时延 / 频率", delayCount);
                app.OutputSpatialTab.Title = app.tabTitle("空间 / 角度", spatialCount);
                app.OutputTimeTab.Title = app.tabTitle("时间 / 多普勒", timeCount);
                app.OutputAdditionalTab.Title = app.tabTitle("附加可视化", additionalCount);
            end
        end

        function renderPlotOverview(app, tab, analysis)
            delete(tab.Children);
            allEntries = analysis.registry.entries;
            if analysis.registry.is_standard_classification
                eligible = [allEntries.is_standard].' | ...
                    ([allEntries.is_additional].' & [allEntries.available].');
                allEntries = allEntries(eligible);
            end
            if isempty(allEntries)
                app.showWaitingPlots(tab, "当前数据没有可登记的特性图。");
                return;
            end
            columns = min(3, numel(allEntries));
            rows = ceil(numel(allEntries) / columns);
            grid = uigridlayout(tab, [rows, columns], ...
                "Padding", [8, 8, 8, 8], "RowSpacing", 8, "ColumnSpacing", 8);
            for index = 1:numel(allEntries)
                entry = allEntries(index);
                if entry.available
                    color = [0.91, 0.97, 0.93];
                    state = "可用";
                    reason = "已通过数据维度与元数据检查";
                else
                    color = [0.97, 0.95, 0.94];
                    state = "不可用";
                    reason = string(entry.reason);
                end
                if entry.is_additional
                    kind = "附加可视化";
                else
                    kind = "标准特性图";
                end
                card = uipanel(grid, "Title", app.tr(string(entry.title_zh)), ...
                    "FontWeight", "bold", "BackgroundColor", color);
                cardGrid = uigridlayout(card, [3, 1], ...
                    "RowHeight", {24, 22, "1x"}, "Padding", [8, 5, 8, 7]);
                uilabel(cardGrid, "Text", app.tr(state + " · " + kind), ...
                    "FontWeight", "bold");
                uilabel(cardGrid, "Text", app.tr("类别：" + string(entry.category)), ...
                    "FontColor", [0.35, 0.40, 0.46]);
                uilabel(cardGrid, "Text", app.tr(reason), "WordWrap", "on", ...
                    "FontColor", [0.35, 0.40, 0.46]);
            end
        end

        function showWaitingPlots(app, tab, message)
            delete(tab.Children);
            grid = uigridlayout(tab, [1, 1]);
            uilabel(grid, "Text", app.tr(message), "HorizontalAlignment", "center", ...
                "FontWeight", "bold", "FontColor", [0.35, 0.40, 0.46]);
        end

        function titleText = tabTitle(app, base, count)
            titleText = app.tr(base) + " (" + string(count) + ")";
            if app.CurrentLanguage == "zh"
                titleText = app.tr(base) + "（" + string(count) + "）";
            end
        end

        function localizeAxes(app, axesHandle)
            try
                axesHandle.Title.String = app.tr(axesHandle.Title.String);
                axesHandle.XLabel.String = app.tr(axesHandle.XLabel.String);
                axesHandle.YLabel.String = app.tr(axesHandle.YLabel.String);
            catch
            end
        end

        function updateModelControls(app)
            isAdvanced = app.ModeDropDown.Value == "advanced";
            if ~isAdvanced
                app.ModelModeDropDown.Value = "auto";
                app.AdaptationDropDown.Value = "auto";
                app.DeviceDropDown.Value = "auto";
            end
            app.ModelModeDropDown.Enable = onOff(isAdvanced);
            app.AdaptationDropDown.Enable = onOff(isAdvanced);
            app.DeviceDropDown.Enable = onOff(isAdvanced);
            isManual = app.ModelModeDropDown.Value == "manual";
            if isManual && isAdvanced
                app.ManualModelDropDown.Enable = "on";
            else
                app.ManualModelDropDown.Enable = "off";
            end
            if isManual
                selected = string(app.ManualModelDropDown.Value);
                app.ModuleThreeSummaryArea.Value = [ ...
                    "高级用户手动选择：" + selected; ...
                    "该模型可能不是系统推荐，结果会写入 Manifest。"; ...
                    "神经模型属于 legacy 16→4 实验候选，长目标采用滚动兼容。"; ...
                    "目标区域 Ground Truth 不参与选择或适配。"];
            elseif isempty(fieldnames(app.PredictionResult))
                app.ModuleThreeSummaryArea.Value = [ ...
                    "普通模式按上传已知区逐参数回测自动选择。"; ...
                    "支持全历史任意长度外推和双向内插。"; ...
                    "性能异常会警告；只有硬性技术错误才拒绝。"];
            end
        end

        function applyUserMode(app)
            isAdvanced = app.ModeDropDown.Value == "advanced";
            if isAdvanced
                app.AdvancedPanels.Visible = "on";
            else
                app.AdvancedPanels.Visible = "off";
            end
            app.updateModelControls();
            app.refreshBackendCompatibility();
        end

        function refreshBackendCompatibility(app)
            if app.IsRunning || isempty(fieldnames(app.ImportResult)) || ...
                    ~isfield(app.ImportResult, "validation") || ...
                    ~app.ImportResult.validation.is_valid || ...
                    isempty(fieldnames(app.InputAnalysis)) || ...
                    ~isfield(app.InputAnalysis, "status") || ...
                    string(app.InputAnalysis.status) == "FAIL"
                return;
            end
            selection = app.resolveBackendSelection();
            app.BackendSelection = selection;
            if selection.success
                label = app.backendDisplayName(selection.selected_backend);
                app.StartButton.Enable = "on";
                app.ModuleTwoRunButton.Enable = "on";
                if selection.requested_backend == "auto"
                    app.StartButton.Text = "开始预测（自动：" + label + "）";
                else
                    app.StartButton.Text = "开始预测（" + label + "）";
                end
                app.ModuleTwoStatusArea.Value = [ ...
                    "模块一验证通过。"; ...
                    "生成器：" + label; ...
                    "选择方式：" + app.backendSelectionSource(selection.source); ...
                    "说明：运行前已同时检查维度兼容性和后端可用性。"];
                app.InputQualityLabel.Value = [ ...
                    app.BaseInputQualityValue(:); ...
                    "生成器预检：PASS，已选择 " + label + "。"];
                if isempty(fieldnames(app.CalibrationResult)) && ...
                        isempty(fieldnames(app.PredictionResult))
                    app.setGlobalStatus("输入任务已验证，生成器兼容性检查通过", "success");
                end
            else
                app.StartButton.Enable = "off";
                app.ModuleTwoRunButton.Enable = "off";
                app.StartButton.Text = "当前无兼容生成器";
                app.ModuleTwoStatusArea.Value = [ ...
                    "模块一的数据仍可查看和分析。"; ...
                    "但当前没有可生成同维度 CIR 的正式后端。"; ...
                    app.backendFailureLines(selection)];
                app.InputQualityLabel.Value = [ ...
                    app.BaseInputQualityValue(:); ...
                    "生成器预检：当前全部正式候选均不适用。"; ...
                    app.backendFailureLines(selection)];
                app.setGlobalStatus("数据分析完成，但暂无兼容的 CIR 生成器", "error");
            end
            app.localizeCurrentView();
        end

        function selection = resolveBackendSelection(app)
            selection = select_generator_backend( ...
                string(app.BackendDropDown.Value), ...
                app.ImportResult.dataset.dimensions, ...
                FullEngineRoot=app.fullEngineRoot());
        end

        function root = fullEngineRoot(app)
            root = strtrim(string(app.EngineRootField.Value));
            if strlength(root) > 0
                return;
            end
            installation = resolve_full_6gpcm_root();
            root = installation.root;
        end

        function scenario = generatorScenario(app, scenario, dimensions)
            dataset = app.ImportResult.dataset;
            metadata = dataset.metadata;
            if isfield(metadata, "center_frequency_hz") && ...
                    isnumeric(metadata.center_frequency_hz) && ...
                    isscalar(metadata.center_frequency_hz) && ...
                    isfinite(metadata.center_frequency_hz) && ...
                    metadata.center_frequency_hz > 0
                scenario.center_frequency_hz = double(metadata.center_frequency_hz);
            end
            if isfield(metadata, "bandwidth_hz") && ...
                    isnumeric(metadata.bandwidth_hz) && ...
                    isscalar(metadata.bandwidth_hz) && ...
                    isfinite(metadata.bandwidth_hz) && metadata.bandwidth_hz > 0
                scenario.bandwidth_hz = double(metadata.bandwidth_hz);
            elseif isfield(dataset.axes, "frequency_hz") && ...
                    numel(dataset.axes.frequency_hz) > 1
                frequencyHz = double(dataset.axes.frequency_hz(:));
                scenario.bandwidth_hz = max(frequencyHz) - min(frequencyHz) + ...
                    median(diff(frequencyHz));
            end
            if isfield(metadata, "snapshot_interval_s") && ...
                    isnumeric(metadata.snapshot_interval_s) && ...
                    isscalar(metadata.snapshot_interval_s) && ...
                    isfinite(metadata.snapshot_interval_s) && ...
                    metadata.snapshot_interval_s > 0
                scenario.snapshot_interval_s = ...
                    double(metadata.snapshot_interval_s);
            elseif isfield(dataset.axes, "time_s") && ...
                    numel(dataset.axes.time_s) > 1
                scenario.snapshot_interval_s = ...
                    median(diff(double(dataset.axes.time_s(:))));
            end
            if dimensions.Nt > 1
                scenario.track_type = "linear";
            else
                scenario.track_type = "static";
            end
        end

        function profile = generatorOutputProfile(app)
            profile = "native";
            if ~isempty(fieldnames(app.InputAnalysis)) && ...
                    isfield(app.InputAnalysis, "classification") && ...
                    string(app.InputAnalysis.classification) == ...
                    "narrowband_static_siso"
                profile = "narrowband";
            end
        end

        function label = calibrationSourceLabel(app)
            label = "known 区 Grid/SA 标定";
            if ~isempty(fieldnames(app.CalibrationResult)) && ...
                    isfield(app.CalibrationResult, "selected_strategy")
                if string(app.CalibrationResult.selected_strategy) == ...
                        "capability_defaults"
                    label = "窄带不可辨识参数：版本化默认值";
                elseif string(app.CalibrationResult.selected_strategy) == ...
                        "frequency_deterministic_recovery"
                    label = "频率轴确定性恢复：不依赖标定（版本化默认值）";
                end
            end
        end

        function message = backendFailureMessage(app, selection)
            if selection.requested_backend == "auto"
                heading = "已检查当前注册的全部正式生成器，但没有可用后端：";
            else
                heading = "手动指定的生成器不可用；系统尊重选择，不会自动替换：";
            end
            message = app.tr(strjoin([ ...
                heading; ...
                app.backendFailureLines(selection); ...
                "QuaDRiGa 尚未接入正式 Generator Adapter，因此本次不会用测试 Mock 或偷偷缩减天线维度。"], ...
                newline));
        end

        function lines = backendFailureLines(app, selection)
            lines = strings(0, 1);
            for index = 1:numel(selection.candidates)
                candidate = selection.candidates(index);
                lines(end + 1, 1) = app.backendDisplayName(candidate.backend) + ...
                    "：" + app.translateBackendReason(candidate); %#ok<AGROW>
            end
        end

        function reason = translateBackendReason(app, candidate)
            switch candidate.reason_code
                case "lite_requires_siso"
                    reason = app.tr("不兼容；Lite 只支持 Tx=1、Rx=1。");
                case "full_fixed_entrypoint_dimensions"
                    reason = app.tr("不兼容；历史 Full 固定入口只支持 Tx=2、Rx=2、Nt=2。");
                case "full_resource_limit_exceeded"
                    reason = app.tr("格式兼容，但当前 Tx×Rx×Nt 超出配置的 Full 运行资源上限。");
                case "backend_unavailable"
                    reason = app.tr("维度兼容，但后端文件或配置不可用。");
                otherwise
                    if candidate.available
                        reason = app.tr("兼容且可用。");
                    else
                        reason = app.tr(string(candidate.reason));
                    end
            end
        end

        function label = backendDisplayName(~, backend)
            if backend == "lite_6gpcm"
                label = "6GPCM-Lite";
            else
                label = "Full 6GPCM";
            end
        end

        function label = backendSelectionSource(~, source)
            if source == "automatic"
                label = "系统自动选择";
            else
                label = "高级用户手动指定";
            end
        end

        function switchLanguage(app)
            if app.LanguageDropDown.Value == "English"
                app.CurrentLanguage = "en";
            else
                app.CurrentLanguage = "zh";
            end
            % Rebuild plots after the language changes.  Axis titles and
            % legends are created by the plotting layer, so translating only
            % existing controls would leave stale Chinese graphics behind.
            if ~isempty(fieldnames(app.InputAnalysis)) && ...
                    isfield(app.InputAnalysis, "registry")
                app.renderAnalysisTabs(app.InputAnalysis, "input");
            end
            if ~isempty(fieldnames(app.PredictionResult)) && ...
                    isfield(app.PredictionResult, "analysis")
                app.renderAnalysisTabs(app.PredictionResult.analysis, "prediction");
            end
            if ~isempty(fieldnames(app.ParameterPrediction))
                app.renderParameterPrediction(app.ParameterPrediction);
            end
            app.localizeCurrentView();
        end

        function value = tr(app, value)
            value = translate_channel_simulator_text(value, app.CurrentLanguage);
        end

        function values = trLines(app, values)
            values = translate_channel_simulator_text(string(values(:)), ...
                app.CurrentLanguage);
        end

        function localizeCurrentView(app)
            % Translate current controls in-place, including output created
            % before the language was changed.  Data fields themselves are
            % intentionally left untouched; this is presentation only.
            components = findall(app.UIFigure);
            for index = 1:numel(components)
                component = components(index);
                try
                    if isprop(component, "Text")
                        component.Text = app.tr(component.Text);
                    end
                    if isprop(component, "Title")
                        component.Title = app.tr(component.Title);
                    end
                    if isprop(component, "Tooltip") && ...
                            strlength(string(component.Tooltip)) > 0
                        component.Tooltip = app.tr(component.Tooltip);
                    end
                    if isprop(component, "Items")
                        component.Items = app.tr(component.Items);
                    end
                    if isprop(component, "ColumnName")
                        component.ColumnName = cellstr(app.tr( ...
                            string(component.ColumnName)));
                    end
                    if isa(component, "matlab.ui.control.TextArea")
                        component.Value = app.trLines(component.Value);
                    end
                    if isprop(component, "String") && ...
                            ~isa(component, "matlab.ui.control.EditField")
                        component.String = app.tr(component.String);
                    end
                catch
                    % Some graphics handles expose read-only presentation
                    % properties.  They are localized separately below.
                end
            end
            axesHandles = findall(app.UIFigure, "Type", "axes");
            for index = 1:numel(axesHandles)
                axesHandle = axesHandles(index);
                try
                    axesHandle.Title.String = app.tr(axesHandle.Title.String);
                    axesHandle.XLabel.String = app.tr(axesHandle.XLabel.String);
                    axesHandle.YLabel.String = app.tr(axesHandle.YLabel.String);
                catch
                end
            end
            legendHandles = findall(app.UIFigure, "Type", "legend");
            for index = 1:numel(legendHandles)
                try
                    legendHandles(index).String = cellstr(app.tr( ...
                        string(legendHandles(index).String)));
                catch
                end
            end
            app.UIFigure.Name = "ChanAI Pulse v3.1.0";
        end

        function exportPrediction(app)
            if isempty(fieldnames(app.PredictionResult))
                uialert(app.UIFigure, "当前没有可导出的 PredictionResult。", "尚无预测结果");
                return;
            end
            target = uigetdir(pwd, "选择预测结果导出目录");
            if isequal(target, 0)
                app.restoreWindowFocus();
                return;
            end
            try
                files = export_prediction_result_bundle(app.PredictionResult, string(target));
                uialert(app.UIFigure, "导出完成：" + newline + files.cir_hdf5, "导出完成");
            catch exception
                app.presentUserError(exception, "export");
            end
            app.restoreWindowFocus();
        end

        function setBusy(app, isBusy, message)
            app.IsRunning = isBusy;
            if isBusy
                app.LoadAnalyzeButton.Enable = "off";
                app.StartButton.Enable = "off";
                app.ModuleTwoRunButton.Enable = "off";
                app.RunPredictionButton.Enable = "off";
                app.setGlobalStatus(message, "running");
            else
                app.LoadAnalyzeButton.Enable = "on";
                inputReady = ~isempty(fieldnames(app.ImportResult)) && ...
                    isfield(app.ImportResult, "validation") && ...
                    app.ImportResult.validation.is_valid && ...
                    ~isempty(fieldnames(app.InputAnalysis)) && ...
                    isfield(app.InputAnalysis, "status") && ...
                    string(app.InputAnalysis.status) ~= "FAIL";
                app.StartButton.Enable = onOff(inputReady);
                app.ModuleTwoRunButton.Enable = app.StartButton.Enable;
                if ~isempty(fieldnames(app.CalibrationResult)) && ...
                        isfield(app.CalibrationResult, "success") && ...
                        app.CalibrationResult.success
                    app.RunPredictionButton.Enable = "on";
                end
            end
            if ~isBusy
                app.localizeCurrentView();
            end
            drawnow;
        end

        function beginProgress(app, titleText, detail)
            % Keep one continuous card for the normal Module-2-to-Module-3
            % workflow.  A later manual rerun starts a fresh card.
            continueCurrentRun = app.ProgressVisible && ...
                app.ProgressDismissButton.Enable == "off";
            if ~continueCurrentRun
                app.ProgressStartedAt = tic;
                update_filled_progress_bar(app.ProgressBar, 0, ...
                    Text="0%", State="running");
                app.ProgressPercentLabel.Text = "0%";
                app.ProgressDismissButton.Enable = "off";
                app.ProgressOverlay.Visible = "on";
                app.ProgressVisible = true;
            end
            app.ProgressTitleLabel.Text = app.tr(titleText);
            app.ProgressDetailArea.Value = app.trLines([ ...
                "当前阶段：" + string(detail); ...
                "请保持软件窗口打开；Full 6GPCM 的单个目标可能需要数十秒。"]);
            app.updateProgressElapsed();
            drawnow;
        end

        function updateProgress(app, fraction, phase, detail, targetNumber, targetCount, backend)
            if ~app.ProgressVisible
                app.beginProgress("正在运行", "正在准备任务。");
            end
            fraction = max(0, min(1, double(fraction)));
            update_filled_progress_bar(app.ProgressBar, fraction, ...
                Text=sprintf("%.0f%%", 100 * fraction), State="running");
            app.ProgressPercentLabel.Text = sprintf("%.0f%%", 100 * fraction);
            lines = ["当前阶段：" + string(phase); string(detail)];
            if targetCount > 0
                lines(end + 1, 1) = sprintf("目标进度：%d / %d", ...
                    targetNumber, targetCount); %#ok<AGROW>
            end
            if strlength(string(backend)) > 0
                lines(end + 1, 1) = "生成后端：" + string(backend); %#ok<AGROW>
            end
            app.ProgressDetailArea.Value = app.trLines(lines);
            app.updateProgressElapsed();
            drawnow limitrate;
        end

        function finishProgress(app, success, detail)
            if ~app.ProgressVisible
                return;
            end
            if success
                update_filled_progress_bar(app.ProgressBar, 1, ...
                    Text="100%", State="success");
                app.ProgressPercentLabel.Text = "100%";
                app.ProgressTitleLabel.Text = app.tr("运行完成");
                app.ProgressDetailArea.Value = app.trLines([ ...
                    "最终状态：成功"; string(detail); ...
                    "可点击“收起进度面板”继续查看结果。"]);
                app.ProgressTitleLabel.FontColor = [0.08, 0.50, 0.25];
            else
                update_filled_progress_bar(app.ProgressBar, ...
                    get_filled_progress_value(app.ProgressBar), ...
                    State="error");
                app.ProgressTitleLabel.Text = app.tr("运行未完成");
                app.ProgressDetailArea.Value = app.trLines([ ...
                    "最终状态：未完成"; string(detail); ...
                    "请根据上方信息修正任务后重新运行。"]);
                app.ProgressTitleLabel.FontColor = [0.70, 0.12, 0.12];
            end
            app.ProgressDismissButton.Enable = "on";
            app.updateProgressElapsed();
            drawnow;
        end

        function dismissProgress(app)
            app.ProgressOverlay.Visible = "off";
            app.ProgressVisible = false;
        end

        function updateProgressElapsed(app)
            elapsedSeconds = 0;
            if app.ProgressStartedAt ~= uint64(0)
                elapsedSeconds = toc(app.ProgressStartedAt);
            end
            if app.CurrentLanguage == "en"
                app.ProgressElapsedLabel.Text = ...
                    "Elapsed: " + sprintf("%.0f", elapsedSeconds) + " s";
            else
                app.ProgressElapsedLabel.Text = ...
                    "已用时间：" + sprintf("%.0f", elapsedSeconds) + " 秒";
            end
        end

        function setGlobalStatus(app, message, kind)
            colors = struct( ...
                "neutral", [0.35, 0.40, 0.46], ...
                "running", [0.68, 0.38, 0.05], ...
                "warning", [0.76, 0.40, 0.04], ...
                "success", [0.08, 0.50, 0.25], ...
                "error", [0.70, 0.12, 0.12]);
            app.GlobalStatusLabel.Text = app.tr(string(message));
            app.GlobalStatusLabel.FontColor = colors.(char(kind));
        end

        function restoreWindowFocus(app)
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                return;
            end
            if app.UIFigure.Visible == "off"
                return;
            end
            if app.UIFigure.WindowState == "minimized"
                app.UIFigure.WindowState = "normal";
            end
            drawnow;
            figure(app.UIFigure);
        end

        function resetLoadedState(app)
            app.ImportResult = struct();
            app.InputAnalysis = struct();
            app.CalibrationResult = struct();
            app.ParameterPrediction = struct();
            app.PredictionResult = struct();
            app.BackendSelection = struct();
            app.StartButton.Enable = "off";
            app.ModuleTwoRunButton.Enable = "off";
            app.RunPredictionButton.Enable = "off";
            app.ExportButton.Enable = "off";
            app.ModuleTwoProgressFraction = 0;
            update_filled_progress_bar(app.ModuleTwoProgressBar, 0, ...
                Text="0%", State="neutral");
            for name = string(fieldnames(app.DimensionCardLabels)).'
                app.DimensionCardLabels.(name).Text = "—";
            end
            app.InputSummaryLabel.Value = "已选择新文件，等待加载验证";
            app.InputQualityLabel.Value = "尚未分析图表能力";
            app.BaseInputQualityValue = "尚未分析图表能力";
            app.showWaitingPlots(app.InputOverviewTab, "加载后显示全部图表能力");
            app.showWaitingPlots(app.InputDelayTab, "加载后显示时延/频率图");
            app.showWaitingPlots(app.InputSpatialTab, "加载后显示空间/角度图");
            app.showWaitingPlots(app.InputTimeTab, "加载后显示时间/多普勒图");
            app.showWaitingPlots(app.InputAdditionalTab, "加载后显示附加可视化");
            app.showWaitingPlots(app.OutputOverviewTab, "等待新的预测结果");
            app.showWaitingPlots(app.OutputDelayTab, "等待新的预测结果");
            app.showWaitingPlots(app.OutputSpatialTab, "等待新的预测结果");
            app.showWaitingPlots(app.OutputTimeTab, "等待新的预测结果");
            app.showWaitingPlots(app.OutputAdditionalTab, "等待新的预测结果");
            app.showWaitingParameterAxes();
            cla(app.TaskRangeAxes);
            app.TaskRangeAxes.YTick = [];
            title(app.TaskRangeAxes, "已选择文件，请加载后查看任务区间", ...
                "FontSize", 10, "FontWeight", "normal");
        end

        function showWaitingParameterAxes(app, message)
            arguments
                app
                message (1, 1) string = "等待模块三生成预测参数"
            end
            for axesHandle = [app.DelayParameterAxes, app.KFactorParameterAxes]
                cla(axesHandle);
                text(axesHandle, 0.5, 0.5, message, ...
                    "Units", "normalized", "HorizontalAlignment", "center", ...
                    "Color", [0.35, 0.40, 0.46]);
                axesHandle.XTick = [];
                axesHandle.YTick = [];
                axesHandle.Box = "on";
            end
        end

        function renderParameterPrediction(app, prediction)
            names = string(prediction.parameter_names(:));
            values = double(prediction.prediction_parameters);
            values = reshape(values(1, :, :), ...
                [size(values, 2), size(values, 3)]);
            targetX = app.targetAxisValues();
            if isfield(prediction, "known_context_parameters") && ...
                    isfield(prediction, ...
                        "known_context_parameter_sample_index")
                knownValues = double(prediction.known_context_parameters);
                knownIndices = double( ...
                    prediction.known_context_parameter_sample_index(:));
                knownX = app.parameterAxisValues(knownIndices);
            else
                knownValues = zeros(0, numel(names));
                knownX = zeros(0, 1);
            end
            if app.currentAxisName() == "frequency"
                % v3.2-4a: Frequency predicts the CTF magnitude/phase at the
                % missing in-band subcarriers; reuse the two module-three
                % parameter axes with the frequency axis in Hz.
                app.renderOneParameter(app.DelayParameterAxes, ...
                    names, knownValues, values, "magnitude", ...
                    knownX, targetX, "线性幅度", ...
                    app.parameterModelName(prediction, "magnitude"));
                app.renderOneParameter(app.KFactorParameterAxes, ...
                    names, knownValues, values, "phase", ...
                    knownX, targetX, "rad", ...
                    app.parameterModelName(prediction, "phase"));
            else
                app.renderOneParameter(app.DelayParameterAxes, ...
                    names, knownValues, values, "DS_mu", knownX, targetX, ...
                    "log10(s)", app.parameterModelName(prediction, "DS_mu"));
                app.renderOneParameter(app.KFactorParameterAxes, ...
                    names, knownValues, values, "KF_mu", knownX, targetX, ...
                    "dB", app.parameterModelName(prediction, "KF_mu"));
            end
        end

        function value = parameterModelName(app, prediction, parameterName)
            value = app.selectedModelName(prediction);
            if isfield(prediction.selection, "selected_model_by_parameter") && ...
                    isfield(prediction.selection.selected_model_by_parameter, ...
                        parameterName)
                value = string(prediction.selection. ...
                    selected_model_by_parameter.(parameterName));
            end
            if isfield(prediction, "stabilization") && ...
                    isfield(prediction.stabilization, "applied") && ...
                    logical(prediction.stabilization.applied) && ...
                    isfield(prediction.stabilization, ...
                        "requested_model_weight_by_parameter")
                weights = prediction.stabilization. ...
                    requested_model_weight_by_parameter;
                if isfield(weights, parameterName) && ...
                        double(weights.(parameterName)) < 1
                    value = value + "+local_guard(" + ...
                        sprintf("%.2f", double(weights.(parameterName))) + ")";
                end
            end
        end

        function renderOneParameter(app, axesHandle, names, knownValues, ...
                predictedValues, parameterName, knownX, targetX, unit, modelName)
            cla(axesHandle);
            parameterIndex = find(names == parameterName, 1);
            if isempty(parameterIndex)
                text(axesHandle, 0.5, 0.5, app.tr(parameterName + " 不在当前参数包中"), ...
                    "Units", "normalized", "HorizontalAlignment", "center");
                return;
            end
            predicted = predictedValues(:, parameterIndex);
            known = knownValues(:, parameterIndex);
            plot(axesHandle, knownX, known, ...
                "o-", "Color", [0.08, 0.38, 0.72], ...
                "MarkerFaceColor", [0.08, 0.38, 0.72], "MarkerSize", 3, ...
                "LineWidth", 1.2, ...
                "DisplayName", app.tr("已知区局部 P8 观测"));
            hold(axesHandle, "on");
            plot(axesHandle, targetX, predicted, "o-", ...
                "Color", [0.93, 0.45, 0.10], "MarkerFaceColor", ...
                [0.93, 0.45, 0.10], "LineWidth", 1.8, ...
                "DisplayName", app.tr("目标区预测"));
            hold(axesHandle, "off");
            grid(axesHandle, "on");
            axesHandle.XTickMode = "auto";
            axesHandle.YTickMode = "auto";
            ylabel(axesHandle, unit);
            title(axesHandle, parameterName + " · " + upper(modelName));
            legend(axesHandle, "Location", "best");
        end

        function values = parameterAxisValues(app, indices)
            indices = double(indices(:));
            axisValues = double(app.ImportResult.task.axis_values(:));
            if all(indices >= 1 & indices <= numel(axisValues) & ...
                    floor(indices) == indices)
                values = axisValues(indices);
            else
                values = indices;
            end
        end

        function text = formatAxisValues(~, values)
            values = double(values(:).');
            if isempty(values)
                text = "—";
            elseif numel(values) <= 12
                text = strjoin(compose("%g", values), ", ");
            else
                text = sprintf("%d 个值（%g 到 %g）", ...
                    numel(values), values(1), values(end));
            end
        end

        function text = formatIndices(~, values)
            values = double(values(:).');
            if isempty(values)
                text = "—";
            elseif numel(values) <= 12
                text = strjoin(string(values), ", ");
            else
                text = sprintf("%d 个索引（%g 到 %g）", numel(values), values(1), values(end));
            end
        end
    end
end

function value = onOff(condition)
if condition
    value = "on";
else
    value = "off";
end
end
