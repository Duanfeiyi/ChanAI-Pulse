function get_statisticalProps_freq(app, cm, owc, tx_track, rx_track, ris, deltaF, fc, B, freq_sample, cm_l)
% 所有仿真图复位
cla(app.UIAxes_FCF);
cla(app.UIAxes_cohBandWidth);
cla(app.UIA_delayPSD);
cla(app.UIAxes_delaySpread);
cla(app.UIAxes_SB);
cla(app.UIAxes_LCRf);

% 天线索引
i_txAntenna = str2double(app.DropDown_txAntennaIndex.Value);
i_rxAntenna = str2double(app.DropDown_rxAntennaIndex.Value);
% 用户索引
i_txUser = str2num(app.DropDown_txUserIndex_freq.Value);
i_rxUser = str2num(app.DropDown_rxUserIndex_freq.Value);

i_snap = 1; % 第一个点
loop = app.EditField_loop_freq.Value;
for i_freq = 1:length(fc)
    f{i_freq} = linspace(fc(i_freq), fc(i_freq)+B(i_freq), freq_sample(i_freq));
end
    
if tools.is_owc_band(app.CallingApp.scenarios, app.CallingApp)
    %% 光无线频段
    app.UIAxes_LCRf.Visible = 'off'; % 则去掉右侧两个图
    app.UIAxes_SB.Visible = 'off';
    % FCF
    fcf = zeros(loop,length(deltaF));
    d_waitbar = uiprogressdlg(app.UIFigure, 'Title', 'Simulation of frequency- and delay-domain channel statistical properties', 'Message', 'Simulating... ...', 'Cancelable','on');
    freqs = mf.str2frequencys(app.CallingApp.EditField.Value, app.CallingApp.bandwidth.Value, app.CallingApp.freqSamples.Value);
    f = freqs(1)*1e9;
    for i_loop = 1: loop
        %fcf_sim = zeros(1,length(deltaF));
        [result, delay] = cm.get_CIR_OWC(owc, tx_track, rx_track);
        power_NLoS = squeeze(result.power_NLoS_RE(1, 1, :, :,1));  % i_tx, i_rx, n, s
        delay_NLoS = squeeze(delay.delay_NLoS_RE(1,1,:,:,1));

        Nc = size(power_NLoS,1); % number of clusters
        N = size(power_NLoS,2); % number of scatterers in a cluster

        H2 = zeros(1,length(deltaF));
        for j = 1:length(deltaF)
            H2(j) = 0; %power_LoS(1)*exp(-1i*2*pi*(f+deltaF(i))*delay_LoS(1));
            for c=1:Nc
                for s=1:N
                    H2(j) = H2(j)+power_NLoS(c,s)*exp(-1i*2*pi*(f+deltaF(j))*delay_NLoS(c,s));
                end
            end
        end
        fcf_sim = abs(xcorr(H2));
        fcf(i_loop,:) = fcf_sim((length(deltaF)):(length(deltaF)*2-1));
        d_waitbar.Value = i_loop/loop/2;
    end
    fcf = sum(fcf, 1)/loop;
    fcf = fcf./max(fcf);
    plot(app.UIAxes_FCF, deltaF/1e6, fcf,'-.m','linewidth',1.2);
    stem(app.UIA_delayPSD, mean(delay_NLoS, 2)', sum(power_NLoS, 2)', '-.m', 'linewidth', 1);
    xlim(app.UIA_delayPSD, [min(mean(delay_NLoS, 2)) max(mean(delay_NLoS, 2))]);
    if 0 >= max(sum(power_NLoS, 2))
        error('Simulation result of the recevied power equals 0， please reset channel parameters');
    else
        ylim(app.UIA_delayPSD,[0 max(sum(power_NLoS, 2)*1.2)]);
    end
    % y轴倍率重合问题
    if app.UIA_delayPSD.YAxis.Exponent ~= 0
        app.UIA_delayPSD.YAxis.Exponent = 0;
    end
    
    % Delay spread
    DS = [];

    for j = 1: loop
        [result, delay] = cm.get_CIR_OWC(owc, tx_track, rx_track);

        % 收发端都取第一对天线
        power_NLoS_RE = squeeze(result.power_NLoS_RE(1,1,:,:,1));
        power_PS = squeeze(result.power_PS(1,1,:,:));
        delay_PS = squeeze(delay.delay_PS(1,1,:,:));
        delay_NLoS_RE = squeeze(delay.delay_NLoS_RE(1,1,:,:));

        Nc0 = size(power_NLoS_RE,1); % number of clusters
        N = size(power_NLoS_RE,2); % number of scatterers in a cluster

        tmp1 = 0; %tmp1 = power_LoS(1,:);
        for s = 1:N
            tmp1 = tmp1 + squeeze(power_PS(s,:))';
        end
        for c=1:Nc0
            for s=1:N
                tmp1 = tmp1 + squeeze(power_NLoS_RE(c,s,:))';
            end
        end

        tmp2 = 0; %tmp2 = delay_LoS(1,:).*power_LoS(1,:);
        for s=1:N
            tmp2 = tmp2 + squeeze(delay_PS(s,:).*power_PS(s,:))';
        end
        for c=1:Nc0
            for s=1:N
                tmp2 = tmp2 + squeeze(delay_NLoS_RE(c,s,:).*power_NLoS_RE(c,s,:))';
            end
        end

        mean_delay = tmp2./tmp1;  % tmp1 为NLoS射线的功率

        tmp3 = 0; %tmp3 = (delay_LoS(1,:)-mean_delay).^2.*power_LoS(1,:);
        for s=1:N
            tmp3 = tmp3 + squeeze((delay_PS(s,:)-mean_delay).^2.*power_PS(s,:))';
        end
        for c=1:Nc0
            for s=1:N
                tmp3 = tmp3 + squeeze((delay_NLoS_RE(c,s,:)-mean_delay).^2.*power_NLoS_RE(c,s,:))';
            end
        end
        DS = [DS, sqrt(tmp3(1)./tmp1(1))]; % unit: s

        d_waitbar.Value = (loop + j)/loop/2;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end
    close(d_waitbar);
    DS = DS(~isnan(DS));
    [yy,xx] = cdfcalc(DS);   % Calculate the CDF of x.
    xx = [-Inf; xx];
    plot(app.UIAxes_delaySpread, xx , yy,'-r','linewidth', 1); % Plot the CCDF of x.

    %相干带宽
    level = 0:0.03:1;
    CoherFreq = zeros(1,length(level));
    for i=1:length(level)
        for j = 1:length(fcf)
            if level(i)>fcf(j)
                break;
            end
            CoherFreq(i) = j*(deltaF(2)-deltaF(1));
        end
    end
    plot(app.UIAxes_cohBandWidth, CoherFreq, level,'-r','linewidth', 1);
    %%

