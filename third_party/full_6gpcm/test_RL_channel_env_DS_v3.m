%% test_RL_channel_env_DS_v3.m
% 用途：
% 1）检查 RL_channel_env_DS_v3 相关依赖是否存在
% 2）检查 UMa 场景与底层 get_CIR 是否正常
% 3）检查目标数据格式是否正确
% 4）预检查 DS 是否能正常算出有限值
% 5）完整调用 RL_channel_env_DS_v3，检查输出是否正确

clear; clc;

fprintf('\n============================================================\n');
fprintf('开始测试：RL_channel_env_DS_v3 是否可以正常运行\n');
fprintf('============================================================\n\n');

%% ===================== 0）基础设置 =====================
project_root = fileparts(mfilename('fullpath'));
cd(project_root);
addpath(genpath(project_root));

data_dir = fullfile(project_root, 'data');
if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end

target_data_path = fullfile(data_dir, 'UM-MIMO.mat');

fprintf('工程根目录：%s\n', project_root);
fprintf('目标数据路径：%s\n\n', target_data_path);

%% ===================== 1）创建测试目标数据（若不存在） =====================
if ~exist(target_data_path, 'file')
    [x_mea_DS, mea_DS] = build_dummy_target_data(5, 300, 60);
    save(target_data_path, 'x_mea_DS', 'mea_DS');
    fprintf('[已创建] 测试目标数据文件：%s\n\n', target_data_path);
else
    fprintf('[已存在] 测试目标数据文件：%s\n\n', target_data_path);
end

%% ===================== 2）检查关键依赖 =====================
fprintf('-------------------- 依赖检查 --------------------\n');

required_items = { ...
    'simulation_parameters', ...
    'channel_model', ...
    'antenna_array', ...
    'track', ...
    'mf.result2H', ...
    'mf.calc_ds', ...
    'calc_capacity', ...
    'RL_calculate_common_error', ...
    'RL_channel_env_DS_v3' ...
    };

missing_items = {};

for i = 1:numel(required_items)
    item = required_items{i};
    item_path = safe_which(item);

    if isempty(item_path)
        fprintf('[缺失] %-30s -> 未找到\n', item);
        missing_items{end+1} = item; %#ok<SAGROW>
    else
        fprintf('[通过] %-30s -> %s\n', item, item_path);
    end
end

fprintf('\n');

if ~isempty(missing_items)
    fprintf('以下依赖未找到，请先修复路径问题：\n');
    for i = 1:numel(missing_items)
        fprintf('  - %s\n', missing_items{i});
    end
    fprintf('\n测试终止。\n');
    return;
end

%% ===================== 3）检查目标数据路径与格式 =====================
fprintf('-------------------- 目标数据检查 --------------------\n');

try
    func_file = which('RL_channel_env_DS_v3');
    func_text = fileread(func_file);

    if contains(func_text, '.\data\UM-MIMO.mat')
        fprintf('[通过] 检测到函数内部使用相对路径 .\\data\\UM-MIMO.mat\n');
    else
        fprintf('[提示] 请确认 RL_channel_env_DS_v3 内部的 target_data_mat_path 设置正确\n');
    end

    S = load(target_data_path);
    assert(isfield(S, 'x_mea_DS'), '目标数据文件缺少变量 x_mea_DS');
    assert(isfield(S, 'mea_DS'),   '目标数据文件缺少变量 mea_DS');

    x_mea_DS = S.x_mea_DS(:);
    mea_DS   = S.mea_DS(:);

    assert(~isempty(x_mea_DS), 'x_mea_DS 为空');
    assert(~isempty(mea_DS), 'mea_DS 为空');
    assert(numel(x_mea_DS) == numel(mea_DS), 'x_mea_DS 与 mea_DS 长度不一致');

    fprintf('[通过] 目标数据文件可读取，长度 = %d\n\n', numel(x_mea_DS));
