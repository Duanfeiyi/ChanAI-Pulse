function [cm, tx_track, rx_track, cm_maritime_l] = preGenSPs(app, B)
%PROGENSPS 此处显示有关此函数的摘要
% 检查用户是否选择了频段和场景
tools.update_ModelselectionItems(app);
scenario = app.scenarios;
% 检查天线运动轨迹等是否已经设置
tools.check_ant_traj_chosen(app, scenario);
tools.check_parasSetting(app);

cm_maritime_l = [];
% 检查用户设置的参数是否合理
[initialPosTx, initialPosRx] = tools.get_initialPos_table(app);
switch app.Model_Selection.Value
    case '6GPCS'
        app.sps.setScenario(strcat(scenario));
    case 'IMT2020'
        tools.check_settings_3GPP(app, app.Model_Selection.Value);
        app.sps.use_3GPP_baseline = true;
        app.sps.use_absolute_delays_3GPP = false;
        app.sps.setScenario(strcat(scenario,'_3GPP'));
    otherwise
        tools.check_settings_3GPP(app, app.Model_Selection.Value);
        app.sps.use_3GPP_baseline = true;
        app.sps.use_large_bandwidth_3GPP = false;
        app.sps.use_absolute_delays_3GPP =true;
        app.sps.use_dual_mobility_3GPP =true;
        app.sps.setScenario(strcat(scenario,'_3GPP'));
end
cm = tools.constructCM(app, scenario);

if isfield(cm.sim_params.scen_para, 'no_snaps_update')
    mf.add_logs('preGenSPs', num2str(cm.sim_params.scen_para.no_snaps_update));
end

% TODO 不同用户是否需要区分
%%% sgxy 判断是否需要考虑大带宽
if ~tools.is_owc_band(scenario, app)
    if mf.is_large_bandwidth(cm, B)
        app.sps.use_large_bandwidth_3GPP = 1;
        cm.sim_params.use_large_bandwidth_3GPP = 1;
    end
end
tx_track_list = table2array(app.UITable_tx.Data);
rx_track_list = table2array(app.UITable_rx.Data);

for j = 1 : size(rx_track_list,1)
    trackOriRx = mf.str2positions(rx_track_list{j,8});
    rxTrackType = char(rx_track_list{j,5});
    rxSpeed = str2double(rx_track_list{j,6});
    rxAcceleration = str2double(rx_track_list{j,7});
    if strfind(scenario, app.sps.scenario_SATELLITE)
        rx_track(j) = track(rxTrackType, app.trackLength.Value, rxSpeed, rxAcceleration, [0, 0, 0], trackOriRx, app.sampleRate.Value, app.wind_speed.Value);
    else
        rx_track(j) = track(rxTrackType, app.trackLength.Value, rxSpeed, rxAcceleration, initialPosRx(j,:), trackOriRx, app.sampleRate.Value, app.wind_speed.Value);
    end

if strfind(scenario, app.sps.scenario_SATELLITE)
    %%%%%%%%% sgxy 240205, 卫星场景，只取表格第一行中的数据, 首先只取initialPosTx第一行
    initialPosTx = initialPosTx(1,:);
    tx_track = tools.get_track_satellite(app, app.trackLength.Value, app.sampleRate.Value, initialPosTx);
else
    for i = 1 : size(tx_track_list,1)
        trackOriTx = mf.str2positions(tx_track_list{i,8});
        txTrackType = char(tx_track_list{i,5});
        txSpeed = str2double(tx_track_list{i,6});
        txAcceleration = str2double(tx_track_list{i,7});
        tx_track(i) = track(txTrackType, app.trackLength.Value, txSpeed, txAcceleration, initialPosTx(i,:), trackOriTx, app.sampleRate.Value);
    end
end
cm.rx_track = rx_track;
cm.tx_track = tx_track;

if strfind(scenario, app.sps.scenario_MARITIME)
    % 海洋场景，海面子信道上对应的cm，簇和子径数量 以及运动轨迹 都是和cm_maritime_h相同的
    cm_maritime_l = tools.constructCM(app, scenario);
    for i = 1:numel(cm_maritime_l.clusters)
        cm_maritime_l.clusters(i).num_clusters = app.noCluster_3.Value;
        cm_maritime_l.clusters(i).num_rays_each_cluster = app.noRaysEachCluster_3.Value;
    end
    cm_maritime_l.rx_track = rx_track;
    cm_maritime_l.tx_track = tx_track;
end

if strfind(scenario, app.sps.scenario_ISAC)
    tar_speed = app.txSpeed.Value;
    tar_acceleration = app.txAcceleration.Value;
    tar_initialPos = [app.txInitialPos.Value,app.txInitialPos_2.Value,app.txInitialPos_3.Value];
    tar_trackOri = mf.str2positions(app.txTrackOri.Value);
    %cm.tar_initialPos = 
    cm.tar_track = track(app.txTrackType.Value, app.trackLength.Value, tar_speed, tar_acceleration, tar_initialPos, tar_trackOri, app.sampleRate.Value); % XUFAN 修改为从界面获取
    cm.tar_num = app.noCluster_9.Value;  % TODO CHENZIXUAN XUFAN

    % TODO CHENZIXUAN
    cm.tar_array = antenna_array('linear', app.noCluster_10.Value, app.sps.carrier_frequency(1),0.5,[],[],0,0,0);
    % % TODO CHENZIXUAN

    cm.sim_params.use_3GPP_baseline = true;
    cm.sim_params.use_large_bandwidth_3GPP = false;
    cm.sim_params.use_absolute_delays_3GPP = false;
    cm.sim_params.use_dual_mobility_3GPP = true;
end
end
