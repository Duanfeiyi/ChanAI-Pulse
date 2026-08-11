function get_statisticalProps_time(app, cm, deltaT, owc, tx_track, rx_track, ris, cm_l)
% 所有仿真图复位
cla(app.UIAxes_TACF);
cla(app.UIAxes_cohTime);
cla(app.UIA_DopplerPSD);
cla(app.UIADopplerSpread);
cla(app.UIAxes_SI);
cla(app.UIAxes_LCRt);

% 天线索引
i_txAntenna = str2double(app.DropDown_txAntennaIndex.Value);
i_rxAntenna = str2double(app.DropDown_rxAntennaIndex.Value);

% 用户索引
i_txUser = str2num(app.DropDown_txUserIndex.Value);
i_rxUser = str2num(app.DropDown_rxUserIndex.Value);

tx_speed_user = tx_track(i_txUser).move_speed(1);
rx_speed_user = rx_track(i_rxUser).move_speed(1);

i_carrier = 1;
loop = app.EditField_loop.Value;
[freqs, bandwidth, freq_samples] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
freq_sample = freq_samples(1);
if length(freq_sample) == 1
    freq_sample = repmat(freq_sample,1,length(freqs));
end
if length(bandwidth) == 1
    bandwidth = repmat(bandwidth,1,length(freqs));
end
B = bandwidth*1e6;

if tx_speed_user == 0 && rx_speed_user == 0
    %app.CallingApp.txSpeed.Value == 0 && app.CallingApp.rxSpeed.Value == 0
    error('When simulating time- and Doppler- domain channel statistical properties, the speed of Tx or Rx should not be 0');
end
for i_freq = 1:length(freqs)
    %fDmax = (app.CallingApp.txSpeed.Value + app.CallingApp.rxSpeed.Value)/cm.sim_params.wavelength(i_freq);
    fDmax = (tx_speed_user + rx_speed_user)/cm.sim_params.wavelength(i_freq);
    fD(:,i_freq) = -fDmax:(2*fDmax/100):fDmax;
end

if tools.is_owc_band(app.CallingApp.scenarios, app.CallingApp)
    %%%%%%%%%%%%%%如果是光无线频段，则去掉右侧两个图
    app.UIAxes_LCRt.Visible = 'off';
    app.UIAxes_SI.Visible = 'off';
    app.UIADopplerSpread.Visible = 'on';
    %%%%%%%%%%%%%%
    owc.LED_no_elements_H = 1;  % 加速计算
    owc.LED_no_elements_V = 1;
    % ACF --- Hnlos_PS
    acf = zeros(loop,length(deltaT));
    doppler_spread = zeros(loop, 1);
    d_waitbar = uiprogressdlg(app.UIFigure,'Title', 'Simulation of time- and Doppler-domain channel statistical properties', 'Message','Simulating... ...','Cancelable','on');
    for i_loop = 1 : loop
        [result, ~] = cm.get_CIR_OWC(owc, tx_track, rx_track);
        H2 = zeros(1,length(deltaT));
        for i = 1:length(deltaT)
            H2(i) = result.Hlos(i_txAntenna, i_rxAntenna, i) + result.Hnlos_PS(i_txAntenna, i_rxAntenna, i) + ...
                sum(result.Hnlos_RE(i_txAntenna, i_rxAntenna, :, i)); % Channel Gain at time t+delta_t
        end
        acf_sim = abs(xcorr(H2));
        acf(i_loop,:) = acf_sim((length(deltaT)):(length(deltaT)*2-1));
        % Third step: Calculate DS
        [fD, doppler_PSD] = cp.get_DopplerPSD(deltaT, sum(acf_sim((length(deltaT)):(length(deltaT)*2-1)), 1)/i_loop, fD);
        doppler = linspace(-fDmax,fDmax,length(fD));
        [ dopplers, ~ ] = mf.calc_ds( doppler, abs(doppler_PSD));
        doppler_spread(i_loop) = dopplers;

        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end
    acf = sum(acf, 1)/loop;
    plot(app.UIAxes_TACF, deltaT, abs(acf)/max(abs(acf)),'-b');

    level = 0:0.03:1;
    CoherTime = zeros(1,length(level));
    for i=1:length(level)
        for j = 1:length(acf)
            if level(i)>acf(j)
                break;
            end
            CoherTime(i) = j*(deltaT(2)-deltaT(1));
        end
    end
    plot(app.UIAxes_cohTime, CoherTime, level,'linewidth', 1);

    [fD, PSDsim] = cp.get_DopplerPSD(deltaT, acf, fD);

    plot(app.UIA_DopplerPSD, fD, 10*log10(abs(PSDsim)),'Linewidth',1);

    % Plot doppler spreads
    [x_doppler_spread, c_doppler_spread] = mf.calc_cdf(doppler_spread, 100);
    
    if min(x_doppler_spread) < max(x_doppler_spread)
        plot(app.UIADopplerSpread, x_doppler_spread,c_doppler_spread, 'Linewidth',1);
        xlim(app.UIADopplerSpread, [min(x_doppler_spread) max(x_doppler_spread)])
    else
        app.UIADopplerSpread.Visible = 'off';
    end
    close(d_waitbar);