catch ME
    fprintf('[失败] 目标数据检查失败\n');
    fprintf('%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    fprintf('\n测试终止。\n');
    return;
end

%% ===================== 4）底层功能冒烟测试 =====================
fprintf('-------------------- 底层功能冒烟测试 --------------------\n');

try
    sps = simulation_parameters;
    sps.carrier_frequency = 5.3e9;
    sps.setScenario('sub-6 GHz_UMa_LoS');

    move_time = 1;
    samp_rate = 1;
    rx_ini_position = [0, 0, 20];
    tx_ini_position = [10, 120, 1.5];

    tx_track = track('static', move_time, 0, 0, tx_ini_position, [1 0 0], samp_rate);
    rx_track = track('static', move_time, 0, 0, rx_ini_position, [1 0 0], samp_rate);

    cm = channel_model(sps);
    cm.rx_array = antenna_array('linear', 4, sps.carrier_frequency, 0.5, [], [], 0, 0, 0);
    cm.tx_array = antenna_array('linear', 1, sps.carrier_frequency, 0.5, [], [], 0, 0, 0);
    cm.rx_track = rx_track;
    cm.tx_track = tx_track;

    [result, delay, ~, ~] = cm.get_CIR([], '', []);
    [H, delay_num] = mf.result2H(result(1,1,:), delay(1,1,:)); 

    fprintf('[通过] get_CIR + mf.result2H 测试成功，H尺寸 = %s\n\n', mat2str(size(H)));
catch ME
    fprintf('[失败] 底层功能冒烟测试失败\n');
    fprintf('%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    fprintf('\n测试终止。\n');
    return;
end

%% ===================== 5）DS有效性预检查 =====================
fprintf('-------------------- DS有效性预检查 --------------------\n');

try
    p = cm.sim_params.scen_para;

    DS_mu        = get_param_value(p, 'DS_mu', 1, -7.0);
    DS_sigma     = get_param_value(p, 'DS_sigma', 1, 0.3);
    r_DS         = get_param_value(p, 'r_DS', 1, 2.2);
    LNS_ksi      = get_param_value(p, 'LNS_ksi', 1, 3.0);
    KF_mu        = get_param_value(p, 'KF_mu', 1, 9.0);
    KF_sigma     = get_param_value(p, 'KF_sigma', 1, 3.0);

    num_clusters = get_default_if_empty(cm.clusters.num_clusters, 12);
    num_rays     = get_default_if_empty(cm.clusters.num_rays_each_cluster, 20);

    % 把参数写入模型，模拟主函数的设置方式
    cm.clusters.num_clusters = num_clusters;
    cm.clusters.num_rays_each_cluster = num_rays;
    cm.sim_params.scen_para.DS_mu = DS_mu;
    cm.sim_params.scen_para.DS_sigma = DS_sigma;
    cm.sim_params.scen_para.r_DS = r_DS;
    cm.sim_params.scen_para.LNS_ksi = LNS_ksi;
    cm.sim_params.scen_para.KF_mu = KF_mu;
    cm.sim_params.scen_para.KF_sigma = KF_sigma;

    test_loop = 10;
    delay_spread_test = nan(1, test_loop);

    for i = 1:test_loop
        [result, delay, ~, ~] = cm.get_CIR([], '', []);
        [H, delay] = mf.result2H(result(1,1,:), delay(1,1,:));

        H1 = squeeze(abs(H).^2);
        taus = squeeze(delay(1,1,1,:));
        delay_PSD = squeeze(H1(1,1,1,:));

        [ds, ~] = mf.calc_ds(taus.', delay_PSD.');

        if ~isempty(ds) && all(isfinite(ds))
            delay_spread_test(i) = mean(ds) * 1e9;
        end
    end

    valid_num = sum(isfinite(delay_spread_test));
    fprintf('预检查中有效DS个数：%d / %d\n', valid_num, test_loop);

    if valid_num == 0
        fprintf('[失败] 预检查发现 DS 全部无效。\n');
        fprintf('这说明问题不在测试脚本，而在 RL_channel_env_DS_v3 内部生成的 delay_spread。\n');
        fprintf('优先检查以下几点：\n');
        fprintf('1）mf.calc_ds 的输入 taus 和 delay_PSD 是否为空\n');
        fprintf('2）delay_PSD 是否全为 0\n');
        fprintf('3）H 和 delay 的维度是否与代码索引方式匹配\n');
        fprintf('4）LoS场景参数是否导致当前配置下无法算出有效DS\n');
        fprintf('\n测试终止。\n');
        return;
    else
        fprintf('[通过] DS预检查正常，可继续完整测试\n\n');
    end

catch ME
    fprintf('[失败] DS有效性预检查失败\n');
    fprintf('%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    fprintf('\n测试终止。\n');
    return;
end

%% ===================== 6）完整运行 RL_channel_env_DS_v3 =====================
fprintf('-------------------- 完整运行测试 --------------------\n');

try
    fprintf('调用函数：RL_channel_env_DS_v3\n');
    fprintf(['参数：DS_mu=%.4f, DS_sigma=%.4f, r_DS=%.4f, ' ...
             'num_clusters=%d, num_rays=%d, LNS_ksi=%.4f, KF_mu=%.4f, KF_sigma=%.4f\n'], ...
        DS_mu, DS_sigma, r_DS, num_clusters, num_rays, LNS_ksi, KF_mu, KF_sigma);

    t0 = tic;
    [Result_DS, state, Capacity] = RL_channel_env_DS_v3( ...
        DS_mu, DS_sigma, r_DS, num_clusters, num_rays, LNS_ksi, KF_mu, KF_sigma);
    elapsed_time = toc(t0);

    validate_env_output(Result_DS, state, Capacity, 8);

    fprintf('\n[通过] RL_channel_env_DS_v3 运行成功，用时 %.2f 秒\n', elapsed_time);
    fprintf('       Result_DS.NRMSE       = %.6f\n', Result_DS.nrmse);
    fprintf('       Result_DS.ks_distance = %.6f\n', Result_DS.ks_distance);
    fprintf('       state长度             = %d\n', numel(state));
    fprintf('       容量点数              = %d\n', numel(Capacity.SNR_dB));

catch ME
    fprintf('\n[失败] RL_channel_env_DS_v3 完整测试失败\n');
    fprintf('%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    fprintf('\n提示：如果这里再次报“输入数据为空或包含无效值”，\n');
    fprintf('说明 RL_channel_env_DS_v3 内部 1000 次循环得到的 delay_spread 在清理后为空。\n');
    fprintf('建议你在 RL_channel_env_DS_v3 里、调用 RL_calculate_common_error 之前加上：\n\n');
    fprintf('delay_spread = delay_spread(isfinite(delay_spread) & isreal(delay_spread));\n');
    fprintf('fprintf(''有效delay_spread个数: %%d\\n'', numel(delay_spread));\n\n');
end

fprintf('\n============================================================\n');
fprintf('测试结束\n');
fprintf('============================================================\n');

%% ===================== 局部函数 =====================

function p = safe_which(name)
    p = which(name);
    if isempty(p)
        try
            if exist(name, 'class') == 8
                p = ['<class> ' name];
            elseif exist(name, 'file') == 2
                p = ['<file> ' name];
            else
                p = '';
            end
        catch
            p = '';
        end
    end
end

function [x_mea_DS, mea_DS] = build_dummy_target_data(x_min, x_max, N)
    x_mea_DS = linspace(x_min, x_max, N).';
    mu = x_min + 0.35 * (x_max - x_min);
    sigma = 0.18 * (x_max - x_min);

    pdf_like = exp(-0.5 * ((x_mea_DS - mu) / sigma).^2);
    pdf_like = pdf_like / sum(pdf_like);

    mea_DS = cumsum(pdf_like);
    mea_DS = mea_DS / mea_DS(end);
end

function val = get_param_value(scen_para, field_name, idx, fallback)
    if ~isfield(scen_para, field_name)
        val = fallback;
        return;
    end

    raw = scen_para.(field_name);

    if isempty(raw)
        val = fallback;
        return;
    end

    if isscalar(raw)
        val = raw;
        return;
    end

    raw = raw(:).';
    if numel(raw) >= idx
        val = raw(idx);
    else
        val = raw(end);
    end
end

function val = get_default_if_empty(x, fallback)
    if isempty(x)
        val = fallback;
    else
        val = x;
    end
end

function validate_env_output(Result_DS, state, Capacity, expected_state_len)
    assert(isstruct(Result_DS), 'Result_DS 不是结构体');
    assert(isfield(Result_DS, 'nrmse'),       'Result_DS 缺少字段 nrmse');
    assert(isfield(Result_DS, 'ks_distance'), 'Result_DS 缺少字段 ks_distance');
    assert(isfield(Result_DS, 'sim_cdf'),     'Result_DS 缺少字段 sim_cdf');
    assert(isfield(Result_DS, 'mea_cdf'),     'Result_DS 缺少字段 mea_cdf');
    assert(isfield(Result_DS, 'x_common'),    'Result_DS 缺少字段 x_common');

    assert(isnumeric(state), 'state 不是数值向量');
    assert(numel(state) == expected_state_len, 'state 维度不正确');

    assert(isstruct(Capacity), 'Capacity 不是结构体');
    assert(isfield(Capacity, 'SNR_dB'), 'Capacity 缺少字段 SNR_dB');
    assert(isfield(Capacity, 'CP'),     'Capacity 缺少字段 CP');
    assert(numel(Capacity.SNR_dB) == numel(Capacity.CP), 'Capacity.SNR_dB 与 Capacity.CP 长度不一致');
end