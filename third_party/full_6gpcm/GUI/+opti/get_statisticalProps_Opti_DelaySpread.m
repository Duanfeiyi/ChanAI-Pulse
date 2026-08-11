function get_statisticalProps_Opti_DelaySpread(app, cm, tx_track, rx_track)
    if isempty(app.Line_Fitting_Meas)
        error('Please import measurement data first!');
    end
    if length(cm.sim_params.carrier_frequency) > 1
        error('Multi-band is not supported');
    end    

    % 天线索引
    i_txAntenna = 1;
    i_rxAntenna = 1;
    % 用户索引
    i_txUser = str2num(app.DropDown_txUserIndex.Value);
    i_rxUser = str2num(app.DropDown_rxUserIndex.Value);

    i_snap = 1; % 第一个点
    [tx_track, rx_track] = mf.get_x_snap_track(i_snap, tx_track, rx_track);
    loop = 100;
    [~,band,freq_sample] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
    %加一个判断

    B = band*1e6;
    delay_spread = zeros(length(cm.sim_params.carrier_frequency),loop);
    d_waitbar = uiprogressdlg(app.ParameterOptimizationUIFigure, 'Title', 'Simulation of frequency- and delay-domain channel statistical properties', 'Message', 'Simulating... ...', 'Cancelable','on');

    for i_loop = 1:loop
        [ result, delay, ~, ~]  = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, [], [], B, freq_sample);
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

        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end
    close(d_waitbar);

    [x_ds,c_ds] = mf.calc_cdf(delay_spread,100);
    app.Line_InitialData = plot(app.Figure_Fitting, x_ds,c_ds, 'b-','Linewidth',1);

    legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData],'Measurement data','Data before optimization');
    app.Figure_Fitting.NextPlot = "add";
end
