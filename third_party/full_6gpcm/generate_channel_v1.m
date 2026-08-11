function [H_all, delay_all] = generate_channel_v1( ...
    DS_mu, DS_sigma, r_DS, num_clusters, num_rays, LNS_ksi, KF_mu, KF_sigma, N)
% generate_channel_v1
% 根据给定的信道模型参数，生成 N 个 H 矩阵及对应 delay

    %% 1）初始化
    if ~isscalar(N) || N <= 0 || floor(N) ~= N
        error('N 必须是正整数。');
    end

    sps = simulation_parameters;
    sps.carrier_frequency = 16e9;
    sps.setScenario('cmWave_Indoor_LoS');

    move_time = 1;
    samp_rate = 1;
    tx_ini_position = [3.2, 2.4, 2.6];
    rx_ini_position = [1, 3, 1.45];
    antenna_spacing = 0.5;

    tx_track = track('static', move_time, 5, 1, tx_ini_position, [1 1 0], samp_rate);
    rx_track = track('static', move_time, 0, 0, rx_ini_position, [1 1 0], samp_rate);

    cm = channel_model(sps);
    cm.rx_array = antenna_array('linear', 2, sps.carrier_frequency, antenna_spacing, [], [], 0, 0, 0);
    cm.tx_array = antenna_array('linear', 2, sps.carrier_frequency, antenna_spacing, [], [], 0, 0, 0);
    cm.rx_track = rx_track;
    cm.tx_track = tx_track;

    %% 2）写入输入参数
    cm.clusters.num_clusters = num_clusters;
    cm.clusters.num_rays_each_cluster = num_rays;
    cm.sim_params.scen_para.DS_mu = DS_mu;
    cm.sim_params.scen_para.DS_sigma = DS_sigma;
    cm.sim_params.scen_para.r_DS = r_DS;
    cm.sim_params.scen_para.LNS_ksi = LNS_ksi;
    cm.sim_params.scen_para.KF_mu = KF_mu;
    cm.sim_params.scen_para.KF_sigma = KF_sigma;

    %% 3）生成 N 个 H 矩阵
    H_all = cell(N, 1);
    delay_all = cell(N, 1);

    for i = 1:N
        [result, delay, ~, ~] = cm.get_CIR([], '', []);
        [H, delay] = mf.result2H(result(1,1,:), delay(1,1,:));
        H_all{i} = H;
        delay_all{i} = delay;
    end
end