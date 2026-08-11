function [Result_DS, state, Capacity] = RL_channel_env_DS_v3( ...
    DS_mu, DS_sigma, r_DS, num_clusters, num_rays, LNS_ksi, KF_mu, KF_sigma)
% RL_channel_env_DS_v3
% 仅针对 DS（时延扩展）进行拟合的强化学习环境函数
%
% 输入参数：
%   DS_mu        - 时延扩展对数正态分布均值
%   DS_sigma     - 时延扩展对数正态分布标准差
%   r_DS         - 时延缩放因子
%   num_clusters - 簇个数
%   num_rays     - 簇内子径数
%   LNS_ksi      - 簇阴影衰落因子
%   KF_mu        - 莱斯因子均值
%   KF_sigma     - 莱斯因子标准差
%
% 输出参数：
%   Result_DS - 包含 nrmse、ks_distance、sim_cdf、mea_cdf、x_common
%   state     - 输入参数向量
%   Capacity  - 结构体，包含 SNR_dB 与 CP

    %% 1）初始化
    % 1.1 场景与系统参数初始化
    sps = simulation_parameters;
    sps.carrier_frequency = 5.3e9;
    sps.setScenario('sub-6 GHz_UMa_LoS');

    move_time = 1;
    samp_rate = 1;
    rx_ini_position = [0, 0, 20];
    tx_ini_position = [10, 120, 1.5];
    antenna_spacing = 0.5;

    loop = 1000;
    SNR_dB_cap = -10:5:10;
    span_cap = 1;

    tx_track = track('static', move_time, 0, 0, tx_ini_position, [1 0 0], samp_rate);
    rx_track = track('static', move_time, 0, 0, rx_ini_position, [1 0 0], samp_rate);

    cm = channel_model(sps);
    cm.rx_array = antenna_array('linear', 4, sps.carrier_frequency, antenna_spacing, [], [], 0, 0, 0);
    cm.tx_array = antenna_array('linear', 2, sps.carrier_frequency, antenna_spacing, [], [], 0, 0, 0);
    cm.rx_track = rx_track;
    cm.tx_track = tx_track;

    delay_spread = zeros(1, loop);
    CP_loop = zeros(length(SNR_dB_cap), loop);

    % 1.2 导入 DS 目标数据
    % 请手动填写 DS 目标数据 .mat 文件路径
    target_data_mat_path = '.\data\UM-MIMO.mat';

    % -----------------------------------------------------------------
    % .mat 文件数据格式要求：
    %
    % 文件中只需要包含以下两个变量：
    %   x_mea_DS   - 目标数据横坐标
    %   mea_DS     - 对应的累计CDF
    %
    % 不要求必须拼成 N×2 矩阵，只要这两个变量存在即可。
    %
    % 示例：
    %   x_mea_DS = [5; 10; 15; 20];
    %   mea_DS   = [0.10; 0.25; 0.60; 1.00];
    %
    % 保存示例：
    %   save('target_data_DS.mat', 'x_mea_DS', 'mea_DS');
    % -----------------------------------------------------------------

    loaded_data = load(target_data_mat_path);

    if ~isfield(loaded_data, 'x_mea_DS') || ~isfield(loaded_data, 'mea_DS')
        error(['目标数据.mat 文件中必须包含变量 "x_mea_DS" 和 "mea_DS"。', ...
               '请检查变量名是否正确。']);
    end

    x_mea_DS = loaded_data.x_mea_DS(:);
    mea_DS   = loaded_data.mea_DS(:);

    valid = isfinite(x_mea_DS) & isfinite(mea_DS) & isreal(x_mea_DS) & isreal(mea_DS);
    x_mea_DS = x_mea_DS(valid);
    mea_DS   = mea_DS(valid);

    if isempty(x_mea_DS) || isempty(mea_DS)
        error('目标数据为空，或清理无效值后为空。');
    end

    if numel(x_mea_DS) ~= numel(mea_DS)
        error('x_mea_DS 和 mea_DS 的长度必须一致。');
    end

    [x_mea_DS, idx] = sort(x_mea_DS);
    mea_DS = mea_DS(idx);

    [x_mea_DS, ia] = unique(x_mea_DS, 'stable');
    mea_DS = mea_DS(ia);

    %% 2）应用输入参数
    cm.clusters.num_clusters = num_clusters;
    cm.clusters.num_rays_each_cluster = num_rays;
    cm.sim_params.scen_para.DS_mu = DS_mu;
    cm.sim_params.scen_para.DS_sigma = DS_sigma;
    cm.sim_params.scen_para.r_DS = r_DS;
    cm.sim_params.scen_para.LNS_ksi = LNS_ksi;
    cm.sim_params.scen_para.KF_mu = KF_mu;
    cm.sim_params.scen_para.KF_sigma = KF_sigma;

    %% 3）蒙特卡罗仿真：计算 DS 与容量
    for i_loop = 1:loop
        [result, delay, ~, ~] = cm.get_CIR([], '', []);
        [H, delay] = mf.result2H(result(1,1,:), delay(1,1,:));

        current_num_snap = size(H, 3);
        CP_snap = zeros(length(SNR_dB_cap), current_num_snap);

        for i_snap = 1:current_num_snap
            cir_tx_rx_L = squeeze(H(:,:,i_snap,:));   % [Nt x Nr x L]
            cir1 = permute(cir_tx_rx_L, [2 1 3]);     % [Nr x Nt x L]
            [CP_s, ~] = calc_capacity(cir1, SNR_dB_cap, span_cap);
            CP_snap(:, i_snap) = CP_s;
        end

        CP_loop(:, i_loop) = mean(CP_snap, 2);

        H1 = squeeze(abs(H).^2);
        taus = squeeze(delay(1,1,1,:));
        delay_PSD = squeeze(H1(1,1,1,:));

        [ds, ~] = mf.calc_ds(taus.', delay_PSD.');
        delay_spread(i_loop) = mean(ds) * 1e9;   % ns
    end

    %% 4）容量输出
    CP_erg = mean(CP_loop, 2);
    Capacity = struct( ...
        'SNR_dB', SNR_dB_cap, ...
        'CP', CP_erg ...
    );

    %% 5）计算 DS 误差
    [nrmse_DS, ks_distance_DS, sim_cdf_DS, mea_cdf_DS, x_common_DS] = ...
        RL_calculate_common_error(delay_spread, x_mea_DS, mea_DS);

    %% 6）输出结果
    Result_DS = struct( ...
        'nrmse', nrmse_DS, ...
        'ks_distance', ks_distance_DS, ...
        'sim_cdf', sim_cdf_DS, ...
        'mea_cdf', mea_cdf_DS, ...
        'x_common', x_common_DS ...
    );

    state = [DS_mu, DS_sigma, r_DS, num_clusters, num_rays, LNS_ksi, KF_mu, KF_sigma];
end