function [ result, delay, lsps, ssps ] = get_CIR_main_sps(app, cm, tx_track, rx_track, ris, cm_l, bandwidth, freq_sample)
% 在一键展示某个域的统计特性功能专用方法
if ~exist('ris', 'var')
    ris = [];
end
if ~exist('cm_l', 'var')
    cm_l = [];
end
if ~exist('bandwidth', 'var')
    bandwidth = 100;
end
if ~exist('freq_sample', 'var')
    freq_sample = 100;
end
scenario = app.scenarios;
B = bandwidth(1);
switch app.Model_Selection.Value
    case '6GPCS'
        if strfind(scenario, app.sps.scenario_SATELLITE)
            [ result, delay, lsps, ssps ] = cm.get_CIR_Satellite(tx_track, rx_track, cm.sim_params.scen_para, 1, 'single-clusters');

        elseif strfind(scenario, app.sps.scenario_UHST)
            [ result, delay, lsps, ssps ] = cm.get_CIR(cm.sim_params.scen_para, app.sps.scenario_UHST);
            % 卫星收发端都为单用户
        elseif strfind(scenario, app.sps.scenario_MARITIME)
            cm.sim_params.scen_para.wind_speed = app.wind_speed.Value;
            cm.sim_params.scen_para.h_duct = app.EditField_7.Value;
            [ result, delay, lsps, ssps ] = cm.get_CIR_maritime( cm_l, tx_track, rx_track);

        elseif strfind(scenario, app.sps.scenario_ISAC)
            ori_scp = cm.sim_params.scen_para;
            [H ,delay, lsps, ssps] = cm.get_CIR_ISAC(cm.tx_track, cm.rx_track, cm.tar_track, ori_scp, 0);
            result = mf.H2ctf(H, freq_sample, B, delay,[]); % H, freq_sample, B, delay

        elseif strfind(scenario, app.sps.scenario_RIS)
            [ H, delay] = cm.get_CIR_totalRIS(ris);
            result = mf.H2ctf(H, freq_sample, B, delay); %  CTF  H, freq_sample, B, delay,

        elseif strfind(scenario, app.sps.scenario_UWA)
            cm.sim_params.scen_para.wind_speed = app.wind_speed_uwa.Value;
            cm.sim_params.scen_para.height_water = app.height_water_uwa.Value;
            [ result, delay, lsps, ssps ] = cm.get_CIR_UWA();

        elseif strfind(scenario, app.sps.scenario_VHF)
            SoS = cm.get_lsf_SOS(cm.decorr_dist);
            [ result, delay, lsps, ssps ] = cm.get_CIR_VHF(cm, tx_track, rx_track,SoS);

        elseif strfind(scenario, app.sps.scenario_IIOT)
            [ result_smc, delay_smc,result_dmc, delay_dmc, ~ ] = cm.get_CIR_IIoT([]);
            result = cell(size(result_smc,1),size(result_smc,2),size(result_smc,4));
            delay = cell(size(result_smc,1),size(result_smc,2),size(result_smc,4));
            for i_user_tx = 1:size(result,1)
                for i_user_rx = 1:size(result,2)
                    for i_freq = 1:size(result,4)
                        [H1, delay11] = mf.result2H_IIoT(result_smc(i_user_tx,i_user_rx,:,i_freq), delay_smc(i_user_tx,i_user_rx,:,i_freq),0);
                        H_CTF_SMC = mf.H2ctf(H1, freq_sample(1), B, delay11);
                        h_SMC = ifft(H_CTF_SMC,[],4);
                        [H2, delay22] = mf.result2H_IIoT(result_dmc(i_user_tx,i_user_rx,:,i_freq), delay_dmc(i_user_tx,i_user_rx,:,i_freq),1);
                        H_CTF_DMC = mf.H2ctf(H2, freq_sample(1), B, delay22);
                        h_DMC = ifft(H_CTF_DMC, [], 4);
                        result{i_user_tx,i_user_rx,i_freq} =  h_SMC + h_DMC; % result: no_txAntenna * no_rxAntenna * snaps * delays
                        delay{i_user_tx,i_user_rx,i_freq} =  cat(4,delay11,delay22); % result: no_txAntenna * no_rxAntenna * snaps * rays
                    end
                end
            end

        elseif length(cm.sim_params.carrier_frequency)>1
            ori_scp = cm.sim_params.scen_para;
            cm.sim_params.use_3GPP_baseline = 0;
            [ result, delay, lsps, ssps ] = cm.get_CIR_MF( ori_scp, 'MF', []);
        else
            ori_scp = cm.sim_params.scen_para;
            SoS = cm.get_lsf_SOS(cm.decorr_dist);
            [result, delay, lsps, ssps] = cm.get_CIR(ori_scp, 'others', [],SoS);
        end
    case {'3GPP TR 38.901','3GPP TR 36.777','3GPP TR 37.885','3GPP TR 38.811','IMT2020'}
        ori_scp = cm.sim_params.scen_para;
        [ result1, delay1, lsps, ssps ] = cm.get_CIR_3GPP(tx_track, rx_track, ori_scp,0);

        result = cell(size(result1,1),size(result1,2),size(result1,4));
        delay = cell(size(result1,1),size(result1,2),size(result1,4));
        for i_user_tx = 1:size(result,1)
            for i_user_rx = 1:size(result,2)
                for i_freq = 1:size(result,4)
                    H1 = result1{i_user_tx,i_user_rx,:,i_freq};
                    delay11 = delay1{i_user_tx,i_user_rx,:,i_freq};
                    H_CTF = mf.H2ctf(H1, freq_sample(1), B, delay11);
                    h = ifft(H_CTF,[],4);
                    result{i_user_tx,i_user_rx,i_freq} =  h; % result: no_txAntenna * no_rxAntenna * snaps * delays
                    delay{i_user_tx,i_user_rx,i_freq} =  delay11; % result: no_txAntenna * no_rxAntenna * snaps * rays
                end
            end
        end
end
end

