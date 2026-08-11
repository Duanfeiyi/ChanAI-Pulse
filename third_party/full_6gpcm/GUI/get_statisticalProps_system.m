function get_statisticalProps_system(app, cm, deltaD, owc, tx_track, rx_track, isTx, ris, cm_l)
cla(app.UIAxes_channelCapacity);
cla(app.UIAxes_pdfA);
cla(app.UIAxes_pdfP);
cla(app.UIAxes_AAoAs);

scen_para = cm.sim_params.scen_para;
loop = app.EditField_loop_system.Value;
[~,band,freq_sample] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
B = band*1e6;
% freq_sample = app.CallingApp.freqSamples.Value;
% B = app.CallingApp.bandwidth.Value*1e6;
i_rxAntenna = 1;
i_txAntenna = 1;
% 用户索引
i_txUser = str2num(app.DropDown_txUserIndex_system.Value);
i_rxUser = str2num(app.DropDown_rxUserIndex_system.Value);
%SNR
SNR_Max = app.SNRMaximum.Value;
SNR_Min = app.SNRMinimum.Value;
SNR_Interval = app.SNRInterval.Value;

SNR_dB = SNR_Min:SNR_Interval:SNR_Max;
if tools.is_owc_band(app.CallingApp.scenarios, app.CallingApp)
    % SCCF
    sccf = [];
    d_waitbar = uiprogressdlg(app.UIFigure, 'Title', 'Simulation of system performance', 'Message','Simulating... ...','Cancelable','on');
    for i_loop = 1: loop
        sccf_sim = zeros(1,length(deltaD));
        [ result, ~ ] = cm.get_CIR_OWC(owc, tx_track, rx_track);
        for i = 1:length(deltaD)
            deltaD_V = deltaD(i);
            H1 = result.Hlos(1,1,1) + result.Hnlos_PS(1,1,1) + sum(result.Hnlos_RE(1,1,:,1));
            if isTx
                H2 = result.Hlos(1,i,1) + result.Hnlos_PS(1,i,1) + sum(result.Hnlos_RE(1,i,:,1));
            else
                H2 = result.Hlos(i,1,1) + result.Hnlos_PS(i,1,1) + sum(result.Hnlos_RE(i,1,:,1));
            end
            prob_death_V = exp(-scen_para.lambdaR * deltaD_V * cos(owc.LED_elevation_angle_V)/scen_para.Corr_distance_A);
            % 上式越来越大 ??
            sccf_sim(i) = prob_death_V * H1 .* H2;
        end
        sccf = [sccf; sccf_sim];
        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end
    sccf = sum(sccf, 1)/loop;
    plot(app.UIAxes_SCCF, deltaD, sccf./max(sccf),'-m','linewidth',1.2);
    close(d_waitbar);
