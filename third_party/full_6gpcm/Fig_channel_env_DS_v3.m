%% plot_RL_channel_env_DS_v3.m
% 用途：
% 1）批量调用 RL_channel_env_DS_v3
% 2）读取测量 DS 数据
% 3）将不同算法的仿真CDF插值到统一x轴
% 4）绘制 DS 对比图

close all; clc; clear
set(0,'DefaultAxesFontName','Times New Roman');
set(0,'DefaultTextFontName','Times New Roman');

%% ===================== 1) 算法参数 =====================
algorithms = [ ...
    struct('name','3GPP',       'DS_mu',-7.225,'DS_sigma',0.26 ,'r_DS',2.5,'num_clusters',12,'num_rays',20,'LNS_ksi',3.00,'KF_mu', 9.000,'KF_sigma',3.500), ...
    struct('name','Search grid','DS_mu',-7.551,'DS_sigma',0.05 ,'r_DS',3.0,'num_clusters',11,'num_rays',20,'LNS_ksi',3.23,'KF_mu',-1.507,'KF_sigma',3.177), ...
    struct('name','DRL-CMPO',   'DS_mu',-7.502,'DS_sigma',0.166,'r_DS',4.0,'num_clusters',18,'num_rays',15,'LNS_ksi',3.23,'KF_mu',-1.507,'KF_sigma',3.177), ...
    struct('name','PPO',        'DS_mu',-7.321,'DS_sigma',0.111,'r_DS',4.0,'num_clusters',18,'num_rays',15,'LNS_ksi',3.23,'KF_mu',-1.507,'KF_sigma',3.177), ...
    struct('name','TD3',        'DS_mu',-7.456,'DS_sigma',0.096,'r_DS',3.0,'num_clusters',10,'num_rays',19,'LNS_ksi',6.00,'KF_mu',-2.210,'KF_sigma',5.610) ...
];

%% ===================== 2) 全局配置 =====================
target_data_mat_path = '.\data\UM-MIMO.mat';
max_attempts         = 10;                    % KS异常时最大重试次数
ks_retry_threshold   = 0.95;                  % KS大于该值认为结果异常
x_fine_DS            = linspace(0,150,1000);  % 统一DS横坐标
fit_gaussian         = false;                 % 是否绘制测量高斯拟合曲线

%% ===================== 3) 导入测量数据 =====================
fprintf('正在导入测量数据...\n');
[x_mea_DS, mea_DS] = import_measurement_data_DS_v1(target_data_mat_path);

if numel(x_mea_DS) ~= numel(mea_DS)
    error('测量数据 x_mea_DS 与 mea_DS 长度不匹配，请检查数据文件。');
end

fprintf('测量数据导入完成，数据点数 = %d\n', numel(x_mea_DS));

%% ===================== 4) 测量高斯拟合（可选） =====================
cdf_fit_DS = [];

if fit_gaussian
    normcdf_fun = @(p,x) 0.5 * (1 + erf((x - p(1)) ./ (p(2) * sqrt(2))));
    p0 = [mean(x_mea_DS), std(x_mea_DS)];

    pDS = lsqcurvefit( ...
        normcdf_fun, p0, x_mea_DS, mea_DS, [], [], ...
        optimset('Display','off'));

    cdf_fit_DS = normcdf_fun(pDS, x_fine_DS);

    fprintf('高斯拟合完成：DS(mu = %.4f, sigma = %.4f)\n', pDS(1), pDS(2));
end

%% ===================== 5) 批量仿真并插值到统一x轴 =====================
fprintf('\n正在获取各算法仿真结果...\n');
alg_results = cell(numel(algorithms),1);

for i = 1:numel(algorithms)
    alg = algorithms(i);
    fprintf('--- %s ---\n', alg.name);

    result_DS = get_algorithm_result_DS(alg, max_attempts, ks_retry_threshold);

    simDS = interp1(result_DS.x_common, result_DS.sim_cdf, x_fine_DS, 'pchip', 'extrap');

    % 外延补齐：左0右1，并截断到[0,1]
    simDS(x_fine_DS <= min(result_DS.x_common)) = 0;
    simDS(x_fine_DS >= max(result_DS.x_common)) = 1;
    simDS = min(max(simDS, 0), 1);

    alg_results{i} = struct( ...
        'name', alg.name, ...
        'result_DS', result_DS, ...
        'sim_cdf_DS_interp', simDS);

    fprintf('  DS: NRMSE = %.4f, KS = %.4f\n', ...
        result_DS.nrmse, result_DS.ks_distance);
end

%% ===================== 6) 绘图 =====================
fprintf('\n正在绘制 DS 对比图...\n');
plot_cdf_comparison_DS( ...
    x_mea_DS, mea_DS, x_fine_DS, cdf_fit_DS, alg_results, fit_gaussian);

fprintf('\nDS对比图绘制完成！\n');

%% ===================== 7) 可选：保存结果到工作区 =====================
assignin('base', 'algorithms_DS', algorithms);
assignin('base', 'alg_results_DS', alg_results);
assignin('base', 'x_mea_DS', x_mea_DS);
assignin('base', 'mea_DS', mea_DS);
assignin('base', 'x_fine_DS', x_fine_DS);

