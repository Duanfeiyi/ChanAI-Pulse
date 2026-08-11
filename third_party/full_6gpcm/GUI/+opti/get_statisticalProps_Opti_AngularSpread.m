function get_statisticalProps_Opti_AngularSpread(app, cm, tx_track, rx_track, isTx)
    if isempty(app.Line_Fitting_Meas)
        error('Please import measurement data first!');
    end
    if length(cm.sim_params.carrier_frequency) > 1
        error('Multi-band is not supported');
    end      
    loop = 100;
    angular_spread = zeros(1,loop);

    i_txUser = str2num(app.DropDown_txUserIndex.Value);
    i_rxUser = str2num(app.DropDown_rxUserIndex.Value);
    i_txAntenna = 1;
    i_rxAntenna = 1;
    i_carrier = 1;
    i_snap = 1; % 取第1个时间点的track量
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

        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end

    % Plot angular spreads

    [x_as,c_as] = mf.calc_cdf(angular_spread,100);
    app.Line_InitialData = plot(app.Figure_Fitting, x_as,c_as, 'b-','Linewidth',1);

    legend(app.Figure_Fitting,[app.Line_Fitting_Meas,app.Line_InitialData],'Measurement data','Data before optimization');
    app.Figure_Fitting.NextPlot = "add";
end
