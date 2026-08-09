classdef ChannelBenchmarkApp < handle
    %CHANNELBENCHMARKAPP Independent accuracy-evaluation UI for Step 13.

    properties (SetAccess = private)
        UIFigure
        Tabs
        InputTab
        MetricsTab
        PlotsTab
        LanguageDropDown
        LanguageLabel
        OriginalField
        PredictionField
        BrowseOriginalButton
        BrowsePredictionButton
        ValidateButton
        RunButton
        AlignmentArea
        MetricTable
        TargetTable
        MetricGroupTabs
        BasicMetricTab
        SpatialMetricTab
        TemporalMetricTab
        RuntimeMetricTab
        FullMetricTab
        TargetPanel
        SummaryLabel
        MetricAxes
        TargetAxes
        ExportRootField
        BrowseExportButton
        ExportButton
        ExportArea
    end

    properties (Access = private)
        OriginalFile string = ""
        PredictionDirectory string = ""
        BenchmarkResult struct = struct()
        Language string = "zh"
        MetricCards struct = struct()
    end

    methods
        function app = ChannelBenchmarkApp(options)
            arguments
                options.Visible (1, 1) string = "on"
            end
            app.buildUI(options.Visible);
            app.applyLanguage();
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end

        function loadBenchmarkInputs(app, originalFile, predictionDirectory)
            arguments
                app
                originalFile (1, 1) string
                predictionDirectory (1, 1) string
            end
            app.resetResult();
            app.OriginalFile = originalFile;
            app.PredictionDirectory = predictionDirectory;
            app.OriginalField.Value = char(originalFile);
            app.PredictionField.Value = char(predictionDirectory);
            app.validateInputs();
        end

        function result = runCurrentBenchmark(app)
            if app.OriginalFile == "" || app.PredictionDirectory == ""
                error("ChannelBenchmarkApp:InputsMissing", ...
                    "Select both Benchmark inputs first.");
            end
            cleanup = onCleanup(@() []);
            if app.UIFigure.Visible == "on"
                dialog = uiprogressdlg(app.UIFigure, "Indeterminate", "on", ...
                    "Title", app.t("正在评估", "Running benchmark"), ...
                    "Message", app.t("正在计算指标和基线……", ...
                        "Computing metrics and baselines..."));
                cleanup = onCleanup(@() delete(dialog));
            end
            try
                result = run_channel_benchmark(app.OriginalFile, ...
                    app.PredictionDirectory);
                app.BenchmarkResult = result;
                app.renderResult();
                app.Tabs.SelectedTab = app.MetricsTab;
            catch exception
                app.BenchmarkResult = struct();
                app.AlignmentArea.Value = [app.t("评估失败：", ...
                    "Benchmark failed:"); string(exception.message)];
                rethrow(exception);
            end
            clear cleanup
        end

        function files = exportCurrentBenchmark(app, outputRoot)
            arguments
                app
                outputRoot (1, 1) string = ""
            end
            if isempty(fieldnames(app.BenchmarkResult))
                error("ChannelBenchmarkApp:NoResult", ...
                    "Run the Benchmark before exporting a report.");
            end
            if outputRoot == ""
                outputRoot = string(app.ExportRootField.Value);
            end
            files = export_channel_benchmark_report(app.BenchmarkResult, outputRoot);
            app.ExportArea.Value = [app.t("报告已导出：", "Report exported:"); ...
                string(files.output_directory); "CSV / Markdown / PNG / Manifest"];
        end

        function state = getReviewState(app)
            state = struct("original_file", app.OriginalFile, ...
                "prediction_directory", app.PredictionDirectory, ...
                "has_result", ~isempty(fieldnames(app.BenchmarkResult)), ...
                "language", app.Language);
            if state.has_result
                state.comparability_status = app.BenchmarkResult.comparability_status;
                state.quality_label = app.BenchmarkResult.quality_label;
                state.metrics = app.BenchmarkResult.metrics;
            end
        end
    end

    methods (Access = private)
        function buildUI(app, visible)
            app.UIFigure = uifigure("Name", "ChanAI Pulse v3.0 Benchmark", ...
                "Position", [80, 60, 1420, 850], "Visible", visible);
            root = uigridlayout(app.UIFigure, [2, 1], ...
                "RowHeight", {56, "1x"}, "Padding", [12, 10, 12, 12]);
            header = uigridlayout(root, [1, 4], ...
                "ColumnWidth", {280, "1x", 90, 150}, "Padding", 0);
            uilabel(header, "Text", "●  ChanAI Pulse", ...
                "FontSize", 23, "FontWeight", "bold", ...
                "FontColor", [0.03, 0.31, 0.61]);
            app.SummaryLabel = uilabel(header, "Text", "", ...
                "HorizontalAlignment", "center", "FontWeight", "bold");
            app.LanguageLabel = uilabel(header, "Text", "Language", ...
                "HorizontalAlignment", "right");
            app.LanguageDropDown = uidropdown(header, ...
                "Items", ["中文", "English"], "ItemsData", ["zh", "en"], ...
                "Value", "zh", "ValueChangedFcn", @(~, ~) app.changeLanguage());

            app.Tabs = uitabgroup(root);
            app.InputTab = uitab(app.Tabs);
            app.MetricsTab = uitab(app.Tabs);
            app.PlotsTab = uitab(app.Tabs);
            app.buildInputTab();
            app.buildMetricsTab();
            app.buildPlotsTab();
        end

        function buildInputTab(app)
            layout = uigridlayout(app.InputTab, [7, 3], ...
                "RowHeight", {34, 44, 44, 50, "1x", 44, 15}, ...
                "ColumnWidth", {170, "1x", 180}, "Padding", [24, 24, 24, 18]);
            app.OriginalField = uieditfield(layout, "text", "Editable", "off");
            app.OriginalField.Layout.Row = 2; app.OriginalField.Layout.Column = 2;
            app.BrowseOriginalButton = uibutton(layout, "push", ...
                "ButtonPushedFcn", @(~, ~) app.browseOriginal());
            app.BrowseOriginalButton.Layout.Row = 2; app.BrowseOriginalButton.Layout.Column = 3;
            app.PredictionField = uieditfield(layout, "text", "Editable", "off");
            app.PredictionField.Layout.Row = 3; app.PredictionField.Layout.Column = 2;
            app.BrowsePredictionButton = uibutton(layout, "push", ...
                "ButtonPushedFcn", @(~, ~) app.browsePrediction());
            app.BrowsePredictionButton.Layout.Row = 3; app.BrowsePredictionButton.Layout.Column = 3;
            app.ValidateButton = uibutton(layout, "push", ...
                "ButtonPushedFcn", @(~, ~) app.validateInputs());
            app.ValidateButton.Layout.Row = 4; app.ValidateButton.Layout.Column = 2;
            app.RunButton = uibutton(layout, "push", "Enable", "off", ...
                "FontWeight", "bold", "BackgroundColor", [0.04, 0.36, 0.68], ...
                "FontColor", "white", "ButtonPushedFcn", @(~, ~) app.runButton());
            app.RunButton.Layout.Row = 4; app.RunButton.Layout.Column = 3;
            app.AlignmentArea = uitextarea(layout, "Editable", "off", ...
                "FontName", "Consolas", "Value", "");
            app.AlignmentArea.Layout.Row = 5;
            app.AlignmentArea.Layout.Column = [1, 3];
        end

        function buildMetricsTab(app)
            layout = uigridlayout(app.MetricsTab, [3, 1], ...
                "RowHeight", {165, 300, "1x"}, "Padding", [18, 18, 18, 18], ...
                "RowSpacing", 12);

            coreGrid = uigridlayout(layout, [1, 4], ...
                "ColumnWidth", {"1x", "1x", "1x", "1x"}, ...
                "Padding", 0, "ColumnSpacing", 12);
            app.createMetricCard(coreGrid, "comparability");
            app.createMetricCard(coreGrid, "quality");
            app.createMetricCard(coreGrid, "complex_nmse");
            app.createMetricCard(coreGrid, "complex_correlation");

            app.MetricGroupTabs = uitabgroup(layout);
            app.BasicMetricTab = uitab(app.MetricGroupTabs);
            app.SpatialMetricTab = uitab(app.MetricGroupTabs);
            app.TemporalMetricTab = uitab(app.MetricGroupTabs);
            app.RuntimeMetricTab = uitab(app.MetricGroupTabs);
            app.FullMetricTab = uitab(app.MetricGroupTabs);

            basicGrid = uigridlayout(app.BasicMetricTab, [1, 4], ...
                "ColumnWidth", {"1x", "1x", "1x", "1x"}, "Padding", 10);
            app.createMetricCard(basicGrid, "magnitude_nrmse");
            app.createMetricCard(basicGrid, "phase_mae_rad");
            app.createMetricCard(basicGrid, "pdp_nrmse");
            app.createMetricCard(basicGrid, "rms_delay_spread_abs_error_s");

            spatialGrid = uigridlayout(app.SpatialMetricTab, [1, 2], ...
                "ColumnWidth", {"1x", "1x"}, "Padding", 10);
            app.createMetricCard(spatialGrid, "spatial_correlation_nrmse");
            app.createMetricCard(spatialGrid, "angular_spectrum_nrmse");

            temporalGrid = uigridlayout(app.TemporalMetricTab, [1, 2], ...
                "ColumnWidth", {"1x", "1x"}, "Padding", 10);
            app.createMetricCard(temporalGrid, "time_autocorrelation_nrmse");
            app.createMetricCard(temporalGrid, "doppler_spectrum_nrmse");

            runtimeGrid = uigridlayout(app.RuntimeMetricTab, [1, 2], ...
                "ColumnWidth", {"1x", "1x"}, "Padding", 10);
            app.createMetricCard(runtimeGrid, "evaluation_runtime_s");
            app.createMetricCard(runtimeGrid, "generation_runtime_s");

            fullGrid = uigridlayout(app.FullMetricTab, [1, 1], "Padding", 8);
            app.MetricTable = uitable(fullGrid, "Data", table(), ...
                "FontSize", 13, "RowStriping", "on");

            app.TargetPanel = uipanel(layout);
            targetGrid = uigridlayout(app.TargetPanel, [1, 1], "Padding", 6);
            app.TargetTable = uitable(targetGrid, "Data", table(), ...
                "FontSize", 12, "RowStriping", "on");
        end

        function createMetricCard(app, parent, key)
            panel = uipanel(parent, "BorderType", "line", ...
                "BackgroundColor", [0.97, 0.98, 1.00]);
            cardGrid = uigridlayout(panel, [3, 1], ...
                "RowHeight", {30, 58, "1x"}, "Padding", [12, 10, 12, 10]);
            titleLabel = uilabel(cardGrid, "Text", "", ...
                "FontSize", 14, "FontWeight", "bold", ...
                "FontColor", [0.08, 0.28, 0.52]);
            valueLabel = uilabel(cardGrid, "Text", "--", ...
                "FontSize", 25, "FontWeight", "bold", ...
                "HorizontalAlignment", "center");
            detailLabel = uilabel(cardGrid, "Text", "", ...
                "FontSize", 11, "WordWrap", "on", ...
                "VerticalAlignment", "top", ...
                "HorizontalAlignment", "center");
            app.MetricCards.(key) = struct("panel", panel, ...
                "title", titleLabel, "value", valueLabel, ...
                "detail", detailLabel);
        end

        function buildPlotsTab(app)
            layout = uigridlayout(app.PlotsTab, [3, 2], ...
                "RowHeight", {"1x", 46, 110}, "ColumnWidth", {"1x", "1x"}, ...
                "Padding", [18, 18, 18, 18]);
            app.MetricAxes = uiaxes(layout); app.TargetAxes = uiaxes(layout);
            app.ExportRootField = uieditfield(layout, "text", ...
                "Value", fullfile(pwd, "benchmark_outputs"));
            app.ExportRootField.Layout.Row = 2; app.ExportRootField.Layout.Column = 1;
            buttonGrid = uigridlayout(layout, [1, 2], "Padding", 0);
            buttonGrid.Layout.Row = 2; buttonGrid.Layout.Column = 2;
            app.BrowseExportButton = uibutton(buttonGrid, "push", ...
                "ButtonPushedFcn", @(~, ~) app.browseExport());
            app.ExportButton = uibutton(buttonGrid, "push", "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.exportButton());
            app.ExportArea = uitextarea(layout, "Editable", "off");
            app.ExportArea.Layout.Row = 3; app.ExportArea.Layout.Column = [1, 2];
        end

        function browseOriginal(app)
            [name, folder] = uigetfile({"*.h5;*.hdf5", "Channel HDF5"});
            if isequal(name, 0), return; end
            app.resetResult();
            app.OriginalFile = string(fullfile(folder, name));
            app.OriginalField.Value = char(app.OriginalFile);
        end

        function browsePrediction(app)
            folder = uigetdir(pwd, app.t("选择预测导出文件夹", ...
                "Select prediction export directory"));
            if isequal(folder, 0), return; end
            app.resetResult();
            app.PredictionDirectory = string(folder);
            app.PredictionField.Value = char(app.PredictionDirectory);
        end

        function browseExport(app)
            folder = uigetdir(pwd, app.t("选择报告输出位置", ...
                "Select report output root"));
            if isequal(folder, 0), return; end
            app.ExportRootField.Value = folder;
        end

        function validateInputs(app)
            try
                original = read_channel_dataset_hdf5(app.OriginalFile);
                bundle = load_prediction_benchmark_bundle(app.PredictionDirectory);
                alignment = validate_benchmark_alignment(original, bundle, app.OriginalFile);
                lines = [ ...
                    app.t("可比性状态：", "Comparability status: ") + alignment.status; ...
                    app.t("任务：", "Task: ") + string(alignment.task_mode) + ...
                        " / " + string(alignment.task_axis); ...
                    sprintf("Known=%d, Target=%d", ...
                        numel(alignment.known_indices), numel(alignment.target_indices))];
                if ~alignment.is_comparable, lines = [lines; alignment.errors]; end
                app.AlignmentArea.Value = lines;
                app.RunButton.Enable = onOff(alignment.is_comparable);
            catch exception
                app.AlignmentArea.Value = [app.t("输入检查失败：", ...
                    "Input validation failed:"); string(exception.message)];
                app.RunButton.Enable = "off";
            end
        end

        function runButton(app)
            try
                app.runCurrentBenchmark();
            catch exception
                uialert(app.UIFigure, string(exception.message), ...
                    app.t("评估失败", "Benchmark failed"));
            end
        end

        function exportButton(app)
            try
                app.exportCurrentBenchmark();
            catch exception
                uialert(app.UIFigure, string(exception.message), ...
                    app.t("导出失败", "Export failed"));
            end
        end

        function renderResult(app)
            result = app.BenchmarkResult;
            methods = ["Prediction"; "Persistence"; "Linear"];
            metric = [result.metrics.prediction; result.metrics.persistence; result.metrics.linear];
            metricNames = ["Complex NMSE"; "Magnitude NRMSE"; ...
                "Phase MAE [rad]"; "Complex correlation"; "PDP NRMSE"; ...
                "RMS delay-spread error [s]"; "Spatial correlation NRMSE"; ...
                "Angular spectrum NRMSE"; "Time autocorrelation NRMSE"; ...
                "Doppler spectrum NRMSE"; "Evaluation runtime [s]"; ...
                "Generation runtime [s]"];
            values = [[metric.complex_nmse]; [metric.magnitude_nrmse]; ...
                [metric.phase_mae_rad]; [metric.complex_correlation]; ...
                [metric.pdp_nrmse]; [metric.rms_delay_spread_abs_error_s]; ...
                [metric.spatial_correlation_nrmse]; ...
                [metric.angular_spectrum_nrmse]; ...
                [metric.time_autocorrelation_nrmse]; ...
                [metric.doppler_spectrum_nrmse]; ...
                [metric.evaluation_runtime_s]; [metric.generation_runtime_s]];
            readingRule = repmat(app.t("越低越好", "Lower is better"), ...
                numel(metricNames), 1);
            readingRule(4) = app.t("越接近 1 越好", "Closer to 1 is better");
            readingRule(11:12) = app.t("仅记录耗时", "Runtime only");
            app.MetricTable.Data = table(metricNames, values(:, 1), ...
                values(:, 2), values(:, 3), readingRule, ...
                'VariableNames', {'Metric', 'Prediction', 'Persistence', ...
                    'Linear', 'ReadingRule'});
            app.TargetTable.Data = struct2table(result.per_target);
            app.renderMetricCards(values, readingRule);
            app.SummaryLabel.Text = app.t("结果：", "Result: ") + ...
                result.quality_label + " | " + app.t("最佳基线：", ...
                "Best baseline: ") + result.best_baseline;
            cla(app.MetricAxes);
            bar(app.MetricAxes, categorical(methods), [metric.complex_nmse]);
            app.MetricAxes.YScale = "log"; grid(app.MetricAxes, "on");
            ylabel(app.MetricAxes, "Complex NMSE");
            title(app.MetricAxes, app.t("整体误差（越低越好）", ...
                "Global error (lower is better)"));
            tableValue = app.TargetTable.Data;
            cla(app.TargetAxes);
            semilogy(app.TargetAxes, tableValue.axis_value, ...
                tableValue.prediction_complex_nmse, "-o", "LineWidth", 1.5);
            hold(app.TargetAxes, "on");
            semilogy(app.TargetAxes, tableValue.axis_value, ...
                tableValue.persistence_complex_nmse, "--s");
            semilogy(app.TargetAxes, tableValue.axis_value, ...
                tableValue.linear_complex_nmse, ":^");
            hold(app.TargetAxes, "off"); grid(app.TargetAxes, "on");
            legend(app.TargetAxes, "Prediction", "Persistence", "Linear", ...
                "Location", "best");
            title(app.TargetAxes, app.t("逐目标点比较", "Per-target comparison"));
            app.ExportButton.Enable = "on";
        end

        function renderMetricCards(app, values, readingRule)
            result = app.BenchmarkResult;
            app.setStatusCard("comparability", ...
                app.t("可比性检查", "Comparability"), ...
                result.comparability_status, ...
                app.t("任务、目标顺序、维度和单位已对齐", ...
                    "Task, target order, dimensions and units are aligned"), ...
                result.comparability_status == "PASS");

            app.setStatusCard("quality", ...
                app.t("相对基线结论", "Versus baselines"), ...
                app.qualityDisplayText(result.quality_label), ...
                app.t("最佳简单基线：", "Best simple baseline: ") + ...
                    result.best_baseline, ...
                result.quality_label == "BETTER_THAN_BASELINE");

            cardKeys = ["complex_nmse", "magnitude_nrmse", ...
                "phase_mae_rad", "complex_correlation", "pdp_nrmse", ...
                "rms_delay_spread_abs_error_s", "spatial_correlation_nrmse", ...
                "angular_spectrum_nrmse", "time_autocorrelation_nrmse", ...
                "doppler_spectrum_nrmse", "evaluation_runtime_s", ...
                "generation_runtime_s"];
            titlesZh = ["复数 NMSE", "幅度 NRMSE", "相位 MAE [rad]", ...
                "复数相关系数", "PDP NRMSE", "RMS 时延扩展误差 [s]", ...
                "空间相关 NRMSE", "角度功率谱 NRMSE", ...
                "时间自相关 NRMSE", "多普勒功率谱 NRMSE", ...
                "评估耗时 [s]", "生成耗时 [s]"];
            titlesEn = ["Complex NMSE", "Magnitude NRMSE", ...
                "Phase MAE [rad]", "Complex correlation", "PDP NRMSE", ...
                "RMS delay-spread error [s]", "Spatial correlation NRMSE", ...
                "Angular spectrum NRMSE", "Time autocorrelation NRMSE", ...
                "Doppler spectrum NRMSE", "Evaluation runtime [s]", ...
                "Generation runtime [s]"];
            for index = 1:numel(cardKeys)
                app.setMetricCard(cardKeys(index), titlesZh(index), ...
                    titlesEn(index), values(index, :), readingRule(index));
            end
        end

        function setMetricCard(app, key, titleZh, titleEn, values, readingRule)
            card = app.MetricCards.(key);
            card.title.Text = app.t(titleZh, titleEn);
            if isnan(values(1))
                card.value.Text = app.t("当前数据不支持", "Unavailable");
                card.value.FontSize = 17;
                card.value.FontColor = [0.45, 0.45, 0.45];
                card.panel.BackgroundColor = [0.96, 0.96, 0.96];
            else
                card.value.Text = formatMetricValue(values(1));
                card.value.FontSize = 25;
                card.value.FontColor = [0.02, 0.38, 0.20];
                card.panel.BackgroundColor = [0.97, 0.99, 1.00];
            end
            card.detail.Text = app.t("预测 / Persistence / Linear：", ...
                "Prediction / Persistence / Linear: ") + newline + ...
                formatMetricValue(values(1)) + " / " + ...
                formatMetricValue(values(2)) + " / " + ...
                formatMetricValue(values(3)) + newline + readingRule;
        end

        function setStatusCard(app, key, titleText, valueText, detailText, positive)
            card = app.MetricCards.(key);
            card.title.Text = titleText;
            card.value.Text = valueText;
            card.value.FontSize = 20;
            card.detail.Text = detailText;
            if positive
                card.value.FontColor = [0.02, 0.48, 0.22];
                card.panel.BackgroundColor = [0.94, 0.99, 0.95];
            else
                card.value.FontColor = [0.75, 0.30, 0.02];
                card.panel.BackgroundColor = [1.00, 0.97, 0.92];
            end
        end

        function value = qualityDisplayText(app, qualityLabel)
            switch string(qualityLabel)
                case "BETTER_THAN_BASELINE"
                    value = app.t("优于基线", "Better than baseline");
                case "SIMILAR_TO_BASELINE"
                    value = app.t("接近基线", "Similar to baseline");
                otherwise
                    value = app.t("未优于基线", "Not better than baseline");
            end
        end

        function resetResult(app)
            app.BenchmarkResult = struct();
            app.MetricTable.Data = table();
            app.TargetTable.Data = table();
            cardKeys = string(fieldnames(app.MetricCards));
            for index = 1:numel(cardKeys)
                card = app.MetricCards.(cardKeys(index));
                card.value.Text = "--";
                card.detail.Text = app.t("等待评估结果", "Waiting for results");
                card.value.FontColor = [0.45, 0.45, 0.45];
                card.panel.BackgroundColor = [0.97, 0.98, 1.00];
            end
            cla(app.MetricAxes);
            cla(app.TargetAxes);
            app.ExportButton.Enable = "off";
            app.ExportArea.Value = "";
            app.SummaryLabel.Text = app.t( ...
                "请检查新输入是否可以公平比较", ...
                "Validate the new inputs before benchmarking");
        end

        function changeLanguage(app)
            app.Language = string(app.LanguageDropDown.Value);
            app.applyLanguage();
        end

        function applyLanguage(app)
            app.BasicMetricTab.Title = app.t("基础与时延", "Core & Delay");
            app.SpatialMetricTab.Title = app.t("空间与角度", "Space & Angle");
            app.TemporalMetricTab.Title = app.t("时间与多普勒", "Time & Doppler");
            app.RuntimeMetricTab.Title = app.t("运行耗时", "Runtime");
            app.FullMetricTab.Title = app.t("完整指标表", "Full metric table");
            app.TargetPanel.Title = app.t("逐目标点结果（用于定位局部误差）", ...
                "Per-target results (locate local errors)");
            app.InputTab.Title = app.t("1. 数据与对齐", "1. Data & Alignment");
            app.MetricsTab.Title = app.t("2. 指标结果", "2. Metrics");
            app.PlotsTab.Title = app.t("3. 图表与导出", "3. Plots & Export");
            app.BrowseOriginalButton.Text = app.t("选择完整原始 H5", ...
                "Select complete original H5");
            app.BrowsePredictionButton.Text = app.t("选择预测导出文件夹", ...
                "Select prediction export folder");
            app.ValidateButton.Text = app.t("检查是否可以公平比较", ...
                "Validate fair alignment");
            app.RunButton.Text = app.t("开始 Benchmark", "Run Benchmark");
            app.BrowseExportButton.Text = app.t("选择输出位置", "Choose output root");
            app.ExportButton.Text = app.t("导出完整报告", "Export full report");
            app.LanguageLabel.Text = app.t("语言", "Language");
            if isempty(fieldnames(app.BenchmarkResult))
                app.SummaryLabel.Text = app.t( ...
                    "请先加载完整原始数据与预测导出包", ...
                    "Load original data and a prediction export");
                app.AlignmentArea.Value = app.t( ...
                    ["Benchmark 会先检查任务、目标顺序、Tx/Rx/Nt 和单位。"; ...
                    "PASS 只表示可以公平比较，不代表预测一定准确。"], ...
                    ["The Benchmark first validates task, target order, dimensions and units."; ...
                    "PASS means comparable, not necessarily accurate."]);
            else
                app.renderResult();
            end
        end

        function value = t(app, zh, en)
            if app.Language == "en", value = en; else, value = zh; end
        end
    end
end

function value = onOff(condition)
if condition, value = "on"; else, value = "off"; end
end

function textValue = formatMetricValue(value)
if isnan(value)
    textValue = "--";
elseif value == 0
    textValue = "0";
elseif abs(value) < 1e-3 || abs(value) >= 1e4
    textValue = string(sprintf("%.3e", value));
else
    textValue = string(sprintf("%.4g", value));
end
end