else
    d_waitbar = uiprogressdlg(app.UIFigure,'Title', 'Running', 'Message','Simulation... ...','Cancelable','on');

    if length(cm.sim_params.carrier_frequency) == 1
        h_A = []; % 幅度
        h_P = []; % 相位
    else
        h_A = cell(1,length(cm.sim_params.carrier_frequency));
        h_P = cell(1,length(cm.sim_params.carrier_frequency));
        for i_freq = 1:length(cm.sim_params.carrier_frequency)
            h_A{i_freq} = [];
            h_P{i_freq} = [];
        end
    end

    for i_loop = 1: loop
        % First step: Obtain CIR
        if strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_IIOT)
            h_CIR = cm_gui.get_CIR_main_sps(app.CallingApp, cm, tx_track, rx_track,[],[], B, freq_sample);
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
            h_A = [h_A, abs(squeeze(H_CTF(i_txAntenna, i_rxAntenna, 1, :)))];
            h_P = [h_P, angle(squeeze(H_CTF(i_txAntenna, i_rxAntenna, 1, :)))];
        else
            for i_freq = 1:length(cm.sim_params.carrier_frequency)
                h_A{i_freq} = [h_A{i_freq},abs(squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna, :)))];
                h_P{i_freq} = [h_P{i_freq},angle(squeeze(H_CTF{i_user_tx,i_user_rx,i_snap,i_freq}(i_txAntenna, i_rxAntenna, :)))];
            end
        end

        d_waitbar.Value = i_loop/loop;
        if d_waitbar.CancelRequested
            close(d_waitbar);
            return;
        end
    end

    for i_freq = 1:length(cm.sim_params.carrier_frequency)
        legend_name{i_freq} = [num2str(cm.sim_params.carrier_frequency(i_freq)/1e9),' GHz'];
    end

    if length(cm.sim_params.carrier_frequency) == 1
        capacity = cp.calc_capacity(h_CIR, SNR_dB, 1);
        plot(app.UIAxes_channelCapacity, SNR_dB, capacity);
        legend(app.UIAxes_channelCapacity,'off');
    else
        cla(app.UIAxes_channelCapacity);
        for i_freq = 1:length(cm.sim_params.carrier_frequency)
            temp_CIR = h_CIR{i_user_tx,i_user_rx,i_snap,i_freq};
            capacity = cp.calc_capacity(temp_CIR, SNR_dB, 1);
            plot(app.UIAxes_channelCapacity, SNR_dB, capacity); hold(app.UIAxes_channelCapacity,'on');
        end
        legend(app.UIAxes_channelCapacity,legend_name);
    end

    % 创建幅度直方图
    if length(cm.sim_params.carrier_frequency) == 1
        [hist, edges] = histcounts(h_A, 'BinMethod', 'auto', 'Normalization', 'pdf');
        bin_centers = (edges(1:end-1) + edges(2:end)) / 2;
        % 绘制幅度PDF
        bar(app.UIAxes_pdfA, bin_centers, hist, 'BarWidth', 0.1);
        legend(app.UIAxes_pdfA,'off');
    else
        cla(app.UIAxes_pdfA);
        [~, edges] = histcounts(h_A{1}, 'BinMethod', 'auto', 'Normalization', 'pdf');
        bin_centers = (edges(1:end-1) + edges(2:end)) / 2;
        delta_bin = bin_centers(2)-bin_centers(1);
        for i_freq = 1:length(cm.sim_params.carrier_frequency)
            [hist, ~] = histcounts(h_A{i_freq}(:), length(edges)-1, 'Normalization', 'pdf');
            % 绘制幅度PDF
            bar(app.UIAxes_pdfA, bin_centers+delta_bin/5*(i_freq-1), hist, 'BarWidth', 0.2); hold(app.UIAxes_pdfA,'on');
        end
        legend(app.UIAxes_pdfA,legend_name);
    end

    if length(cm.sim_params.carrier_frequency) == 1
        % 创建相位直方图
        [hist_P, edges_P] = histcounts(h_P, 'BinMethod', 'auto', 'Normalization', 'pdf');
        bin_centers_P = (edges_P(1:end-1) + edges_P(2:end)) / 2;
        % 绘制相位PDF
        bar(app.UIAxes_pdfP, bin_centers_P, hist_P, 'BarWidth', 0.1);
        legend(app.UIAxes_pdfP,'off');
    else
        cla(app.UIAxes_pdfP);
        [~, edges] = histcounts(h_P{1}(:), 'BinMethod', 'auto', 'Normalization', 'pdf');
        bin_centers = (edges(1:end-1) + edges(2:end)) / 2;
        delta_bin = bin_centers(2)-bin_centers(1);
        for i_freq = 1:length(cm.sim_params.carrier_frequency)
            % 创建相位直方图
            [hist_P, ~] = histcounts(h_P{i_freq},length(edges)-1, 'Normalization', 'pdf');
            % bin_centers_P = (edges_P(1:end-1) + edges_P(2:end)) / 2;
            % 绘制相位PDF
            bar(app.UIAxes_pdfP, bin_centers+delta_bin/5*(i_freq-1), hist_P, 'BarWidth', 0.2);hold(app.UIAxes_pdfP,'on');
        end
        legend(app.UIAxes_pdfP,legend_name);
    end

    %沿天线阵列的los径到达方位角验证球面波特性
    tx_antenna = cm.tx_array(i_txUser);
    rx_antenna = cm.rx_array(i_rxUser);
    tx_pos = tx_track(i_txUser).positions(1,:);
    rx_pos = rx_track(i_rxUser).positions(1,:);
    antenna_index = rx_antenna.no_elements;
    AAoAs = tools.get_AAoA_Los(tx_pos,rx_pos,tx_antenna,rx_antenna);
    plot(app.UIAxes_AAoAs, 1:antenna_index, AAoAs);

    close(d_waitbar);
end
end