function saveparameters(app, savePath, scenario, lsps, tx_track, rx_track, h_CIR_all,h_CIR_BR_all,h_CIR_RU_all,H_CTF_BR_all, H_CTF_RU_all, H_CTF_all,delay_all, ssps_all,G_RIS_diag,H_B_CTF_all)

%参数保存
%   此处显示详细说明
% answer = questdlg('Save the configuration and results or not?', 'Option', 'Save', 'Do not save', 'Do not save');
save_selectedNodes = app.Tree_save.CheckedNodes;
% switch answer
%     case 'Save'
if ~exist(savePath, 'dir')
    mkdir(savePath);
end
if strfind(scenario, app.sps.scenario_RIS)
    for i = 1:length(save_selectedNodes)
        nodeText = save_selectedNodes(i).Text;
        switch nodeText
            case '大尺度参数(Large scale parameters)'
                save(strcat(savePath, filesep, 'lsps.mat'),  'lsps');
            case '发射端运动轨迹信息(Movement track information of Tx)'
                save(strcat(savePath, filesep, 'track_TX.mat'),  'tx_track');
            case '接收端运动轨迹信息(Movement track information of Rx)'
                save(strcat(savePath, filesep, 'track_RX.mat'),  'rx_track');
            case '小尺度衰落信道冲激响应矩阵(Channel impulse response)'
                save(strcat(savePath, filesep, 'h_CIR_BR.mat'),  'h_CIR_BR_all');
                save(strcat(savePath, filesep, 'h_CIR_RU.mat'),  'h_CIR_RU_all');
            case '小尺度衰落信道转移矩阵(Channel transition matrix)'
                save(strcat(savePath, filesep, 'h_CTF_BR.mat'),  'H_CTF_BR_all');
                save(strcat(savePath, filesep, 'h_CTF_RU.mat'),  'H_CTF_RU_all');
            case '子径时延(Sub-path delay)'
                save(strcat(savePath, filesep, 'delay.mat'),  'delay_all');
            case '散射体位置信息(Scatterers’ positions information)'
                msgbox('Does not support saving sub-path power and scatterers’ positions information in RIS scenario', '提示', 'warn');
            case '波束域结果(Beam domain results)'
                save(strcat(savePath, filesep, 'h_B_CTF.mat'),  'H_B_CTF_all');
                return;
        end
    end
    save(strcat(savePath, filesep, 'G_RIS_diag.mat'),  'G_RIS_diag');
elseif  strfind(scenario, app.sps.scenario_IIOT)
    for i = 1:length(save_selectedNodes)
        nodeText = save_selectedNodes(i).Text;
        switch nodeText
            case '大尺度参数(Large scale parameters)'
                save(strcat(savePath, filesep, 'lsps.mat'),  'lsps');
            case '发射端运动轨迹信息(Movement track information of Tx)'
                save(strcat(savePath, filesep, 'track_TX.mat'),  'tx_track');
            case '接收端运动轨迹信息(Movement track information of Rx)'
                save(strcat(savePath, filesep, 'track_RX.mat'),  'rx_track');
            case '小尺度衰落信道冲激响应矩阵(Channel impulse response)'
                save(strcat(savePath, filesep, 'h_CIR.mat'), 'h_CIR_all');
            case '小尺度衰落信道转移矩阵(Channel transition matrix)'
                save(strcat(savePath, filesep, 'h_CTF.mat'),  'H_CTF_all');
            case '子径时延(Sub-path delay)'
                msgbox('Does not support saving sub-path delay and power in IIOT scenario', '提示', 'warn');
                return;
            case '散射体位置信息(Scatterers’ positions information)'
                save(strcat(savePath, filesep, 'ssps.mat'),  'ssps_all');
            case '波束域结果(Beam domain results)'
                save(strcat(savePath, filesep, 'h_B_CTF.mat'),  'H_B_CTF_all');
        end
    end
elseif tools.is_owc_band(scenario, app)

    for i = 1:length(save_selectedNodes)
        nodeText = save_selectedNodes(i).Text;
        switch nodeText
            case {'大尺度参数(Large scale parameters)', '发射端运动轨迹信息(Movement track information of Tx)', '接收端运动轨迹信息(Movement track information of Rx)','小尺度衰落信道转移矩阵(Channel transition matrix)', '子径时延(Sub-path delay)', '子径功率(Sub-path power)', '散射体位置信息(Scatterers, positions information)', '波束域结果(Beam domain results)'}
                msgbox('Only supports saving channel impulse response in OWC scenario', '提示', 'warn');
                return;
            case '小尺度衰落信道冲激响应矩阵(Channel impulse response)'
                save(strcat(savePath, filesep, 'h_CIR.mat'), 'h_CIR_all');
        end
    end
else
    for i = 1:length(save_selectedNodes)
        nodeText = save_selectedNodes(i).Text;
        switch nodeText
            case '大尺度参数(Large scale parameters)'
                save(strcat(savePath, filesep, 'lsps.mat'),  'lsps');
            case '发射端运动轨迹信息(Movement track information of Tx)'
                save(strcat(savePath, filesep, 'track_TX.mat'),  'tx_track');
            case '接收端运动轨迹信息(Movement track information of Rx)'
                save(strcat(savePath, filesep, 'track_RX.mat'),  'rx_track');
            case '小尺度衰落信道冲激响应矩阵(Channel impulse response)'
                save(strcat(savePath, filesep, 'h_CIR.mat'), 'h_CIR_all');
            case '小尺度衰落信道转移矩阵(Channel transition matrix)'
                save(strcat(savePath, filesep, 'h_CTF.mat'),  'H_CTF_all');
            case '子径时延(Sub-path delay)'
                save(strcat(savePath, filesep, 'delay.mat'),  'delay_all');

            case '散射体位置信息(Scatterers’ positions information)'
                save(strcat(savePath, filesep, 'ssps.mat'),  'ssps_all');
            case '波束域结果(Beam domain results)'
                save(strcat(savePath, filesep, 'h_B_CTF.mat'),  'H_B_CTF_all');
        end
    end
end

allSettings = transpose(tools.app2settings(app, app.scenarios));
settingsFileName = strcat(savePath, filesep, 'confs.mat');
save(settingsFileName, 'allSettings');

msgbox(["End running !  The selected parameter information has been saved in the directory : ", savePath], "modal");
%mf.add_logs('CIRButtonPushed', ['End running, CIR ', resultFileName,  'large-scale parameters ', lspsFileName, 'and correspondence configuration ', settingsFileName, ' are saved to the results folder']);

%     case 'Do not save'
%         msgbox("End running, the configuration and results are not saved", "modal");
%         mf.add_logs('CIRButtonPushed', "End running, the configuration and results are not chose to be saved");
% end
end