%% ========================================================================
%% 获取单个算法结果（带KS异常重试）
function result_DS = get_algorithm_result_DS(alg, max_attempts, ks_retry_threshold)

    ks = inf;
    attempt = 0;
    result_DS = [];

    while ks > ks_retry_threshold && attempt < max_attempts
        [res_DS, ~, ~] = RL_channel_env_DS_v3( ...
            alg.DS_mu, alg.DS_sigma, alg.r_DS, ...
            alg.num_clusters, alg.num_rays, alg.LNS_ksi, ...
            alg.KF_mu, alg.KF_sigma);

        result_DS = res_DS;
        ks = res_DS.ks_distance;
        attempt = attempt + 1;

        if ks > ks_retry_threshold
            fprintf('  第%d次尝试 - KS异常(%.4f)，重试...\n', attempt, ks);
        end
    end

    if ks > ks_retry_threshold
        warning('%s：%d次尝试后KS仍异常(%.4f)，结果可能不可靠。', ...
            alg.name, attempt, ks);
    end
end

%% ========================================================================
%% 导入并清洗测量DS数据
function [x_mea_DS, mea_DS] = import_measurement_data_DS_v1(target_data_mat_path)

    if ~exist(target_data_mat_path, 'file')
        error('未找到测量数据文件：%s', target_data_mat_path);
    end

    loaded_data = load(target_data_mat_path);

    if ~isfield(loaded_data, 'x_mea_DS') || ~isfield(loaded_data, 'mea_DS')
        error(['目标数据.mat 文件中必须包含变量 "x_mea_DS" 和 "mea_DS"。', ...
               '请检查变量名是否正确。']);
    end

    x_mea_DS = loaded_data.x_mea_DS(:);
    mea_DS   = loaded_data.mea_DS(:);

    valid = isfinite(x_mea_DS) & isfinite(mea_DS) & ...
            isreal(x_mea_DS)   & isreal(mea_DS);

    x_mea_DS = x_mea_DS(valid);
    mea_DS   = mea_DS(valid);

    if isempty(x_mea_DS) || isempty(mea_DS)
        error('测量数据为空，或清洗无效值后为空。');
    end

    if numel(x_mea_DS) ~= numel(mea_DS)
        error('x_mea_DS 与 mea_DS 长度必须一致。');
    end

    [x_mea_DS, idx] = sort(x_mea_DS);
    mea_DS = mea_DS(idx);

    [x_mea_DS, ia] = unique(x_mea_DS, 'stable');
    mea_DS = mea_DS(ia);
end

%% ========================================================================
%% DS对比图绘制
function plot_cdf_comparison_DS(x_mea_DS, mea_DS, x_fine_DS, cdf_fit_DS, alg_results, show_fit)

    % ===== 用户可调区 =====
    marker_every = 40;
    lw_main      = 2.2;
    x_min        = 0;
    x_max        = 150;
    xt_step      = 30;
    % ====================

    figure('Color','white','Position',[100,100,800,600]);
    hold on; box on; grid on;

    % 测量点
    scatter(x_mea_DS(:), mea_DS(:), 70, 'filled', ...
        'MarkerFaceColor', [0.9 0.2 0.2], ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.1, ...
        'DisplayName', 'Measurements');

    % 测量拟合曲线（可选）
    if show_fit && ~isempty(cdf_fit_DS)
        plot(x_fine_DS, cdf_fit_DS, ...
            'LineWidth', lw_main, ...
            'Color', [0.9 0.2 0.2], ...
            'LineStyle', '-', ...
            'DisplayName', 'Fitted (Meas.)');
    end

    % 算法曲线
    for i = 1:numel(alg_results)
        alg = alg_results{i};
        [color, linestyle, marker, dispname] = style_from_name(alg.name);

        plot(x_fine_DS, alg.sim_cdf_DS_interp, ...
            'LineWidth', lw_main, ...
            'Color', color, ...
            'LineStyle', linestyle, ...
            'Marker', marker, ...
            'MarkerIndices', 1:marker_every:numel(x_fine_DS), ...
            'MarkerSize', 7, ...
            'DisplayName', dispname);
    end

    xlabel('DS (ns)', 'FontSize', 18);
    ylabel('CDF', 'FontSize', 18);
    title(' ', 'FontSize', 16);

    xlim([x_min x_max]);
    xticks(x_min:xt_step:x_max);
    ylim([0 1]);
    yticks(0:0.1:1);

    set(gca, 'FontSize', 20, 'GridLineStyle', ':', 'TickDir', 'in');
    legend('Location', 'southeast', 'FontSize', 24, 'Box', 'on');

    hold off;
end

%% ========================================================================
%% 样式映射：颜色/线型/marker
function [color, linestyle, marker, alg_label] = style_from_name(fname)

    fl = lower(string(fname));

    if contains(fl,'3gpp')
        alg_label = '3GPP';
        color     = [1,   0.5, 0];
        linestyle = ':';
        marker    = 'v';

    elseif contains(fl,'search')
        alg_label = 'Grid Search';
        color     = [0,   0,   1];
        linestyle = '--';
        marker    = 'd';

    elseif contains(fl,'drl') || contains(fl,'cmpo') || contains(fl,'sac') || contains(fl,'rl4cm')
        alg_label = 'DRL-CMPO';
        color     = [0,   0.5, 0];
        linestyle = '-.';
        marker    = 's';

    elseif contains(fl,'ppo')
        alg_label = 'PPO';
        color     = [0,   0.3, 0.7];
        linestyle = '--';
        marker    = 'o';

    elseif contains(fl,'td3')
        alg_label = 'TD3';
        color     = [0.5, 0,   0.5];
        linestyle = '-';
        marker    = '^';

    else
        alg_label = char(fname);
        color     = [0, 0, 0];
        linestyle = '-';
        marker    = 'o';
    end
end