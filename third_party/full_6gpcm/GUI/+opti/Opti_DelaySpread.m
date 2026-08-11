function Opti_DelaySpread(app, cm, tx_track, rx_track)
loop = 50;
delay_spread = zeros(1,loop);
Opti_loop_num = app.LoopNum.Value; %循环次数 由用户设置

% tx_track.samp_rate = 2;
% rx_track.samp_rate = 2;%% Delay spread

% 天线索引
i_txAntenna = 1;
i_rxAntenna = 1;
% 用户索引
i_txUser = str2num(app.DropDown_txUserIndex.Value);
i_rxUser = str2num(app.DropDown_rxUserIndex.Value);
i_snap = 1; % 取第1个时间点的track量
[tx_track, rx_track] = mf.get_x_snap_track(i_snap, tx_track, rx_track);

[~,band,freq_sample] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
B = band*1e6;
d_waitbar = uiprogressdlg(app.ParameterOptimizationUIFigure, 'Title', 'Simulation of frequency- and delay-domain channel statistical properties', 'Message', 'Simulating... ...', 'Cancelable','on');
%计算当前配置下的MSE
for i_loop = 1:loop
    [ result, delay, ~, ~]  = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track,[], [], B, freq_sample);
    if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
        [H, delay] = mf.result2H(result(i_txUser,i_rxUser,:), delay(i_txUser,i_rxUser,:)); % B5G中的H no_txAntenna * no_rxAntenna * snaps * m*n
        H_CTF = mf.H2ctf(H, freq_sample, B, delay); % H, freq_sample, B, delay,
        h_CIR = ifft(H_CTF, [], 4);
    else
        h_CIR = result{i_txUser, i_rxUser};
    end

    delay_PSD = abs(squeeze(h_CIR(i_txAntenna, i_rxAntenna, i_snap, :))).^2;
    taus = (0 : freq_sample - 1) / B;
    [ ds, ~ ] = mf.calc_ds( taus, delay_PSD.' );
    delay_spread(i_loop) = ds*1e9;

end

[x_ds,c_ds] = mf.calc_cdf(delay_spread,loop);

%当前（最小）误差
Min_MSE = tools.cal_MSE(app.MeasureData.x,app.MeasureData.y,x_ds,c_ds);
%显示当前参数

Initial_value_d_Rx_min = cm.sim_params.scen_para.d_Rx_min;
Best_value_d_Rx_min = cm.sim_params.scen_para.d_Rx_min;
opt_range_d_Rx_min = linspace(Initial_value_d_Rx_min/2,Initial_value_d_Rx_min*1.5,Opti_loop_num);

Initial_value_d_Rx_mean = cm.sim_params.scen_para.d_Rx_mean;
Best_value_d_Rx_mean = cm.sim_params.scen_para.d_Rx_mean;
opt_range_d_Rx_mean = linspace(Initial_value_d_Rx_mean/2,Initial_value_d_Rx_mean*1.5,Opti_loop_num);

Initial_value_d_Tx_min = cm.sim_params.scen_para.d_Tx_min;
Best_value_d_Tx_min = cm.sim_params.scen_para.d_Tx_min;
opt_range_d_Tx_min = linspace(Initial_value_d_Tx_min/2,Initial_value_d_Tx_min*1.5,Opti_loop_num);

Initial_value_d_Tx_mean = cm.sim_params.scen_para.d_Tx_mean;
Best_value_d_Tx_mean = cm.sim_params.scen_para.d_Tx_mean;
opt_range_d_Tx_mean = linspace(Initial_value_d_Tx_mean/2,Initial_value_d_Tx_mean*1.5,Opti_loop_num);

error_MSE = zeros(1,Opti_loop_num * 2);
i_judge = 1;
for Opti_loop = 1:Opti_loop_num * 2  %优化循环

    %设置优化参数

    % 1）首末跳簇和天线的距离
    %    d_Rx_min、d_Rx_mean、d_Tx_min、d_Tx_mean
    % 2）高斯分布的平均值
    %    Tsigmax、Tsigmay、Tsigmaz、Rsigmax、Rsigmay、Rsigmaz

    %先尝试1）d_Rx_min、d_Rx_mean、d_Tx_min、d_Tx_mean

    for i_loop = 1:loop  % 计算Delay Spread
        [ result, delay, ~, ~]  = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track);
        if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
            [H, delay] = mf.result2H(result(i_txUser,i_rxUser,:), delay(i_txUser,i_rxUser,:)); % B5G中的H no_txAntenna * no_rxAntenna * snaps * m*n
        else
            result_select = result{i_txUser,i_txUser};
            delay_select = delay{i_txUser,i_txUser};
            H = result_select;
            delay = delay_select;
        end
        H_CTF = mf.H2ctf(H, freq_sample, B, delay); % H, freq_sample, B, delay,
        h_CIR = ifft(H_CTF, [], 4);

        delay_PSD = abs(squeeze(h_CIR(i_txAntenna, i_rxAntenna, i_snap, :))).^2;
        taus = (0 : freq_sample - 1) / B;
        [ ds, ~ ] = mf.calc_ds( taus, delay_PSD.' );
        delay_spread(i_loop) = ds*1e9;
    end
    [x_ds,c_ds] = mf.calc_cdf(delay_spread,100);
    if ishandle(app.Line_InitialData)
        app.Line_InitialData = plot(app.Figure_Fitting, x_ds,c_ds, 'b-','Linewidth',1);
        legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData],'Measurement data','Initial configuration');
        app.Figure_Fitting.NextPlot = "add";
    end

    if i_judge <= Opti_loop_num
        cm.sim_params.scen_para.d_Rx_min = opt_range_d_Rx_min(Opti_loop);
        cm.sim_params.scen_para.d_Rx_mean = opt_range_d_Rx_mean(Opti_loop);
        %计算误差
        error_MSE(Opti_loop) = tools.cal_MSE(app.MeasureData.x,app.MeasureData.y,x_ds,c_ds);
        %比较误差
        if error_MSE(Opti_loop) < Min_MSE

            Min_MSE = error_MSE(Opti_loop);
            Best_value_d_Rx_min = cm.sim_params.scen_para.d_Rx_min; %用于展示参数表
            Best_value_d_Rx_mean = cm.sim_params.scen_para.d_Rx_mean; %用于展示参数表
        end
    end

    if i_judge > Opti_loop_num && i_judge <= Opti_loop_num * 2
        Opti_loop_d_Tx = Opti_loop - Opti_loop_num;
        cm.sim_params.scen_para.d_Tx_min = opt_range_d_Tx_min(Opti_loop_d_Tx);
        cm.sim_params.scen_para.d_Tx_mean = opt_range_d_Tx_mean(Opti_loop_d_Tx);

        %计算误差
        error_MSE(Opti_loop) = tools.cal_MSE(app.MeasureData.x,app.MeasureData.y,x_ds,c_ds);

        plot(app.Figure_Fitting,x_ds,c_ds, '--','Color',[0.5 0.5 0.5],'Linewidth',0.5);
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
            Best_value_d_Tx_min = cm.sim_params.scen_para.d_Tx_min; %用于展示参数表
            Best_value_d_Tx_mean = cm.sim_params.scen_para.d_Tx_mean; %用于展示参数表
        end
        %更新当前最优结果，包括画图和参数表(图已更新，张惟天更新参数表)
        if ~isempty(app.Line_BestData)
            delete(app.Line_BestData);
        end

        app.Line_BestData = plot(app.Figure_Fitting,x_ds,c_ds,'r-','LineWidth',1.2);
        app.Figure_Fitting.NextPlot = "add";
        legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData,app.Line_BestData],'Measurement data','Initial configuration','Configuration after optimization');
        app.settings.Value = '';
        opti.show_check_allsettings_Opti(app, app.CallingApp.scenarios,Best_value_d_Rx_min, Best_value_d_Rx_mean, Best_value_d_Tx_min, Best_value_d_Tx_mean);
    end

    i_judge = i_judge + 1;
    d_waitbar.Value = Opti_loop/(Opti_loop_num * 2);
    if d_waitbar.CancelRequested
        close(d_waitbar);
        return;
    end
end
end