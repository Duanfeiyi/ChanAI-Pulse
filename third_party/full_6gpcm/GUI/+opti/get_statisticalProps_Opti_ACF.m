function get_statisticalProps_Opti_ACF(app, cm, tx_track, rx_track)
    if isempty(app.Line_Fitting_Meas)
        error('Please import measurement data first!');
    end

    if length(cm.sim_params.carrier_frequency) > 1
        error('Multi-band is not supported');
    end   
    
    loop = 100;
    no_simPoints = min(length(tx_track(1).time_scale), 200);
    deltaT = tx_track(1).time_scale(1: no_simPoints)';    
    % 天线索引
    i_txAntenna = 1;
    i_rxAntenna = 1;
    % 用户索引
    i_txUser = str2num(app.DropDown_txUserIndex.Value);
    i_rxUser = str2num(app.DropDown_rxUserIndex.Value);

    i_carrier = 1;

    [~,band,freq_sample] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
    B = band*1e6;
    d_waitbar = uiprogressdlg(app.ParameterOptimizationUIFigure,'Title', 'Generate the current configuration feature', 'Message','Generating... ...','Cancelable','on');  
    acf = 0;
    no_loop_eff = loop;
    for i_loop = 1:loop
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
        if numel(acf_sim(isnan(acf_sim))) > 0
            no_loop_eff = no_loop_eff - 1;
        else
            acf = acf + acf_sim;
        end

        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end

    acf = acf./max(1, no_loop_eff);
    app.Line_InitialData = plot(app.Figure_Fitting, deltaT, abs(acf)/max(abs(acf)), 'b-','Linewidth',1);
    
    legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData],'Measurement data','Data before optimization');
    app.Figure_Fitting.NextPlot = "add";
end
