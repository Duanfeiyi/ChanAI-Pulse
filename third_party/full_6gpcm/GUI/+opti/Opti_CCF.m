function Opti_CCF(app, cm, tx_track, rx_track, isTx)
    loop = 50;
    Opti_loop_num = app.LoopNum.Value; %循环次数 由用户设置
    scen_para = cm.sim_params.scen_para;

    % 天线索引
    i_txAntenna = 1;
    i_rxAntenna = 1;

    % 用户索引
    i_txUser = str2num(app.DropDown_txUserIndex.Value);
    i_rxUser = str2num(app.DropDown_rxUserIndex.Value);

    i_snap = 1; % 取第1个时间点的track量
    i_carrier = 1;
    [tx_track, rx_track] = mf.get_x_snap_track(i_snap, tx_track, rx_track);
    [~,band,freq_sample] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
    B = band*1e6;
    d_waitbar = uiprogressdlg(app.ParameterOptimizationUIFigure,'Title', 'Parameter optimization', 'Message','Optimizing... ...','Cancelable','on'); 
    if isTx
        if cm.tx_array(1).no_elements < 4
            warndlg('Warning: the number of antenna elements at the Tx < 4, please increase the setting to analyze spatial and angular channel statistical properties', "Inappropriate parameter setting", "model");
            return;
        end
        for i_freq = 1:length(cm.sim_params.carrier_frequency)
            deltaD(i_freq,:) = linspace(0, cm.tx_array(i_txUser).no_elements-1, cm.tx_array(i_txUser).no_elements)...
                * cm.tx_array(i_txUser).element_spacing * app.CallingApp.sps.wavelength(i_freq);
            if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
                prob_death(:,i_freq) = exp(-scen_para.lambdaR * deltaD(i_freq,:) * cos(cm.tx_array(i_txUser).elevation_angle)/30)';  % scen_para.Corr_distance_A
            else
                prob_death(:,i_freq) = 1;
            end
        end
        i_rxAntenna = i_rxUser;
    else
        if cm.rx_array(1).no_elements < 4
            warndlg('Warning: the number of antenna elements at the Rx < 4, please increase the setting to analyze spatial and angular channel statistical properties', "Inappropriate parameter setting", "model");
            return;
        end
        for i_freq = 1:length(cm.sim_params.carrier_frequency)
            deltaD(i_freq,:) = linspace(0, cm.rx_array(i_rxUser).no_elements-1, cm.rx_array(i_rxUser).no_elements)...
                * cm.rx_array(i_rxUser).element_spacing * app.CallingApp.sps.wavelength(i_freq);
            if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
                prob_death(:,i_freq) = exp(-scen_para.lambdaR * deltaD(i_freq,:) * cos(cm.tx_array(i_rxUser).elevation_angle)/30)';  % scen_para.Corr_distance_A
            else
                prob_death(:,i_freq) = 1;
            end
        end
        i_txAntenna = i_txUser;
    end
    %计算当前配置下的MSE
    ccf = 0;
    no_loop_eff = loop;
    for i_loop = 1:loop  % 计算CCF
        [ result, delay, ~, ~]  = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track,[], [], B, freq_sample);
        if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
            [H, delay] = mf.result2H(result(i_txUser,i_rxUser,:), delay(i_txUser,i_rxUser,:)); % B5G中的H no_txAntenna * no_rxAntenna * snaps * m*n
            H_CTF = mf.H2ctf(H, freq_sample, B, delay); % H, freq_sample, B, delay,
        else
            h_CIR = result{i_txUser, i_rxUser};
            H_CTF = fft(h_CIR,[],4); % calculation based on the CTF matrix
        end
        h = squeeze(H_CTF(:, :, i_snap, i_carrier)); % 第几个时间点 TODO 可调
        if isTx
            ccf_sim = h(1,i_rxAntenna)' * h(:,i_rxAntenna) / abs(h(1,i_rxAntenna)) ./ abs(h(:,i_rxAntenna)); % TODO 可调
        else
            ccf_sim = h(i_txAntenna,1) * h(i_txAntenna,:)' / abs(h(i_txAntenna,1)) ./ abs(h(i_txAntenna,:)'); % TODO 可调
        end
        if numel(ccf_sim(isnan(ccf_sim))) > 0
            no_loop_eff = no_loop_eff - 1;
        else
            ccf = ccf + ccf_sim .* prob_death;
        end

    end

    ccf = ccf./max(1, no_loop_eff);
    %当前（最小）误差
    Min_MSE = tools.cal_MSE(app.MeasureData.x,app.MeasureData.y,deltaD,abs(ccf)/max(abs(ccf)));
    %显示当前参数

    Initial_value_d_Rx_min = cm.sim_params.scen_para.d_Rx_min;
    Best_value_d_Rx_min = cm.sim_params.scen_para.d_Rx_min;
    opt_range_d_Rx_min = linspace(Initial_value_d_Rx_min/2,Initial_value_d_Rx_min*1.5,Opti_loop_num);

    error_MSE = zeros(1,Opti_loop_num);

    for Opti_loop = 1:Opti_loop_num   %优化循环

        %设置优化参数
        
        % 1）首末跳簇和天线的距离
        %    d_Rx_min、d_Rx_mean、d_Tx_min、d_Tx_mean 
        % 2）高斯分布的平均值
        %    Tsigmax、Tsigmay、Tsigmaz、Rsigmax、Rsigmay、Rsigmaz
        
        %先尝试1）d_Rx_min、d_Rx_mean、d_Tx_min、d_Tx_mean 


        cm.sim_params.scen_para.d_Rx_min = opt_range_d_Rx_min(Opti_loop);
        cm.sim_params.scen_para.d_Rx_mean = opt_range_d_Rx_min(Opti_loop);
        cm.sim_params.scen_para.d_Tx_min = opt_range_d_Rx_min(Opti_loop);
        cm.sim_params.scen_para.d_Tx_mean = opt_range_d_Rx_min(Opti_loop);
        ccf = 0;
        no_loop_eff = loop;
        for i_loop = 1:loop  % 计算CCF
    
            [ result, delay, ~, ~]  = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, [], [], B, freq_sample);
            if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
                [H, delay] = mf.result2H(result(i_txUser,i_rxUser,:), delay(i_txUser,i_rxUser,:)); % B5G中的H no_txAntenna * no_rxAntenna * snaps * m*n
            else
                result_select = result{1,1};
                delay_select = delay{1,1};
                H = result_select;
                delay = delay_select;
            end
            H_CTF = mf.H2ctf(H, freq_sample, B, delay); % H, freq_sample, B, delay,
            h = squeeze(H_CTF(:, :, i_snap, i_carrier)); % 第几个时间点 TODO 可调
            if isTx
                ccf_sim = h(1,i_rxAntenna)' * h(:,i_rxAntenna) / abs(h(1,i_rxAntenna)) ./ abs(h(:,i_rxAntenna)); % TODO 可调
            else
                ccf_sim = h(i_txAntenna,1) * h(i_txAntenna,:)' / abs(h(i_txAntenna,1)) ./ abs(h(i_txAntenna,:)'); % TODO 可调
            end
            if numel(ccf_sim(isnan(ccf_sim))) > 0
                no_loop_eff = no_loop_eff - 1;
            else
                ccf = ccf + ccf_sim .* prob_death;
            end
    
        end
        ccf = ccf./max(1, no_loop_eff);
        if ishandle(app.Line_InitialData)
            app.Line_InitialData = plot(app.Figure_Fitting, deltaD, abs(ccf)/max(abs(ccf)), 'b-','Linewidth',1);
            legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData],'Measurement data','Initial configuration');
            app.Figure_Fitting.NextPlot = "add";
        end
        %计算误差
        error_MSE(Opti_loop) = tools.cal_MSE(app.MeasureData.x,app.MeasureData.y,deltaD,abs(ccf)/max(abs(ccf)));
        plot(app.Figure_Fitting,deltaD, abs(ccf)/max(abs(ccf)), '--','Color',[0.5 0.5 0.5],'Linewidth',0.5);
        if ~ishandle(app.Line_BestData)
            legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData],'Measurement data','Initial configuration');
        else
            legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData,app.Line_BestData],'Measurement data','Initial configuration','Configuration after optimization');
        end
        drawnow;
        app.Figure_Fitting.NextPlot = "add";

        %比较误差
        if error_MSE(Opti_loop) < Min_MSE

            Min_MSE = error_MSE(Opti_loop);
            Best_value_d_Rx_min = cm.sim_params.scen_para.d_Rx_min; %用于展示参数表
            Best_value_d_Rx_mean = cm.sim_params.scen_para.d_Rx_mean; %用于展示参数表
            Best_value_d_Tx_min = cm.sim_params.scen_para.d_Tx_min; %用于展示参数表
            Best_value_d_Tx_mean = cm.sim_params.scen_para.d_Tx_mean; %用于展示参数表
            if ~isempty(app.Line_BestData)
                delete(app.Line_BestData);
            end
            
            app.Line_BestData = plot(app.Figure_Fitting,deltaD,abs(ccf)/max(abs(ccf)),'r-','LineWidth',1.2);
            app.Figure_Fitting.NextPlot = "add";
            legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData,app.Line_BestData],'Measurement data','Initial configuration','Configuration after optimization');
            app.settings.Value = ''; 
            % opti.show_check_allsettings_Opti(app, app.CallingApp.scenarios,Best_value_d_Rx_min, Best_value_d_Rx_mean, Best_value_d_Tx_min, Best_value_d_Tx_mean);
            %更新当前最优结果，包括画图和参数表(图已更新，张惟天更新参数表)
        end
        d_waitbar.Value = Opti_loop/Opti_loop_num;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end
end