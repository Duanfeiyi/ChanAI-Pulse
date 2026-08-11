function Opti_AngularSpread(app, cm, tx_track, rx_track, isTx)
    loop = 100;
    angular_spread = zeros(1,loop);
    Opti_loop_num = app.LoopNum.Value; %循环次数 由用户设置

    i_txAntenna = 1;
    i_rxAntenna = 1;

    i_txUser = str2num(app.DropDown_txUserIndex.Value);
    i_rxUser = str2num(app.DropDown_rxUserIndex.Value);

    i_snap = 1; % 取第1个时间点的track量
    i_carrier = 1;
    [tx_track, rx_track] = mf.get_x_snap_track(i_snap, tx_track, rx_track);

    [~,band,freq_sample] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
    B = band*1e6;
    % d_waitbar = uiprogressdlg(app.UIFigure,'Title', 'Generate the current configuration feature', 'Message','Generating... ...','Cancelable','on');
    d_waitbar = uiprogressdlg(app.ParameterOptimizationUIFigure,'Title', 'Simulation of spatial and angular channel statistical properties', 'Message','Simulating ... ...','Cancelable','on');

    if isTx
        if cm.tx_array(1).no_elements < 4
            warndlg('Warning: the number of antenna elements at the Tx < 4, please increase the setting to analyze spatial and angular channel statistical properties', "Inappropriate parameter setting", "model");
            return;
        end
    else
        if cm.rx_array(1).no_elements < 4
            warndlg('Warning: the number of antenna elements at the Rx < 4, please increase the setting to analyze spatial and angular channel statistical properties', "Inappropriate parameter setting", "model");
            return;
        end
    end

    %计算当前配置下的MSE
    for i_loop = 1:loop  % 计算Angle Spread
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
            h_PAS = h(:,i_rxAntenna).' ;
        else
            h_PAS = h(i_txAntenna,:);
        end
        phi = linspace(-90, 90, 100);
        ula_col = 0 : length(h_PAS) - 1;
        angular_PSD = zeros(length(phi),1);
        for k1 = 1:length(phi)
            a = exp(-1j*2*pi*0.5*sind(phi(k1))*ula_col);
            angular_PSD(k1,1) = abs(conj(a)*h_PAS'*h_PAS*a.'/(a*a'));
        end
        as = mf.calc_ds( phi, angular_PSD.' );
        angular_spread(i_loop) = as;    
    end
    [x_as,c_as] = mf.calc_cdf(angular_spread,100);
    
    %当前（最小）误差
    Min_MSE = tools.cal_MSE(app.MeasureData.x,app.MeasureData.y,x_as,c_as);
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
        
        for i_loop = 1:loop 
            [ result, delay, ~, ~]  = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, [], [], B, freq_sample);
            if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
                [H, delay] = mf.result2H(result(i_txUser,i_rxUser,:), delay(i_txUser,i_rxUser,:)); % B5G中的H no_txAntenna * no_rxAntenna * snaps * m*n
            else
                result_select = result{i_txUser,i_txUser};
                delay_select = delay{i_txUser,i_txUser};
                H = result_select;
                delay = delay_select;
            end
            H_CTF = mf.H2ctf(H, freq_sample, B, delay); % H, freq_sample, B, delay,
            h = squeeze(H_CTF(:, :, i_snap, i_carrier)); % 第几个时间点 TODO 可调
            if isTx
                h_PAS = h(:,i_rxAntenna).' ;
            else
                h_PAS = h(i_txAntenna,:);
            end
            phi = linspace(-90, 90, 100);
            ula_col = 0 : length(h_PAS) - 1;
            angular_PSD = zeros(length(phi),1);
            for k1 = 1:length(phi)
                a = exp(-1j*2*pi*0.5*sind(phi(k1))*ula_col);
                angular_PSD(k1,1) = abs(conj(a)*h_PAS'*h_PAS*a.'/(a*a'));
            end
            as = mf.calc_ds( phi, angular_PSD.' );
            angular_spread(i_loop) = as;
        end
        [x_as,c_as] = mf.calc_cdf(angular_spread,100);
        if ishandle(app.Line_InitialData)
            app.Line_InitialData = plot(app.Figure_Fitting, x_as,c_as, 'b-','Linewidth',1);
            legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData],'Measurement data','Initial configuration');
            app.Figure_Fitting.NextPlot = "add";
        end
        %计算误差
        error_MSE(Opti_loop) = tools.cal_MSE(app.MeasureData.x,app.MeasureData.y,x_as,c_as);
        plot(app.Figure_Fitting,x_as,c_as, '--','Color',[0.5 0.5 0.5],'Linewidth',0.5);
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
            
            app.Line_BestData = plot(app.Figure_Fitting,x_as,c_as,'r-','LineWidth',1.2);
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