else
    app.UIAxes_LCRt.Visible = 'on';
    app.UIAxes_SI.Visible = 'on';
    app.UIADopplerSpread.Visible = 'on';
    %% 其他频段和场景的统计特性计算
    % 以下SMC参数在仿真DMC的时候做过修改，在循环的时候需要更正SMC的参数
    acf = zeros(length(deltaT),length(freqs));
    SI = cell(1,length(freqs));
    if length(freqs) == 1
        SI{1} = [];
    else
        for i_freq = 1:length(freqs)
            SI{i_freq} = [];
        end
    end
    no_loop_eff = loop;
    doppler_spread = zeros(length(freqs),loop);
    % TODO 最大速度
    for i_freq = 1:length(freqs)
        %fDmax(i_freq) = (app.CallingApp.txSpeed.Value + app.CallingApp.rxSpeed.Value)/cm.sim_params.wavelength(i_freq);
        fDmax(i_freq) = (tx_speed_user + rx_speed_user)/cm.sim_params.wavelength(i_freq);
        %xf 0206.20:44
    end
    d_waitbar = uiprogressdlg(app.UIFigure, 'Title', 'Simulation of time- and Doppler-domain channel statistical properties', 'Message','Simulating ... ...','Cancelable','on');
    for i_loop = 1: loop
       % First step: Obtain CIR
        if strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_IIOT)
            h_CIR = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, [], [], B, freq_sample);
            h_CIR = h_CIR{i_txUser, i_rxUser};
            H_CTF = fft(h_CIR,[],4); % calculation based on the CTF matrix
        elseif strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_RIS)
            H_CTF = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, ris,[], B, freq_sample);
            h_CIR = ifft(H_CTF, [], 4);
        elseif strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_ISAC)
            H_CTF = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, [],[], B, freq_sample);
            h_CIR = ifft(H_CTF, [], 4);
        else
            [ result, delay, ~, ~]  = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track,[], cm_l, B, freq_sample);
            if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
                if length(freqs)==1
                    [H, delay] = mf.result2H(result(i_txUser,i_rxUser,:), delay(i_txUser,i_rxUser,:)); % B5G中的H no_txAntenna * no_rxAntenna * snaps * m*n
                    H_CTF = mf.H2ctf(H, freq_sample, B, delay); % H, freq_sample, B, delay,
                    h_CIR = ifft(H_CTF, [], 4);
                end
            else
                h_CIR = result{i_txUser, i_rxUser};
                H_CTF = fft(h_CIR,[],4); % calculation based on the CTF matrix
            end
            if length(freqs)>1
                H_CTF = mf.H2ctf_multiF(result,delay,B,freq_sample);
                h_CIR = cell(size(H_CTF));
                for i_user_tx = 1:size(H_CTF,1)
                    for i_user_rx = 1:size(H_CTF,2)
                        for i_snap = 1:size(H_CTF,3)
                            for i_freq = 1:size(H_CTF,4)
                                h_CIR{i_user_tx,i_user_rx,i_snap,i_freq} = ifft(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq},[],3);
                            end
                        end
                    end
                end
            end
        end

        if length(freqs)==1
            % Second step: Calculate ACF
            h = squeeze(H_CTF(i_txAntenna, i_rxAntenna, 1:length(deltaT), i_carrier)); % 第几对天线 TODO 可调
            acf_sim = h(1)' * h.' / abs(h(1)) ./ abs(h.');
            if numel(acf_sim(isnan(acf_sim))) > 0
                no_loop_eff = no_loop_eff - 1;
            else
                acf = acf + acf_sim.';
            end
            % Third step: Calculate DS
            doppler = linspace(-fDmax,fDmax,length(deltaT));
            [doppler, doppler_PSD] = cp.get_DopplerPSD(deltaT.', acf_sim.', doppler);
            [ dopplers, ~ ] = mf.calc_ds( doppler, doppler_PSD);
            doppler_spread(i_loop) = dopplers;
            % Fourth step: Calculate stationary time
            pdp = abs(squeeze(h_CIR(i_txAntenna, i_rxAntenna,1 :length(deltaT), :))).^2;
            window_size = 5;
            SI{1} = [SI{1}, cp.get_stationary_interval(pdp,window_size,deltaT)];
            signal(i_loop,:) = abs(squeeze(H_CTF(i_txAntenna, i_rxAntenna, 1:length(deltaT), i_carrier)));
        else
            for i_freq = 1:length(freqs)
                for i_snap = 1:length(deltaT)
                    h(i_snap) = squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna, i_carrier));
                end
                acf_sim = h(1)' * h.' / abs(h(1)) ./ abs(h.');
                if numel(acf_sim(isnan(acf_sim))) > 0
                    no_loop_eff = no_loop_eff - 1;
                else
                    acf(:,i_freq) = acf(:,i_freq) +  acf_sim;
                end
                % Third step: Calculate DS
                doppler = linspace(-fDmax(i_freq),fDmax(i_freq),length(deltaT));
                [doppler, doppler_PSD] = cp.get_DopplerPSD(deltaT.', acf_sim, doppler);
                [ dopplers, ~ ] = mf.calc_ds( doppler, doppler_PSD);
                doppler_spread(i_freq,i_loop) = dopplers;
                % Fourth step: Calculate stationary time
                for i_snap = 1:length(deltaT)
                    pdp(i_snap,:) = squeeze(h_CIR{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna, :));
                end
                window_size = 5;
                SI{i_freq} = [SI{i_freq}, cp.get_stationary_interval(pdp,window_size,deltaT)];
            end
            signal(i_loop,:) = abs(squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna,i_carrier)));
        end

        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end
    close(d_waitbar);

    % Plot ACF
    acf = acf./max(1, no_loop_eff);
    for i_freq = 1:length(freqs)
        legend_name{i_freq} = [num2str(freqs(i_freq)),' GHz'];
    end
    if length(freqs) == 1
        plot(app.UIAxes_TACF, deltaT, abs(acf(:,i_freq))/max(abs(acf(:,i_freq))),'linewidth', 1);
        legend(app.UIAxes_TACF,'off')
    else
        cla(app.UIAxes_TACF);
        for i_freq = 1:length(freqs)
            plot(app.UIAxes_TACF, deltaT, abs(acf(:,i_freq))/max(abs(acf(:,i_freq))), 'linewidth', 1); hold(app.UIAxes_TACF,'on');
        end
        legend(app.UIAxes_TACF,legend_name);
    end

    % Calculate and plot coherence time
    c_th = 0.01:0.01:1;
    coherTime = zeros(1, length(c_th));
    tDelta = deltaT(2) - deltaT(1);
    cla(app.UIAxes_cohTime);
    for i_freq = 1:length(freqs)
        acf_abs = abs(acf(:,i_freq))/max(abs(acf(:,i_freq)));
        for c_th_index = 1 : length(c_th)
            min_index = find( acf_abs < c_th(c_th_index), 1 ); % 第一个小于门限值的是第几个点
            if isempty(min_index)
                coherTime(c_th_index) = deltaT(end) - deltaT(1);
                continue;
            end
            coherTime(c_th_index) = min(min_index * tDelta, deltaT(end));
        end
        plot(app.UIAxes_cohTime, coherTime, c_th,'Linewidth',1); hold(app.UIAxes_cohTime,'on');
    end
    if length(freqs)>1
        legend(app.UIAxes_cohTime,legend_name);
    else
        legend(app.UIAxes_cohTime,'off')
    end
    ylim(app.UIAxes_cohTime, [min(c_th) max(c_th)]);
    xlabel(app.UIAxes_cohTime,'Coherence time (s)');

    % Calculate and plot doppler PSD
    cla(app.UIA_DopplerPSD);
    for i_freq = 1:length(freqs)
        [fD2, PSDsim] = cp.get_DopplerPSD(deltaT.', acf(:,i_freq), fD(:,i_freq));
        plot(app.UIA_DopplerPSD, fD2, 10*log10(abs(PSDsim)),'Linewidth',1); hold(app.UIA_DopplerPSD,'on');
        xlim(app.UIA_DopplerPSD, [min(fD2) max(fD2)]);
    end
    if length(freqs)>1
        legend(app.UIA_DopplerPSD,legend_name);
    else
        legend(app.UIA_DopplerPSD,'off')
    end

    % Plot doppler spreads
    cla(app.UIADopplerSpread);
    xlim_max = 0;
    for i_freq = 1:length(freqs)
        [x_doppler_spread,c_doppler_spread] = mf.calc_cdf(doppler_spread(i_freq,:), 100);
        plot(app.UIADopplerSpread, x_doppler_spread,c_doppler_spread, 'Linewidth',1); hold(app.UIADopplerSpread,'on');
        if i_freq == 1
            xlim_min = min(x_doppler_spread);
        end
        xlim_min = min(min(x_doppler_spread),xlim_min);
        xlim_max = max(max(x_doppler_spread),xlim_max);
    end
    xlim(app.UIADopplerSpread, [xlim_min xlim_max]);
    if length(freqs)>1
        legend(app.UIADopplerSpread,legend_name);
    else
        legend(app.UIADopplerSpread,'off')
    end

    if length(freqs)==1
        % Plot LCR time
        num_thresholds = 500;
        % LCR_time = zeros(num_freqs, num_thresholds);
        max_signal = max(signal(:));
        max_deltaT = max(deltaT);
        threshold = linspace(0, max_signal, num_thresholds);
        
        for i_loop=1:loop
            sample = length(deltaT)-1;
            T = max_deltaT;
            for thre_index = 1:length(threshold)
                thre = threshold(thre_index);
                crossings = sum((signal(i_loop,1:sample-1) > thre) & (signal(i_loop,2:sample) <= thre));
                LCR_time(i_loop,thre_index) = crossings / T;
            end
        end
        avg_LCR_time = mean(LCR_time, 1);
        plot(app.UIAxes_LCRt, threshold, avg_LCR_time,'linewidth',1);
        legend(app.UIAxes_LCRt,'off')
        xlim(app.UIAxes_LCRt, [0, max(0.0001, max_signal)]);
        ylim(app.UIAxes_LCRt, [0, max(0.0001, max(avg_LCR_time(:)))]*1.2);
    else
        cla(app.UIAxes_LCRt);
        for i_freq = 1:length(freqs)
            for i_snap = 1:length(deltaT)
                signal(i_snap) = abs(squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna, i_carrier)));
            end
            max_signal = max(signal);
            max_deltaT = max(deltaT);

            threshold = linspace(0, max_signal, 500);
            sample = length(deltaT)-1;
            T = max_deltaT;
            LCR_time = zeros(1, length(threshold));

            for thre_index = 1:length(threshold)
                thre = threshold(thre_index);
                crossings = sum((signal(1:sample-1) > thre) & (signal(2:sample) <= thre));
                LCR_time(thre_index) = crossings / T;
            end
            plot(app.UIAxes_LCRt, threshold, LCR_time,'linewidth',1); hold(app.UIAxes_LCRt,'on');
        end
        legend(app.UIAxes_LCRt,legend_name);
        xlim(app.UIAxes_LCRt, [0, max(0.0001, max_signal)]);
        ylim(app.UIAxes_LCRt, [0, max(0.0001, max(LCR_time))]);
    end

    % Plot stationary time
    if isempty(SI) || isempty(SI{1})
        plot(app.UIAxes_SI, 0, 0, 'b-','Linewidth',1);
        error('When simulating the stationary time, the number of simulation snaps is too small, please increase the setting');
    elseif sum(SI{1}) == 0
        text(0.5, 0.5, 'The channel is stationary', 'Parent', app.UIAxes_SI, 'FontSize', 14, 'Color', [1, 0, 0], 'HorizontalAlignment', 'center');
    else
        cla(app.UIAxes_SI);
        for i_freq = 1:length(freqs)
            [x_si,c_si] = mf.calc_cdf(SI{i_freq},1000);
            plot(app.UIAxes_SI, x_si,c_si,'Linewidth',1); hold(app.UIAxes_SI,'on') ;
        end
        if length(freqs)>1
            legend(app.UIAxes_SI,legend_name);
        else
            legend(app.UIAxes_SI,'off')
        end
        xlim(app.UIAxes_SI,[0, max([0.0001 x_si])]);
        ylim(app.UIAxes_SI,[0, max([0.0001 c_si])]);
    end
end
end