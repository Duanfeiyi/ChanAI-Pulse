classdef ChannelSimulatorApp < matlab.apps.AppBase
    % Channel Simulator v126.3 (Dual Language Support)
    % 修复: 初始启动时的中英文状态同步问题
    
    %% ==================== UI Components ====================
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        TabGroup                 matlab.ui.container.TabGroup
        
        % --- [语言切换核心] 语言选择下拉框 (所有页面可见) ---
        LangDropDown             matlab.ui.control.DropDown
        
        % --- Tab 1 ---
        DataImportTab            matlab.ui.container.Tab
        DataImportScrollPanel    matlab.ui.container.Panel 
        BasicConfigPanel         matlab.ui.container.Panel
        FreqBandLabel            matlab.ui.control.Label
        FreqBandDropDown         matlab.ui.control.DropDown
        ScenarioLabel            matlab.ui.control.Label        
        ScenarioDropDown         matlab.ui.control.DropDown 
        BandwidthLabel           matlab.ui.control.Label
        BandwidthEdit            matlab.ui.control.NumericEditField
        DataMgmtPanel            matlab.ui.container.Panel  
        DatasetDropDown          matlab.ui.control.DropDown  
        LoadDataButton           matlab.ui.control.Button  
        ClearDataButton          matlab.ui.control.Button   
        ChannelCharsPanel        matlab.ui.container.Panel
        AngularPowerAxes         matlab.ui.control.UIAxes
        DelayPowerAxes           matlab.ui.control.UIAxes
        DopplerPowerAxes         matlab.ui.control.UIAxes
        SpreadCDFAxes            matlab.ui.control.UIAxes 
        
        % --- Tab 2 ---
        ChannelGenTab            matlab.ui.container.Tab
        GenScrollPanel           matlab.ui.container.Panel
        GenConfigPanel           matlab.ui.container.Panel
        GenModelDropDown         matlab.ui.control.DropDown
        GenStartButton           matlab.ui.control.Button
        GenSendToAIButton        matlab.ui.control.Button
        GenModelLabel            matlab.ui.control.Label
        
        GenParamPanel            matlab.ui.container.Panel
        DSmuLabel                matlab.ui.control.Label
        DSmuEdit                 matlab.ui.control.NumericEditField
        DSsigmaLabel             matlab.ui.control.Label
        DSsigmaEdit              matlab.ui.control.NumericEditField
        rDSLabel                 matlab.ui.control.Label
        rDSEdit                  matlab.ui.control.NumericEditField
        ClusterLabel             matlab.ui.control.Label
        ClusterEdit              matlab.ui.control.NumericEditField
        RayLabel                 matlab.ui.control.Label
        RayEdit                  matlab.ui.control.NumericEditField
        KFmuLabel                matlab.ui.control.Label
        KFmuEdit                 matlab.ui.control.NumericEditField
        KFsigmaLabel             matlab.ui.control.Label
        KFsigmaEdit              matlab.ui.control.NumericEditField
        SnapLabel                matlab.ui.control.Label
        SnapEdit                 matlab.ui.control.NumericEditField
        
        GenPDPAxes               matlab.ui.control.UIAxes
        GenCDFAxes               matlab.ui.control.UIAxes
        
        % --- Tab 3 ---
        ChannelPredTab           matlab.ui.container.Tab
        ChannelPredScrollPanel   matlab.ui.container.Panel 
        PredConfigPanel          matlab.ui.container.Panel 
        AlgoPanel                matlab.ui.container.Panel
        TCNButton                matlab.ui.control.Button 
        LSTMButton               matlab.ui.control.Button
        GRUButton                matlab.ui.control.Button
        TargetPanel              matlab.ui.container.Panel
        TimeDomainButton         matlab.ui.control.Button
        FreqDomainButton         matlab.ui.control.Button
        SpaceDomainButton        matlab.ui.control.Button
        TaskPanel                matlab.ui.container.Panel
        TrainButton              matlab.ui.control.Button 
        PredictButton            matlab.ui.control.Button
        ParamPanel               matlab.ui.container.Panel
        PredLengthLabel          matlab.ui.control.Label
        PredLengthEdit           matlab.ui.control.NumericEditField
        BatchSizeLabel           matlab.ui.control.Label
        BatchSizeEdit            matlab.ui.control.NumericEditField
        SavePredDataButton       matlab.ui.control.Button
        ExportModelButton        matlab.ui.control.Button
        
        DataScaleInfoLabel       matlab.ui.control.Label 
        
        PredPlotPanel            matlab.ui.container.Panel 
        PredCapacityAxes         matlab.ui.control.UIAxes 
        PredRawDataAxes          matlab.ui.control.UIAxes 
        PredSpreadAxes           matlab.ui.control.UIAxes 
        PredRMSEAxes             matlab.ui.control.UIAxes
        PredAngularAxes          matlab.ui.control.UIAxes
        PredDopplerAxes          matlab.ui.control.UIAxes
    end
    
    %% ==================== Private Properties ====================
    properties (Access = private)
        LoadedData     = {}       
        ChannelMetrics = {}       
        DatasetPaths   = {}       
        DatasetMetadata = {}
        PredictionResults = struct(); 
        CurrentPredDataset = '';
        
        TrainedNet     = [];      
        NormParams     = struct('Mu', 0, 'Sigma', 1); 
        PredictionWindow = 10; 
        selectedAlgo = 'TCN';      
        selectedTarget = 'Time';   
        
        GeneratedH     single                 
        GeneratedDelay single  
        LastTrainTime  = 0;
        ExperimentContext = struct();
        
        % --- [语言切换核心] 语言状态: 'CN' 或 'EN' (修正默认值为英文) ---
        CurrentLang = 'EN';
        
        Color_Bg         = [1.00, 1.00, 1.00]; 
        Color_Panel      = [0.96, 0.96, 0.96]; 
        Color_Text       = [0.10, 0.10, 0.10]; 
        Color_TextDim    = [0.35, 0.35, 0.35]; 
        DefaultBtnColor  = [0.94, 0.94, 0.94]; 
        ActiveBtnColor   = [0.00, 0.4470, 0.7410]; 
        Color_Blue       = [0.00, 0.4470, 0.7410]; 
        
        Color_Primary    = [0.000, 0.447, 0.741]; 
        Color_Secondary  = [0.850, 0.325, 0.098]; 
        Color_TCN        = [0.000, 0.447, 0.741]; 
        Color_LSTM       = [0.850, 0.325, 0.098]; 
        Color_GRU        = [0.466, 0.674, 0.188]; 
        Color_True       = [0.550, 0.550, 0.570]; 
    end
    
    %% ==================== [语言切换核心] 语言切换核心方法 ====================
    methods (Access = private)
        
        function langDropdownChanged(app, event)
            % 根据下拉框的值切换语言状态
            if strcmp(event.Value, '中文')
                app.CurrentLang = 'CN';
            else
                app.CurrentLang = 'EN';
            end
            app.updateAllUIText();
        end
        
        function updateAllUIText(app)
            % 同步下拉框状态
            if strcmp(app.CurrentLang, 'CN')
                app.LangDropDown.Value = '中文';
            else
                app.LangDropDown.Value = 'English';
            end

            if strcmp(app.CurrentLang, 'CN')
                % ====== 切换到中文 ======
                app.UIFigure.Name = '6G 信道预测器';
                app.LangDropDown.Tooltip = '选择界面语言';
                
                % Tab 标题
                app.DataImportTab.Title = '1. 信道特性分析';
                app.ChannelGenTab.Title = '2. 信道生成';
                app.ChannelPredTab.Title = '3. 预测与训练';
                
                % === Tab 1 ===
                app.BasicConfigPanel.Title = '参数与场景设置';
                app.FreqBandLabel.Text = '频段:';
                app.ScenarioLabel.Text = '场景:';
                app.BandwidthLabel.Text = '带宽 (MHz):';
                app.DataMgmtPanel.Title = '数据加载';
                app.LoadDataButton.Text = '加载数据';
                app.ClearDataButton.Text = '清除';
                app.ChannelCharsPanel.Title = '信道特性图';
                
                % === Tab 2 ===
                app.GenConfigPanel.Title = '仿真参数与执行';
                app.GenModelLabel.Text = '仿真模型:';
                app.GenStartButton.Text = '生成信道';
                app.GenSendToAIButton.Text = '发送至 AI';
                app.GenParamPanel.Title = '随机引擎物理参数 (大尺度与小尺度衰落)';
                app.DSmuLabel.Text = 'DS mu:';
                app.DSsigmaLabel.Text = 'DS sigma:';
                app.rDSLabel.Text = 'r DS:';
                app.ClusterLabel.Text = 'Clusters:';
                app.RayLabel.Text = 'Rays:';
                app.KFmuLabel.Text = 'KF mu:';
                app.KFsigmaLabel.Text = 'KF sigma:';
                app.SnapLabel.Text = '快照数:';
                
                % === Tab 3 ===
                app.PredConfigPanel.Title = '训练配置';
                app.AlgoPanel.Title = '算法';
                app.TCNButton.Text = 'TCN';
                app.LSTMButton.Text = 'LSTM';
                app.GRUButton.Text = 'GRU';
                app.TargetPanel.Title = '域类型';
                app.TimeDomainButton.Text = '时域';
                app.FreqDomainButton.Text = '频域';
                app.SpaceDomainButton.Text = '空间域';
                app.TaskPanel.Title = '任务控制';
                app.TrainButton.Text = '1. 训练模型';
                app.PredictButton.Text = '2. 运行预测';
                app.ParamPanel.Title = '未来生成';
                app.PredLengthLabel.Text = '预测步数 (快拍数) :';
                app.BatchSizeLabel.Text = '批次大小 (组数) :';
                app.SavePredDataButton.Text = '保存数据';
                app.ExportModelButton.Text = '导出模型';
                app.PredPlotPanel.Title = '验证结果';
                
            else
                % ====== 切换到英文 ======
                app.UIFigure.Name = '6G Channel Predictor';
                app.LangDropDown.Tooltip = 'Select Interface Language';
                
                % Tab 标题
                app.DataImportTab.Title = '1. Characterization';
                app.ChannelGenTab.Title = '2. Channel Generation';
                app.ChannelPredTab.Title = '3. Prediction & Training';
                
                % === Tab 1 ===
                app.BasicConfigPanel.Title = 'Parameters & Scenario';
                app.FreqBandLabel.Text = 'Band:';
                app.ScenarioLabel.Text = 'Scenario:';
                app.BandwidthLabel.Text = 'BW (MHz):';
                app.DataMgmtPanel.Title = 'Data Load';
                app.LoadDataButton.Text = 'Load Data';
                app.ClearDataButton.Text = 'Clear';
                app.ChannelCharsPanel.Title = 'Characteristic Plots';
                
                % === Tab 2 ===
                app.GenConfigPanel.Title = 'Simulation Parameters & Execution';
                app.GenModelLabel.Text = 'Simulation Model:';
                app.GenStartButton.Text = 'Generate Channel';
                app.GenSendToAIButton.Text = 'Send to AI';
                app.GenParamPanel.Title = 'Stochastic Engine Physics (Large & Small Scale Fading)';
                app.DSmuLabel.Text = 'DS mu:';
                app.DSsigmaLabel.Text = 'DS sigma:';
                app.rDSLabel.Text = 'r DS:';
                app.ClusterLabel.Text = 'Clusters:';
                app.RayLabel.Text = 'Rays:';
                app.KFmuLabel.Text = 'KF mu:';
                app.KFsigmaLabel.Text = 'KF sigma:';
                app.SnapLabel.Text = 'Snaps:';
                
                % === Tab 3 ===
                app.PredConfigPanel.Title = 'Training Configuration';
                app.AlgoPanel.Title = 'Algo';
                app.TCNButton.Text = 'TCN';
                app.LSTMButton.Text = 'LSTM';
                app.GRUButton.Text = 'GRU';
                app.TargetPanel.Title = 'Domain';
                app.TimeDomainButton.Text = 'Time';
                app.FreqDomainButton.Text = 'Freq';
                app.SpaceDomainButton.Text = 'Space';
                app.TaskPanel.Title = 'Task Control';
                app.TrainButton.Text = '1. Train Model';
                app.PredictButton.Text = '2. Run Predict';
                app.ParamPanel.Title = 'Future Gen';
                app.PredLengthLabel.Text = 'Prediction Steps (Snaps):';
                app.BatchSizeLabel.Text = 'Batch Size (Sets):';
                app.SavePredDataButton.Text = 'Save Data';
                app.ExportModelButton.Text = 'Export Model';
                app.PredPlotPanel.Title = 'Verification Results';
            end
            
            % 更新频段下拉选项
            if strcmp(app.CurrentLang, 'CN')
                app.FreqBandDropDown.Items = {'Sub-6', '毫米波 (mmWave)', '太赫兹 (THz)', '光无线 (OWC)'};
                curr = app.FreqBandDropDown.Value;
                map = containers.Map({'Sub-6', 'mmWave', 'THz', 'Optical Wireless'}, ...
                                     {'Sub-6', '毫米波 (mmWave)', '太赫兹 (THz)', '光无线 (OWC)'});
                if isKey(map, curr), app.FreqBandDropDown.Value = map(curr); end
            else
                app.FreqBandDropDown.Items = {'Sub-6', 'mmWave', 'THz', 'Optical Wireless'};
                curr = app.FreqBandDropDown.Value;
                map = containers.Map({'Sub-6', '毫米波 (mmWave)', '太赫兹 (THz)', '光无线 (OWC)'}, ...
                                     {'Sub-6', 'mmWave', 'THz', 'Optical Wireless'});
                if isKey(map, curr), app.FreqBandDropDown.Value = map(curr); end
            end
            
            % 更新场景下拉选项
            app.updateScenarioItemsLang();
            
            % 更新图表
            if isempty(app.DatasetPaths)
                app.showPlaceholderPlots();
                app.showPredPlaceholderPlots();
            else
                app.updateVisualizations();
            end
            app.updateDataScaleProbe();
        end
        
        function updateScenarioItemsLang(app)
            % 根据当前语言更新场景下拉选项
            band_val = app.FreqBandDropDown.Value;
            en_band = band_val;
            if strcmp(app.CurrentLang, 'CN')
                cn2en = containers.Map({'Sub-6', '毫米波 (mmWave)', '太赫兹 (THz)', '光无线 (OWC)'}, ...
                                       {'Sub-6', 'mmWave', 'THz', 'Optical Wireless'});
                if isKey(cn2en, band_val), en_band = cn2en(band_val); end
            end
            
            if strcmp(app.CurrentLang, 'CN')
                base_scenes = {'卫星', '无人机', '海洋', 'RIS', '工业物联网', 'ISAC'};
            else
                base_scenes = {'Satellite', 'UAV', 'Maritime', 'RIS', 'Industrial IoT', 'ISAC'};
            end
            
            % 标准化 switch/if-else 语句
            isCN = strcmp(app.CurrentLang, 'CN');
            switch en_band
                case 'Sub-6'
                    if isCN, fallback = '场景 1'; else, fallback = 'Scenario 1'; end
                case 'mmWave'
                    if isCN, fallback = '场景 2'; else, fallback = 'Scenario 2'; end
                case 'THz'
                    if isCN, fallback = '场景 3'; else, fallback = 'Scenario 3'; end
                case 'Optical Wireless'
                    if isCN, fallback = '场景 4'; else, fallback = 'Scenario 4'; end
                otherwise
                    if isCN, fallback = '场景 1'; else, fallback = 'Scenario 1'; end
            end
            
            items = [base_scenes, {fallback}];
            old_val = app.ScenarioDropDown.Value;
            app.ScenarioDropDown.Items = items;
            
            scene_map_en2cn = containers.Map(...
                {'Satellite', 'UAV', 'Maritime', 'RIS', 'Industrial IoT', 'ISAC', 'Scenario 1', 'Scenario 2', 'Scenario 3', 'Scenario 4'}, ...
                {'卫星', '无人机', '海洋', 'RIS', '工业物联网', 'ISAC', '场景 1', '场景 2', '场景 3', '场景 4'});
            scene_map_cn2en = containers.Map(...
                {'卫星', '无人机', '海洋', 'RIS', '工业物联网', 'ISAC', '场景 1', '场景 2', '场景 3', '场景 4'}, ...
                {'Satellite', 'UAV', 'Maritime', 'RIS', 'Industrial IoT', 'ISAC', 'Scenario 1', 'Scenario 2', 'Scenario 3', 'Scenario 4'});
            
            if strcmp(app.CurrentLang, 'CN')
                if isKey(scene_map_en2cn, old_val), new_val = scene_map_en2cn(old_val); else, new_val = fallback; end
            else
                if isKey(scene_map_cn2en, old_val), new_val = scene_map_cn2en(old_val); else, new_val = fallback; end
            end
            
            if any(strcmp(items, new_val)), app.ScenarioDropDown.Value = new_val; else, app.ScenarioDropDown.Value = fallback; end
            
            if isprop(app, 'GenModelDropDown') && ~isempty(app.GenModelDropDown) && isvalid(app.GenModelDropDown)
                app.GenModelDropDown.Items = items;
                app.GenModelDropDown.Value = app.ScenarioDropDown.Value;
            end
        end
        
        function updateScenarioItems(app)
            app.updateScenarioItemsLang();
            app.ConfigValueChanged();
        end
        
        function status_text = getStatusText(app, key)
            if strcmp(app.CurrentLang, 'CN')
                switch key
                    case 'waiting_data', status_text = '状态: 等待数据...';
                    case 'cleared', status_text = '► 状态: 已清除';
                    case 'waiting_scale', status_text = '► 输入规模: 等待中...';
                    otherwise, status_text = key;
                end
            else
                switch key
                    case 'waiting_data', status_text = 'Status: Waiting for Data...';
                    case 'cleared', status_text = '► Status: Cleared';
                    case 'waiting_scale', status_text = '► Input Scale: Waiting...';
                    otherwise, status_text = key;
                end
            end
        end
    end
    
    %% ==================== Helper Methods ====================
    methods (Access = private)
        function stabilizeFocus(app, prevState)
            if ~isvalid(app) || ~isvalid(app.UIFigure), return; end
            drawnow limitrate;
            try
                if nargin > 1 
                    if strcmp(app.UIFigure.WindowState, 'minimized')
                        if strcmp(prevState, 'minimized'), prevState = 'normal'; end
                        app.UIFigure.WindowState = prevState;
                    end
                    figure(app.UIFigure); 
                end
            catch
            end
        end
        
        function setFullWidthAxes(~, ax, x_data)
            try
                if isempty(x_data), return; end
                xmin = min(x_data(:)); xmax = max(x_data(:));
                if xmin == xmax, xmax = xmin + 1; end
                ax.XLim = [xmin, xmax];
                try ax.XLimitMethod = 'tight'; catch; end 
            catch
            end
        end
        
        function applyYLimMargin(~, ax, y_data)
            try
                if isempty(y_data), return; end
                y_val = double(y_data(isfinite(y_data(:))));
                if isempty(y_val), return; end
                min_y = min(y_val); max_y = max(y_val);
                hasBar = ~isempty(findobj(ax, 'Type', 'bar'));
                if hasBar, min_y = min(0, min_y); end
                yrange = max_y - min_y;
                if yrange == 0, yrange = max(1, abs(max_y) * 0.1); end
                ax.YLim = [min_y - 0.1*yrange, max_y + 0.1*yrange];
            catch
            end
        end
        
        function [band, scen] = autoDetectScenario(~, searchStr)
            band = ''; scen = ''; lowerStr = lower(searchStr);
            if contains(lowerStr, 'sub-6') || contains(lowerStr, 'sub6'), band = 'Sub-6'; end
            if contains(lowerStr, '毫米波') || contains(lowerStr, 'mmwave'), band = 'mmWave'; end
            if contains(lowerStr, '太赫兹') || contains(lowerStr, 'thz'), band = 'THz'; end
            if contains(lowerStr, '光无线') || contains(lowerStr, 'owc') || contains(lowerStr, 'vlc'), band = 'Optical Wireless'; end
            if contains(lowerStr, '卫星') || contains(lowerStr, 'satellite') || contains(lowerStr, 'leo'), scen = 'Satellite'; end
            if contains(lowerStr, '无人机') || contains(lowerStr, 'uav') || contains(lowerStr, 'drone'), scen = 'UAV'; end
            if contains(lowerStr, '海洋') || contains(lowerStr, 'maritime') || contains(lowerStr, 'sea'), scen = 'Maritime'; end
            if contains(lowerStr, '反射面') || contains(lowerStr, 'ris') || contains(lowerStr, 'irs'), scen = 'RIS'; end
            if contains(lowerStr, '物联网') || contains(lowerStr, 'iiot') || contains(lowerStr, 'iot'), scen = 'Industrial IoT'; end
            if contains(lowerStr, '通感') || contains(lowerStr, 'isac') || contains(lowerStr, 'jcac'), scen = 'ISAC'; end
            if contains(lowerStr, '场景 1') || contains(lowerStr, 'scen1'), scen = 'Scenario 1'; end
            if contains(lowerStr, '场景 2') || contains(lowerStr, 'scen2'), scen = 'Scenario 2'; end
            if contains(lowerStr, '场景 3') || contains(lowerStr, 'scen3'), scen = 'Scenario 3'; end
            if contains(lowerStr, '场景 4') || contains(lowerStr, 'scen4'), scen = 'Scenario 4'; end
        end
        
        function data = extract_raw_data(app, f1)
            data = extract_raw_data(f1);
        end
        
        function [angles, aps_dB] = calculate_angular_spectrum(~, raw_data)
            [angles, aps_dB] = calculate_angular_spectrum(raw_data);
        end
        
        function initAxesStyle(app, ax)
            init_axes_style(ax, app.Color_TextDim);
        end
        
        function applyAxesStyle(app, ax, titleText, xLabelText, yLabelText)
            if nargin > 3
                apply_axes_style(ax, titleText, xLabelText, yLabelText, app.Color_Text);
            else
                apply_axes_style(ax, titleText, '', '', app.Color_Text);
            end
        end
        
        function fns_sorted = safe_sort_files(~, fns)
            if ischar(fns), fns = {fns}; end 
            try fns_sorted = sort_nat(fns); catch, fns_sorted = sort(fns); end
        end
        
        function s = getSageData(~, rs)
            if iscell(rs), s=rs{1}; else, s=rs; end; if length(s)>1, s=s(1); end
        end
        
        function ds = calc_ds_native(~, taus, pdp_linear)
            pm = sum(pdp_linear);
            if pm == 0, ds = 0; return; end
            mx = sum(taus .* pdp_linear) / pm;
            ds = sqrt(abs(sum((taus.^2) .* pdp_linear) / pm - mx^2));
        end
        
        function updateDataScaleProbe(app)
            if ~isprop(app, 'DataScaleInfoLabel') || ~isvalid(app.DataScaleInfoLabel), return; end
            if isempty(app.DatasetPaths) || strcmp(app.DatasetDropDown.Value, '[None]')
                app.DataScaleInfoLabel.Text = app.getStatusText('waiting_data');
                return;
            end
            idx = find(strcmp(app.DatasetPaths, app.DatasetDropDown.Value), 1);
            if ~isempty(idx)
                curr_data = app.LoadedData{idx};
                [bins, snaps] = size(curr_data);
                app.DataScaleInfoLabel.Text = sprintf('► Input Scale: %d Bins × %d Snaps', bins, snaps);
            end
        end
    end
    
    %% ==================== [Tab 1] Data Loading ====================
    methods (Access = private)
        function loadData_Generic(app, scenario_name)
            prevState = app.UIFigure.WindowState;
            if strcmp(app.CurrentLang, 'CN')
                dlg_title = '选择数据集';
            else
                dlg_title = 'Select Dataset';
            end
            [fns, fp] = uigetfile('*.mat', dlg_title, 'MultiSelect', 'on');
            app.stabilizeFocus(prevState);
            
            if isequal(fns, 0), return; end
            fns = app.safe_sort_files(fns); nFiles = length(fns);
            
            searchStr = [fp, fns{1}];
            [det_band, det_scen] = app.autoDetectScenario(searchStr);
            
            if isempty(det_band)
                band_cur = app.FreqBandDropDown.Value;
                if contains(band_cur, 'Sub-6'), det_band = 'Sub-6';
                elseif contains(band_cur, 'mmWave'), det_band = 'mmWave';
                elseif contains(band_cur, 'THz'), det_band = 'THz';
                else, det_band = 'Optical Wireless'; end
            end
            if isempty(det_scen)
                switch det_band
                    case 'Sub-6', det_scen = 'Scenario 1';
                    case 'mmWave', det_scen = 'Scenario 2';
                    case 'THz', det_scen = 'Scenario 3';
                    case 'Optical Wireless', det_scen = 'Scenario 4';
                    otherwise, det_scen = 'Scenario 1';
                end
            end
            
            if strcmp(app.CurrentLang, 'CN')
                msg = sprintf('检测到以下配置:\n\n🔹 频段: %s\n🔹 场景: %s\n\n应用此配置？', det_band, det_scen);
                dlg_title2 = '智能分配';
                opt1 = '确认'; opt2 = '保持选择';
            else
                msg = sprintf('Detected the following configuration:\n\n🔹 Band: %s\n🔹 Scenario: %s\n\nApply this configuration?', det_band, det_scen);
                dlg_title2 = 'Smart Assignment';
                opt1 = 'Confirm'; opt2 = 'Keep Selection';
            end
            sel = uiconfirm(app.UIFigure, msg, dlg_title2, 'Options', {opt1, opt2}, 'DefaultOption', 1);
            
            band_cn = containers.Map({'Sub-6', 'mmWave', 'THz', 'Optical Wireless'}, ...
                                     {'Sub-6', '毫米波 (mmWave)', '太赫兹 (THz)', '光无线 (OWC)'});
            scene_cn = containers.Map(...
                {'Satellite', 'UAV', 'Maritime', 'RIS', 'Industrial IoT', 'ISAC', 'Scenario 1', 'Scenario 2', 'Scenario 3', 'Scenario 4'}, ...
                {'卫星', '无人机', '海洋', 'RIS', '工业物联网', 'ISAC', '场景 1', '场景 2', '场景 3', '场景 4'});
            
            band_disp = det_band; scene_disp = det_scen;
            if strcmp(app.CurrentLang, 'CN')
                if isKey(band_cn, det_band), band_disp = band_cn(det_band); end
                if isKey(scene_cn, det_scen), scene_disp = scene_cn(det_scen); end
            end
            
            if strcmp(sel, opt1)
                app.FreqBandDropDown.Value = band_disp;
                app.updateScenarioItemsLang();
                if any(strcmp(app.ScenarioDropDown.Items, scene_disp))
                    app.ScenarioDropDown.Value = scene_disp;
                    if isprop(app, 'GenModelDropDown') && ~isempty(app.GenModelDropDown) && isvalid(app.GenModelDropDown)
                        app.GenModelDropDown.Value = scene_disp;
                    end
                end
                app.ConfigValueChanged();
                scenario_name = [strrep(det_band, ' ', ''), '-', det_scen];
            else
                scenario_name = [strrep(det_band, ' ', ''), '-', det_scen];
            end
            
            if strcmp(app.CurrentLang, 'CN')
                progress_title = [scenario_name, ' 处理中...'];
            else
                progress_title = [scenario_name, ' Processing...'];
            end
            d = uiprogressdlg(app.UIFigure, 'Title', progress_title, 'Indeterminate', 'on');
            drawnow; 
            
            t_load = tic;
            try
                if contains(scenario_name, 'Industrial IoT') || contains(scenario_name, 'mmWave'), len_dpsd = 500; else, len_dpsd = 200; end
                h_dbm_matrix = zeros(len_dpsd, nFiles); all_aps = zeros(128, nFiles); 
                for i = 1:nFiles
                    f1 = load(fullfile(fp, fns{i})); data = app.extract_raw_data(f1); 
                    [angle_xaxis, all_aps(:, i)] = app.calculate_angular_spectrum(data);
                    
                    dpsd_dbm = prepare_dpsd_snapshot(data, string(scenario_name), len_dpsd);
                    h_dbm_matrix(:, i) = dpsd_dbm; 
                end
                
                h_dbm_matrix(isnan(h_dbm_matrix) | isinf(h_dbm_matrix)) = -130; 
                mets = app.analyzeChannelData_Generic(h_dbm_matrix, app.BandwidthEdit.Value * 1e6);
                mets.space.angle = angle_xaxis; mets.space.psd = mean(all_aps, 2);
                
                [~,dn] = fileparts(strip(fp, 'right', filesep));
                
                if strcmp(app.CurrentLang, 'CN')
                    ds_name = sprintf('[原始] %s (%s - %d 快拍)', dn, scenario_name, nFiles);
                else
                    ds_name = sprintf('[Raw] %s (%s - %d Snaps)', dn, scenario_name, nFiles);
                end
                
                curr_len = length(app.LoadedData);
                app.LoadedData{curr_len+1} = h_dbm_matrix; 
                app.ChannelMetrics{curr_len+1} = mets;
                app.DatasetPaths{curr_len+1} = ds_name;
                app.DatasetMetadata{curr_len+1} = struct( ...
                    'kind', "real_local", ...
                    'real_source_index', curr_len + 1, ...
                    'generated_sequence', [], ...
                    'source_label', string(ds_name));
                app.DatasetDropDown.Items = app.DatasetPaths; 
                app.DatasetDropDown.Value = ds_name;
                
                if ~strcmp(app.CurrentPredDataset, ds_name)
                    app.PredictionResults = struct();
                    app.CurrentPredDataset = ds_name;
                    app.ExperimentContext = struct();
                end
                
                app.updateVisualizations(); 
                app.updateDataScaleProbe();
                
                if isvalid(d), delete(d); end 
                app.stabilizeFocus(prevState);
                
                mem_mb = (numel(h_dbm_matrix)*8)/1024^2;
                t_elapsed = toc(t_load);
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, sprintf('源数据加载成功!\n\n规模: %d Bins × %d 快拍\n内存: %.2f MB\n时间: %.2f s', len_dpsd, nFiles, mem_mb, t_elapsed), '完成');
                else
                    uialert(app.UIFigure, sprintf('Source Data Loaded!\n\nScale: %d Bins × %d Snaps\nRAM: %.2f MB\nTime: %.2f s', len_dpsd, nFiles, mem_mb, t_elapsed), 'Done');
                end
            catch ME
                if ~isvalid(app) || ~isvalid(app.UIFigure), return; end
                if exist('d', 'var') && isvalid(d), delete(d); end
                app.stabilizeFocus(prevState);
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, ['加载失败: ' ME.message], '错误'); 
                else
                    uialert(app.UIFigure, ['Load Failed: ' ME.message], 'Error'); 
                end
            end
        end
    end
    
    %% ==================== [Tab 2] Native GBSM Physics Engine ====================
    methods (Access = private)
        function GenStartButtonPushed(app, ~)
            app.GenStartButton.Enable = 'off';
            if strcmp(app.CurrentLang, 'CN')
                app.GenStartButton.Text = '计算中...';
            else
                app.GenStartButton.Text = 'Computing...';
            end
            drawnow limitrate;
            try
                DS_mu = app.DSmuEdit.Value;
                DS_sigma = app.DSsigmaEdit.Value;
                r_DS = app.rDSEdit.Value;
                num_clusters = round(app.ClusterEdit.Value);
                num_rays = round(app.RayEdit.Value);
                KF_mu = app.KFmuEdit.Value;
                KF_sigma = app.KFsigmaEdit.Value;
                N_snaps = round(app.SnapEdit.Value);
                
                B_Hz = app.BandwidthEdit.Value * 1e6;
                delay_grid_step_ns = 1.0;
                delay_max_ns = 300;
                
                if strcmp(app.CurrentLang, 'CN')
                    d = uiprogressdlg(app.UIFigure, 'Title', '原生引擎运行中', 'Message', '生成物理多径张量...');
                else
                    d = uiprogressdlg(app.UIFigure, 'Title', 'Native Engine Running', 'Message', 'Generating physical multipath tensors...');
                end
                t_gen_start = tic;
                
                fd = 50;
                gen_val = app.GenModelDropDown.Value;
                if contains(gen_val, '卫星') || contains(gen_val, 'Satellite'), fd = 4000; end
                if contains(gen_val, '无人机') || contains(gen_val, 'UAV'), fd = 500; end
                
                generationConfig = default_6gpcm_lite_config();
                generationConfig.bandwidth_hz = B_Hz;
                generationConfig.delay_grid_step_ns = delay_grid_step_ns;
                generationConfig.delay_max_ns = delay_max_ns;
                generationConfig.ds_mu = DS_mu;
                generationConfig.ds_sigma = DS_sigma;
                generationConfig.r_ds = r_DS;
                generationConfig.clusters = num_clusters;
                generationConfig.rays = num_rays;
                generationConfig.kf_mu_db = KF_mu;
                generationConfig.kf_sigma_db = KF_sigma;
                generationConfig.snapshots = N_snaps;
                generationConfig.doppler_hz = fd;
                generationResult = generate_6gpcm_lite(generationConfig);

                app.GeneratedH = generationResult.cir;
                app.GeneratedDelay = generationResult.delay;
                ds_all_ns = generationResult.delay_spread_ns;
                first_h_delay = generationResult.preview.cir;
                first_taus = generationResult.preview.cluster_delays_s;
                first_h_CIR = generationResult.preview.cluster_gains;
                delay_axis_ns = generationResult.preview.delay_axis_ns;
                t_gen_end = toc(t_gen_start);
                
                %% =================== Perfect Plot Rendering ===================
                avg_pdp_linear = abs(first_h_delay).^2;
                avg_pdp_linear = avg_pdp_linear / max(avg_pdp_linear + eps);
                
                noise_floor_dB = -60;
                noise_amplitude_dB = 5.0;
                noise_trace_dB = noise_floor_dB + noise_amplitude_dB * (2 * rand(size(delay_axis_ns)) - 1);
                noise_linear = 10.^(noise_trace_dB / 10);
                pdp_plot_dB = 10 * log10(avg_pdp_linear + noise_linear + eps);
                
                delete(app.GenPDPAxes.Children);
                m_idx = round(linspace(1, length(delay_axis_ns), 20));
                h_pdp = plot(app.GenPDPAxes, delay_axis_ns, pdp_plot_dB, '-o', 'Color', app.Color_Primary, 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerIndices', m_idx, 'MarkerFaceColor', app.Color_Primary);
                
                tap_power_linear = abs(first_h_CIR).^2;
                tap_power_linear = tap_power_linear / max(tap_power_linear + eps);
                tap_power_dB = 10 * log10(tap_power_linear + eps);
                hold(app.GenPDPAxes, 'on');
                h_scatter = plot(app.GenPDPAxes, first_taus * 1e9, tap_power_dB, 's', 'Color', app.Color_Secondary, 'LineWidth', 1.2, 'MarkerSize', 6, 'MarkerFaceColor', app.Color_Secondary);
                hold(app.GenPDPAxes, 'off');
                
                if strcmp(app.CurrentLang, 'CN')
                    lgd_str1 = 'PDP 带噪声底'; lgd_str2 = '多径分量';
                    pdp_title = sprintf('时延功率谱 (%s)', app.GenModelDropDown.Value);
                    app.applyAxesStyle(app.GenPDPAxes, pdp_title, '时延 (ns)', '功率 (dB)');
                else
                    lgd_str1 = 'PDP with noise floor'; lgd_str2 = 'Multipath components';
                    pdp_title = sprintf('Delay Power Spectrum (%s)', app.GenModelDropDown.Value);
                    app.applyAxesStyle(app.GenPDPAxes, pdp_title, 'Delay (ns)', 'Power (dB)');
                end
                lgd1 = legend(app.GenPDPAxes, [h_pdp, h_scatter], {lgd_str1, lgd_str2}, 'Location', 'best');
                lgd1.Color = 'none'; lgd1.EdgeColor = 'none'; lgd1.TextColor = app.Color_Text; lgd1.FontName = 'Times New Roman'; lgd1.FontSize = 12;
                
                xlim(app.GenPDPAxes, [0 delay_max_ns]);
                
                ds_sorted = sort(ds_all_ns(:));
                cdf_y = (1:numel(ds_sorted))' / numel(ds_sorted);
                [ds_unique, ia] = unique(ds_sorted, 'stable');
                cdf_unique = cdf_y(ia);
                
                if length(ds_unique) > 1
                    x_fine = linspace(ds_unique(1), ds_unique(end), 500);
                    cdf_smooth = interp1(ds_unique, cdf_unique, x_fine, 'pchip');
                    cdf_smooth = cummax(cdf_smooth);
                    cdf_smooth = min(max(cdf_smooth, 0), 1);
                else
                    x_fine = [0, ds_unique, max(1, ds_unique*2)];
                    cdf_smooth = [0, 1, 1];
                end
                
                delete(app.GenCDFAxes.Children);
                m_idx_cdf = round(linspace(1, length(x_fine), 20));
                plot(app.GenCDFAxes, x_fine, cdf_smooth, '-o', 'Color', app.Color_Primary, 'LineWidth', 1.8, 'MarkerSize', 5, 'MarkerIndices', m_idx_cdf, 'MarkerFaceColor', app.Color_Primary);
                if strcmp(app.CurrentLang, 'CN')
                    cdf_title = '时延扩展的累积分布函数';
                    app.applyAxesStyle(app.GenCDFAxes, cdf_title, '时延扩展 (ns)', 'CDF'); 
                else
                    cdf_title = 'CDF of DS';
                    app.applyAxesStyle(app.GenCDFAxes, cdf_title, 'DS (ns)', 'CDF'); 
                end
                xlim(app.GenCDFAxes, [x_fine(1), x_fine(end)]);
                ylim(app.GenCDFAxes, [0, 1]);
                
                if isvalid(d), delete(d); end
                app.GenStartButton.Enable = 'on';
                if strcmp(app.CurrentLang, 'CN')
                    app.GenStartButton.Text = '生成信道';
                else
                    app.GenStartButton.Text = 'Generate Channel';
                end
                
                delayBinCount = size(app.GeneratedH, 4);
                tensor_mem = (numel(app.GeneratedH) * 8) / (1024^2);
                if strcmp(app.CurrentLang, 'CN')
                    bench_msg = sprintf('原生引擎仿真成功!\n\n[数据库规模]\n生成4D张量: 1x1x%dx%d\n内存占用: %.2f MB\n生成时间: %.2f s', N_snaps, delayBinCount, tensor_mem, t_gen_end);
                    uialert(app.UIFigure, bench_msg, '成功 (基准信息)', 'Icon', 'success');
                else
                    bench_msg = sprintf('Native Engine Simulation Success!\n\n[Database Scale]\nGenerated 4D Tensor: 1x1x%dx%d\nRAM Footprint: %.2f MB\nGeneration Time: %.2f s', N_snaps, delayBinCount, tensor_mem, t_gen_end);
                    uialert(app.UIFigure, bench_msg, 'Success (Benchmark Info)', 'Icon', 'success');
                end
                
            catch ME
                if exist('d','var') && isvalid(d), delete(d); end
                app.GenStartButton.Enable = 'on';
                if strcmp(app.CurrentLang, 'CN')
                    app.GenStartButton.Text = '生成信道';
                    uialert(app.UIFigure, ['仿真错误: ', ME.message], '错误');
                else
                    app.GenStartButton.Text = 'Generate Channel';
                    uialert(app.UIFigure, ['Simulation Error: ', ME.message], 'Error');
                end
            end
        end
        
        function GenSendToAIButtonPushed(app, ~)
            if isempty(app.GeneratedH)
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, '请先生成信道。', '信息');
                else
                    uialert(app.UIFigure, 'Please Generate Channel First.', 'Info');
                end
                return; 
            end
            if strcmp(app.CurrentLang, 'CN')
                d = uiprogressdlg(app.UIFigure, 'Title', '数据管道', 'Message', '内插与增强数据...');
            else
                d = uiprogressdlg(app.UIFigure, 'Title', 'Data Pipeline', 'Message', 'Interpolating & Augmenting Data...');
            end
            try
                generationResult = struct('cir', app.GeneratedH);
                dpsd_dbm_sim = generation_result_to_dpsd(generationResult);
                
                len_dpsd = 200;
                gen_val = app.GenModelDropDown.Value;
                band_val = app.FreqBandDropDown.Value;
                if contains(gen_val, '工业') || contains(gen_val, 'Industrial') || contains(band_val, '毫米波') || contains(band_val, 'mmWave')
                    len_dpsd = 500; 
                end
                
                has_source = false;
                source_data = [];
                source_idx = [];
                if ~isempty(app.LoadedData) && ~strcmp(app.DatasetDropDown.Value, '[None]')
                    for idx = 1:length(app.DatasetPaths)
                        if contains(app.DatasetPaths{idx}, '[Raw]') || ...
                                contains(app.DatasetPaths{idx}, '[原始]')
                            source_data = app.LoadedData{idx};
                            source_idx = idx;
                            len_dpsd = size(source_data, 1);
                            has_source = true;
                            break;
                        end
                    end
                end
                
                if size(dpsd_dbm_sim, 1) >= len_dpsd
                    dpsd_dbm_sim = dpsd_dbm_sim(1:len_dpsd, :);
                else
                    pad = zeros(len_dpsd - size(dpsd_dbm_sim,1), size(dpsd_dbm_sim,2)) - 130; 
                    dpsd_dbm_sim = [dpsd_dbm_sim; pad];
                end
                
                if has_source
                    N_real = size(source_data, 2);
                    N_sim = size(dpsd_dbm_sim, 2);
                    N_total = N_real + N_sim;
                    
                    x_real = linspace(0, 1, N_real);
                    x_total = linspace(0, 1, N_total);
                    source_interp = interp1(x_real, source_data', x_total, 'pchip')';
                    
                    sim_zero_mean = dpsd_dbm_sim - mean(dpsd_dbm_sim, 2);
                    x_sim = linspace(0, 1, N_sim);
                    sim_interp = interp1(x_sim, sim_zero_mean', x_total, 'spline')';
                    
                    alpha = 0.15; 
                    dpsd_dbm_combined = source_interp + alpha * sim_interp;
                    
                    if strcmp(app.CurrentLang, 'CN')
                        aug_label = '增强';
                        ds_name = sprintf('[%s] %s (实测 + %d 仿真)', aug_label, app.GenModelDropDown.Value, N_sim);
                    else
                        aug_label = 'Augmented';
                        ds_name = sprintf('[%s] %s (Real + %d Sim)', aug_label, app.GenModelDropDown.Value, N_sim);
                    end
                else
                    dpsd_dbm_combined = dpsd_dbm_sim;
                    if strcmp(app.CurrentLang, 'CN')
                        sim_label = '仿真';
                        ds_name = sprintf('[%s] %s (%d 快拍)', sim_label, app.GenModelDropDown.Value, size(dpsd_dbm_sim,2));
                    else
                        sim_label = 'Simulated';
                        ds_name = sprintf('[%s] %s (%d Snaps)', sim_label, app.GenModelDropDown.Value, size(dpsd_dbm_sim,2));
                    end
                end
                
                mets = app.analyzeChannelData_Generic(dpsd_dbm_combined, app.BandwidthEdit.Value * 1e6);
                
                curr_len = length(app.LoadedData);
                app.LoadedData{curr_len+1} = dpsd_dbm_combined; 
                app.ChannelMetrics{curr_len+1} = mets;
                app.DatasetPaths{curr_len+1} = ds_name;
                if has_source
                    app.DatasetMetadata{curr_len+1} = struct( ...
                        'kind', "augmented_real_plus_synthetic", ...
                        'real_source_index', source_idx, ...
                        'generated_sequence', dpsd_dbm_sim, ...
                        'source_label', string(ds_name));
                else
                    app.DatasetMetadata{curr_len+1} = struct( ...
                        'kind', "synthetic_generated", ...
                        'real_source_index', [], ...
                        'generated_sequence', dpsd_dbm_sim, ...
                        'source_label', string(ds_name));
                end
                
                app.DatasetDropDown.Items = app.DatasetPaths; 
                app.DatasetDropDown.Value = ds_name;
                
                if ~strcmp(app.CurrentPredDataset, ds_name)
                    app.PredictionResults = struct();
                    app.CurrentPredDataset = ds_name;
                    app.ExperimentContext = struct();
                end
                
                app.updateVisualizations();
                app.updateDataScaleProbe();
                
                if isvalid(d), delete(d); end
                app.TabGroup.SelectedTab = app.ChannelPredTab;
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, '数据内插、增强并发送至AI流水线!', '成功');
                else
                    uialert(app.UIFigure, 'Data Interpolated, Augmented and Sent to AI Pipeline!', 'Success');
                end
            catch ME
                if isvalid(d), delete(d); end
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, ['映射失败: ', ME.message], '错误');
                else
                    uialert(app.UIFigure, ['Mapping Failed: ', ME.message], 'Error');
                end
            end
        end
    end
    
    %% ==================== [Tab 3] AI Pipeline ====================
    methods (Access = private)
        
        function metrics = analyzeChannelData_Generic(~, dpsd_dbm, B_hz)
            metrics = analyze_channel_data(dpsd_dbm, B_hz);
        end

        function metadata = getDatasetMetadata(app, datasetIndex)
            metadata = struct( ...
                'kind', "legacy_unknown", ...
                'real_source_index', datasetIndex, ...
                'generated_sequence', [], ...
                'source_label', string(app.DatasetPaths{datasetIndex}));
            if datasetIndex <= numel(app.DatasetMetadata) && ...
                    ~isempty(app.DatasetMetadata{datasetIndex})
                metadata = app.DatasetMetadata{datasetIndex};
            end
        end
        
        function success = trainModel_Generic(app)
            success = false;
            if isempty(app.DatasetPaths) || strcmp(app.DatasetDropDown.Value, '[None]'), return; end
            idx = find(strcmp(app.DatasetPaths, app.DatasetDropDown.Value), 1);
            try
                metadata = app.getDatasetMetadata(idx);
                evaluationIndex = idx;
                evaluationSequence = double(app.LoadedData{idx}.');
                trainingPolicy = "real_only_chronological";
                if string(metadata.kind) == "augmented_real_plus_synthetic"
                    evaluationIndex = metadata.real_source_index;
                    if isempty(evaluationIndex) || evaluationIndex > numel(app.LoadedData)
                        error('ChanAI:MissingRealSource', ...
                            'The real source sequence for this augmented dataset is unavailable.');
                    end
                    evaluationSequence = double(app.LoadedData{evaluationIndex}.');
                    experiment = prepare_temporal_prediction_experiment(evaluationSequence, ...
                        'WindowLength', 10);
                    experiment = append_generated_training_windows(experiment, ...
                        double(metadata.generated_sequence.'), ...
                        'GeneratedSourceId', string(metadata.source_label));
                    trainingPolicy = "real_train_plus_synthetic_generated";
                else
                    experiment = prepare_temporal_prediction_experiment(evaluationSequence, ...
                        'WindowLength', 10);
                    if string(metadata.kind) == "synthetic_generated"
                        trainingPolicy = "synthetic_only_chronological";
                    end
                end
            catch ME
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, ['无法建立训练、验证与测试切分: ' ME.message], '错误');
                else
                    uialert(app.UIFigure, ['Unable to prepare train/validation/test split: ' ME.message], 'Error');
                end
                return;
            end
            app.NormParams = experiment.norm_params;
            app.PredictionWindow = experiment.window_length;
            
            prevState = app.UIFigure.WindowState;
            
            d = [];
            if isdeployed
                plot_mode = 'none';
                if strcmp(app.CurrentLang, 'CN')
                    dlg_title = ['训练模型 (' app.selectedAlgo ')...'];
                    dlg_msg = '深度训练进行中 (500 epochs)...';
                else
                    dlg_title = ['Training model (' app.selectedAlgo ')...'];
                    dlg_msg = 'Deep training in progress (500 epochs)...';
                end
                d = uiprogressdlg(app.UIFigure, 'Title', dlg_title, 'Message', dlg_msg);
                drawnow limitrate;
            else
                plot_mode = 'training-progress';
                if strcmp(app.CurrentLang, 'CN')
                    app.TrainButton.Text = '[ 训练中... ]';
                else
                    app.TrainButton.Text = '[ Training... ]';
                end
                app.TrainButton.Enable = 'off';
                drawnow limitrate; pause(0.1); 
            end
            
            t_train = tic;
            try
                trainingResult = train_prediction_model(experiment, app.selectedAlgo, ...
                    "PlotMode", plot_mode);
                app.TrainedNet = trainingResult.net;
                app.ExperimentContext = struct( ...
                    'experiment', experiment, ...
                    'evaluation_dataset_index', evaluationIndex, ...
                    'evaluation_dataset_label', string(app.DatasetPaths{evaluationIndex}), ...
                    'training_dataset_index', idx, ...
                    'training_policy', trainingPolicy, ...
                    'validation_rmse', trainingResult.validation_rmse, ...
                    'validation_nrmse', trainingResult.validation_nrmse);
                app.LastTrainTime = trainingResult.train_time;
                success = true;
            catch ME
                if ~isvalid(app) || ~isvalid(app.UIFigure), return; end
                if ~isempty(d) && isvalid(d), delete(d); end
                if strcmp(app.CurrentLang, 'CN')
                    app.TrainButton.Text = '1. 训练模型';
                else
                    app.TrainButton.Text = '1. Train Model';
                end
                app.TrainButton.Enable = 'on';
                app.stabilizeFocus(prevState);
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, ['训练失败: ' ME.message], '错误'); 
                else
                    uialert(app.UIFigure, ['Training failed: ' ME.message], 'Error'); 
                end
            end
            if ~success
                app.LastTrainTime = toc(t_train);
            end
            
            if ~isvalid(app) || ~isvalid(app.UIFigure), return; end
            if ~isempty(d) && isvalid(d), delete(d); end
            if strcmp(app.CurrentLang, 'CN')
                app.TrainButton.Text = '1. 训练模型';
            else
                app.TrainButton.Text = '1. Train Model';
            end
            app.TrainButton.Enable = 'on';
            app.stabilizeFocus(prevState);
        end
        
        function runPredictionLogic_Generic(app, noise_test, prefix)
            if isempty(app.DatasetPaths) || ~isfield(app.ExperimentContext, 'experiment')
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, '请重新训练当前数据集，以建立独立验证集和测试集。', '提示');
                else
                    uialert(app.UIFigure, 'Please retrain the current dataset to create hold-out validation and test sets.', 'Info');
                end
                return;
            end
            curr_ds = app.DatasetDropDown.Value;
            idx = find(strcmp(app.DatasetPaths, curr_ds), 1);
            if idx ~= app.ExperimentContext.training_dataset_index
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, '数据集已切换。请重新训练后再预测。', '提示');
                else
                    uialert(app.UIFigure, 'Dataset selection changed. Please retrain before prediction.', 'Info');
                end
                return;
            end
            experiment = app.ExperimentContext.experiment;
            evaluationIndex = app.ExperimentContext.evaluation_dataset_index;
            metric_data = app.ChannelMetrics{evaluationIndex};
            
            prevState = app.UIFigure.WindowState;
            if strcmp(app.CurrentLang, 'CN')
                d = uiprogressdlg(app.UIFigure, 'Title', '验证与推理中...', 'Indeterminate', 'on');
            else
                d = uiprogressdlg(app.UIFigure, 'Title', 'Verification and inference...', 'Indeterminate', 'on');
            end
            drawnow;
            
            future_len = round(app.PredLengthEdit.Value);
            batch_size = round(app.BatchSizeEdit.Value);
            if batch_size < 1, batch_size = 1; end
            B_hz = app.BandwidthEdit.Value * 1e6;
            noise_dBm = [noise_test, noise_test-5, noise_test-10, noise_test-15, noise_test-20];
            res = run_prediction_model(app.TrainedNet, experiment, app.NormParams, ...
                "FutureSteps", future_len, "BatchSize", batch_size, ...
                "BandwidthHz", B_hz, "NoiseDbm", noise_dBm, ...
                "ValidationRMSE", app.ExperimentContext.validation_rmse, ...
                "ValidationNRMSE", app.ExperimentContext.validation_nrmse);
            [nS, curr_dim] = size(res.Raw_Ori);
            res.Metrics = metric_data;
            
            if contains(curr_ds, '[增强]') || contains(curr_ds, '[Augmented]')
                res_key = sprintf('%s_Aug', app.selectedAlgo); tag_label = 'Real + Synthetic Train';
            elseif contains(curr_ds, '[原始]') || contains(curr_ds, '[Raw]')
                res_key = sprintf('%s_Raw', app.selectedAlgo); tag_label = 'Raw';
            else
                res_key = sprintf('%s_Sim', app.selectedAlgo); tag_label = 'Simulated';
            end
            
            if strcmp(app.CurrentLang, 'CN')
                res.DataScale = sprintf('%d Bins × %d 测试目标', curr_dim, nS);
            else
                res.DataScale = sprintf('%d Bins × %d Test Targets', curr_dim, nS);
            end
            res.TrainTime = app.LastTrainTime; res.TagLabel = tag_label;
            res.TrainingPolicy = app.ExperimentContext.training_policy;
            res.EvaluationDataset = app.ExperimentContext.evaluation_dataset_label;
            app.PredictionResults.(res_key) = res;
            
            if ~isvalid(app) || ~isvalid(app.UIFigure), return; end
            
            app.updatePredictionPlots_Generic(prefix);
            app.DataScaleInfoLabel.Text = sprintf('► Predict Output: %d Bins × %d Snaps', curr_dim, future_len);
            
            if exist('d', 'var') && isvalid(d), delete(d); end
            app.stabilizeFocus(prevState);
            
            app.showCustomReportDialog(prefix, app.selectedAlgo, res);
        end
        
        function showCustomReportDialog(app, prefix, algo, res)
            if strcmp(app.CurrentLang, 'CN')
                rpt_name = '评估报告';
                title_str = '验证结果';
                algo_label = '算法';
                data_label = '数据';
                acc_label = '[ 精度指标 ]';
                cap_label = '容量精度';
                ds_label = 'DS 误差';
                rmse_label = '绝对 RMSE';
                perf_label = '[ 性能与规模 ]';
                dim_label = '输入维度';
                time_label = '训练时间';
                delay_label = '推理延迟';
                ok_text = '确定';
            else
                rpt_name = 'Evaluation Report';
                title_str = 'Verification Results';
                algo_label = 'Algorithm';
                data_label = 'Data';
                acc_label = '[ Accuracy Metrics ]';
                cap_label = 'Capacity Acc';
                ds_label = 'DS Error';
                rmse_label = 'Abs RMSE';
                perf_label = '[ Performance & Scale ]';
                dim_label = 'Input Dimension';
                time_label = 'Train Time';
                delay_label = 'Infer Delay';
                ok_text = 'OK';
            end
            
            if strcmp(app.CurrentLang, 'CN')
                validation_rmse_label = '验证 RMSE';
                test_nrmse_label = '测试 NRMSE';
                test_rmse_label = '测试 RMSE';
            else
                validation_rmse_label = 'Validation RMSE';
                test_nrmse_label = 'Test NRMSE';
                test_rmse_label = 'Test RMSE';
            end

            rptFig = uifigure('Name', rpt_name, 'Position', [100, 100, 420, 470], 'WindowStyle', 'modal');
            rptFig.Color = [0.94 0.94 0.94]; movegui(rptFig, 'center'); 
            uilabel(rptFig, 'Text', title_str, 'Position', [20, 420, 380, 35], 'FontSize', 20, 'FontWeight', 'bold', 'FontColor', 'k', 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
            
            html_text = sprintf([...
                '<html><body style="font-family: ''Times New Roman'', serif; font-size: 14px; line-height: 1.8; color: #000000;">' ...
                '<div style="background-color: #FFFFFF; padding: 15px; border-radius: 8px; border: 1px solid #E5E5EA;">' ...
                '<b>%s:</b> %s (%s %s)<hr style="border:0; border-top:1px solid #E5E5EA;">' ...
                '<b>%s</b><br>' ...
                '<b>%s:</b> <span style="font-size:16px; color:#0071E3;"><b>%.2f %%</b></span><br>' ...
                '<b>%s:</b> <span style="font-size:16px;"><b>%.4f dBm</b></span><br>' ...
                '<b>%s:</b> <span style="font-size:16px;"><b>%.2f %%</b></span><br>' ...
                '<b>%s:</b> <span style="font-size:16px;"><b>%.4f dBm</b></span>' ...
                '<hr style="border:0; border-top:1px solid #E5E5EA;">' ...
                '<b>%s</b><br>' ...
                '<b>%s:</b> <span style="font-size:14px;"><b>%s</b></span><br>' ...
                '<b>%s:</b> <span style="font-size:14px;"><b>%.2f s</b></span><br>' ...
                '<b>%s:</b> <span style="font-size:14px;"><b>%.4f s</b></span>' ...
                '</div></body></html>'], ...
                algo_label, algo, res.TagLabel, data_label, ...
                acc_label, cap_label, res.CapAcc, ...
                validation_rmse_label, res.ValidationRMSE, ...
                test_nrmse_label, res.NRMSE, ...
                test_rmse_label, res.RMSE, ...
                perf_label, dim_label, res.DataScale, ...
                time_label, res.TrainTime, ...
                delay_label, res.InferTime);
            
            uihtml(rptFig, 'HTMLSource', html_text, 'Position', [20, 70, 380, 340]);
            uibutton(rptFig, 'Text', ok_text, 'Position', [140, 15, 140, 40], 'FontSize', 16, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn,event) close(rptFig), 'FontName', 'Times New Roman', 'BackgroundColor', [0.2 0.2 0.2], 'FontColor', 'white');
        end
        
        function updatePredictionPlots_Generic(app, prefix)
            algos_all = fieldnames(app.PredictionResults);
            if isempty(algos_all), return; end
            
            curr_ds = app.DatasetDropDown.Value;
            if contains(curr_ds, '[增强]') || contains(curr_ds, '[Augmented]'), curr_tag = '_Aug';
            elseif contains(curr_ds, '[原始]') || contains(curr_ds, '[Raw]'), curr_tag = '_Raw';
            else, curr_tag = '_Sim'; end
            
            algos = {};
            for i = 1:length(algos_all)
                if endsWith(algos_all{i}, curr_tag), algos{end+1} = algos_all{i}; end
            end
            if isempty(algos), return; end
            
            base_res = app.PredictionResults.(algos{1}); c_ori = app.Color_True; 
            c_dict = struct(); c_dict.TCN = app.Color_TCN; c_dict.LSTM = app.Color_LSTM; c_dict.GRU = app.Color_GRU;
            m_dict = struct(); m_dict.TCN = 'o'; m_dict.LSTM = '^'; m_dict.GRU = 'd';
            
            legend_opts = {'Location', 'best', 'TextColor', app.Color_Text, 'Color', 'none', 'EdgeColor', 'none', 'FontName', 'Times New Roman', 'FontSize', 12};
            
            if strcmp(app.CurrentLang, 'CN')
                cap_leg_true = '真实容量 (虚线)'; cap_leg_pred = 'AI 预测容量 (实线)';
                psd_leg_true = '测量值 (虚线)'; psd_leg_pred = '预测值 (实线)';
                cdf_leg_true = '真实 CDF (虚线)'; cdf_leg_pred = '预测 CDF (实线)';
                
                cap_title = sprintf('【%s】容量验证 (准确率: %.2f%%)', prefix, base_res.CapAcc);
                cap_xlab = 'SNR (dB)'; cap_ylab = '容量 (Gbps)';
                
                rmse_title = sprintf('【%s】分组 RMSE (NRMSE: %.2f%%)', prefix, base_res.NRMSE);
                rmse_title2 = sprintf('【%s】整体 RMSE', prefix);
                rmse_xlab = '分组索引'; rmse_ylab = 'RMSE (dBm)';
                
                psd_title = 'PSD 验证 (去噪后)';
                psd_xlab = '时延 (ns)'; psd_ylab = '功率 (dBm)';
                
                cdf_title = sprintf('【%s】时延扩展 CDF', prefix);
                cdf_xlab = '时延扩展 \tau (ns)'; cdf_ylab = 'CDF';
                
                ang_title = sprintf('【%s】角度功率谱', prefix);
                ang_xlab = '角度 (deg)'; ang_ylab = '功率 (dB)';
                
                dop_title = sprintf('【%s】多普勒', prefix);
                dop_xlab = 'Hz'; dop_ylab = 'dB';
            else
                cap_leg_true = 'Measurement'; cap_leg_pred = 'Predict';
                psd_leg_true = 'Measurement'; psd_leg_pred = 'Predict';
                cdf_leg_true = 'Measurement CDF'; cdf_leg_pred = 'Predict CDF';
                
                cap_title = sprintf('[%s] Capacity', prefix);
                cap_xlab = 'SNR (dB)'; cap_ylab = 'Capacity (Gbps)';
                
                rmse_title = sprintf('[%s] Group RMSE', prefix);
                rmse_title2 = sprintf('[%s] Overall RMSE', prefix);
                rmse_xlab = 'Group Index'; rmse_ylab = 'RMSE (dBm)';
                
                [~, worst_g] = max(base_res.GroupRMSE);
                psd_title = sprintf('PSD Verification (Worst-Case Group %d)', worst_g);
                psd_xlab = 'Delay (ns)'; psd_ylab = 'Power (dBm)';
                
                cdf_title = sprintf('[%s] DS CDF', prefix);
                cdf_xlab = 'DS \tau (ns)'; cdf_ylab = 'CDF';
                
                ang_title = sprintf('[%s] Angular PSD', prefix);
                ang_xlab = 'Angle (deg)'; ang_ylab = 'Power (dB)';
                
                dop_title = sprintf('[%s] Doppler', prefix);
                dop_xlab = 'Hz'; dop_ylab = 'dB';
            end
            
            % --- 1. 容量 ---
            delete(app.PredCapacityAxes.Children); hold(app.PredCapacityAxes, 'on');
            m_idx_cap = round(linspace(1, length(base_res.SNR), 5)); 
            h_cori = plot(app.PredCapacityAxes, base_res.SNR, base_res.C_ori, '--s', 'Color', c_ori, 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerIndices', m_idx_cap, 'MarkerFaceColor', c_ori); 
            lgds_cap = {h_cori}; strs_cap = {cap_leg_true}; y_cap_all = base_res.C_ori;
            for i = 1:length(algos)
                key = algos{i}; r = app.PredictionResults.(key);
                if contains(key, 'TCN'), alg_base='TCN'; elseif contains(key, 'LSTM'), alg_base='LSTM'; else, alg_base='GRU'; end
                if isfield(c_dict, alg_base), c_pre = c_dict.(alg_base); else, c_pre = app.Color_Primary; end
                if isfield(m_dict, alg_base), m_pre = m_dict.(alg_base); else, m_pre = 'o'; end
                h_cpre = plot(app.PredCapacityAxes, r.SNR, r.C_pre, ['-', m_pre], 'Color', c_pre, 'LineWidth', 1.5, 'MarkerFaceColor', c_pre, 'MarkerSize', 6, 'MarkerIndices', round(linspace(1, length(r.SNR), 5))); 
                lgds_cap{end+1} = h_cpre;
                if strcmp(app.CurrentLang, 'CN')
                    strs_cap{end+1} = cap_leg_pred; 
                else
                    strs_cap{end+1} = [alg_base ' ' cap_leg_pred];
                end
                y_cap_all = [y_cap_all; r.C_pre(:)];
            end
            hold(app.PredCapacityAxes, 'off');
            legend(app.PredCapacityAxes, [lgds_cap{:}], strs_cap, legend_opts{:});
            app.applyAxesStyle(app.PredCapacityAxes, cap_title, cap_xlab, cap_ylab); 
            app.applyYLimMargin(app.PredCapacityAxes, y_cap_all); app.setFullWidthAxes(app.PredCapacityAxes, base_res.SNR);
            
            % --- 2. RMSE ---
            delete(app.PredRMSEAxes.Children); hold(app.PredRMSEAxes, 'on');
            if length(base_res.GroupRMSE) > 1
                lgds_rmse = {}; strs_rmse = {}; y_rmse_all = [];
                for i = 1:length(algos)
                    key = algos{i}; r = app.PredictionResults.(key);
                    if contains(key, 'TCN'), alg_base='TCN'; elseif contains(key, 'LSTM'), alg_base='LSTM'; else, alg_base='GRU'; end
                    if isfield(c_dict, alg_base), c_pre = c_dict.(alg_base); else, c_pre = app.Color_Primary; end
                    if isfield(m_dict, alg_base), m_pre = m_dict.(alg_base); else, m_pre = 'o'; end
                    h_rmse = plot(app.PredRMSEAxes, 1:length(r.GroupRMSE), r.GroupRMSE, ['-', m_pre], 'Color', c_pre, 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerIndices', round(linspace(1, length(r.GroupRMSE), min(10, length(r.GroupRMSE)))), 'MarkerFaceColor', c_pre); 
                    lgds_rmse{end+1} = h_rmse; strs_rmse{end+1} = alg_base; y_rmse_all = [y_rmse_all; r.GroupRMSE(:)];
                end
                legend(app.PredRMSEAxes, [lgds_rmse{:}], strs_rmse, legend_opts{:});
                app.applyAxesStyle(app.PredRMSEAxes, rmse_title, rmse_xlab, rmse_ylab); 
                app.applyYLimMargin(app.PredRMSEAxes, y_rmse_all); app.setFullWidthAxes(app.PredRMSEAxes, 1:length(base_res.GroupRMSE));
            else
                vals = zeros(1, length(algos));
                for i = 1:length(algos), vals(i) = app.PredictionResults.(algos{i}).RMSE; end
                b = bar(app.PredRMSEAxes, 1:length(algos), vals, 0.4, 'FaceColor', 'flat', 'EdgeColor', 'none'); 
                for i = 1:length(algos)
                    key = algos{i}; if contains(key, 'TCN'), alg_base='TCN'; elseif contains(key, 'LSTM'), alg_base='LSTM'; else, alg_base='GRU'; end
                    if isfield(c_dict, alg_base), b.CData(i,:) = c_dict.(alg_base); else, b.CData(i,:) = app.Color_Primary; end
                end
                app.PredRMSEAxes.XTick = 1:length(algos); 
                tick_labels = {}; for i=1:length(algos), if contains(algos{i}, 'TCN'), tick_labels{i}='TCN'; elseif contains(algos{i}, 'LSTM'), tick_labels{i}='LSTM'; else, tick_labels{i}='GRU'; end; end
                app.PredRMSEAxes.XTickLabel = tick_labels;
                app.applyAxesStyle(app.PredRMSEAxes, rmse_title2, 'Algorithm', rmse_ylab); app.applyYLimMargin(app.PredRMSEAxes, vals);
            end
            hold(app.PredRMSEAxes, 'off');
            
            % --- 3. 原始全景 PSD ---
            delete(app.PredRawDataAxes.Children); hold(app.PredRawDataAxes, 'on');
            [~, worst_g] = max(base_res.GroupRMSE); total_snaps = size(base_res.Raw_Ori, 1); group_size = max(1, floor(total_snaps / 10));
            s_idx = (worst_g - 1) * group_size + 1; e_idx = min(total_snaps, worst_g * group_size);
            x_delay_raw = base_res.Metrics.delay.x; x_delay = x_delay_raw(:);
            tmp_ori_pwr = mean(10.^(base_res.Raw_Ori(s_idx:e_idx, :)/10), 1); raw_ori_pdp = 10*log10(tmp_ori_pwr(:) + 1e-20);
            
            m_idx_psd = round(linspace(1, length(x_delay), 20)); 
            h_rori = plot(app.PredRawDataAxes, x_delay, raw_ori_pdp, '--s', 'Color', [c_ori, 0.7], 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerIndices', m_idx_psd, 'MarkerFaceColor', c_ori); 
            lgds_psd = {h_rori}; strs_psd = {psd_leg_true}; y_all_raw = raw_ori_pdp(:); 
            
            for i = 1:length(algos)
                key = algos{i}; r = app.PredictionResults.(key);
                if contains(key, 'TCN'), alg_base='TCN'; elseif contains(key, 'LSTM'), alg_base='LSTM'; else, alg_base='GRU'; end
                if isfield(c_dict, alg_base), c_pre = c_dict.(alg_base); else, c_pre = app.Color_Primary; end
                if isfield(m_dict, alg_base), m_pre = m_dict.(alg_base); else, m_pre = 'o'; end
                
                t_snaps = size(r.Raw_Pre, 1); g_size = max(1, floor(t_snaps / 10)); rs_idx = (worst_g - 1) * g_size + 1; re_idx = min(t_snaps, worst_g * g_size);
                tmp_pre_pwr = mean(10.^(r.Raw_Pre(rs_idx:re_idx, :)/10), 1); raw_pre_pdp = 10*log10(tmp_pre_pwr(:) + 1e-20);
                
                h_rpre = plot(app.PredRawDataAxes, x_delay, raw_pre_pdp, ['-', m_pre], 'Color', c_pre, 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerIndices', m_idx_psd, 'MarkerFaceColor', c_pre); 
                lgds_psd{end+1} = h_rpre; 
                if strcmp(app.CurrentLang, 'CN')
                    strs_psd{end+1} = psd_leg_pred;
                else
                    strs_psd{end+1} = [alg_base ' ' psd_leg_pred];
                end
                y_all_raw = [y_all_raw; raw_pre_pdp(:)];
            end
            hold(app.PredRawDataAxes, 'off');
            legend(app.PredRawDataAxes, [lgds_psd{:}], strs_psd, legend_opts{:});
            app.applyAxesStyle(app.PredRawDataAxes, psd_title, psd_xlab, psd_ylab);
            app.applyYLimMargin(app.PredRawDataAxes, y_all_raw); app.setFullWidthAxes(app.PredRawDataAxes, x_delay);
            
            % --- 4. DS CDF ---
            delete(app.PredSpreadAxes.Children); hold(app.PredSpreadAxes, 'on');
            m_idx_cdf = round(linspace(1, length(base_res.xo), 15));
            h_sfo = plot(app.PredSpreadAxes, base_res.xo, base_res.fo, '--s', 'Color', c_ori, 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerIndices', m_idx_cdf, 'MarkerFaceColor', c_ori); 
            lgds_cdf = {h_sfo}; strs_cdf = {cdf_leg_true}; 
            for i = 1:length(algos)
                key = algos{i}; r = app.PredictionResults.(key);
                if contains(key, 'TCN'), alg_base='TCN'; elseif contains(key, 'LSTM'), alg_base='LSTM'; else, alg_base='GRU'; end
                if isfield(c_dict, alg_base), c_pre = c_dict.(alg_base); else, c_pre = app.Color_Primary; end
                if isfield(m_dict, alg_base), m_pre = m_dict.(alg_base); else, m_pre = 'o'; end
                h_sfp = plot(app.PredSpreadAxes, r.xp, r.fp, ['-', m_pre], 'Color', c_pre, 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerIndices', round(linspace(1, length(r.xp), 15)), 'MarkerFaceColor', c_pre); 
                lgds_cdf{end+1} = h_sfp;
                if strcmp(app.CurrentLang, 'CN')
                    strs_cdf{end+1} = cdf_leg_pred;
                else
                    strs_cdf{end+1} = [alg_base ' ' cdf_leg_pred];
                end
            end
            hold(app.PredSpreadAxes, 'off');
            legend(app.PredSpreadAxes, [lgds_cdf{:}], strs_cdf, legend_opts{:});
            app.applyAxesStyle(app.PredSpreadAxes, cdf_title, cdf_xlab, cdf_ylab); 
            app.PredSpreadAxes.YLim = [0, 1]; app.setFullWidthAxes(app.PredSpreadAxes, base_res.xp);
            
            % --- 5. 角度与多普勒 ---
            if strcmp(app.CurrentLang, 'CN')
                no_data_str = '无数据';
            else
                no_data_str = 'No Data';
            end
            delete(app.PredAngularAxes.Children); m = base_res.Metrics;
            if isfield(m, 'space') && max(m.space.psd) > -900
                plot(app.PredAngularAxes, m.space.angle, m.space.psd, '-o', 'Color', app.Color_Primary, 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerIndices', round(linspace(1, length(m.space.angle), 20)), 'MarkerFaceColor', app.Color_Primary);
                app.applyAxesStyle(app.PredAngularAxes, ang_title, ang_xlab, ang_ylab);
                app.applyYLimMargin(app.PredAngularAxes, m.space.psd); app.setFullWidthAxes(app.PredAngularAxes, m.space.angle);
            else
                set(app.PredAngularAxes, 'XTick', [], 'YTick', []);
                text(app.PredAngularAxes, 0.5, 0.5, no_data_str, 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', app.Color_TextDim, 'FontName', 'Times New Roman');
                app.applyAxesStyle(app.PredAngularAxes, ang_title, ang_xlab, ang_ylab);
            end
            
            delete(app.PredDopplerAxes.Children);
            if isfield(m, 'time') && max(m.time.y) > -900
                plot(app.PredDopplerAxes, m.time.x, m.time.y, '-o', 'Color', app.Color_Primary, 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerIndices', round(linspace(1, length(m.time.x), 20)), 'MarkerFaceColor', app.Color_Primary);
                app.applyAxesStyle(app.PredDopplerAxes, dop_title, dop_xlab, dop_ylab);
                app.applyYLimMargin(app.PredDopplerAxes, m.time.y); app.setFullWidthAxes(app.PredDopplerAxes, m.time.x);
            else
                set(app.PredDopplerAxes, 'XTick', [], 'YTick', []);
                text(app.PredDopplerAxes, 0.5, 0.5, no_data_str, 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', app.Color_TextDim, 'FontName', 'Times New Roman');
                app.applyAxesStyle(app.PredDopplerAxes, dop_title, dop_xlab, dop_ylab);
            end
            drawnow limitrate;
        end
    end
    
    %% ==================== 界面响应与防缩放排版 ====================
    methods (Access = private)
        function startupFcn(app)
            % 强制进行一次全局多语言同步，确保初始启动界面的所有元素绝对一致
            app.updateAllUIText();
        end
        
        function ConfigValueChanged(app, ~)
            band_val = app.FreqBandDropDown.Value;
            bw = 100;
            if contains(band_val, 'mmWave') || contains(band_val, '毫米波'), bw = 200; end
            if contains(band_val, 'THz') || contains(band_val, '太赫兹'), bw = 200; end
            if contains(band_val, 'OWC') || contains(band_val, '光无线'), bw = 200; end
            app.BandwidthEdit.Value = bw;
        end
        
        function UIFigureSizeChanged(app, ~)
            pos = app.UIFigure.Position; actualW = pos(3); actualH = pos(4);
            
            % === [关键修复 1] 语言切换下拉框排版 (固定在右上角) ===
            ddW = 100; ddH = 30;
            app.LangDropDown.Position = [actualW - ddW - 10, actualH - ddH - 5, ddW, ddH];
            
            % 将 TabGroup 的高度下压 40 像素，给顶部控件留出专属空间，防止被遮挡
            app.TabGroup.Position = [1, 1, actualW, actualH - 40]; 
            
            % 内部滚动高度也相应减去顶部的 40 像素
            usableH = actualH - 40 - 35; 
            vW = max(actualW, 1200); vH = max(usableH, 750); 
            
            app.DataImportScrollPanel.Position = [1 1 actualW usableH]; 
            app.ChannelPredScrollPanel.Position = [1 1 actualW usableH];
            
            if isprop(app, 'GenScrollPanel') && ~isempty(app.GenScrollPanel) && isvalid(app.GenScrollPanel)
                app.GenScrollPanel.Position = [1 1 actualW usableH];
            end
            
            pw = vW - 30;
            
            app.BasicConfigPanel.Position = [15, vH - 85, pw, 70]; 
            app.FreqBandLabel.Position = [15 15 80 25]; 
            app.FreqBandDropDown.Position = [95 15 160 25];
            app.ScenarioLabel.Position = [280 15 60 25]; 
            app.ScenarioDropDown.Position = [340 15 140 25];
            app.BandwidthLabel.Position = [505 15 90 25]; 
            app.BandwidthEdit.Position = [595 15 80 25];
            
            app.DataMgmtPanel.Position = [15, vH - 165, pw, 70];
            app.DatasetDropDown.Position = [15 15 600 25]; 
            
            btnWidth = 120; btnHeight = 30;
            app.LoadDataButton.Position  = [pw - btnWidth - 10, 12, btnWidth, btnHeight]; 
            app.ClearDataButton.Position = [pw - btnWidth*2 - 20, 12, btnWidth, btnHeight]; 
            
            charH = vH - 190; 
            app.ChannelCharsPanel.Position = [15, 15, pw, charH];
            ph1 = charH - 30; mx1 = 70; my1 = 50; gx1 = 80; gy1 = 70; 
            aw1 = max(1, (pw - 2*mx1 - gx1)/2); ah1 = max(1, (ph1 - 2*my1 - gy1)/2);
            app.SpreadCDFAxes.Position = [mx1, my1 + ah1 + gy1, aw1, ah1]; 
            app.DopplerPowerAxes.Position = [mx1 + aw1 + gx1, my1 + ah1 + gy1, aw1, ah1]; 
            app.DelayPowerAxes.Position = [mx1, my1, aw1, ah1]; 
            app.AngularPowerAxes.Position = [mx1 + aw1 + gx1, my1, aw1, ah1];
            
            if isprop(app, 'GenConfigPanel') && ~isempty(app.GenConfigPanel) && isvalid(app.GenConfigPanel)
                app.GenConfigPanel.Position = [15, vH - 85, pw, 70];
                app.GenModelLabel.Position = [15 15 120 25];
                app.GenModelDropDown.Position = [135 15 150 25];
                genBtnWidth = 160; genBtnHeight = 35;
                app.GenStartButton.Position = [315 10, genBtnWidth, genBtnHeight];
                app.GenSendToAIButton.Position = [495 10, genBtnWidth, genBtnHeight];
                
                if isprop(app, 'GenParamPanel') && ~isempty(app.GenParamPanel) && isvalid(app.GenParamPanel)
                    app.GenParamPanel.Position = [15, vH - 165, pw, 70];
                    w = 80; sx = 15; sp = 100;
                    app.DSmuLabel.Position = [sx 15 w 25]; app.DSmuEdit.Position = [sx+50 15 50 25]; sx = sx + sp + 10;
                    app.DSsigmaLabel.Position = [sx 15 w 25]; app.DSsigmaEdit.Position = [sx+65 15 45 25]; sx = sx + sp + 20;
                    app.rDSLabel.Position = [sx 15 w 25]; app.rDSEdit.Position = [sx+40 15 45 25]; sx = sx + sp;
                    app.ClusterLabel.Position = [sx 15 w 25]; app.ClusterEdit.Position = [sx+55 15 45 25]; sx = sx + sp + 10;
                    app.RayLabel.Position = [sx 15 w 25]; app.RayEdit.Position = [sx+40 15 45 25]; sx = sx + sp;
                    app.KFmuLabel.Position = [sx 15 w 25]; app.KFmuEdit.Position = [sx+45 15 45 25]; sx = sx + sp;
                    app.KFsigmaLabel.Position = [sx 15 w 25]; app.KFsigmaEdit.Position = [sx+60 15 45 25]; sx = sx + sp + 10;
                    app.SnapLabel.Position = [sx 15 w 25]; app.SnapEdit.Position = [sx+45 15 50 25];
                end
                
                if isprop(app, 'GenPDPAxes') && ~isempty(app.GenPDPAxes) && isvalid(app.GenPDPAxes)
                    gh = vH - 190;
                    aw2 = max(1, (pw - 2*mx1 - gx1)/2); 
                    ah2 = max(1, gh - 2*my1);
                    app.GenPDPAxes.Position = [mx1, my1, aw2, ah2];
                    app.GenCDFAxes.Position = [mx1 + aw2 + gx1, my1, aw2, ah2];
                end
            end
            
            app.PredConfigPanel.Position = [15, vH - 175, pw, 160];
            cx = max(15, (pw - 780) / 2); 
            app.AlgoPanel.Position   = [cx,       10, 130, 120];
            app.TargetPanel.Position = [cx + 140, 10, 130, 120];
            app.TaskPanel.Position   = [cx + 280, 10, 150, 120];
            app.ParamPanel.Position  = [cx + 440, 10, 250, 120];
            
            bw_btn = 100; bx = 10;
            app.TCNButton.Position = [bx, 65, bw_btn, 25];
            app.LSTMButton.Position = [bx, 35, bw_btn, 25];
            app.GRUButton.Position = [bx, 5, bw_btn, 25];
            
            app.TimeDomainButton.Position = [bx, 65, bw_btn, 25];
            app.FreqDomainButton.Position = [bx, 35, bw_btn, 25];
            app.SpaceDomainButton.Position = [bx, 5, bw_btn, 25];
            
            taskBtnWidth = 120; taskBtnHeight = 35;
            app.TrainButton.Position = [15, 55, taskBtnWidth, taskBtnHeight];
            app.PredictButton.Position = [15, 10, taskBtnWidth, taskBtnHeight];
            
            app.PredLengthLabel.Position = [10, 65, 150, 25];                                               
            app.PredLengthEdit.Position = [160, 65, 60, 25];                                                
            app.BatchSizeLabel.Position = [10, 35, 150, 25];                                                
            app.BatchSizeEdit.Position = [160, 35, 60, 25];                                                 
            
            app.DataScaleInfoLabel.Position = [10, 8, 230, 20];                                            
            
            saveBtnWidth = 160; saveBtnHeight = 35;
            app.SavePredDataButton.Position = [pw - saveBtnWidth - 15, 80, saveBtnWidth, saveBtnHeight]; 
            app.ExportModelButton.Position = [pw - saveBtnWidth - 15, 20, saveBtnWidth, saveBtnHeight];
            
            plotH = vH - 190; 
            app.PredPlotPanel.Position = [15, 15, pw, plotH];
            
            mx3 = 45; my3 = 45; gx3 = 60; gy3 = 60; 
            ph3 = plotH - 30;
            aw3 = max(1, (pw - 2*mx3 - 2*gx3)/3); 
            ah3 = max(1, (ph3 - 2*my3 - gy3)/2);
            
            app.PredCapacityAxes.Position = [mx3, my3 + ah3 + gy3, aw3, ah3]; 
            app.PredRawDataAxes.Position  = [mx3 + aw3 + gx3, my3 + ah3 + gy3, aw3, ah3]; 
            app.PredAngularAxes.Position  = [mx3 + 2*aw3 + 2*gx3, my3 + ah3 + gy3, aw3, ah3]; 
            
            app.PredRMSEAxes.Position     = [mx3, my3, aw3, ah3]; 
            app.PredSpreadAxes.Position   = [mx3 + aw3 + gx3, my3, aw3, ah3];
            app.PredDopplerAxes.Position  = [mx3 + 2*aw3 + 2*gx3, my3, aw3, ah3];
        end
        
        function LoadDataButtonPushed(app, ~)
            combo_name = [app.FreqBandDropDown.Value, '-', app.ScenarioDropDown.Value];
            app.loadData_Generic(combo_name);
        end
        
        function updateVisualizations(app)
            if isempty(app.DatasetPaths), return; end
            idx = find(strcmp(app.DatasetPaths, app.DatasetDropDown.Value), 1);
            metrics = app.ChannelMetrics{idx};
            axesHandles = struct( ...
                'angular', app.AngularPowerAxes, ...
                'delay', app.DelayPowerAxes, ...
                'spread', app.SpreadCDFAxes, ...
                'doppler', app.DopplerPowerAxes);
            style = struct( ...
                'language', app.CurrentLang, ...
                'primary_color', app.Color_Primary, ...
                'text_color', app.Color_Text, ...
                'text_dim_color', app.Color_TextDim);
            render_characterization_plots(axesHandles, metrics, style);
        end
        
        function ClearDataButtonPushed(app, ~)
            app.LoadedData={}; app.ChannelMetrics={}; app.DatasetPaths={}; app.DatasetMetadata={};
            app.DatasetDropDown.Items={'[None]'}; app.PredictionResults=struct(); 
            app.TrainedNet=[]; app.ExperimentContext=struct(); app.showPlaceholderPlots(); app.showPredPlaceholderPlots();
            app.DataScaleInfoLabel.Text = app.getStatusText('cleared'); 
        end
        
        function TrainButtonPushed(app, ~)
            if isempty(app.DatasetPaths)
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, '请先加载数据!', '信息');
                else
                    uialert(app.UIFigure, 'Please load data first!', 'Info');
                end
                return; 
            end
            app.trainModel_Generic(); 
        end
        
        function PredictButtonPushed(app, ~)
            if isempty(app.TrainedNet)
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, '请先训练模型!', '信息');
                else
                    uialert(app.UIFigure, 'Please train the model first!', 'Info');
                end
                return; 
            end
            band_val = app.FreqBandDropDown.Value;
            if contains(band_val, 'Sub-6'), band_en = 'Sub-6';
            elseif contains(band_val, 'mmWave'), band_en = 'mmWave';
            elseif contains(band_val, 'THz'), band_en = 'THz';
            else, band_en = 'Optical Wireless'; end
            
            scen_val = app.ScenarioDropDown.Value;
            scene_map = containers.Map(...
                {'卫星', '无人机', '海洋', 'RIS', '工业物联网', 'ISAC', '场景 1', '场景 2', '场景 3', '场景 4'}, ...
                {'Satellite', 'UAV', 'Maritime', 'RIS', 'Industrial IoT', 'ISAC', 'Scenario 1', 'Scenario 2', 'Scenario 3', 'Scenario 4'});
            if isKey(scene_map, scen_val), scen_en = scene_map(scen_val); else, scen_en = scen_val; end
            
            noise = -100; 
            if contains(band_en, 'mmWave'), noise = -37; end
            if contains(band_en, 'THz'), noise = -120; end
            if contains(band_en, 'Optical Wireless'), noise = -130; end
            prefix = [band_en, '-', scen_en]; 
            app.runPredictionLogic_Generic(noise, prefix); 
        end
        
        function resetAlgoButtons(app)
            app.TCNButton.BackgroundColor = app.DefaultBtnColor; app.TCNButton.FontColor = app.Color_Text;
            app.LSTMButton.BackgroundColor = app.DefaultBtnColor; app.LSTMButton.FontColor = app.Color_Text;
            app.GRUButton.BackgroundColor = app.DefaultBtnColor; app.GRUButton.FontColor = app.Color_Text;
        end
        function TCNButtonPushed(app, ~), app.resetAlgoButtons(); app.selectedAlgo='TCN'; app.TCNButton.BackgroundColor=app.ActiveBtnColor; app.TCNButton.FontColor='w'; end
        function LSTMButtonPushed(app, ~), app.resetAlgoButtons(); app.selectedAlgo='LSTM'; app.LSTMButton.BackgroundColor=app.ActiveBtnColor; app.LSTMButton.FontColor='w'; end
        function GRUButtonPushed(app, ~), app.resetAlgoButtons(); app.selectedAlgo='GRU'; app.GRUButton.BackgroundColor=app.ActiveBtnColor; app.GRUButton.FontColor='w'; end
        
        function resetDomainButtons(app)
            app.TimeDomainButton.BackgroundColor = app.DefaultBtnColor; app.TimeDomainButton.FontColor = app.Color_Text;
            app.FreqDomainButton.BackgroundColor = app.DefaultBtnColor; app.FreqDomainButton.FontColor = app.Color_Text;
            app.SpaceDomainButton.BackgroundColor = app.DefaultBtnColor; app.SpaceDomainButton.FontColor = app.Color_Text;
        end
        function TimeDomainButtonPushed(app, ~), app.resetDomainButtons(); app.selectedTarget='Time'; app.TimeDomainButton.BackgroundColor=app.ActiveBtnColor; app.TimeDomainButton.FontColor='w'; end
        function FreqDomainButtonPushed(app, ~), app.resetDomainButtons(); app.selectedTarget='Freq'; app.FreqDomainButton.BackgroundColor=app.ActiveBtnColor; app.FreqDomainButton.FontColor='w'; end
        function SpaceDomainButtonPushed(app, ~), app.resetDomainButtons(); app.selectedTarget='Space'; app.SpaceDomainButton.BackgroundColor=app.ActiveBtnColor; app.SpaceDomainButton.FontColor='w'; end
        
        function ExportModelButtonPushed(app, ~)
            if isempty(app.TrainedNet)
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, '无模型可导出', '错误');
                else
                    uialert(app.UIFigure, 'No model to export', 'Error');
                end
                return; 
            end
            prevState = app.UIFigure.WindowState;
            if strcmp(app.CurrentLang, 'CN')
                dlg_title = '保存模型';
            else
                dlg_title = 'Save Model';
            end
            [f, p] = uiputfile('*.mat', dlg_title);
            app.stabilizeFocus(prevState); 
            if isequal(f,0) || isequal(p,0), return; end
            net = app.TrainedNet; save(fullfile(p,f), 'net');
            if strcmp(app.CurrentLang, 'CN')
                uialert(app.UIFigure, '模型导出成功!', '成功');
            else
                uialert(app.UIFigure, 'Model exported successfully!', 'Success');
            end
        end
        
        function SavePredDataButtonPushed(app, ~)
            if isempty(fieldnames(app.PredictionResults))
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, '无预测数据可用!', '错误');
                else
                    uialert(app.UIFigure, 'No prediction data available!', 'Error');
                end
                return; 
            end
            
            algos = fieldnames(app.PredictionResults);
            curr_base = app.selectedAlgo;
            match_key = '';
            for i = 1:length(algos)
                if startsWith(algos{i}, curr_base)
                    match_key = algos{i}; 
                end
            end
            if isempty(match_key)
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, '当前选定算法无预测数据!', '错误');
                else
                    uialert(app.UIFigure, 'No prediction data for currently selected algorithm!', 'Error');
                end
                return; 
            end
            
            res = app.PredictionResults.(match_key);
            prevState = app.UIFigure.WindowState; batch_size = length(res.Future_Pre);
            if batch_size <= 1
                if strcmp(app.CurrentLang, 'CN')
                    dlg_title = '保存预测结果';
                else
                    dlg_title = 'Save prediction results';
                end
                [f,p] = uiputfile('*.mat', dlg_title); 
                app.stabilizeFocus(prevState);
                if isequal(f,0) || isequal(p,0), return; end
                save(fullfile(p,f), 'res');
                if strcmp(app.CurrentLang, 'CN')
                    uialert(app.UIFigure, '预测数据导出成功!', '成功');
                else
                    uialert(app.UIFigure, 'Prediction data exported successfully!', 'Success');
                end
            else
                if strcmp(app.CurrentLang, 'CN')
                    dlg_title = sprintf('选择文件夹以输出 %d 个独立数据集', batch_size);
                else
                    dlg_title = sprintf('Select folder to output %d independent datasets', batch_size);
                end
                selpath = uigetdir('', dlg_title); 
                app.stabilizeFocus(prevState);
                if isequal(selpath,0) || isequal(selpath,''), return; end
                val_metrics = rmfield(res, 'Future_Pre'); 
                save(fullfile(selpath, 'Validation_Metrics_Base.mat'), 'val_metrics');
                if strcmp(app.CurrentLang, 'CN')
                    d = uiprogressdlg(app.UIFigure, 'Title', '导出批数据集...', 'Indeterminate', 'on');
                else
                    d = uiprogressdlg(app.UIFigure, 'Title', 'Exporting batch datasets...', 'Indeterminate', 'on');
                end
                try
                    for b = 1:batch_size
                        channel_data = res.Future_Pre{b}; 
                        save(fullfile(selpath, sprintf('Future_Dataset_%03d.mat', b)), 'channel_data'); 
                    end
                    if isvalid(d), delete(d); end
                    if strcmp(app.CurrentLang, 'CN')
                        uialert(app.UIFigure, sprintf('成功在选定文件夹生成 %d 个独立数据集!', batch_size), '批量导出成功');
                    else
                        uialert(app.UIFigure, sprintf('Successfully generated %d independent datasets in selected folder!', batch_size), 'Batch export successful');
                    end
                catch ME
                    if isvalid(d), delete(d); end
                    if strcmp(app.CurrentLang, 'CN')
                        uialert(app.UIFigure, ['导出失败: ' ME.message], '错误');
                    else
                        uialert(app.UIFigure, ['Export failed: ' ME.message], 'Error');
                    end
                end
            end
        end
        
        function showPlaceholderPlots(app)
            if strcmp(app.CurrentLang, 'CN')
                wait_str = '等待数据...';
            else
                wait_str = 'Waiting Data...';
            end
            app.applyAxesStyle(app.AngularPowerAxes, wait_str, '', ''); 
            app.applyAxesStyle(app.DelayPowerAxes, wait_str, '', '');
            app.applyAxesStyle(app.SpreadCDFAxes, wait_str, '', ''); 
            app.applyAxesStyle(app.DopplerPowerAxes, wait_str, '', '');
        end
        
        function showPredPlaceholderPlots(app)
            if strcmp(app.CurrentLang, 'CN')
                cap_str = '容量等待中...';
                psd_str = 'PSD等待中...';
                rmse_str = 'RMSE等待中...';
                spread_str = '扩展等待中...';
                ang_str = '角度等待中...';
                dop_str = '多普勒等待中...';
            else
                cap_str = 'Capacity Waiting...';
                psd_str = 'PSD Waiting...';
                rmse_str = 'RMSE Waiting...';
                spread_str = 'Spread Waiting...';
                ang_str = 'Angle Waiting...';
                dop_str = 'Doppler Waiting...';
            end
            app.applyAxesStyle(app.PredCapacityAxes, cap_str, '', ''); 
            app.applyAxesStyle(app.PredRawDataAxes, psd_str, '', '');
            app.applyAxesStyle(app.PredRMSEAxes, rmse_str, '', ''); 
            app.applyAxesStyle(app.PredSpreadAxes, spread_str, '', '');
            app.applyAxesStyle(app.PredAngularAxes, ang_str, '', ''); 
            app.applyAxesStyle(app.PredDopplerAxes, dop_str, '', '');
        end
    end
    
    %% ==================== UI 创建逻辑 ====================
    methods (Access = private)
        function createComponents(app)
            try
                warning('off', 'MATLAB:ui:container:AutoResizeChildren');
                
                app.UIFigure = uifigure('Name', '6G Channel Predictor', 'Position', [100 100 1300 850], 'Visible', 'off', 'Color', app.Color_Bg);
                app.UIFigure.AutoResizeChildren = 'off';
                
                % === [语言切换核心] 语言切换下拉框 (右上角，置于UIFigure顶层) ===
                app.LangDropDown = uidropdown(app.UIFigure, ...
                    'Items', {'English', '中文'}, ...
                    'Value', 'English', ...
                    'Position', [1210, 812, 100, 30], ...
                    'BackgroundColor', [0.96, 0.96, 0.96], ...
                    'FontName', 'Times New Roman', ...
                    'FontSize', 14, ...
                    'FontWeight', 'bold', ...
                    'FontColor', [0.1, 0.1, 0.1], ...
                    'Tooltip', 'Select Interface Language', ...
                    'ValueChangedFcn', createCallbackFcn(app, @langDropdownChanged, true));
                
                app.TabGroup = uitabgroup(app.UIFigure, 'Position', [1 1 1300 850]);
                app.TabGroup.AutoResizeChildren = 'off';
                
                % --- 第一页 ---
                app.DataImportTab = uitab(app.TabGroup, 'Title', '1. Characterization', 'BackgroundColor', app.Color_Bg);
                app.DataImportScrollPanel = uipanel(app.DataImportTab, 'Scrollable', 'on', 'BackgroundColor', app.Color_Bg, 'BorderType', 'none');
                app.DataImportScrollPanel.AutoResizeChildren = 'off';
                
                app.BasicConfigPanel = uipanel(app.DataImportScrollPanel, 'Title', 'Parameters & Scenario', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.BasicConfigPanel.AutoResizeChildren = 'off';
                
                app.FreqBandLabel = uilabel(app.BasicConfigPanel, 'Text', 'Band:', 'FontName', 'Times New Roman');
                app.FreqBandDropDown = uidropdown(app.BasicConfigPanel, 'Items', ...
                    {'Sub-6', 'mmWave', 'THz', 'Optical Wireless'}, ...
                    'ValueChangedFcn', createCallbackFcn(app, @(s,e) app.updateScenarioItems(), true), 'FontName', 'Times New Roman');
                
                app.ScenarioLabel = uilabel(app.BasicConfigPanel, 'Text', 'Scenario:', 'FontWeight', 'bold', 'FontName', 'Times New Roman');
                app.ScenarioDropDown = uidropdown(app.BasicConfigPanel, 'Items', {'Loading...'}, ...
                    'ValueChangedFcn', createCallbackFcn(app, @ConfigValueChanged, true), 'FontName', 'Times New Roman');
                
                app.BandwidthLabel = uilabel(app.BasicConfigPanel, 'Text', 'BW (MHz):', 'FontName', 'Times New Roman');
                app.BandwidthEdit = uieditfield(app.BasicConfigPanel, 'numeric', 'Value', 100, 'FontName', 'Times New Roman');
                
                app.DataMgmtPanel = uipanel(app.DataImportScrollPanel, 'Title', 'Data Load', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.DataMgmtPanel.AutoResizeChildren = 'off';
                
                app.DatasetDropDown = uidropdown(app.DataMgmtPanel, 'Items', {'[None]'}, 'FontName', 'Times New Roman', 'ValueChangedFcn', createCallbackFcn(app, @(~,~) app.updateDataScaleProbe(), true));
                app.ClearDataButton = uibutton(app.DataMgmtPanel, 'Text', 'Clear', 'ButtonPushedFcn', createCallbackFcn(app, @ClearDataButtonPushed, true), 'FontName', 'Times New Roman');
                app.LoadDataButton = uibutton(app.DataMgmtPanel, 'Text', 'Load Data', 'BackgroundColor', app.ActiveBtnColor, 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @LoadDataButtonPushed, true), 'FontName', 'Times New Roman');
                
                app.ChannelCharsPanel = uipanel(app.DataImportScrollPanel, 'Title', 'Characteristic Plots', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.ChannelCharsPanel.AutoResizeChildren = 'off';
                
                app.AngularPowerAxes = uiaxes(app.ChannelCharsPanel);
                app.DelayPowerAxes = uiaxes(app.ChannelCharsPanel);
                app.DopplerPowerAxes = uiaxes(app.ChannelCharsPanel);
                app.SpreadCDFAxes = uiaxes(app.ChannelCharsPanel);
                
                % --- 第二页 ---
                app.ChannelGenTab = uitab(app.TabGroup, 'Title', '2. Channel Generation', 'BackgroundColor', app.Color_Bg);
                app.GenScrollPanel = uipanel(app.ChannelGenTab, 'BackgroundColor', app.Color_Bg, 'BorderType', 'none');
                app.GenScrollPanel.AutoResizeChildren = 'off';
                
                app.GenConfigPanel = uipanel(app.GenScrollPanel, 'Title', 'Simulation Parameters & Execution', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.GenConfigPanel.AutoResizeChildren = 'off';
                
                app.GenModelLabel = uilabel(app.GenConfigPanel, 'Text', 'Simulation Model:', 'FontName', 'Times New Roman');
                app.GenModelDropDown = uidropdown(app.GenConfigPanel, 'Items', {'Loading...'}, 'FontName', 'Times New Roman');
                app.GenStartButton = uibutton(app.GenConfigPanel, 'Text', 'Generate Channel', 'BackgroundColor', [0 0.5 0.2], 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @GenStartButtonPushed, true), 'FontName', 'Times New Roman');
                app.GenSendToAIButton = uibutton(app.GenConfigPanel, 'Text', 'Send to AI', 'BackgroundColor', app.Color_Blue, 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @GenSendToAIButtonPushed, true), 'FontName', 'Times New Roman');
                
                app.GenParamPanel = uipanel(app.GenScrollPanel, 'Title', 'Stochastic Engine Physics (Large & Small Scale Fading)', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.GenParamPanel.AutoResizeChildren = 'off';
                
                app.DSmuLabel = uilabel(app.GenParamPanel, 'Text', 'DS mu:', 'FontName', 'Times New Roman');
                app.DSmuEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', -7.925, 'FontName', 'Times New Roman');
                app.DSsigmaLabel = uilabel(app.GenParamPanel, 'Text', 'DS sigma:', 'FontName', 'Times New Roman');
                app.DSsigmaEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 0.060, 'FontName', 'Times New Roman');
                app.rDSLabel = uilabel(app.GenParamPanel, 'Text', 'r DS:', 'FontName', 'Times New Roman');
                app.rDSEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 2.8, 'FontName', 'Times New Roman');
                app.ClusterLabel = uilabel(app.GenParamPanel, 'Text', 'Clusters:', 'FontName', 'Times New Roman');
                app.ClusterEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 12, 'FontName', 'Times New Roman');
                app.RayLabel = uilabel(app.GenParamPanel, 'Text', 'Rays:', 'FontName', 'Times New Roman');
                app.RayEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 20, 'FontName', 'Times New Roman');
                app.KFmuLabel = uilabel(app.GenParamPanel, 'Text', 'KF mu:', 'FontName', 'Times New Roman');
                app.KFmuEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', -0.39, 'FontName', 'Times New Roman');
                app.KFsigmaLabel = uilabel(app.GenParamPanel, 'Text', 'KF sigma:', 'FontName', 'Times New Roman');
                app.KFsigmaEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 2.4, 'FontName', 'Times New Roman');
                app.SnapLabel = uilabel(app.GenParamPanel, 'Text', 'Snaps:', 'FontName', 'Times New Roman');
                app.SnapEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 50, 'FontName', 'Times New Roman');
                
                app.GenPDPAxes = uiaxes(app.GenScrollPanel);
                app.GenCDFAxes = uiaxes(app.GenScrollPanel);
                
                % --- 第三页 ---
                app.ChannelPredTab = uitab(app.TabGroup, 'Title', '3. Prediction & Training', 'BackgroundColor', app.Color_Bg);
                app.ChannelPredScrollPanel = uipanel(app.ChannelPredTab, 'Scrollable', 'on', 'BackgroundColor', app.Color_Bg, 'BorderType', 'none');
                app.ChannelPredScrollPanel.AutoResizeChildren = 'off';
                
                app.PredConfigPanel = uipanel(app.ChannelPredScrollPanel, 'Title', 'Training Configuration', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.PredConfigPanel.AutoResizeChildren = 'off';
                
                app.AlgoPanel = uipanel(app.PredConfigPanel, 'Title', 'Algo', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.AlgoPanel.AutoResizeChildren = 'off';
                app.TCNButton = uibutton(app.AlgoPanel, 'Text', 'TCN', 'ButtonPushedFcn', createCallbackFcn(app, @TCNButtonPushed, true), 'FontName', 'Times New Roman');
                app.LSTMButton = uibutton(app.AlgoPanel, 'Text', 'LSTM', 'ButtonPushedFcn', createCallbackFcn(app, @LSTMButtonPushed, true), 'FontName', 'Times New Roman');
                app.GRUButton = uibutton(app.AlgoPanel, 'Text', 'GRU', 'ButtonPushedFcn', createCallbackFcn(app, @GRUButtonPushed, true), 'FontName', 'Times New Roman');
                
                app.TargetPanel = uipanel(app.PredConfigPanel, 'Title', 'Domain', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.TargetPanel.AutoResizeChildren = 'off';
                app.TimeDomainButton = uibutton(app.TargetPanel, 'Text', 'Time', 'ButtonPushedFcn', createCallbackFcn(app, @TimeDomainButtonPushed, true), 'FontName', 'Times New Roman');
                app.FreqDomainButton = uibutton(app.TargetPanel, 'Text', 'Freq', 'ButtonPushedFcn', createCallbackFcn(app, @FreqDomainButtonPushed, true), 'FontName', 'Times New Roman');
                app.SpaceDomainButton = uibutton(app.TargetPanel, 'Text', 'Space', 'ButtonPushedFcn', createCallbackFcn(app, @SpaceDomainButtonPushed, true), 'FontName', 'Times New Roman');
                
                app.TaskPanel = uipanel(app.PredConfigPanel, 'Title', 'Task Control', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.TaskPanel.AutoResizeChildren = 'off';
                app.TrainButton = uibutton(app.TaskPanel, 'Text', '1. Train Model', 'BackgroundColor', app.ActiveBtnColor, 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @TrainButtonPushed, true), 'FontName', 'Times New Roman');
                app.PredictButton = uibutton(app.TaskPanel, 'Text', '2. Run Predict', 'BackgroundColor', app.ActiveBtnColor, 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @PredictButtonPushed, true), 'FontName', 'Times New Roman');
                
                app.ParamPanel = uipanel(app.PredConfigPanel, 'Title', 'Future Gen', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.ParamPanel.AutoResizeChildren = 'off';
                app.PredLengthLabel = uilabel(app.ParamPanel, 'Text', 'Prediction Steps (Snaps):', 'FontName', 'Times New Roman');
                app.PredLengthEdit = uieditfield(app.ParamPanel, 'numeric', 'Value', 50, 'FontName', 'Times New Roman'); 
                app.BatchSizeLabel = uilabel(app.ParamPanel, 'Text', 'Batch Size (Sets):', 'FontName', 'Times New Roman');
                app.BatchSizeEdit = uieditfield(app.ParamPanel, 'numeric', 'Value', 1, 'FontName', 'Times New Roman'); 
                
                app.DataScaleInfoLabel = uilabel(app.ParamPanel, 'Text', '► Input Scale: Waiting...', 'FontName', 'Times New Roman', 'FontColor', [0.8 0.1 0.1], 'FontWeight', 'bold');
                
                app.SavePredDataButton = uibutton(app.PredConfigPanel, 'Text', 'Save Data', ...
                    'BackgroundColor', app.ActiveBtnColor, 'FontColor', 'w', 'FontWeight', 'bold', ...
                    'ButtonPushedFcn', createCallbackFcn(app, @SavePredDataButtonPushed, true), 'FontName', 'Times New Roman');
                
                app.ExportModelButton = uibutton(app.PredConfigPanel, 'Text', 'Export Model', ...
                    'BackgroundColor', app.ActiveBtnColor, 'FontColor', 'w', 'FontWeight', 'bold', ...
                    'ButtonPushedFcn', createCallbackFcn(app, @ExportModelButtonPushed, true), 'FontName', 'Times New Roman');
                
                app.PredPlotPanel = uipanel(app.ChannelPredScrollPanel, 'Title', 'Verification Results', 'FontSize', 14, 'FontName', 'Times New Roman');
                app.PredPlotPanel.AutoResizeChildren = 'off';
                
                app.PredCapacityAxes = uiaxes(app.PredPlotPanel);
                app.PredRawDataAxes = uiaxes(app.PredPlotPanel);
                app.PredRMSEAxes = uiaxes(app.PredPlotPanel);
                app.PredSpreadAxes = uiaxes(app.PredPlotPanel);
                app.PredAngularAxes = uiaxes(app.PredPlotPanel);
                app.PredDopplerAxes = uiaxes(app.PredPlotPanel);
                
                % === 样式设置 ===
                panels = [app.BasicConfigPanel, app.DataMgmtPanel, ...
                          app.ChannelCharsPanel, app.GenConfigPanel, app.GenParamPanel, ...
                          app.PredConfigPanel, app.AlgoPanel, ...
                          app.TargetPanel, app.TaskPanel, app.ParamPanel, app.PredPlotPanel];
                set(panels, 'BackgroundColor', app.Color_Panel, 'ForegroundColor', app.Color_Text); 
                
                scrollPanels = [app.DataImportScrollPanel, app.GenScrollPanel, app.ChannelPredScrollPanel];
                set(scrollPanels, 'BackgroundColor', app.Color_Bg, 'BorderType', 'none');
                
                labels = [app.FreqBandLabel, app.ScenarioLabel, app.BandwidthLabel, ...
                          app.GenModelLabel, app.PredLengthLabel, app.BatchSizeLabel, ...
                          app.DSmuLabel, app.DSsigmaLabel, app.rDSLabel, app.ClusterLabel, ...
                          app.RayLabel, app.KFmuLabel, app.KFsigmaLabel, app.SnapLabel];
                set(labels, 'FontColor', app.Color_Text);
                
                dds = [app.FreqBandDropDown, app.ScenarioDropDown, app.GenModelDropDown, app.DatasetDropDown];
                set(dds, 'BackgroundColor', [1 1 1], 'FontColor', app.Color_Text);
                
                edits = [app.BandwidthEdit, app.PredLengthEdit, app.BatchSizeEdit, ...
                         app.DSmuEdit, app.DSsigmaEdit, app.rDSEdit, app.ClusterEdit, ...
                         app.RayEdit, app.KFmuEdit, app.KFsigmaEdit, app.SnapEdit];
                set(edits, 'BackgroundColor', [1 1 1], 'FontColor', app.Color_Text);
                
                axesList = [app.AngularPowerAxes, app.DelayPowerAxes, app.DopplerPowerAxes, app.SpreadCDFAxes, ...
                            app.GenPDPAxes, app.GenCDFAxes, ...
                            app.PredCapacityAxes, app.PredRawDataAxes, app.PredRMSEAxes, app.PredSpreadAxes, ...
                            app.PredAngularAxes, app.PredDopplerAxes];
                for k = 1:length(axesList)
                    app.initAxesStyle(axesList(k));
                end
                
                allButtons = [app.LoadDataButton, app.ClearDataButton, ...
                              app.GenStartButton, app.GenSendToAIButton, ...
                              app.TCNButton, app.LSTMButton, app.GRUButton, ...
                              app.TimeDomainButton, app.FreqDomainButton, app.SpaceDomainButton, ...
                              app.TrainButton, app.PredictButton, app.SavePredDataButton, app.ExportModelButton];
                for k = 1:length(allButtons)
                    if ~isequal(allButtons(k).BackgroundColor, app.ActiveBtnColor) && ~isequal(allButtons(k).BackgroundColor, [0 0.5 0.2])
                        allButtons(k).BackgroundColor = app.DefaultBtnColor;
                        allButtons(k).FontColor = app.Color_Text;
                    end
                end
                
                app.TCNButton.BackgroundColor = app.ActiveBtnColor; app.TCNButton.FontColor = 'w';
                app.TimeDomainButton.BackgroundColor = app.ActiveBtnColor; app.TimeDomainButton.FontColor = 'w';
                
                allComps = findall(app.UIFigure);
                for i = 1:length(allComps)
                    if isprop(allComps(i), 'AutoResizeChildren')
                        try allComps(i).AutoResizeChildren = 'off'; catch, end
                    end
                end
                
                app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @UIFigureSizeChanged, true);
                
                % === [关键修复 2]：强制将下拉框图层提到最上层 ===
                uistack(app.LangDropDown, 'top');
                
                app.UIFigure.Visible = 'on';
                
                app.updateScenarioItems();
                UIFigureSizeChanged(app, []);
                
            catch ME
                errordlg(['UI Creation Failed: ' ME.message], 'Critical Error'); 
            end
        end
    end
    
    methods (Access = public)
        function app = ChannelSimulatorApp
            appFile = mfilename('fullpath');
            repoRoot = fileparts(fileparts(appFile));
            coreRoot = fullfile(repoRoot, 'core');
            if isfolder(coreRoot), addpath(genpath(coreRoot)); end
            createComponents(app)
            registerApp(app, app.UIFigure)
            runStartupFcn(app, @startupFcn)
            if nargout == 0; clear app; end
        end
        function delete(app), delete(app.UIFigure); end
    end
end
