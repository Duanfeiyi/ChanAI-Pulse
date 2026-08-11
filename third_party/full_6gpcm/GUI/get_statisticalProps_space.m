function get_statisticalProps_space(app, cm, ~, owc, tx_track, rx_track, isTx, ris, cm_l)
%GET_STATISTICALPROPS_GUI 此处显示有关此函数的摘要
% 所有仿真图复位
cla(app.UIAxes_SCCF);
cla(app.UIAxes_cohDistance);
cla(app.UIAxes_sptialdopplerPSD);
cla(app.UIAxes_angleSpreads);
cla(app.UIAxes_SD);
cla(app.UIAxes_LCRs);

% 用户索引
i_txUser = str2num(app.DropDown_txUserIndex_space.Value);
i_rxUser = str2num(app.DropDown_rxUserIndex_space.Value);

scen_para = cm.sim_params.scen_para;
loop = app.EditField_loop_space.Value;
[~,band,freq_sample] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
B = band*1e6;
% freq_sample = app.CallingApp.freqSamples.Value;
% B = app.CallingApp.bandwidth.Value*1e6;
i_carrier = 1;
i_snap = 1;
if tools.is_owc_band(app.CallingApp.scenarios, app.CallingApp)
    %%%%%%%%%%%%%%如果是光无线频段，则去掉右侧两个图
    app.UIAxes_LCRs.Visible = 'off';
    app.UIAxes_SD.Visible = 'off';
    %%%%%%%%%%%%%%
    % SCCF
    if isTx
        if owc.LED_no_elements_H < 2
            warndlg('Warning: the number of LED units per row < 2. Please increase the number of units for spatial simulation', "Inappropriate parameter setting", "model");
            return;
        end
        deltaD = linspace(1, owc.LED_element_spacing_H * owc.LED_no_elements_H, owc.LED_no_elements_H)-1; % CCF Tx端间隔;
    else
        if owc.LED_no_elements_V < 2
            warndlg('Warning: the number of LED units per column < 2. Please increase the number of units for spatial simulation', "Inappropriate parameter setting", "model");
            return;
        end
        deltaD = linspace(1, owc.LED_element_spacing_V * owc.LED_no_elements_V, owc.LED_no_elements_V)-1; % CCF Rx端间隔;
    end

    sccf = zeros(loop,length(deltaD));
    d_waitbar = uiprogressdlg(app.UIFigure,'Title', 'Simulation of spatial and angular channel statistical properties', 'Message','Simulating... ...','Cancelable','on');
    for i_loop = 1: loop
        [ result, ~ ] = cm.get_CIR_OWC(owc, tx_track, rx_track);
        H2 = zeros(1,length(deltaD));
        for i = 1:length(deltaD)
            %H1 = result.Hlos(1,1,1) + result.Hnlos_PS(1,1,1) + sum(result.Hnlos_RE(1,1,:,1));
            if isTx
                H2(i) = result.Hlos(i,1,1) + result.Hnlos_PS(i,1,1) + sum(result.Hnlos_RE(i,1,:,1));
            else
                H2(i) = result.Hlos(1,i,1) + result.Hnlos_PS(1,i,1) + sum(result.Hnlos_RE(1,i,:,1));
            end
        end
        sccf_sim = abs(xcorr(H2));
        sccf(i_loop,:) = sccf_sim((length(deltaD)):(length(deltaD)*2-1));

        d_waitbar.Value = i_loop/loop;

        % Plot angular spreads
        h_PAS = H2;
        phi = linspace(-90, 90, 100);
        ula_col = 0 : length(h_PAS) - 1;
        angular_PSD = zeros(length(phi),1);
        for k1 = 1:length(phi)
            a = exp(-1j*2*pi*0.5*sind(phi(k1))*ula_col);
            angular_PSD(k1,1) = abs(conj(a)*h_PAS'*h_PAS*a.'/(a*a'));
        end
        as = mf.calc_ds( phi, angular_PSD.' );
        angular_spread(i_loop) = as;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end
    sccf = sum(sccf, 1)/loop;
    plot(app.UIAxes_SCCF, deltaD, sccf./max(sccf),'-m','linewidth',1.2);
    xlabel(app.UIAxes_SCCF, 'LED spacing (m)','FontSize',12);
    close(d_waitbar);

    % Calculate and plot spatial-doppler PSD
    costheta = -1:0.01:1;
    PSD_sim = cp.get_spatial_doppler_PSD(deltaD, sccf, costheta, 3e8 / cm.sim_params.carrier_frequency);
    plot(app.UIAxes_sptialdopplerPSD, costheta, 10*log10(abs(PSD_sim)), 'b-', 'Linewidth', 1);
    xlim(app.UIAxes_sptialdopplerPSD, [min(costheta) max(costheta)]);
    % Calculate and plot coherence distance
    c_th = 0.01:0.01:1;
    coherDis = zeros(1,length(c_th));
    dDelta = deltaD(2) - deltaD(1);
    for c_th_index = 1 : length(c_th)
        min_index = find((abs(sccf)/max(abs(sccf))) < c_th(c_th_index), 1 ); % 第一个小于门限值的是第几个点
        if isempty(min_index)
            coherDis(c_th_index) = deltaD(end) - deltaD(1);
            continue;
        end
        coherDis(c_th_index) = min(min_index * dDelta, deltaD(end));
    end
    plot(app.UIAxes_cohDistance, coherDis, c_th, 'b-','Linewidth',1);
    ylim(app.UIAxes_cohDistance, [min(c_th) max(c_th)]);

    [x_as,c_as] = mf.calc_cdf(angular_spread,100);
    plot(app.UIAxes_angleSpreads, x_as, c_as, 'b-','Linewidth',1);
    xlim(app.UIAxes_angleSpreads, [min(x_as) max(x_as)])
else
    app.UIAxes_LCRs.Visible = 'on';
    app.UIAxes_SD.Visible = 'on';
    %% 其他频段和场景的统计特性计算
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
                prob_death(:,i_freq) = exp(-scen_para.lambdaR * deltaD(i_freq,:) * cos(cm.rx_array(i_rxUser).elevation_angle)/30)';  % scen_para.Corr_distance_A
            else
                prob_death(:,i_freq) = 1;
            end
        end
        i_txAntenna = i_txUser;
    end

    ccf = zeros(size(deltaD,2),length(cm.sim_params.carrier_frequency));
    if length(cm.sim_params.carrier_frequency) == 1
        SD{1} = [];
    else
        SD = cell(1,length(cm.sim_params.carrier_frequency));
        for i_freq = 1:length(cm.sim_params.carrier_frequency)
            SD{i_freq} = [];
        end
    end
    angular_spread =zeros(length(cm.sim_params.carrier_frequency),loop);
    d_waitbar = uiprogressdlg(app.UIFigure,'Title', 'Simulation of spatial and angular channel statistical properties', 'Message','Simulating ... ...','Cancelable','on');
    no_loop_eff = loop;
    for i_loop = 1: loop
        % First step: Obtain CIR
        if strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_IIOT)
            h_CIR = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track,[],[], B, freq_sample);
            h_CIR = h_CIR{i_txUser, i_rxUser};
            H_CTF = fft(h_CIR,[],4);

        elseif strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_RIS)
            H_CTF = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, ris,[], B, freq_sample);
            h_CIR = ifft(H_CTF, [], 4);
        elseif strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_ISAC)
            H_CTF = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track, [],[], B, freq_sample);
            h_CIR = ifft(H_CTF, [], 4);
        else
            [ result, delay, ~, ~]  = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track,[], cm_l, B, freq_sample);
            if strcmp(app.CallingApp.Model_Selection.Value,'6GPCS')
                if length(cm.sim_params.carrier_frequency)==1
                    [H, delay] = mf.result2H(result(i_txUser,i_rxUser,:), delay(i_txUser,i_rxUser,:)); % B5G中的H no_txAntenna * no_rxAntenna * snaps * m*n
                    H_CTF = mf.H2ctf(H, freq_sample, B, delay); % H, freq_sample, B, delay,
                    h_CIR = ifft(H_CTF, [], 4);
                end
            else
                h_CIR = result{i_txUser, i_rxUser};
                H_CTF = fft(h_CIR,[],4); % calculation based on the CTF matrix
            end
            if length(cm.sim_params.carrier_frequency)>1
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

        if length(cm.sim_params.carrier_frequency) == 1
            % Second step: Calculate CCF
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
            % Third step: Calculate AS
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
            % Fourth step: Calculate stationary distance
            if isTx
                pdp = abs(squeeze(h_CIR(:, i_rxAntenna, i_snap, :))).^2;
            else
                pdp = abs(squeeze(h_CIR(i_txAntenna, :, i_snap, :))).^2;
            end
            window_size = 5;
            SD{1} = [SD{1}, cp.get_stationary_distance(pdp, window_size, deltaD)];
            if isTx
                space_signal(i_loop,:) = abs(squeeze(H_CTF(:, i_rxAntenna,i_snap, 1)));  % Tx端信号
            else
                space_signal(i_loop,:) = abs(squeeze(H_CTF(i_txAntenna,:,i_snap, 1)));  % Rx端信号
            end
        else
            for i_freq = 1:length(cm.sim_params.carrier_frequency)
                h = squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(:, :, i_carrier));
                if isTx
                    ccf_sim = h(1,i_rxAntenna)' * h(:,i_rxAntenna) / abs(h(1,i_rxAntenna)) ./ abs(h(:,i_rxAntenna)); % TODO 可调
                else
                    ccf_sim = h(i_txAntenna,1) * h(i_txAntenna,:)' / abs(h(i_txAntenna,1)) ./ abs(h(i_txAntenna,:)'); % TODO 可调
                end
                
                if numel(ccf_sim(isnan(ccf_sim))) > 0
                    no_loop_eff = no_loop_eff - 1;
                else
                    ccf(:,i_freq) = ccf(:,i_freq) + ccf_sim .* prob_death(:,i_freq);
                end
                % Third step: Calculate AS
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
                angular_spread(i_freq,i_loop) = as;
                % Fourth step: Calculate stationary distance
                if isTx
                    pdp = abs(squeeze(h_CIR{i_user_tx,i_user_rx,i_snap,i_freq}(:, i_rxAntenna, :))).^2;
                else
                    pdp = abs(squeeze(h_CIR{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, :, :))).^2;
                end
                window_size = 5;
                SD{i_freq} = [SD{i_freq}, cp.get_stationary_distance(pdp, window_size, deltaD(i_freq,:))];
            end
            if isTx
                space_signal(i_loop,:) = abs(squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(:, i_rxAntenna, 1)));  % Tx端信号
            else
                space_signal(i_loop,:) = abs(squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna,:, 1)));  % Rx端信号
            end
        end

        

        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end
    close(d_waitbar);
    % Plot SCCF
    ccf = ccf./max(1, no_loop_eff);
    for i_freq = 1:length(cm.sim_params.carrier_frequency)
        legend_name{i_freq} = [num2str(cm.sim_params.carrier_frequency(i_freq)/1e9),' GHz'];
    end
    if length(cm.sim_params.carrier_frequency) == 1
        plot(app.UIAxes_SCCF, deltaD, abs(ccf)/max(abs(ccf)), 'linewidth', 1);
        legend(app.UIAxes_SCCF,'off');
    else
        cla(app.UIAxes_SCCF);
        for i_freq = 1:length(cm.sim_params.carrier_frequency)
            plot(app.UIAxes_SCCF, deltaD(i_freq,:), abs(ccf(:,i_freq))/max(abs(ccf(:,i_freq))),'linewidth', 1); hold(app.UIAxes_SCCF,'on');
        end
        xlabel(app.UIAxes_SCCF, 'Antenna spacing (m)','FontSize',12);
        legend(app.UIAxes_SCCF,legend_name);
    end

    % Calculate and plot coherence distance
    c_th = 0.01:0.01:1;
    coherDis = zeros(1,length(c_th));
    dDelta = deltaD(i_freq,2) - deltaD(i_freq,1);
    cla(app.UIAxes_cohDistance);
    for i_freq = 1:length(cm.sim_params.carrier_frequency)
        for c_th_index = 1 : length(c_th)
            min_index = find((abs(ccf(:,i_freq))/max(abs(ccf(:,i_freq)))) < c_th(c_th_index), 1 ); % 第一个小于门限值的是第几个点
            if isempty(min_index)
                coherDis(c_th_index) = deltaD(end) - deltaD(1);
                continue;
            end
            coherDis(c_th_index) = min(min_index * dDelta, deltaD(end));
        end
        plot(app.UIAxes_cohDistance, coherDis, c_th,'Linewidth',1);hold(app.UIAxes_cohDistance,'on');
    end
    ylim(app.UIAxes_cohDistance, [min(c_th) max(c_th)]);
    if length(cm.sim_params.carrier_frequency)>1
        legend(app.UIAxes_SCCF,legend_name);
    else
        legend(app.UIAxes_SCCF,'off');
    end

    % Calculate and plot spatial-doppler PSD
    costheta = -1:0.01:1;
    cla(app.UIAxes_sptialdopplerPSD);
    for i_freq = 1:length(cm.sim_params.carrier_frequency)
        PSD_sim = cp.get_spatial_doppler_PSD(deltaD(i_freq,:), ccf(:,i_freq).', costheta, 3e8 / cm.sim_params.carrier_frequency(i_freq));
        plot(app.UIAxes_sptialdopplerPSD, costheta, 10*log10(abs(PSD_sim)), 'Linewidth', 1); hold(app.UIAxes_sptialdopplerPSD,'on');
        % xlim(app.UIAxes_sptialdopplerPSD, [min(costheta) max(costheta)])
    end
    if length(cm.sim_params.carrier_frequency)>1
        legend(app.UIAxes_sptialdopplerPSD,legend_name);
    else
        legend(app.UIAxes_sptialdopplerPSD,'off');
    end

    % Plot angular spreads
    cla(app.UIAxes_angleSpreads);
    xlim_max = 0;
    for i_freq = 1:length(cm.sim_params.carrier_frequency)
        [x_as,c_as] = mf.calc_cdf(angular_spread(i_freq,:),100);
        plot(app.UIAxes_angleSpreads, x_as,c_as, 'Linewidth',1); hold(app.UIAxes_angleSpreads,'on');
        if i_freq == 1
            xlim_min = min(x_as);
        end
        xlim_min = min(min(x_as),xlim_min);
        xlim_max = max(max(x_as),xlim_max);
    end
    xlim(app.UIAxes_angleSpreads, [xlim_min xlim_max]);
    if length(cm.sim_params.carrier_frequency)>1
        legend(app.UIAxes_angleSpreads,legend_name);
    else
        legend(app.UIAxes_angleSpreads,'off');
    end

    if  length(cm.sim_params.carrier_frequency)==1
        % Plot LCR space
        % if isTx
        %     space_signal = abs(squeeze(H_CTF(:, i_rxAntenna,i_snap, 1)));  % Tx端信号
        % else
        %     space_signal = abs(squeeze(H_CTF(i_txAntenna,:,i_snap, 1)));  % Rx端信号
        % end
        % 设置阈值范围
        num_freqs = size(H_CTF, 4);
        num_thresholds = 500;
        threshold = linspace(0, max(space_signal(:)), num_thresholds);
        % 初始化 LCR 数组
        % LCR_space = zeros(1, num_thresholds);
        % 计算空域 LCR
        for i_loop=1:loop
            for thre_index = 1:num_thresholds
                thre = threshold(thre_index);
                crossings = sum((space_signal(i_loop,1:end-1) > thre) & (space_signal(i_loop,2:end) <= thre));
                LCR_space(i_loop,thre_index) = crossings / 1; %  除以单位距离
            end
        end
        % 绘制空域 LCR
        avg_LCR_space = mean(LCR_space, 1);
        plot(app.UIAxes_LCRs, threshold, avg_LCR_space, 'linewidth', 1);
        legend(app.UIAxes_LCRs,'off');
        % 设置坐标轴范围
        xlim(app.UIAxes_LCRs, [0, max(space_signal(:))]);
        ylim(app.UIAxes_LCRs, [0, max(0.001, max(avg_LCR_space(:))*1.2)]);
    else
        cla(app.UIAxes_LCRs);
        for i_freq = 1:length(cm.sim_params.carrier_frequency)
            squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(:, :, i_carrier));
            if isTx
                space_signal = abs( squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(:,i_rxAntenna, i_carrier)));
            else
                space_signal = abs( squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna,:, i_carrier)));
            end
            % 设置阈值范围
            num_thresholds = 500;
            threshold = linspace(0, max(space_signal), num_thresholds);
            % 初始化 LCR 数组
            LCR_space = zeros(1, num_thresholds);
            % 计算空域 LCR
            for thre_index = 1:num_thresholds
                thre = threshold(thre_index);
                crossings = sum((space_signal(1:end-1) > thre) & (space_signal(2:end) <= thre));
                LCR_space(thre_index) = crossings / 1; %  除以单位距离
            end
            % 绘制空域 LCR
            plot(app.UIAxes_LCRs, threshold, LCR_space,'linewidth', 1); hold(app.UIAxes_LCRs,'on');
            % 设置坐标轴范围
            xlim(app.UIAxes_LCRs, [0, max(space_signal)]);
            ylim(app.UIAxes_LCRs, [0, max(0.001, max(LCR_space))]);
        end
        legend(app.UIAxes_LCRs,legend_name);
    end

    % Plot stationary distance
    if isempty(SD) || isempty(SD{1})
        plot(app.UIAxes_SD, 0, 0, 'Linewidth',1);
        error('When drawing the stationary distance, the number of antenna elements is too small, please increase to at least 16');
    elseif sum(SD{1}) == 0
        text(0.5, 0.1, 'The channel is stationary', 'Parent', app.UIAxes_SD, 'FontSize', 14, 'Color', [1, 0, 0], 'HorizontalAlignment', 'center');
    else
        cla(app.UIAxes_SD);
        for i_freq = 1:length(cm.sim_params.carrier_frequency)
            [x_si,c_si] = mf.calc_cdf(SD{i_freq},1000);
            plot(app.UIAxes_SD, x_si,c_si,'Linewidth',1); hold(app.UIAxes_SD,'on');
        end
        % xlim(app.UIAxes_SD, [min(x_si) max(x_si)]);
        if length(cm.sim_params.carrier_frequency)>1
            legend(app.UIAxes_SD,legend_name);
        else
            legend(app.UIAxes_SD,'off');
        end
    end
end
end
