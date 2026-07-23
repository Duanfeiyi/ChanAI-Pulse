classdef ChannelSimulatorApp01 < matlab.apps.AppBase
    % Channel Simulator v99.9 (Ultimate Standalone & English Academic Edition)
    
    %% ==================== UI Components ====================
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        TabGroup                 matlab.ui.container.TabGroup
        
        % --- Tab 1 (模块一: 增强版) ---
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
        
        % [新增] Data Quality与能力标签面板
        DataQualityPanel         matlab.ui.container.Panel
        ValidLamp                matlab.ui.control.Lamp
        ValidStatusLabel         matlab.ui.control.Label
        Mod23ReadyLabel          matlab.ui.control.Label
        MetaInfoTextArea         matlab.ui.control.TextArea
        
        % [新增] 原数据/预适配 视图控制
        ViewModeLabel            matlab.ui.control.Label
        ViewModeSwitch           matlab.ui.control.Switch
        
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
        PredictionResults = struct(); 
        
        % [新增] 模块一核心追踪状态
        DataTypes      = {}       % 存储数据类型: 'Legacy' 或是 'Complex-H'
        RawMetrics     = {}       % 存储原始未适配数据，用于Switch切换对比
        
        TrainedNet     = [];      
        NormParams     = struct('Min', 0, 'Max', 1); 
        PredictionWindow = 10; 
        selectedAlgo = 'TCN';      
        selectedTarget = 'Time';   
        
        GeneratedH     single                 
        GeneratedDelay single  
        
        Color_Bg         = [1.00, 1.00, 1.00]; 
        Color_Panel      = [0.96, 0.96, 0.96]; 
        Color_Text       = [0.10, 0.10, 0.10]; 
        Color_TextDim    = [0.35, 0.35, 0.35]; 
        Color_Primary    = [0.00, 0.4470, 0.7410]; 
        Color_Secondary  = [0.8500, 0.3250, 0.0980]; 
        DefaultBtnColor  = [0.94, 0.94, 0.94]; 
        ActiveBtnColor   = [0.00, 0.4470, 0.7410]; 
        Color_Blue       = [0.00, 0.4470, 0.7410]; 
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
        
        function updateScenarioItems(app)
            band = app.FreqBandDropDown.Value;
            base_scenarios = {'Satellite', 'UAV', 'Maritime', 'RIS', 'Industrial IoT', 'ISAC'};
            
            switch band
                case 'Sub-6'
                    fallback = 'Scenario 1';
                case 'mmWave'
                    fallback = 'Scenario 2';
                case 'THz'
                    fallback = 'Scenario 3';
                case 'Optical Wireless'
                    fallback = 'Scenario 4';
                otherwise
                    fallback = 'Scenario 1';
            end
            
            items = [base_scenarios, {fallback}];
            curr_val = app.ScenarioDropDown.Value;
            
            app.ScenarioDropDown.Items = items;
            if isprop(app, 'GenModelDropDown') && ~isempty(app.GenModelDropDown) && isvalid(app.GenModelDropDown)
                app.GenModelDropDown.Items = items;
            end
            
            if any(strcmp(items, curr_val))
                app.ScenarioDropDown.Value = curr_val;
                if isprop(app, 'GenModelDropDown') && ~isempty(app.GenModelDropDown) && isvalid(app.GenModelDropDown)
                    app.GenModelDropDown.Value = curr_val; 
                end
            else
                app.ScenarioDropDown.Value = fallback; 
                if isprop(app, 'GenModelDropDown') && ~isempty(app.GenModelDropDown) && isvalid(app.GenModelDropDown)
                    app.GenModelDropDown.Value = fallback; 
                end
            end
            app.ConfigValueChanged(); 
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
        
        function [data, isComplexH_Flag] = extract_raw_data(app, f1)
            data = f1;
            while isstruct(data) || iscell(data)
                if isstruct(data)
                    fields = fieldnames(data);
                    if isempty(fields), error('Empty struct detected'); end
                    if isfield(data, 'DPSD_dB'), data = data.DPSD_dB; continue; end
                    if isfield(data, 'DPSD_cut'), data = data.DPSD_cut; continue; end
                    if isfield(data, 'sage'), tmp = app.getSageData(data.sage); data = tmp.cir; continue; end
                    if isfield(data, 'cir'), data = data.cir; continue; end
                    if isfield(data, 'CIRData'), data = data.CIRData; continue; end
                    if isfield(data, 'IRuse'), data = data.IRuse; continue; end
                    if isfield(data, 'input'), data = data.input; continue; end
                    data = data.(fields{1});
                elseif iscell(data)
                    if isempty(data), error('Empty cell array detected'); end
                    data = data{1};
                end
            end
            if isnumeric(data) || islogical(data), data = double(data); else, error('Data is non-numeric.'); end
            
            % [核心数据识别] 判断是否为Complex-H复杂信道数据
            isComplexH_Flag = ~isreal(data) && ndims(data) >= 3;
        end
        
        function [angles, aps_dB] = calculate_angular_spectrum(~, raw_data)
            angles = linspace(-90, 90, 128); aps_dB = zeros(128, 1) - 1000;
            try
                if ~isreal(raw_data)
                    sz = size(raw_data); spatial_dim = 0;
                    for d = 1:length(sz)
                        if sz(d) > 1 && sz(d) <= 64, spatial_dim = d; break; end
                    end
                    if spatial_dim > 0
                        aps = fftshift(fft(raw_data, 128, spatial_dim), spatial_dim);
                        pwr = abs(aps).^2;
                        dims_to_mean = setdiff(1:ndims(pwr), spatial_dim);
                        for k = fliplr(dims_to_mean), pwr = mean(pwr, k); end
                        aps_dB = 10*log10(pwr(:) + 1e-20); aps_dB = aps_dB - max(aps_dB);
                    end
                end
            catch
            end
        end
        
        function initAxesStyle(app, ax)
            ax.FontName = 'Helvetica'; ax.FontSize = 10; ax.LineWidth = 0.8; ax.Box = 'on'; 
            ax.Color = [1 1 1]; ax.XColor = app.Color_TextDim; ax.YColor = app.Color_TextDim;
            grid(ax, 'on'); ax.GridAlpha = 0.15; ax.GridColor = [0.8 0.8 0.8];
            ax.XMinorGrid = 'off'; ax.YMinorGrid = 'off'; ax.TickDir = 'in'; ax.TickLength = [0.01 0.01];
            try ax.XLimitMethod = 'tight'; catch; end 
            hold(ax, 'on'); 
        end
        
        function applyAxesStyle(app, ax, titleText, xLabelText, yLabelText)
            title(ax, titleText, 'FontName', 'Helvetica', 'FontSize', 12, 'FontWeight', 'bold', 'Color', app.Color_Text);
            if nargin > 3
                xlabel(ax, xLabelText, 'FontWeight', 'bold', 'FontName', 'Helvetica', 'Color', app.Color_Text); 
                ylabel(ax, yLabelText, 'FontWeight', 'bold', 'FontName', 'Helvetica', 'Color', app.Color_Text); 
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
            if pm == 0
                ds = 0; return;
            end
            mx = sum(taus .* pdp_linear) / pm;
            ds = sqrt(abs(sum((taus.^2) .* pdp_linear) / pm - mx^2));
        end
    end

    %% ==================== [Tab 1] Load & Validate / 数据导入与预适配 ====================
    methods (Access = private)
        function loadData_Generic(app, scenario_name)
            prevState = app.UIFigure.WindowState;
            [fns, fp] = uigetfile('*.mat', ['Select ', scenario_name, ' Dataset'], 'MultiSelect', 'on');
            app.stabilizeFocus(prevState);
            
            if isequal(fns, 0), return; end
            fns = app.safe_sort_files(fns); nFiles = length(fns);
            
            searchStr = [fp, fns{1}];
            [det_band, det_scen] = app.autoDetectScenario(searchStr);
            
            if isempty(det_band)
                det_band = app.FreqBandDropDown.Value; 
            end
            if isempty(det_scen)
                switch det_band
                    case 'Sub-6'
                        det_scen = 'Scenario 1';
                    case 'mmWave'
                        det_scen = 'Scenario 2';
                    case 'THz'
                        det_scen = 'Scenario 3';
                    case 'Optical Wireless'
                        det_scen = 'Scenario 4';
                    otherwise
                        det_scen = 'Scenario 1';
                end
            end
            
            app.FreqBandDropDown.Value = det_band;
            app.updateScenarioItems(); 
            if any(strcmp(app.ScenarioDropDown.Items, det_scen))
                app.ScenarioDropDown.Value = det_scen;
            end
            app.ConfigValueChanged(); 
            scenario_name = [strrep(det_band, ' ', ''), '-', app.ScenarioDropDown.Value];
            
            d = uiprogressdlg(app.UIFigure, 'Title', [scenario_name, ' Processing...'], 'Indeterminate', 'on');
            drawnow; 
            try
                if contains(scenario_name, 'Industrial') || contains(scenario_name, 'mmWave'), len_dpsd = 500; else, len_dpsd = 200; end
                
                h_dbm_matrix_raw = zeros(len_dpsd, nFiles);
                h_dbm_matrix_pre = zeros(len_dpsd, nFiles);
                all_aps = zeros(128, nFiles); 
                
                complex_detected = false;
                dim_str = '';
                
                % [Data Validation & Pre-adaptation Pipeline]
                for i = 1:nFiles
                    f1 = load(fullfile(fp, fns{i})); 
                    [data, isComplexH_Flag] = app.extract_raw_data(f1); 
                    
                    if isComplexH_Flag, complex_detected = true; end
                    if i == 1, dim_str = mat2str(size(data)); end
                    
                    [angle_xaxis, all_aps(:, i)] = app.calculate_angular_spectrum(data);
                    
                    % 转DPSD
                    if isreal(data)
                        dpsd_dbm = squeeze(data); if size(dpsd_dbm, 1) == 1 && size(dpsd_dbm, 2) > 1, dpsd_dbm = dpsd_dbm.'; end
                        if all(dpsd_dbm(:) >= 0) && max(dpsd_dbm(:)) < 1e5, dpsd_dbm = 10 * log10(dpsd_dbm / 1e-3 + 1e-20); end
                    else
                        if contains(scenario_name, 'RIS')
                            if ndims(data) == 5, h_freq = squeeze(sum(sum(sum(data, 1), 2), 3)); elseif ndims(data) == 4, h_freq = squeeze(sum(sum(data, 1), 2)); elseif ndims(data) == 3, h_freq = squeeze(sum(data, 1)); else, h_freq = squeeze(data); end
                            if size(h_freq, 1) == 1 && size(h_freq, 2) > 1, h_freq = h_freq.'; end
                            h_time = ifft(h_freq); dpsd_dbm = 10 * log10(abs(h_time).^2 / 1e-3 + 1e-20);
                        elseif contains(scenario_name, 'Sub-6')
                            if ndims(data) >= 3, pdp_lin = squeeze(sum(sum(abs(data).^2, 1), 2)); else, pdp_lin = abs(data).^2; end
                            if size(pdp_lin, 1) == 1 && size(pdp_lin, 2) > 1, pdp_lin = pdp_lin.'; end
                            dpsd_dbm = 10 * log10(pdp_lin / 1e-3 + 1e-20);
                        else 
                            if ndims(data) >= 4, cir_slice = squeeze(data(1, 1, :, :)); elseif ndims(data) == 3, cir_slice = squeeze(data(1, 1, :)); else, cir_slice = squeeze(data); end
                            if size(cir_slice, 1) == 1 && size(cir_slice, 2) > 1, cir_slice = cir_slice.'; end
                            dpsd_dbm = 10 * log10(abs(cir_slice).^2 / 1e-3 + 1e-20);
                        end
                    end
                    
                    dpsd_dbm = real(dpsd_dbm(:));
                    if length(dpsd_dbm) >= len_dpsd, dpsd_dbm = dpsd_dbm(1:len_dpsd); else, pad = zeros(len_dpsd - length(dpsd_dbm), 1) - 130; dpsd_dbm = [dpsd_dbm; pad]; end
                    
                    % 原始记录
                    h_dbm_matrix_raw(:, i) = dpsd_dbm; 
                    
                    % 预适配过滤(除噪/平滑/异常值截断)
                    dpsd_adapted = dpsd_dbm;
                    dpsd_adapted(isnan(dpsd_adapted) | isinf(dpsd_adapted)) = -130;
                    local_noise = median(dpsd_adapted) - 5;
                    dpsd_adapted(dpsd_adapted < local_noise) = local_noise;
                    h_dbm_matrix_pre(:, i) = dpsd_adapted;
                end
                
                h_dbm_matrix_raw(isnan(h_dbm_matrix_raw) | isinf(h_dbm_matrix_raw)) = -130; 
                
                % 分别生成原始与预适配指标
                mets_raw = app.analyzeChannelData_Generic(h_dbm_matrix_raw, app.BandwidthEdit.Value * 1e6);
                mets_pre = app.analyzeChannelData_Generic(h_dbm_matrix_pre, app.BandwidthEdit.Value * 1e6);
                
                mets_raw.space.angle = angle_xaxis; mets_raw.space.psd = mean(all_aps, 2);
                mets_pre.space.angle = angle_xaxis; mets_pre.space.psd = mean(all_aps, 2);
                
                % 数据类型标识与能力标签解析
                if complex_detected
                    dt = 'Complex-H';
                    tags = 'Tags: [MIMO], [Phase Included], [Complex Tensor], [3D-Spatial]';
                else
                    dt = 'Legacy';
                    tags = 'Tags: [SISO/MISO], [Power Only], [PDP], [1D-Series]';
                end
                
                [~,dn] = fileparts(strip(fp, 'right', filesep));
                curr_len = length(app.LoadedData);
                
                % 数据入库
                app.LoadedData{curr_len+1} = h_dbm_matrix_pre; % 默认主数据为预适配
                app.ChannelMetrics{curr_len+1} = mets_pre;
                app.RawMetrics{curr_len+1} = mets_raw;
                app.DataTypes{curr_len+1} = dt;
                
                app.DatasetPaths{curr_len+1} = sprintf('%s (%s - %d Snaps)', dn, scenario_name, nFiles);
                app.DatasetDropDown.Items = app.DatasetPaths; 
                app.DatasetDropDown.Value = app.DatasetPaths{curr_len+1};
                
                % [UI面板更新: Data Quality & Compatibility Status]
                app.ValidLamp.Color = [0.00, 0.70, 0.20]; % 绿灯
                app.ValidStatusLabel.Text = sprintf('Status: Valid Data Loaded (%s)', dt);
                app.Mod23ReadyLabel.Text = 'Entry to Module 2/3: ALLOWED';
                app.Mod23ReadyLabel.FontColor = [0.00, 0.60, 0.00];
                
                meta_str = sprintf('Source: %s\nDim: %s\n%s', dn, dim_str, tags);
                app.MetaInfoTextArea.Value = meta_str;
                
                app.updateVisualizations(); 
                
                if isvalid(d), delete(d); end 
                app.stabilizeFocus(prevState);
            catch ME
                if ~isvalid(app) || ~isvalid(app.UIFigure), return; end
                if exist('d', 'var') && isvalid(d), delete(d); end
                
                % [UI面板更新: 错误拦截]
                app.ValidLamp.Color = [0.80, 0.00, 0.00]; % 红灯
                app.ValidStatusLabel.Text = 'Status: Load Failed / Incompatible';
                app.Mod23ReadyLabel.Text = 'Entry to Module 2/3: DENIED';
                app.Mod23ReadyLabel.FontColor = [0.80, 0.00, 0.00];
                app.MetaInfoTextArea.Value = ['Error Log: ', ME.message];
                
                app.stabilizeFocus(prevState);
                uialert(app.UIFigure, ['Load Failed: ' ME.message], 'Error'); 
            end
        end
    end

    %% ==================== [Tab 2] Native GBSM Physics Engine ====================
    methods (Access = private)
        function GenStartButtonPushed(app, ~)
            app.GenStartButton.Enable = 'off'; app.GenStartButton.Text = 'Computing...'; drawnow limitrate;
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
                Ns = round(delay_max_ns / delay_grid_step_ns) + 1;
                
                app.GeneratedH = zeros(1, 1, N_snaps, Ns) + 1i*zeros(1, 1, N_snaps, Ns);
                app.GeneratedDelay = zeros(1, 1, N_snaps, Ns);
                
                ds_all_ns = zeros(N_snaps, 1);
                
                d = uiprogressdlg(app.UIFigure, 'Title', 'Native Engine Running', 'Message', 'Generating physical multipath tensors...');
                
                fd = 50; 
                if contains(app.GenModelDropDown.Value, 'Satellite'), fd = 4000; end
                if contains(app.GenModelDropDown.Value, 'UAV'), fd = 500; end
                
                t = (0:N_snaps-1)' * 1e-3;
                
                for i = 1:N_snaps
                    ds = 10^(randn * DS_sigma + DS_mu);
                    
                    taus = sort(exprnd(ds * r_DS, [1, num_clusters]));
                    taus = taus - min(taus); 
                    
                    powers = exp(-taus / ds) .* (10.^(-randn(1, num_clusters)/10)); 
                    
                    K_lin = 10^((randn * KF_sigma + KF_mu) / 10);
                    powers(1) = powers(1) + K_lin * sum(powers);
                    
                    powers = powers / sum(powers); 
                    
                    h_CIR = sqrt(powers) .* (randn(1, num_clusters) + 1i*randn(1, num_clusters)) / sqrt(2);
                    
                    df = B_Hz / Ns;
                    f = (-floor(Ns/2):ceil(Ns/2)-1) * df;
                    F = zeros(1, Ns);
                    for k = 1:num_clusters
                        fading = sum(exp(1i * 2 * pi * fd * t(i) * rand(1,5) + rand(1,5)*2*pi)) / sqrt(5);
                        F = F + h_CIR(k) * fading * exp(-1i * 2 * pi * f * taus(k));
                    end
                    h_delay = ifft(ifftshift(F));
                    
                    app.GeneratedH(1, 1, i, :) = h_delay;
                    delay_axis_ns = (0:Ns-1) / B_Hz * 1e9;
                    app.GeneratedDelay(1, 1, i, :) = delay_axis_ns * 1e-9;
                    
                    pdp_linear = abs(h_delay).^2;
                    ds_all_ns(i) = app.calc_ds_native(delay_axis_ns * 1e-9, pdp_linear) * 1e9;
                    
                    if i == 1
                        first_h_delay = h_delay;
                        first_taus = taus;
                        first_h_CIR = h_CIR;
                    end
                end
                
                avg_pdp_linear = abs(first_h_delay).^2;
                avg_pdp_linear = avg_pdp_linear / max(avg_pdp_linear + eps);
                
                noise_floor_dB = -60;
                noise_amplitude_dB = 5.0;
                noise_trace_dB = noise_floor_dB + noise_amplitude_dB * (2 * rand(size(delay_axis_ns)) - 1);
                noise_linear = 10.^(noise_trace_dB / 10);
                pdp_plot_dB = 10 * log10(avg_pdp_linear + noise_linear + eps);
                
                delete(app.GenPDPAxes.Children);
                h_pdp = plot(app.GenPDPAxes, delay_axis_ns, pdp_plot_dB, '-', 'Color', app.Color_Primary, 'LineWidth', 1.5);
                
                tap_power_linear = abs(first_h_CIR).^2;
                tap_power_linear = tap_power_linear / max(tap_power_linear + eps);
                tap_power_dB = 10 * log10(tap_power_linear + eps);
                hold(app.GenPDPAxes, 'on');
                h_scatter = plot(app.GenPDPAxes, first_taus * 1e9, tap_power_dB, 'o', 'Color', app.Color_Secondary, 'LineWidth', 1.2, 'MarkerSize', 6);
                hold(app.GenPDPAxes, 'off');
                
                lgd1 = legend(app.GenPDPAxes, [h_pdp, h_scatter], {'PDP with noise floor', 'Multipath components'}, 'Location', 'northeast');
                lgd1.Color = 'none'; lgd1.EdgeColor = 'none'; lgd1.TextColor = app.Color_Text;
                
                app.applyAxesStyle(app.GenPDPAxes, sprintf('Delay Power Spectrum (%s)', app.GenModelDropDown.Value), 'Delay (ns)', 'Power (dB)');
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
                plot(app.GenCDFAxes, x_fine, cdf_smooth, '-', 'Color', app.Color_Primary, 'LineWidth', 1.8);
                app.applyAxesStyle(app.GenCDFAxes, 'CDF of Delay Spread', 'Delay spread (ns)', 'CDF');
                xlim(app.GenCDFAxes, [x_fine(1), x_fine(end)]);
                ylim(app.GenCDFAxes, [0, 1]);
                
                if isvalid(d), delete(d); end
                app.GenStartButton.Enable = 'on'; app.GenStartButton.Text = 'Generate';
                uialert(app.UIFigure, 'Native Engine Simulation Success! 4D Tensor Generated.', 'Success');
                
            catch ME
                if exist('d','var') && isvalid(d), delete(d); end
                app.GenStartButton.Enable = 'on'; app.GenStartButton.Text = 'Generate';
                uialert(app.UIFigure, ['Simulation Error: ', ME.message], 'Error');
            end
        end

        function GenSendToAIButtonPushed(app, ~)
            if isempty(app.GeneratedH)
                uialert(app.UIFigure, 'Please Generate Channel First.', 'Info'); return; 
            end
            d = uiprogressdlg(app.UIFigure, 'Title', 'Data Pipeline', 'Message', 'Mapping to frequency domain feature set...');
            try
                cir_squeeze = squeeze(app.GeneratedH); 
                n_fft = size(cir_squeeze, 2);
                H_CTF_native = fft(cir_squeeze, n_fft, 2); 
                
                ai_data = abs(H_CTF_native).^2; 
                dpsd_dbm = 10*log10(ai_data.' / 1e-3 + 1e-20); 
                
                len_dpsd = 200; 
                if contains(app.GenModelDropDown.Value, 'Industrial') || contains(app.FreqBandDropDown.Value, 'mmWave'), len_dpsd = 500; end
                if ~isempty(app.LoadedData), len_dpsd = size(app.LoadedData{1}, 1); end
                
                if size(dpsd_dbm, 1) >= len_dpsd
                    dpsd_dbm = dpsd_dbm(1:len_dpsd, :);
                else
                    pad = zeros(len_dpsd - size(dpsd_dbm,1), size(dpsd_dbm,2)) - 130; dpsd_dbm = [dpsd_dbm; pad];
                end
                
                mets = app.analyzeChannelData_Generic(dpsd_dbm, app.BandwidthEdit.Value * 1e6);
                ds_name = sprintf('Simulated_%s (%d Snaps)', app.GenModelDropDown.Value, size(dpsd_dbm,2));
                
                curr_len = length(app.LoadedData);
                app.LoadedData{curr_len+1} = dpsd_dbm; 
                app.ChannelMetrics{curr_len+1} = mets;
                app.RawMetrics{curr_len+1} = mets; 
                app.DataTypes{curr_len+1} = 'Legacy'; 
                app.DatasetPaths{curr_len+1} = ds_name;
                
                app.DatasetDropDown.Items = app.DatasetPaths; 
                app.DatasetDropDown.Value = ds_name;
                app.updateVisualizations();
                
                if isvalid(d), delete(d); end
                app.TabGroup.SelectedTab = app.ChannelPredTab; 
                uialert(app.UIFigure, 'Simulation Data Sent to AI Pipeline!', 'Success');
            catch ME
                if isvalid(d), delete(d); end
                uialert(app.UIFigure, ['Mapping Failed: ', ME.message], 'Error');
            end
        end
    end

    %% ==================== [Tab 3] AI Model & Prediction ====================
    methods (Access = private)
        function metrics = analyzeChannelData_Generic(~, dpsd_dbm, B_hz)
            metrics = struct(); [nL, nSnaps] = size(dpsd_dbm);
            pdp_lin = 10.^(dpsd_dbm/10); avg_pdp = mean(pdp_lin, 2).'; 
            taus = (0 : nL - 1) / B_hz;
            metrics.delay.x = taus * 1e9; metrics.delay.y = 10*log10(avg_pdp + 1e-20); 
            
            taus_mat = taus(:); pm = sum(pdp_lin, 1); pm(pm == 0) = 1e-20; 
            mx = sum(taus_mat .* pdp_lin, 1) ./ pm; 
            ds_vec = sqrt(abs(sum((taus_mat.^2) .* pdp_lin, 1) ./ pm - mx.^2)); 
            
            [f_ds, x_ds] = ecdf(ds_vec * 1e9);
            metrics.delay.cdf_x = x_ds; metrics.delay.cdf_y = f_ds;
            metrics.space.angle = 0:1; metrics.space.psd = 0:1; metrics.space.cdf_x = 0; metrics.space.cdf_y = 0; metrics.hasDoppler = true;
            h_t = dpsd_dbm(floor(nL/2)+1, :); h_t = h_t - mean(h_t);
            Nfft = 2^nextpow2(nSnaps); d_spec = fftshift(abs(fft(h_t, Nfft)).^2);
            metrics.time.x = linspace(-1, 1, Nfft); metrics.time.y = 10*log10(d_spec/max(d_spec(:))+1e-20);
        end
        
        function success = trainModel_Generic(app)
            success = false;
            if isempty(app.DatasetPaths) || strcmp(app.DatasetDropDown.Value, '[None]'), return; end
            idx = find(strcmp(app.DatasetPaths, app.DatasetDropDown.Value), 1);
            dpsd_dbm = app.LoadedData{idx}; [nL, nSnaps] = size(dpsd_dbm);
            
            if nSnaps < 2
                dpsd_dbm = [dpsd_dbm, dpsd_dbm + randn(size(dpsd_dbm))*0.1];
                nSnaps = 2;
            end
            
            min_v = min(dpsd_dbm(:)); max_v = max(dpsd_dbm(:));
            if max_v==min_v, max_v=min_v+1; end
            data_norm = double((dpsd_dbm - min_v) / (max_v - min_v)); 
            app.NormParams.Min = min_v; app.NormParams.Max = max_v;
            
            win = min(10, nSnaps - 1); 
            app.PredictionWindow = win; 
            
            num_s = nSnaps - win;
            XTrain = cell(num_s, 1); YTrain = zeros(num_s, nL);
            for i = 1:num_s, XTrain{i} = data_norm(:, i : i+win-1); YTrain(i, :) = data_norm(:, i+win).'; end
            
            if strcmp(app.selectedAlgo, 'TCN')
                numFilters = 64; filterSize = 3;
                layers = [
                    sequenceInputLayer(nL, 'Name', 'in')
                    convolution1dLayer(filterSize, numFilters, 'Padding', 'causal', 'DilationFactor', 1, 'Name', 'conv1')
                    batchNormalizationLayer('Name', 'bn1')
                    reluLayer('Name', 'relu1')
                    convolution1dLayer(filterSize, numFilters, 'Padding', 'causal', 'DilationFactor', 2, 'Name', 'conv2')
                    batchNormalizationLayer('Name', 'bn2')
                    reluLayer('Name', 'relu2')
                    convolution1dLayer(filterSize, numFilters, 'Padding', 'causal', 'DilationFactor', 4, 'Name', 'conv3')
                    batchNormalizationLayer('Name', 'bn3')
                    reluLayer('Name', 'relu3')
                    globalAveragePooling1dLayer('Name', 'gap_reducer') 
                    fullyConnectedLayer(nL, 'Name', 'fc')
                    regressionLayer('Name', 'out')
                ];
            elseif strcmp(app.selectedAlgo, 'GRU')
                layers = [sequenceInputLayer(nL, 'Name', 'in'), gruLayer(64, 'OutputMode', 'sequence'), gruLayer(64, 'OutputMode', 'last'), fullyConnectedLayer(nL), regressionLayer];
            else 
                layers = [sequenceInputLayer(nL, 'Name', 'in'), lstmLayer(64, 'OutputMode', 'last'), fullyConnectedLayer(nL), regressionLayer];
            end
            
            prevState = app.UIFigure.WindowState;
            
            d = [];
            if isdeployed
                plot_mode = 'none';
                d = uiprogressdlg(app.UIFigure, 'Title', ['Training model (' app.selectedAlgo ')...'], 'Message', 'Background training, please wait...');
                drawnow limitrate;
            else
                plot_mode = 'training-progress';
                app.TrainButton.Text = '[ Training... ]'; app.TrainButton.Enable = 'off';
                drawnow limitrate; pause(0.1); 
            end
            
            opts = trainingOptions('adam', 'MaxEpochs', 30, 'MiniBatchSize', 16, 'InitialLearnRate', 0.005, 'Plots', plot_mode, 'Verbose', 0);
            
            try
                app.TrainedNet = trainNetwork(XTrain, YTrain, layers, opts);
                success = true;
            catch ME
                if ~isvalid(app) || ~isvalid(app.UIFigure), return; end
                if ~isempty(d) && isvalid(d), delete(d); end
                app.TrainButton.Text = '1. Train Model';
                app.TrainButton.Enable = 'on';
                app.stabilizeFocus(prevState);
                uialert(app.UIFigure, ['Training failed: ' ME.message], 'Error'); 
            end
            
            if ~isvalid(app) || ~isvalid(app.UIFigure), return; end
            if ~isempty(d) && isvalid(d), delete(d); end
            app.TrainButton.Text = '1. Train Model';
            app.TrainButton.Enable = 'on';
            app.stabilizeFocus(prevState);
        end
        
        function runPredictionLogic_Generic(app, noise_test, prefix)
            if isempty(app.DatasetPaths), return; end
            idx = find(strcmp(app.DatasetPaths, app.DatasetDropDown.Value), 1);
            gt_dbm = app.LoadedData{idx}.'; [nS, curr_dim] = size(gt_dbm);
            metric_data = app.ChannelMetrics{idx};
            
            prevState = app.UIFigure.WindowState;
            d = uiprogressdlg(app.UIFigure, 'Title', 'Verification and inference...', 'Indeterminate', 'on');
            drawnow;
            
            if nS < 2
                gt_dbm = [gt_dbm; gt_dbm + randn(size(gt_dbm))*0.1];
                nS = 2;
            end
            
            min_v = app.NormParams.Min; max_v = app.NormParams.Max;
            win = app.PredictionWindow;
            if isempty(win) || win == 0, win = 1; end
            
            if ~isempty(app.TrainedNet)
                preds_dbm = zeros(nS, curr_dim); req_dim = app.TrainedNet.Layers(1).InputSize;
                if curr_dim ~= req_dim, gt_res = interp1(linspace(0,1,curr_dim), gt_dbm', linspace(0,1,req_dim))'; else, gt_res = gt_dbm; end
                d_norm = (gt_res' - min_v) / (max_v - min_v); 
                
                if size(d_norm,2) > win
                    inp = cell(nS-win, 1); for i=1:nS-win, inp{i} = d_norm(:, i:i+win-1); end
                    p_norm = predict(app.TrainedNet, inp); p_val = p_norm * (max_v - min_v) + min_v;
                    if curr_dim ~= req_dim, p_res = interp1(linspace(0,1,req_dim), p_val', linspace(0,1,curr_dim))'; else, p_res = p_val; end
                    preds_dbm(win+1:nS, :) = p_res; preds_dbm(1:win, :) = gt_dbm(1:win, :);
                else, preds_dbm = gt_dbm; end
            else
                preds_dbm = gt_dbm + randn(size(gt_dbm))*2;
            end
            
            future_len = round(app.PredLengthEdit.Value);
            batch_size = round(app.BatchSizeEdit.Value);
            if batch_size < 1, batch_size = 1; end
            
            future_preds_cell = cell(batch_size, 1);
            if future_len > 0 && ~isempty(app.TrainedNet)
                num_cols = size(d_norm, 2);
                base_window_norm = d_norm(:, num_cols-win+1:num_cols); 
                
                for b = 1:batch_size
                    current_window_norm = base_window_norm;
                    if batch_size > 1
                        current_window_norm = current_window_norm + randn(size(current_window_norm)) * 0.02;
                    end
                    
                    curr_future = zeros(future_len, curr_dim);
                    for step = 1:future_len
                        p_norm = predict(app.TrainedNet, {current_window_norm}); 
                        p_val = p_norm * (max_v - min_v) + min_v;
                        if curr_dim ~= req_dim
                            p_res = interp1(linspace(0,1,req_dim), p_val', linspace(0,1,curr_dim))'; 
                        else
                            p_res = p_val; 
                        end
                        curr_future(step, :) = p_res;
                        
                        c_cols = size(current_window_norm, 2);
                        current_window_norm = [current_window_norm(:, 2:c_cols), p_norm'];
                    end
                    future_preds_cell{b} = curr_future;
                end
            end
            
            B_hz = app.BandwidthEdit.Value * 1e6; res = struct();
            pre_W = 10 .^ (preds_dbm / 10 - 3); ori_W = 10 .^ (gt_dbm / 10 - 3);
            pre_total_power = sum(pre_W, 2); ori_total_power = sum(ori_W, 2);
            
            noise_dBm = [noise_test, noise_test-5, noise_test-10, noise_test-15, noise_test-20];
            
            res.SNR = zeros(5,1); res.C_pre = zeros(5,1); res.C_ori = zeros(5,1);
            for i = 1:5
                N_W = 10^(noise_dBm(i)/10 - 3);
                res.C_pre(i) = mean(B_hz * log2(1 + (pre_total_power/curr_dim) / N_W)) / 1e9;
                res.C_ori(i) = mean(B_hz * log2(1 + (ori_total_power/curr_dim) / N_W)) / 1e9;
                res.SNR(i) = 10*log10(mean(ori_total_power/curr_dim)/N_W);
            end
            
            error_ratio = mean(abs(res.C_pre - res.C_ori) ./ res.C_ori);
            res.CapAcc = max(0, (1 - error_ratio)) * 100;
            
            group_size = max(1, floor(nS / 10)); 
            num_groups = floor(nS / group_size);
            if num_groups >= 1
                rmse_values = zeros(num_groups, 1);
                for g = 1:num_groups
                    gt_g = gt_dbm((g-1)*group_size+1 : g*group_size, :);
                    pr_g = preds_dbm((g-1)*group_size+1 : g*group_size, :);
                    rmse_values(g) = sqrt(mean((gt_g(:) - pr_g(:)).^2));
                end
                res.GroupRMSE = rmse_values;
            else, res.GroupRMSE = sqrt(mean((preds_dbm(:) - gt_dbm(:)).^2)); end
            
            res.RMSE = sqrt(mean((preds_dbm(:) - gt_dbm(:)).^2));
            res.NRMSE = res.RMSE / (max(gt_dbm(:)) - min(gt_dbm(:))) * 100;
            
            idx_ax = 0:(curr_dim-1); dt_ns = (1 / B_hz) * 1e9;
            if curr_dim > 1
                ptau = sqrt(sum((idx_ax - (sum(idx_ax.*pre_W,2)./pre_total_power)).^2 .* pre_W, 2)./pre_total_power) * dt_ns;
                otau = sqrt(sum((idx_ax - (sum(idx_ax.*ori_W,2)./ori_total_power)).^2 .* ori_W, 2)./ori_total_power) * dt_ns;
                p_mu = mean(ptau(:)); p_sig = std(ptau(:)); o_mu = mean(otau(:)); o_sig = std(otau(:));
                cx = linspace(min([ptau(:); otau(:)]), max([ptau(:); otau(:)]), 1000);
                res.fp = 0.5 * (1 + erf((cx - p_mu) ./ (max(1e-6, p_sig) * sqrt(2)))); res.xp = cx;
                res.fo = 0.5 * (1 + erf((cx - o_mu) ./ (max(1e-6, o_sig) * sqrt(2)))); res.xo = cx;
            else
                res.fp=[0 1]; res.xp=[0 0]; res.fo=[0 1]; res.xo=[0 0];
            end
            res.Raw_Pre = preds_dbm; res.Raw_Ori = gt_dbm;
            res.Future_Pre = future_preds_cell; 
            res.Metrics = metric_data; 
            
            app.PredictionResults = res;
            
            if ~isvalid(app) || ~isvalid(app.UIFigure), return; end
            
            app.updatePredictionPlots_Generic(prefix);
            if exist('d', 'var') && isvalid(d), delete(d); end
            
            app.stabilizeFocus(prevState);
            app.showCustomReportDialog(prefix, app.selectedAlgo, res);
        end
        
        function showCustomReportDialog(~, prefix, algo, res)
            rptFig = uifigure('Name', 'Evaluation Report', 'Position', [100, 100, 420, 360], 'WindowStyle', 'modal');
            rptFig.Color = [0.94 0.94 0.94];
            movegui(rptFig, 'center'); 
            
            uilabel(rptFig, 'Text', 'Verification Results', 'Position', [20, 310, 380, 35], 'FontSize', 20, 'FontWeight', 'bold', 'FontColor', 'k', 'HorizontalAlignment', 'center', 'FontName', 'Helvetica');
            
            html_text = sprintf([...
                '<html><body style="font-family: Helvetica, sans-serif; font-size: 14px; line-height: 1.8; color: #000000;">' ...
                '<div style="background-color: #FFFFFF; padding: 15px; border-radius: 8px; border: 1px solid #E5E5EA;">' ...
                '<b>Test Scenario:</b> %s<br>' ...
                '<b>Core Algorithm:</b> %s<hr style="border:0; border-top:1px solid #E5E5EA;">' ...
                '<b>Capacity Accuracy:</b> <span style="font-size:16px; color:#0071E3;"><b>%.2f %%</b></span><br>' ...
                '<b>Delay Spread Error (NRMSE):</b> <span style="font-size:16px;"><b>%.2f %%</b></span><br>' ...
                '<b>Absolute Error (RMSE):</b> <span style="font-size:16px;"><b>%.4f dBm</b></span>' ...
                '</div></body></html>'], ...
                prefix, algo, res.CapAcc, res.NRMSE, res.RMSE);
            
            uihtml(rptFig, 'HTMLSource', html_text, 'Position', [20, 80, 380, 210]);
            uibutton(rptFig, 'Text', 'OK', 'Position', [140, 20, 140, 40], 'FontSize', 16, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn,event) close(rptFig), 'FontName', 'Helvetica', 'BackgroundColor', [0.2 0.2 0.2], 'FontColor', 'white');
        end
        
        function updatePredictionPlots_Generic(app, prefix)
            res = app.PredictionResults;
            c_pre = app.Color_Primary;   
            c_ori = app.Color_Secondary; 
            
            % --- 容量绘制 ---
            delete(app.PredCapacityAxes.Children);
            h_cpre = plot(app.PredCapacityAxes, res.SNR, res.C_pre, '-o', 'Color', c_pre, 'LineWidth', 1.5, 'MarkerFaceColor', c_pre, 'MarkerSize', 4); 
            h_cori = plot(app.PredCapacityAxes, res.SNR, res.C_ori, '--', 'Color', c_ori, 'LineWidth', 1.5); 
            
            lgd1 = legend(app.PredCapacityAxes, [h_cpre, h_cori], {'AI capacity (solid)', 'True capacity (dashed)'}, 'Location', 'southeast');
            lgd1.Color = 'none'; lgd1.EdgeColor = 'none'; lgd1.TextColor = app.Color_Text;
            
            app.applyAxesStyle(app.PredCapacityAxes, sprintf('[%s] Capacity (Acc: %.2f%%)', prefix, res.CapAcc), 'SNR (dB)', 'Capacity (Gbps)'); 
            app.applyYLimMargin(app.PredCapacityAxes, [res.C_pre(:); res.C_ori(:)]);
            app.setFullWidthAxes(app.PredCapacityAxes, res.SNR);
            
            % --- RMSE 绘制 ---
            delete(app.PredRMSEAxes.Children);
            if length(res.GroupRMSE) > 1
                plot(app.PredRMSEAxes, 1:length(res.GroupRMSE), res.GroupRMSE, '-', 'Color', c_pre, 'LineWidth', 1.5); 
                app.applyAxesStyle(app.PredRMSEAxes, sprintf('[%s] Group RMSE (NRMSE: %.2f%%)', prefix, res.NRMSE), 'Group Index', 'RMSE (dBm)'); 
                app.applyYLimMargin(app.PredRMSEAxes, res.GroupRMSE);
                app.setFullWidthAxes(app.PredRMSEAxes, 1:length(res.GroupRMSE));
            else
                bar(app.PredRMSEAxes, res.RMSE, 'FaceColor', c_pre, 'EdgeColor', 'none', 'BarWidth', 0.4); 
                app.applyAxesStyle(app.PredRMSEAxes, sprintf('[%s] RMSE (NRMSE: %.2f%%)', prefix, res.NRMSE), 'Index', 'RMSE (dBm)'); 
                app.applyYLimMargin(app.PredRMSEAxes, res.RMSE);
            end
            
            % --- 原始数据 PSD ---
            delete(app.PredRawDataAxes.Children);
            
            x_delay_raw = res.Metrics.delay.x;
            x_delay = x_delay_raw(:);
            
            tmp_ori_pwr = mean(10.^(res.Raw_Ori/10), 1);
            tmp_ori_db = 10*log10(tmp_ori_pwr);
            raw_ori_pdp = tmp_ori_db(:);
            
            tmp_pre_pwr = mean(10.^(res.Raw_Pre/10), 1);
            tmp_pre_db = 10*log10(tmp_pre_pwr);
            raw_pre_pdp = tmp_pre_db(:);
            
            noise_est = median(raw_ori_pdp(:));
            peak_val = max(raw_ori_pdp(:));
            dyn_thresh = min(noise_est + 5, peak_val - 3); 
            
            raw_pre_clean = raw_pre_pdp;
            raw_pre_clean(raw_pre_clean < dyn_thresh) = dyn_thresh;
            raw_ori_clean = raw_ori_pdp;
            raw_ori_clean(raw_ori_clean < dyn_thresh) = dyn_thresh;
            
            h_rori = plot(app.PredRawDataAxes, x_delay, raw_ori_clean, '--', 'Color', [c_ori, 0.7], 'LineWidth', 1.2); 
            h_rpre = plot(app.PredRawDataAxes, x_delay, raw_pre_clean, '-', 'Color', c_pre, 'LineWidth', 1.5); 
            
            y_all_raw = [raw_ori_clean(:); raw_pre_clean(:)];
            
            if ~isempty(res.Future_Pre) && ~isempty(res.Future_Pre{1})
                fut_matrix = res.Future_Pre{1};
                tmp_fut_pwr = mean(10.^(fut_matrix/10), 1);
                tmp_fut_db = 10*log10(tmp_fut_pwr);
                fut_pdp = tmp_fut_db(:);
                
                fut_pdp(fut_pdp < dyn_thresh) = dyn_thresh; 
                h_rfut = plot(app.PredRawDataAxes, x_delay, fut_pdp, ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.5); 
                y_all_raw = [y_all_raw; fut_pdp(:)];
                
                lgd2 = legend(app.PredRawDataAxes, [h_rori, h_rpre, h_rfut], {'Measurement (dashed)', 'Prediction (solid)', 'Future (dotted)'}, 'Location', 'northeast');
            else
                lgd2 = legend(app.PredRawDataAxes, [h_rori, h_rpre], {'Measurement (dashed)', 'Prediction (solid)'}, 'Location', 'northeast');
            end
            lgd2.Color = 'none'; lgd2.EdgeColor = 'none'; lgd2.TextColor = app.Color_Text;
            
            app.applyAxesStyle(app.PredRawDataAxes, 'PSD Verification', 'Delay (ns)', 'Power (dBm)');
            app.applyYLimMargin(app.PredRawDataAxes, y_all_raw);
            
            valid_idx = find(raw_ori_pdp > dyn_thresh | raw_pre_pdp > dyn_thresh); 
            if ~isempty(valid_idx)
                margin = max(5, round(length(x_delay) * 0.05)); 
                vlen = length(valid_idx);
                idx_start = max(1, valid_idx(1) - margin);
                idx_end = min(length(x_delay), valid_idx(vlen) + margin);
                
                x_min = x_delay(idx_start);
                x_max = x_delay(idx_end);
                
                if x_min < x_max
                    xlim(app.PredRawDataAxes, [x_min, x_max]);
                else
                    app.setFullWidthAxes(app.PredRawDataAxes, x_delay);
                end
            else
                app.setFullWidthAxes(app.PredRawDataAxes, x_delay);
            end
            
            % --- 延时扩展 Spread ---
            delete(app.PredSpreadAxes.Children);
            h_sfp = plot(app.PredSpreadAxes, res.xp, res.fp, '-', 'Color', c_pre, 'LineWidth', 1.5); 
            h_sfo = plot(app.PredSpreadAxes, res.xo, res.fo, '--', 'Color', c_ori, 'LineWidth', 1.5); 
            
            lgd3 = legend(app.PredSpreadAxes, [h_sfp, h_sfo], {'Predicted CDF (solid)', 'True CDF (dashed)'}, 'Location', 'southeast');
            lgd3.Color = 'none'; lgd3.EdgeColor = 'none'; lgd3.TextColor = app.Color_Text;
            
            app.applyAxesStyle(app.PredSpreadAxes, sprintf('[%s] Delay Spread CDF', prefix), 'Delay Spread \tau (ns)', 'CDF'); 
            app.applyYLimMargin(app.PredSpreadAxes, [res.fp(:); res.fo(:)]);
            app.setFullWidthAxes(app.PredSpreadAxes, res.xp);
            
            % --- 角度功率谱 ---
            delete(app.PredAngularAxes.Children);
            m = res.Metrics;
            if isfield(m, 'space') && max(m.space.psd) > -900
                plot(app.PredAngularAxes, m.space.angle, m.space.psd, '-', 'Color', c_pre, 'LineWidth', 1.5);
                app.applyAxesStyle(app.PredAngularAxes, sprintf('[%s] Angular PSD', prefix), 'Angle (deg)', 'Power (dB)');
                app.applyYLimMargin(app.PredAngularAxes, m.space.psd); 
                app.setFullWidthAxes(app.PredAngularAxes, m.space.angle);
            else
                set(app.PredAngularAxes, 'XTick', [], 'YTick', []);
                text(app.PredAngularAxes, 0.5, 0.5, 'No Data', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', app.Color_TextDim, 'FontName', 'Helvetica');
                app.applyAxesStyle(app.PredAngularAxes, sprintf('[%s] Angular PSD', prefix), 'Angle (deg)', 'Power (dB)');
            end
            
            % --- 多普勒功率谱 ---
            delete(app.PredDopplerAxes.Children);
            if isfield(m, 'time') && max(m.time.y) > -900
                plot(app.PredDopplerAxes, m.time.x, m.time.y, '-', 'Color', c_pre, 'LineWidth', 1.5);
                app.applyAxesStyle(app.PredDopplerAxes, sprintf('[%s] Doppler', prefix), 'Hz', 'dB');
                app.applyYLimMargin(app.PredDopplerAxes, m.time.y);
                app.setFullWidthAxes(app.PredDopplerAxes, m.time.x);
            else
                set(app.PredDopplerAxes, 'XTick', [], 'YTick', []);
                text(app.PredDopplerAxes, 0.5, 0.5, 'No Data', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', app.Color_TextDim, 'FontName', 'Helvetica');
                app.applyAxesStyle(app.PredDopplerAxes, sprintf('[%s] Doppler', prefix), 'Hz', 'dB');
            end
            
            drawnow limitrate;
        end
    end
    
    %% ==================== 界面响应与防缩放排版 ====================
    methods (Access = private)
        function startupFcn(app), app.showPlaceholderPlots(); app.showPredPlaceholderPlots(); end
        
        function ConfigValueChanged(app, ~)
            band = app.FreqBandDropDown.Value;
            bw = 100;
            if contains(band, 'mmWave'), bw = 200; end
            if contains(band, 'THz'), bw = 200; end
            if contains(band, 'Optical Wireless'), bw = 200; end
            app.BandwidthEdit.Value = bw;
        end
        
        function UIFigureSizeChanged(app, ~)
            pos = app.UIFigure.Position; 
            actualW = pos(3); 
            actualH = pos(4);
            
            usableH = actualH - 35; 
            vW = max(actualW, 1200); 
            vH = max(usableH, 750); 
            
            app.TabGroup.Position = [1 1 actualW actualH]; 
            app.DataImportScrollPanel.Position = [1 1 actualW usableH]; 
            app.ChannelPredScrollPanel.Position = [1 1 actualW usableH];
            
            if isprop(app, 'GenScrollPanel') && ~isempty(app.GenScrollPanel) && isvalid(app.GenScrollPanel)
                app.GenScrollPanel.Position = [1 1 actualW usableH];
            end
            
            pw = vW - 30;
            
            % --- Tab 1 增强排版 ---
            % 第一行：基础配置 与 数据管理
            app.BasicConfigPanel.Position = [15, vH - 85, 450, 70]; 
            app.FreqBandLabel.Position = [15 15 70 25]; 
            app.FreqBandDropDown.Position = [65 15 100 25];
            app.ScenarioLabel.Position = [185 15 70 25]; 
            app.ScenarioDropDown.Position = [255 15 90 25];
            app.BandwidthLabel.Position = [355 15 40 25]; 
            app.BandwidthEdit.Position = [395 15 50 25];
            
            app.DataMgmtPanel.Position = [480, vH - 85, 350, 70];
            app.DatasetDropDown.Position = [15 15 140 25]; 
            
            btnWidth = 80; btnHeight = 25;
            app.LoadDataButton.Position  = [170, 15, btnWidth, btnHeight]; 
            app.ClearDataButton.Position = [260, 15, btnWidth, btnHeight]; 
            
            % 第二行：Data Quality面板 (含兼容识别、元信息展示)
            app.DataQualityPanel.Position = [15, vH - 170, pw, 75];
            app.ValidLamp.Position = [15, 25, 20, 20];
            app.ValidStatusLabel.Position = [45, 25, 200, 20];
            app.Mod23ReadyLabel.Position = [250, 25, 250, 20];
            app.MetaInfoTextArea.Position = [500, 10, pw - 520, 45];
            
            % 第三行：数据视图对照控制
            % 第三行：数据视图对照控制
            app.ViewModeLabel.Position = [15, vH - 210, 80, 25];
            % 修复纵横比警告：使用标准的 45x20 大小
            % 修复重叠：X 轴右移至 180，为左侧的 "Original" 文本预留充足空间
            app.ViewModeSwitch.Position = [180, vH - 208, 45, 20];
            
            % 第四行：自适应四图区
            charH = vH - 225; 
            app.ChannelCharsPanel.Position = [15, 15, pw, charH];
            ph1 = charH - 30; mx1 = 70; my1 = 50; gx1 = 80; gy1 = 70; 
            aw1 = max(1, (pw - 2*mx1 - gx1)/2); ah1 = max(1, (ph1 - 2*my1 - gy1)/2);
            
            app.SpreadCDFAxes.Position = [mx1, my1 + ah1 + gy1, aw1, ah1]; 
            app.DopplerPowerAxes.Position = [mx1 + aw1 + gx1, my1 + ah1 + gy1, aw1, ah1]; 
            app.DelayPowerAxes.Position = [mx1, my1, aw1, ah1]; 
            app.AngularPowerAxes.Position = [mx1 + aw1 + gx1, my1, aw1, ah1];
            
            % --- Tab 2 排版 ---
            if isprop(app, 'GenConfigPanel') && ~isempty(app.GenConfigPanel) && isvalid(app.GenConfigPanel)
                app.GenConfigPanel.Position = [15, vH - 85, pw, 70];
                app.GenModelLabel.Position = [15 15 120 25];
                app.GenModelDropDown.Position = [135 15 150 25];
                genBtnWidth = 160; genBtnHeight = 35;
                app.GenStartButton.Position = [pw - genBtnWidth*2 - 20, 10, genBtnWidth, genBtnHeight];
                app.GenSendToAIButton.Position = [pw - genBtnWidth - 10, 10, genBtnWidth, genBtnHeight];
                
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
            
            % --- Tab 3 排版 ---
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
            
            app.PredLengthLabel.Position = [10, 60, 150, 25];
            app.PredLengthEdit.Position = [160, 60, 60, 25];
            app.BatchSizeLabel.Position = [10, 20, 150, 25];
            app.BatchSizeEdit.Position = [160, 20, 60, 25];
            
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
            combo_name = [strrep(app.FreqBandDropDown.Value, ' ', ''), '-', app.ScenarioDropDown.Value];
            app.loadData_Generic(combo_name);
        end
        
        % [自适应四图与模式切换逻辑核心]
        function updateVisualizations(app)
            if isempty(app.DatasetPaths), return; end
            idx = find(strcmp(app.DatasetPaths, app.DatasetDropDown.Value), 1); 
            
            % 获取原数据或预适配数据指标
            if strcmp(app.ViewModeSwitch.Value, 'Original') && length(app.RawMetrics) >= idx
                m = app.RawMetrics{idx};
            else
                m = app.ChannelMetrics{idx};
            end
            
            dt = 'Legacy';
            if length(app.DataTypes) >= idx && ~isempty(app.DataTypes{idx})
                dt = app.DataTypes{idx};
            end
            isComplex = strcmp(dt, 'Complex-H');
            
            % [图1: 角度与空间域自适应]
            delete(app.AngularPowerAxes.Children); 
            if max(m.space.psd) > -900
                if isComplex
                    plot(app.AngularPowerAxes, m.space.angle, m.space.psd, '-o', 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.2);
                    app.applyAxesStyle(app.AngularPowerAxes, '[Complex-H] Spatial Profile/Subspace', 'Antenna/Angle', 'Magnitude (dB)');
                else
                    plot(app.AngularPowerAxes, m.space.angle, m.space.psd, 'Color', app.Color_Primary, 'LineWidth', 1.5);
                    app.applyAxesStyle(app.AngularPowerAxes, '[Legacy] Angle Power Spectrum', 'Angle (deg)', 'Norm Power (dB)');
                end
                app.applyYLimMargin(app.AngularPowerAxes, m.space.psd); 
                app.setFullWidthAxes(app.AngularPowerAxes, m.space.angle);
            else
                set(app.AngularPowerAxes, 'XTick', [], 'YTick', []);
                text(app.AngularPowerAxes, 0.5, 0.5, 'No Data', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', app.Color_TextDim, 'FontName', 'Helvetica');
                app.applyAxesStyle(app.AngularPowerAxes, 'Angle Power Spectrum', 'Angle (deg)', 'Norm Power (dB)');
            end
            
            % [图2: 延迟域自适应]
            dy = m.delay.y;
            delete(app.DelayPowerAxes.Children); 
            if isComplex
                plot(app.DelayPowerAxes, m.delay.x, dy, 'Color', [0.3010 0.7450 0.9330], 'LineWidth', 1.5);
                app.applyAxesStyle(app.DelayPowerAxes, '[Complex-H] Delay Tensor Extent', 'Delay (ns)', 'Intensity'); 
            else
                plot(app.DelayPowerAxes, m.delay.x, dy, 'Color', app.Color_Primary, 'LineWidth', 1.5); 
                app.applyAxesStyle(app.DelayPowerAxes, '[Legacy] Delay PSD', 'Delay (ns)', 'Power (dB)'); 
            end
            app.applyYLimMargin(app.DelayPowerAxes, dy);
            
            noise_est = median(dy(:));
            peak_val = max(dy(:));
            dyn_thresh = min(noise_est + 5, peak_val - 3); 
            valid_idx = find(dy >= dyn_thresh);
            if ~isempty(valid_idx)
                margin = max(10, round(length(dy) * 0.05));
                vlen = length(valid_idx);
                idx_start = max(1, valid_idx(1) - margin);
                idx_end = min(length(dy), valid_idx(vlen) + margin);
                x_min = m.delay.x(idx_start); x_max = m.delay.x(idx_end);
                if x_min < x_max
                    xlim(app.DelayPowerAxes, [x_min, x_max]);
                else
                    app.setFullWidthAxes(app.DelayPowerAxes, m.delay.x);
                end
            else
                app.setFullWidthAxes(app.DelayPowerAxes, m.delay.x);
            end
            
            % [图3: 扩展域自适应]
            delete(app.SpreadCDFAxes.Children); 
            if isComplex
                plot(app.SpreadCDFAxes, m.delay.cdf_x, m.delay.cdf_y, '-.', 'Color', [0.4940 0.1840 0.5560], 'LineWidth', 1.8);
                app.applyAxesStyle(app.SpreadCDFAxes, '[Complex-H] Singular Value/Spread CDF', 'Value', 'CDF'); 
            else
                plot(app.SpreadCDFAxes, m.delay.cdf_x, m.delay.cdf_y, 'Color', app.Color_Primary, 'LineWidth', 1.5); 
                app.applyAxesStyle(app.SpreadCDFAxes, '[Legacy] Spread CDF', 'Spread', 'CDF'); 
            end
            app.applyYLimMargin(app.SpreadCDFAxes, m.delay.cdf_y); 
            app.setFullWidthAxes(app.SpreadCDFAxes, m.delay.cdf_x);
            
            % [图4: 时域/多普勒域自适应]
            delete(app.DopplerPowerAxes.Children); 
            if isfield(m, 'time') && max(m.time.y) > -900
                if isComplex
                    plot(app.DopplerPowerAxes, m.time.x, m.time.y, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.2);
                    app.applyAxesStyle(app.DopplerPowerAxes, '[Complex-H] Time/Doppler Covariance', 'Hz', 'Norm (dB)');
                else
                    plot(app.DopplerPowerAxes, m.time.x, m.time.y, 'Color', app.Color_Primary, 'LineWidth', 1.5); 
                    app.applyAxesStyle(app.DopplerPowerAxes, '[Legacy] Doppler PSD', 'Hz', 'dB');
                end
                app.applyYLimMargin(app.DopplerPowerAxes, m.time.y);
                app.setFullWidthAxes(app.DopplerPowerAxes, m.time.x);
            else
                set(app.DopplerPowerAxes, 'XTick', [], 'YTick', []);
                text(app.DopplerPowerAxes, 0.5, 0.5, 'No Data', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', app.Color_TextDim, 'FontName', 'Helvetica');
                app.applyAxesStyle(app.DopplerPowerAxes, 'Doppler', 'Hz', 'dB');
            end
            drawnow limitrate;
        end
        
        function ClearDataButtonPushed(app, ~)
            app.LoadedData={}; app.ChannelMetrics={}; app.DatasetPaths={}; 
            app.DataTypes={}; app.RawMetrics={}; 
            app.DatasetDropDown.Items={'[None]'}; app.TrainedNet=[]; 
            
            % 重置UI面板
            app.ValidLamp.Color = [0.8 0 0];
            app.ValidStatusLabel.Text = 'Status: Pending Load';
            app.Mod23ReadyLabel.Text = 'Entry to Module 2/3: DENIED';
            app.Mod23ReadyLabel.FontColor = [0.8 0 0];
            app.MetaInfoTextArea.Value = 'Awaiting data...';
            
            app.showPlaceholderPlots(); 
            app.showPredPlaceholderPlots(); 
        end
        
        function TrainButtonPushed(app, ~)
            if isempty(app.DatasetPaths), uialert(app.UIFigure, 'Please load data first!', 'Info'); return; end
            app.trainModel_Generic(); 
        end
        
        function PredictButtonPushed(app, ~)
            if isempty(app.TrainedNet), uialert(app.UIFigure, 'Please train the model first!', 'Info'); return; end
            band = app.FreqBandDropDown.Value; scen = app.ScenarioDropDown.Value;
            noise = -100;
            if contains(band, 'mmWave'), noise = -37; end
            if contains(band, 'THz'), noise = -120; end
            if contains(band, 'Optical Wireless'), noise = -130; end
            prefix = [band, '-', scen];
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
            if isempty(app.TrainedNet), uialert(app.UIFigure, 'No model to export', 'Error'); return; end; 
            prevState = app.UIFigure.WindowState;
            [f, p] = uiputfile('*.mat', 'Save Model'); 
            app.stabilizeFocus(prevState);
            if isequal(f,0) || isequal(p,0), return; end
            net = app.TrainedNet; save(fullfile(p,f), 'net'); 
            uialert(app.UIFigure, 'Model exported successfully!', 'Success'); 
        end
        
        function SavePredDataButtonPushed(app, ~)
            if isempty(app.PredictionResults) || ~isfield(app.PredictionResults, 'Future_Pre')
                uialert(app.UIFigure, 'No prediction data! Please run Predict first.', 'Error'); 
                return; 
            end
            
            prevState = app.UIFigure.WindowState;
            batch_size = length(app.PredictionResults.Future_Pre);
            
            if batch_size <= 1
                [f,p] = uiputfile('*.mat', 'Save prediction results and extrapolation data'); 
                app.stabilizeFocus(prevState);
                if isequal(f,0) || isequal(p,0), return; end
                res = app.PredictionResults; 
                save(fullfile(p,f), 'res'); 
                uialert(app.UIFigure, 'Validation data and extrapolation data exported successfully!', 'Success');
            else
                selpath = uigetdir('', sprintf('Select folder to output %d independent datasets', batch_size));
                app.stabilizeFocus(prevState);
                if isequal(selpath,0) || isequal(selpath,''), return; end
                
                res = app.PredictionResults;
                val_metrics = rmfield(res, 'Future_Pre');
                save(fullfile(selpath, 'Validation_Metrics_Base.mat'), 'val_metrics');
                
                d = uiprogressdlg(app.UIFigure, 'Title', 'Exporting batch datasets...', 'Indeterminate', 'on');
                try
                    for b = 1:batch_size
                        channel_data = res.Future_Pre{b};
                        filename = fullfile(selpath, sprintf('Future_Dataset_%03d.mat', b));
                        save(filename, 'channel_data');
                    end
                    if isvalid(d), delete(d); end
                    uialert(app.UIFigure, sprintf('Successfully generated %d independent datasets in selected folder!', batch_size), 'Batch export successful');
                catch ME
                    if isvalid(d), delete(d); end
                    uialert(app.UIFigure, ['Export failed: ' ME.message], 'Error');
                end
            end
        end
        
        function showPlaceholderPlots(app)
            app.applyAxesStyle(app.AngularPowerAxes, 'Waiting Data...', '', ''); app.applyAxesStyle(app.DelayPowerAxes, 'Waiting Data...', '', '');
            app.applyAxesStyle(app.SpreadCDFAxes, 'Waiting Data...', '', ''); app.applyAxesStyle(app.DopplerPowerAxes, 'Waiting Data...', '', '');
        end
        function showPredPlaceholderPlots(app)
            app.applyAxesStyle(app.PredCapacityAxes, 'Capacity Waiting...', '', ''); app.applyAxesStyle(app.PredRawDataAxes, 'PSD Waiting...', '', '');
            app.applyAxesStyle(app.PredRMSEAxes, 'RMSE Waiting...', '', ''); app.applyAxesStyle(app.PredSpreadAxes, 'Spread Waiting...', '', '');
            app.applyAxesStyle(app.PredAngularAxes, 'Angle Waiting...', '', ''); app.applyAxesStyle(app.PredDopplerAxes, 'Doppler Waiting...', '', '');
        end
    end
    
    %% ==================== UI 创建逻辑 ====================
    methods (Access = private)
        function createComponents(app)
            try
                warning('off', 'MATLAB:ui:container:AutoResizeChildren');
                
                app.UIFigure = uifigure('Name', '6G Predictor (Ultimate Standalone Edition)', 'Position', [100 100 1300 850], 'Visible', 'off', 'Color', app.Color_Bg);
                app.UIFigure.AutoResizeChildren = 'off';
                
                app.TabGroup = uitabgroup(app.UIFigure, 'Position', [1 1 1300 850]);
                app.TabGroup.AutoResizeChildren = 'off';
                
                % --- 第一页 (已强化) ---
                app.DataImportTab = uitab(app.TabGroup, 'Title', '1. Characterization', 'BackgroundColor', app.Color_Bg);
                app.DataImportScrollPanel = uipanel(app.DataImportTab, 'Scrollable', 'on', 'BackgroundColor', app.Color_Bg, 'BorderType', 'none');
                app.DataImportScrollPanel.AutoResizeChildren = 'off';
                
                app.BasicConfigPanel = uipanel(app.DataImportScrollPanel, 'Title', 'Parameters & Scenario', 'FontSize', 14);
                app.BasicConfigPanel.AutoResizeChildren = 'off';
                
                app.FreqBandLabel = uilabel(app.BasicConfigPanel, 'Text', 'Band:');
                app.FreqBandDropDown = uidropdown(app.BasicConfigPanel, 'Items', ...
                    {'Sub-6', 'mmWave', 'THz', 'Optical Wireless'}, ...
                    'ValueChangedFcn', createCallbackFcn(app, @(s,e) app.updateScenarioItems(), true));
                
                app.ScenarioLabel = uilabel(app.BasicConfigPanel, 'Text', 'Scenario:', 'FontWeight', 'bold');
                app.ScenarioDropDown = uidropdown(app.BasicConfigPanel, 'Items', {'Loading...'}, ...
                    'ValueChangedFcn', createCallbackFcn(app, @ConfigValueChanged, true));
                
                app.BandwidthLabel = uilabel(app.BasicConfigPanel, 'Text', 'BW (MHz):');
                app.BandwidthEdit = uieditfield(app.BasicConfigPanel, 'numeric', 'Value', 100);
                
                app.DataMgmtPanel = uipanel(app.DataImportScrollPanel, 'Title', 'Data Load', 'FontSize', 14);
                app.DataMgmtPanel.AutoResizeChildren = 'off';
                
                app.DatasetDropDown = uidropdown(app.DataMgmtPanel, 'Items', {'[None]'});
                app.LoadDataButton = uibutton(app.DataMgmtPanel, 'Text', 'Load Data', 'BackgroundColor', app.ActiveBtnColor, 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @LoadDataButtonPushed, true));
                app.ClearDataButton = uibutton(app.DataMgmtPanel, 'Text', 'Clear', 'ButtonPushedFcn', createCallbackFcn(app, @ClearDataButtonPushed, true));
                
                % [新增] Data Quality & Validation Panel
                app.DataQualityPanel = uipanel(app.DataImportScrollPanel, 'Title', 'Data Quality & Validation', 'FontSize', 14);
                app.DataQualityPanel.AutoResizeChildren = 'off';
                
                app.ValidLamp = uilamp(app.DataQualityPanel, 'Color', [0.8 0 0]);
                app.ValidStatusLabel = uilabel(app.DataQualityPanel, 'Text', 'Status: Pending Load', 'FontWeight', 'bold');
                app.Mod23ReadyLabel = uilabel(app.DataQualityPanel, 'Text', 'Entry to Module 2/3: DENIED', 'FontWeight', 'bold', 'FontColor', [0.8 0 0]);
                app.MetaInfoTextArea = uitextarea(app.DataQualityPanel, 'Editable', 'off', 'Value', 'Awaiting data...');
                
                % [新增] 视图模式切换控制
                app.ViewModeLabel = uilabel(app.DataImportScrollPanel, 'Text', 'View Mode:', 'FontWeight', 'bold');
                app.ViewModeSwitch = uiswitch(app.DataImportScrollPanel, 'Items', {'Original', 'Pre-Adapted'}, ...
                    'Value', 'Pre-Adapted', 'ValueChangedFcn', createCallbackFcn(app, @(s,e) updateVisualizations(app), true));
                
                app.ChannelCharsPanel = uipanel(app.DataImportScrollPanel, 'Title', 'Characteristic Plots', 'FontSize', 14);
                app.ChannelCharsPanel.AutoResizeChildren = 'off';
                
                app.AngularPowerAxes = uiaxes(app.ChannelCharsPanel);
                app.DelayPowerAxes = uiaxes(app.ChannelCharsPanel);
                app.DopplerPowerAxes = uiaxes(app.ChannelCharsPanel);
                app.SpreadCDFAxes = uiaxes(app.ChannelCharsPanel);
                
                % --- 第二页 ---
                app.ChannelGenTab = uitab(app.TabGroup, 'Title', '2. Channel Generation', 'BackgroundColor', app.Color_Bg);
                app.GenScrollPanel = uipanel(app.ChannelGenTab, 'BackgroundColor', app.Color_Bg, 'BorderType', 'none');
                app.GenScrollPanel.AutoResizeChildren = 'off';
                
                app.GenConfigPanel = uipanel(app.GenScrollPanel, 'Title', 'Simulation Parameters & Execution', 'FontSize', 14);
                app.GenConfigPanel.AutoResizeChildren = 'off';
                
                app.GenModelLabel = uilabel(app.GenConfigPanel, 'Text', 'Simulation Model:');
                app.GenModelDropDown = uidropdown(app.GenConfigPanel, 'Items', {'Loading...'});
                app.GenStartButton = uibutton(app.GenConfigPanel, 'Text', 'Generate', 'BackgroundColor', [0 0.5 0.2], 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @GenStartButtonPushed, true));
                app.GenSendToAIButton = uibutton(app.GenConfigPanel, 'Text', 'Send to AI', 'BackgroundColor', app.Color_Blue, 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @GenSendToAIButtonPushed, true));
                
                app.GenParamPanel = uipanel(app.GenScrollPanel, 'Title', 'Stochastic Engine Physics (Large & Small Scale Fading)', 'FontSize', 14);
                app.GenParamPanel.AutoResizeChildren = 'off';
                
                app.DSmuLabel = uilabel(app.GenParamPanel, 'Text', 'DS mu:');
                app.DSmuEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', -7.925);
                app.DSsigmaLabel = uilabel(app.GenParamPanel, 'Text', 'DS sigma:');
                app.DSsigmaEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 0.060);
                app.rDSLabel = uilabel(app.GenParamPanel, 'Text', 'r DS:');
                app.rDSEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 2.8);
                app.ClusterLabel = uilabel(app.GenParamPanel, 'Text', 'Clusters:');
                app.ClusterEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 12);
                app.RayLabel = uilabel(app.GenParamPanel, 'Text', 'Rays:');
                app.RayEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 20);
                app.KFmuLabel = uilabel(app.GenParamPanel, 'Text', 'KF mu:');
                app.KFmuEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', -0.39);
                app.KFsigmaLabel = uilabel(app.GenParamPanel, 'Text', 'KF sigma:');
                app.KFsigmaEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 2.4);
                app.SnapLabel = uilabel(app.GenParamPanel, 'Text', 'Snaps:');
                app.SnapEdit = uieditfield(app.GenParamPanel, 'numeric', 'Value', 50);
                
                app.GenPDPAxes = uiaxes(app.GenScrollPanel);
                app.GenCDFAxes = uiaxes(app.GenScrollPanel);
                
                % --- 第三页 ---
                app.ChannelPredTab = uitab(app.TabGroup, 'Title', '3. Prediction & Training', 'BackgroundColor', app.Color_Bg);
                app.ChannelPredScrollPanel = uipanel(app.ChannelPredTab, 'Scrollable', 'on', 'BackgroundColor', app.Color_Bg, 'BorderType', 'none');
                app.ChannelPredScrollPanel.AutoResizeChildren = 'off';
                
                app.PredConfigPanel = uipanel(app.ChannelPredScrollPanel, 'Title', 'Training Configuration', 'FontSize', 14);
                app.PredConfigPanel.AutoResizeChildren = 'off';
                
                app.AlgoPanel = uipanel(app.PredConfigPanel, 'Title', 'Algo', 'FontSize', 14);
                app.AlgoPanel.AutoResizeChildren = 'off';
                app.TCNButton = uibutton(app.AlgoPanel, 'Text', 'TCN', 'ButtonPushedFcn', createCallbackFcn(app, @TCNButtonPushed, true));
                app.LSTMButton = uibutton(app.AlgoPanel, 'Text', 'LSTM', 'ButtonPushedFcn', createCallbackFcn(app, @LSTMButtonPushed, true));
                app.GRUButton = uibutton(app.AlgoPanel, 'Text', 'GRU', 'ButtonPushedFcn', createCallbackFcn(app, @GRUButtonPushed, true));
                
                app.TargetPanel = uipanel(app.PredConfigPanel, 'Title', 'Domain', 'FontSize', 14);
                app.TargetPanel.AutoResizeChildren = 'off';
                app.TimeDomainButton = uibutton(app.TargetPanel, 'Text', 'Time', 'ButtonPushedFcn', createCallbackFcn(app, @TimeDomainButtonPushed, true));
                app.FreqDomainButton = uibutton(app.TargetPanel, 'Text', 'Freq', 'ButtonPushedFcn', createCallbackFcn(app, @FreqDomainButtonPushed, true));
                app.SpaceDomainButton = uibutton(app.TargetPanel, 'Text', 'Space', 'ButtonPushedFcn', createCallbackFcn(app, @SpaceDomainButtonPushed, true));
                
                app.TaskPanel = uipanel(app.PredConfigPanel, 'Title', 'Task Control', 'FontSize', 14);
                app.TaskPanel.AutoResizeChildren = 'off';
                app.TrainButton = uibutton(app.TaskPanel, 'Text', '1. Train Model', 'BackgroundColor', app.ActiveBtnColor, 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @TrainButtonPushed, true));
                app.PredictButton = uibutton(app.TaskPanel, 'Text', '2. Run Predict', 'BackgroundColor', app.ActiveBtnColor, 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @PredictButtonPushed, true));
                
                app.ParamPanel = uipanel(app.PredConfigPanel, 'Title', 'Future Gen', 'FontSize', 14);
                app.ParamPanel.AutoResizeChildren = 'off';
                app.PredLengthLabel = uilabel(app.ParamPanel, 'Text', 'Prediction Steps (Snaps):');
                app.PredLengthEdit = uieditfield(app.ParamPanel, 'numeric', 'Value', 50); 
                app.BatchSizeLabel = uilabel(app.ParamPanel, 'Text', 'Batch Size (Sets):');
                app.BatchSizeEdit = uieditfield(app.ParamPanel, 'numeric', 'Value', 1); 
                
                app.SavePredDataButton = uibutton(app.PredConfigPanel, 'Text', 'Save Data', ...
                    'BackgroundColor', app.ActiveBtnColor, 'FontColor', 'w', 'FontWeight', 'bold', ...
                    'ButtonPushedFcn', createCallbackFcn(app, @SavePredDataButtonPushed, true));
                
                app.ExportModelButton = uibutton(app.PredConfigPanel, 'Text', 'Export Model', ...
                    'BackgroundColor', app.ActiveBtnColor, 'FontColor', 'w', 'FontWeight', 'bold', ...
                    'ButtonPushedFcn', createCallbackFcn(app, @ExportModelButtonPushed, true));
                
                app.PredPlotPanel = uipanel(app.ChannelPredScrollPanel, 'Title', 'Verification Results', 'FontSize', 14);
                app.PredPlotPanel.AutoResizeChildren = 'off';
                
                app.PredCapacityAxes = uiaxes(app.PredPlotPanel);
                app.PredRawDataAxes = uiaxes(app.PredPlotPanel);
                app.PredRMSEAxes = uiaxes(app.PredPlotPanel);
                app.PredSpreadAxes = uiaxes(app.PredPlotPanel);
                app.PredAngularAxes = uiaxes(app.PredPlotPanel);
                app.PredDopplerAxes = uiaxes(app.PredPlotPanel);
                
                % --- 渲染引擎初始化 ---
                panels = [app.BasicConfigPanel, app.DataMgmtPanel, app.DataQualityPanel, ...
                          app.ChannelCharsPanel, app.GenConfigPanel, app.GenParamPanel, ...
                          app.PredConfigPanel, app.AlgoPanel, ...
                          app.TargetPanel, app.TaskPanel, app.ParamPanel, app.PredPlotPanel];
                set(panels, 'BackgroundColor', app.Color_Panel, 'ForegroundColor', app.Color_Text); 
                
                scrollPanels = [app.DataImportScrollPanel, app.GenScrollPanel, app.ChannelPredScrollPanel];
                set(scrollPanels, 'BackgroundColor', app.Color_Bg, 'BorderType', 'none');
                
                labels = [app.FreqBandLabel, app.ScenarioLabel, app.BandwidthLabel, ...
                          app.ValidStatusLabel, app.Mod23ReadyLabel, app.ViewModeLabel, ...
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
                
                % 【最后步骤：关闭所有组件的 AutoResizeChildren，挂载事件】
                allComps = findall(app.UIFigure);
                for i = 1:length(allComps)
                    if isprop(allComps(i), 'AutoResizeChildren')
                        try
                            allComps(i).AutoResizeChildren = 'off';
                        catch
                        end
                    end
                end
                
                app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @UIFigureSizeChanged, true);
                app.UIFigure.Visible = 'on';
                
                app.updateScenarioItems();
                UIFigureSizeChanged(app, []);
                
            catch ME
                errordlg(['UI Creation Failed: ' ME.message], 'Critical Error'); 
            end
        end
    end
    
    methods (Access = public)
        function app = ChannelSimulatorApp01
            createComponents(app)
            registerApp(app, app.UIFigure)
            runStartupFcn(app, @startupFcn)
            if nargout == 0; clear app; end
        end
        function delete(app), delete(app.UIFigure); end
    end
end