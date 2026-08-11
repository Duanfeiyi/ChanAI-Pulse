function get_statisticalProps_Opti_CCF(app, cm, tx_track, rx_track, isTx)
    if isempty(app.Line_Fitting_Meas)
        error('Please import measurement data first!');
    end
    if length(cm.sim_params.carrier_frequency) > 1
        error('Multi-band is not supported');
    end    
    loop = 100;
    
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
    ccf = 0;
    [~,band,freq_sample] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
    B = band*1e6;
    d_waitbar = uiprogressdlg(app.ParameterOptimizationUIFigure,'Title', 'Generate the current configuration feature', 'Message','Generating... ...','Cancelable','on');  
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
        
        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end

    ccf = ccf./max(1, no_loop_eff);
    app.Line_InitialData = plot(app.Figure_Fitting, deltaD, abs(ccf)/max(abs(ccf)), 'b-','Linewidth',1);
    
    legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData],'Measurement data','Data before optimization');
    app.Figure_Fitting.NextPlot = "add";
end