else
    app.UIAxes_LCRf.Visible = 'on';
    app.UIAxes_SB.Visible = 'on';
    
    % fcf = 0;
    for i_freq = 1:length(fc)
        fcf = zeros(freq_sample(i_freq),length(fc));
    end
    delay_spread = zeros(length(fc),loop);

    if length(fc) == 1
        SB = cell(1,1);
        SB{1} = [];
    else
        SB = cell(1,length(fc));
        for i_freq = 1:length(fc)
            SB{i_freq} = [];
        end
    end

    d_waitbar = uiprogressdlg(app.UIFigure, 'Title', 'Simulation of frequency- and delay-domain channel statistical properties', 'Message', 'Simulating... ...', 'Cancelable','on');
    
    no_loop_eff = loop;
    for i_loop = 1: loop
        %First step: Obtain CIR
        if strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_IIOT)
            h_CIR = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, [], [], B, freq_sample);
            h_CIR = h_CIR{i_txUser, i_rxUser};
            H_CTF = fft(h_CIR,[],4);
            % h_CIR, h_SMC, h_DMC : CIR
        elseif strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_RIS)
            H_CTF = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, ris,[], B, freq_sample);
            h_CIR = ifft(H_CTF, [], 4);
        elseif strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_ISAC)
            H_CTF = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, [],[], B, freq_sample);
            h_CIR = ifft(H_CTF, [], 4);
        else
            [ result, delay, ~, ~]  = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track,[], cm_l, B, freq_sample);
            if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
                if length(fc)==1
                    [H, delay] = mf.result2H(result(i_txUser,i_rxUser,:), delay(i_txUser,i_rxUser,:)); % B5G中的H no_txAntenna * no_rxAntenna * snaps * m*n
                    H_CTF = mf.H2ctf(H, freq_sample, B, delay); % H, freq_sample, B, delay,
                    h_CIR = ifft(H_CTF, [], 4);
                end
            else
                h_CIR = result{i_txUser, i_rxUser};
                H_CTF = fft(h_CIR,[],4); % calculation based on the CTF matrix
            end
            if length(fc)>1
                H_CTF = mf.H2ctf_multiF(result, delay,B,freq_sample);
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

        if length(fc)==1
            % Second step: Calculate FCF
            h = squeeze(H_CTF(i_txAntenna, i_rxAntenna, i_snap, :));
            fcf_sim = h(1)' * h ./ abs(h(1)) ./ abs(h);
            
            if numel(fcf_sim(isnan(fcf_sim))) > 0
                no_loop_eff = no_loop_eff - 1;
            else
                fcf = fcf +  fcf_sim;
            end
            % Third step: Calculate DS
            delay_PSD = abs(squeeze(h_CIR(i_txAntenna, i_rxAntenna, i_snap, :))).^2;
            taus = (0 : freq_sample - 1) / B;
            [ ds, ~ ] = mf.calc_ds( taus, delay_PSD.' );
            delay_spread(i_loop) = ds*1e9;
            % Fourth step: Calculate stationary bandwidth
            window_size = 5;
            %TODO SB为1*0 double
            SB{1} = [SB{1},cp.get_stationary_bandwidth(squeeze(h_CIR(i_txAntenna, i_rxAntenna, i_snap, :)),window_size,deltaF{1})];
            freq_signal(i_loop,:) = abs(squeeze(H_CTF(i_txAntenna, i_rxAntenna, 1, :)));  % 频域信号
        else
            for i_freq = 1:length(fc)
                h = squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna, :));
                fcf_sim = h(1)' * h ./ abs(h(1)) ./ abs(h);
                
                if numel(fcf_sim(isnan(fcf_sim))) > 0
                    no_loop_eff = no_loop_eff - 1;
                else
                    fcf(:,i_freq) = fcf(:,i_freq) +  fcf_sim;
                end
                delay_PSD = abs(squeeze(h_CIR{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna, :))).^2;
                taus = (0 : freq_sample(i_freq) - 1) / B(i_freq);
                [ ds, ~ ] = mf.calc_ds( taus, delay_PSD.' );
                delay_spread(i_freq,i_loop) = ds*1e9;

                window_size = 5;
                %TODO 
                SB{i_freq} = [SB{i_freq},cp.get_stationary_bandwidth(squeeze(h_CIR{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna, :)),window_size,deltaF{i_freq})];
            end
            freq_signal(i_loop,:) = abs(squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna, :))); % 频域信号
        end

        
        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end
    close(d_waitbar);

    % Plot FCF
    for i_freq = 1:length(fc)
        legend_name{i_freq} = [num2str(fc(i_freq)/1e9),' GHz'];
    end
    mean_fcf = fcf / max(1, no_loop_eff);
    cla(app.UIAxes_FCF);
    for i_freq = 1:length(fc)
        plot(app.UIAxes_FCF, deltaF{i_freq}/1e6, abs(mean_fcf(:,i_freq)), 'Linewidth',1); hold(app.UIAxes_FCF,'on');
    end
    % xlim(app.UIAxes_FCF,[deltaF(1)/1e6 deltaF(end)/1e6]);
    if length(fc)>1
        legend(app.UIAxes_FCF,legend_name);
    else
        legend(app.UIAxes_FCF,'off');
    end

    % Calculate and plot coherence bandwidth
    c_th = 0.01:0.01:1;
    coh_bandwidth = zeros(length(fc),length(c_th));
    cla(app.UIAxes_cohBandWidth);
    for i_freq = 1:length(fc)
        fDelta = f{i_freq}(2) - f{i_freq}(1);
        for c_th_index = 1:length(c_th)
            min_index = find(abs(mean_fcf(:,i_freq)) < c_th(c_th_index), 1 ); % 第一个小于门限值的是第几个点
            if isempty(min_index)
                coh_bandwidth(i_freq,c_th_index) = f{i_freq}(end) - f{i_freq}(1);
                continue;
            end
            coh_bandwidth(i_freq,c_th_index) =  min(min_index * fDelta, f{i_freq}(end));
        end
        plot(app.UIAxes_cohBandWidth, coh_bandwidth(i_freq,:)/1e6, c_th,'Linewidth',1); hold(app.UIAxes_cohBandWidth,'on');
    end
    ylim(app.UIAxes_cohBandWidth,[0.01 1]);
    if length(fc)>1
        legend(app.UIAxes_cohBandWidth,legend_name);
    else
        legend(app.UIAxes_cohBandWidth,'off');
    end

    % Calculate and plot delay PSD
    cla(app.UIA_delayPSD);  
    if contains(cm.sim_params.scenarioName, 'GroundWave')
        tau = squeeze(delay(i_txAntenna, i_rxAntenna, 1, :));
        PSDsim = 20*log10(abs(squeeze(H(i_txAntenna, i_rxAntenna, 1, :))));
        stem(app.UIA_delayPSD, tau*1e9, PSDsim, 'b'); hold(app.UIA_delayPSD,'on');
        xlim(app.UIA_delayPSD,[min(tau*1e9)*0.9 max(tau*1e9)*1.2]);
        ylim(app.UIA_delayPSD,[min(PSDsim) max(PSDsim)]);
    else
        for i_freq = 1:length(fc)
            tau = (0:freq_sample(i_freq)-1) / B(i_freq);
            [tau,PSDsim] = cp.get_delay_PSD(deltaF{i_freq},mean_fcf(:,i_freq).',tau);
            % PSDsim=squeeze(mean(abs(h_CIR).^2,[1 2]));%黄昱崧
            plot(app.UIA_delayPSD, tau*1e9, 10*log10(abs(PSDsim)),'Linewidth',1); hold(app.UIA_delayPSD,'on');
        end
        xlim(app.UIA_delayPSD,[min(tau*1e9) max(tau*1e9)]);
        ylim(app.UIA_delayPSD,[min(10*log10(abs(PSDsim))) max(10*log10(abs(PSDsim)))]);
    end
    
    if length(fc)>1
        legend(app.UIA_delayPSD,legend_name);
    else
        legend(app.UIA_delayPSD,'off');
    end

    % Plot delay spreads
    cla(app.UIAxes_delaySpread);
    xlim_max = 0;
    for i_freq = 1:length(fc)
        [x_ds,c_ds] = mf.calc_cdf(delay_spread(i_freq,:),100);
        plot(app.UIAxes_delaySpread, x_ds,c_ds,'Linewidth',1); hold(app.UIAxes_delaySpread,'on');
        if i_freq == 1
            xlim_min = min(x_ds);
        end
        xlim_min = min(min(x_ds),xlim_min);
        xlim_max = max(max(x_ds),xlim_max);
    end
    xlim(app.UIAxes_delaySpread,[xlim_min xlim_max]);
    if length(fc)>1
        legend(app.UIAxes_delaySpread,legend_name);
    else
        legend(app.UIAxes_delaySpread,'off');
    end

    if length(fc)==1
        % Plot LCT freq
        % freq_signal = abs(squeeze(H_CTF(i_txAntenna, i_rxAntenna, 1, :)));  % 频域信号
        % 寻找频率信号的最大值，以确定阈值范围
        max_freq_signal = max(freq_signal(:));
        threshold = linspace(0, max_freq_signal, 500);

        for i_loop=1:loop
            % 设置阈值范围
            % 初始化 LCR 数组
            % LCR_freq = zeros(1, length(threshold));
            % 计算频域 LCR
            for thre_index = 1:length(threshold)
                thre = threshold(thre_index);
                crossings = sum((freq_signal(i_loop,1:end-1) > thre) & (freq_signal(i_loop,2:end) <= thre));
                LCR_freq(i_loop,thre_index) = crossings / 1; % 除以单位频率   length(freq_signal);
            end
        end
        avg_LCR_freq = mean(LCR_freq, 1);
        % 绘制频域 LCR
        plot(app.UIAxes_LCRf, threshold, avg_LCR_freq, 'linewidth', 1);
        legend(app.UIAxes_LCRf,'off')
        xlabel(app.UIAxes_LCRf, 'Envelope level');
        ylabel(app.UIAxes_LCRf, 'Frequency Domain LCR');
        % 设置坐标轴范围
        xlim(app.UIAxes_LCRf, [0, max_freq_signal]);
        ylim(app.UIAxes_LCRf, [0, max(0.001, max(avg_LCR_freq(:)))]*1.2);
    else
        cla(app.UIAxes_LCRf);
        for i_freq = 1:length(fc)
            % Plot LCT freq
            freq_signal = abs(squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna, :)));
            % 寻找频率信号的最大值，以确定阈值范围
            max_freq_signal = max(freq_signal);
            % 设置阈值范围
            threshold = linspace(0, max_freq_signal, 500);
            % 初始化 LCR 数组
            LCR_freq = zeros(1, length(threshold));
            % 计算频域 LCR
            for thre_index = 1:length(threshold)
                thre = threshold(thre_index);
                crossings = sum((freq_signal(1:end-1) > thre) & (freq_signal(2:end) <= thre));
                LCR_freq(thre_index) = crossings / 1; % 除以单位频率   length(freq_signal);
            end
            % 绘制频域 LCR
            plot(app.UIAxes_LCRf, threshold, LCR_freq, 'linewidth', 1); hold(app.UIAxes_LCRf,'on');
            xlabel(app.UIAxes_LCRf, 'Envelope level');
            ylabel(app.UIAxes_LCRf, 'Frequency Domain LCR');
            % 设置坐标轴范围
            xlim(app.UIAxes_LCRf, [0, max_freq_signal]);
            ylim(app.UIAxes_LCRf, [0, max(0.001, max(LCR_freq))]);
        end
        legend(app.UIAxes_LCRf,legend_name);
    end

    % Plot stationary bandwidth
    if isempty(SB) || isempty(SB{1})
        plot(app.UIAxes_SB, 0, 0,'Linewidth',1);
        error('When drawing the stationary bandwidth, the number of subcarriers is too small, please increase the setting');
    elseif sum(SB{1}) == 0
        text(0.5, 0.5, 'The channel is stationary', 'Parent', app.UIAxes_SB, 'FontSize', 14, 'Color', [1, 0, 0], 'HorizontalAlignment', 'center');
    else
        xlim_max = 0;
        for i_freq = 1:length(fc)
            [x_si, c_si] = mf.calc_cdf(SB{i_freq}/1e6,1000);
            if i_freq == 1
                xlim_min = min(x_si);
            else
                hold(app.UIAxes_SB,'on');
            end
            xlim_min = min(min(x_ds),xlim_min);
            xlim_max = max(max(x_ds),xlim_max);
            
            plot(app.UIAxes_SB, x_si,c_si,'Linewidth',1); 
        end
        xlim(app.UIAxes_SI,[xlim_min xlim_max]);
        if length(fc)>1
            legend(app.UIAxes_SB,legend_name);
        else
            legend(app.UIAxes_SB,'off');
        end
    end
end
end