function get_statisticalProps_Opti_DopplerSpread(app, cm, tx_track, rx_track)
    if isempty(app.Line_Fitting_Meas)
        error('Please import measurement data first!');
    end
    if length(cm.sim_params.carrier_frequency) > 1
        error('Multi-band is not supported');
    end    
    loop = 100;
    doppler_spread = zeros(1,loop);
    no_simPoints = min(length(tx_track(1).time_scale), 200);
    deltaT = tx_track(1).time_scale(1: no_simPoints)';
    % 天线索引
    i_txAntenna = 1;
    i_rxAntenna = 1;

    % 用户索引
    i_txUser = str2num(app.DropDown_txUserIndex.Value);
    i_rxUser = str2num(app.DropDown_rxUserIndex.Value);

    tx_speed_user = tx_track(i_txUser).move_speed(1);
    rx_speed_user = rx_track(i_rxUser).move_speed(1);

    i_carrier = 1;
    [~,band,freq_sample] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
    B = band*1e6;


    if tx_speed_user == 0 && rx_speed_user == 0
        error('When simulating time- and Doppler- domain channel statistical properties, the speed of Tx or Rx should not be 0');
    end
    for i_freq = 1:length(cm.sim_params.carrier_frequency)
        fDmax = (tx_speed_user + rx_speed_user)/cm.sim_params.wavelength(i_freq);
    end

    d_waitbar = uiprogressdlg(app.ParameterOptimizationUIFigure, 'Title', 'Simulation of time- and Doppler-domain channel statistical properties', 'Message','Simulating ... ...','Cancelable','on');
    for i_loop = 1: loop
        [ result, delay, ~, ~]  = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track,[], [], B, freq_sample);
        if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
            [H, delay] = mf.result2H(result(i_txUser,i_rxUser,:), delay(i_txUser,i_rxUser,:)); % B5G中的H no_txAntenna * no_rxAntenna * snaps * m*n
            H_CTF = mf.H2ctf(H, freq_sample, B, delay); % H, freq_sample, B, delay,
        else
            h_CIR = result{i_txUser, i_rxUser};
            H_CTF = fft(h_CIR,[],4); % calculation based on the CTF matrix
        end

        % Calculate ACF
        h = squeeze(H_CTF(i_txAntenna, i_rxAntenna,1:length(deltaT), i_carrier)); % 第几对天线 TODO 可调
        acf_sim = h(1)' * h.' / abs(h(1)) ./ abs(h.');

        % Calculate DS
        doppler = linspace(-fDmax,fDmax,length(deltaT));
        [doppler, doppler_PSD] = cp.get_DopplerPSD(deltaT.', acf_sim.', doppler);
        [ dopplers, ~ ] = mf.calc_ds( doppler, doppler_PSD);
        doppler_spread(i_loop) = dopplers;

        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end
    close(d_waitbar);

    [x_doppler_spread,c_doppler_spread] = mf.calc_cdf(doppler_spread,100);
    app.Line_InitialData = plot(app.Figure_Fitting, x_doppler_spread,c_doppler_spread, 'b-','Linewidth',1);

    legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData],'Measurement data','Data before optimization');
    app.Figure_Fitting.NextPlot = "add";
end
