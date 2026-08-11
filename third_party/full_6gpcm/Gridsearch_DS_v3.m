% RL_Search_DS_v3.m
clear; clc;

%% ===================== 1) 人工配置区 =====================
rng_seed = 1;
rng(rng_seed);

use_env_conf_start = true;

env_conf.carrier_frequency = 5.3e9;
env_conf.scenario_name     = 'sub-6 GHz_UMa_LoS';

param_table = struct( ...
    'DS_mu',        struct('value', -7.225, 'bounds', [-7.5, -6.0], 'is_search', true ), ...
    'DS_sigma',     struct('value',  0.260, 'bounds', [ 0.10, 2.00], 'is_search', true ), ...
    'r_DS',         struct('value',  2.500, 'bounds', [ 1.00, 5.00], 'is_search', true ), ...
    'num_clusters', struct('value', 12,     'bounds', [ 10,   25  ], 'is_search', true ), ...
    'num_rays',     struct('value', 20,     'bounds', [ 10,   40  ], 'is_search', true ), ...
    'LNS_ksi',      struct('value',  3.000, 'bounds', [ 3.00, 6.00], 'is_search', true ), ...
    'KF_mu',        struct('value',  9.000, 'bounds', [-10,  20  ], 'is_search', false), ...
    'KF_sigma',     struct('value',  3.500, 'bounds', [ 0.00, 10.0 ], 'is_search', false) ...
);

N_coarse = 30; % 粗搜候选数
N_local  = 40; % 局部迭代数
n_repeat = 1; %避免信道生成随机性，重复生成次数

step1 = struct( ...
    'DS_mu',        0.1, ...
    'DS_sigma',     0.20, ...
    'r_DS',         0.50, ...
    'num_clusters', 3, ...
    'num_rays',     3, ...
    'LNS_ksi',      0.50, ...
    'KF_mu',        1.00, ...
    'KF_sigma',     0.50);

shrink_ratio  = 0.5;
shrink_rounds = [round(N_local*0.33), round(N_local*0.66)];

%% ===================== 2) 读取起点 =====================
param_table = load_param_table_from_env_conf(use_env_conf_start, env_conf, param_table);

fprintf('\n==================== 当前搜索起点 ====================\n');
print_param_table(param_table);

cfg0 = param_table_to_cfg(param_table);

%% ===================== 3) 评估起点 =====================
[best_obj, best_ks] = eval_cfg(cfg0, n_repeat);
best_cfg = cfg0;

fprintf('\nInit: NRMSE=%.6f, KS=%.6f | %s\n', ...
    best_obj, best_ks, cfg_to_string(best_cfg));

%% ===================== 4) 阶段1：随机粗搜 =====================
fprintf('\nStage-1: coarse random search...\n');

for k = 1:N_coarse
    cfg = sample_cfg(cfg0, param_table, step1);
    cfg = project_to_bounds(cfg, param_table);

    [obj_mean, ks_mean] = eval_cfg(cfg, n_repeat);

    if obj_mean < best_obj
        best_obj = obj_mean;
        best_ks  = ks_mean;
        best_cfg = cfg;

        fprintf('  [Improved] NRMSE=%.6f, KS=%.6f | %s\n', ...
            best_obj, best_ks, cfg_to_string(best_cfg));
    else
        fprintf('  tried NRMSE=%.6f, KS=%.6f\n', obj_mean, ks_mean);
    end
end

%% ===================== 5) 阶段2：局部缩步搜索 =====================
fprintf('\nStage-2: local search...\n');

step2 = step1;

for t = 1:N_local
    if any(t == shrink_rounds)
        step2 = shrink_step(step2, shrink_ratio);
    end

    cfg = sample_cfg(best_cfg, param_table, step2);
    cfg = project_to_bounds(cfg, param_table);

    [obj_mean, ks_mean] = eval_cfg(cfg, n_repeat);

    if obj_mean < best_obj
        best_obj = obj_mean;
        best_ks  = ks_mean;
        best_cfg = cfg;

        fprintf('  [Improved] NRMSE=%.6f, KS=%.6f | %s\n', ...
            best_obj, best_ks, cfg_to_string(best_cfg));
    else
        fprintf('  tried NRMSE=%.6f, KS=%.6f\n', obj_mean, ks_mean);
    end
end

%% ===================== 6) 输出最终结果 =====================
fprintf('\n==================== Best Found ====================\n');
fprintf('best_nrmse = %.6f\n', best_obj);
fprintf('best_ks    = %.6f\n', best_ks);
fprintf('%s\n', cfg_to_code_string(best_cfg));

%% ========================================================================
function [obj_mean, ks_mean] = eval_cfg(cfg, n_repeat)

    obj_list = zeros(1, n_repeat);
    ks_list  = zeros(1, n_repeat);

    for r = 1:n_repeat
        [res_DS, ~, ~] = RL_channel_env_DS_v3( ...
            cfg.DS_mu, cfg.DS_sigma, cfg.r_DS, ...
            cfg.num_clusters, cfg.num_rays, cfg.LNS_ksi, ...
            cfg.KF_mu, cfg.KF_sigma);

        obj_list(r) = res_DS.nrmse;
        ks_list(r)  = res_DS.ks_distance;
    end

    obj_mean = mean(obj_list, 'omitnan');
    ks_mean  = mean(ks_list, 'omitnan');
end

%% ========================================================================
function cfg = sample_cfg(center_cfg, param_table, step)

    cfg = center_cfg;
    names = fieldnames(param_table);

    for i = 1:numel(names)
        name = names{i};

        if ~param_table.(name).is_search
            continue;
        end

        if ~isfield(step, name)
            continue;
        end

        if is_integer_param(name)
            cfg.(name) = center_cfg.(name) + round(step.(name) * randn);
        else
            cfg.(name) = center_cfg.(name) + step.(name) * randn;
        end
    end
end

%% ========================================================================
function cfg = project_to_bounds(cfg, param_table)

    names = fieldnames(param_table);

    for i = 1:numel(names)
        name = names{i};
        bd = param_table.(name).bounds;

        cfg.(name) = min(max(cfg.(name), bd(1)), bd(2));

        if is_integer_param(name)
            cfg.(name) = round(cfg.(name));
        end
    end
end

%% ========================================================================
function step_out = shrink_step(step_in, ratio)

    step_out = step_in;
    names = fieldnames(step_in);

    for i = 1:numel(names)
        name = names{i};

        if is_integer_param(name)
            step_out.(name) = max(1, round(step_in.(name) * ratio));
        else
            step_out.(name) = step_in.(name) * ratio;
        end
    end
end

%% ========================================================================
function tf = is_integer_param(name)

    tf = ismember(name, {'num_clusters', 'num_rays'});
end

%% ========================================================================
function param_table = load_param_table_from_env_conf(use_env_conf_start, env_conf, param_table)

    if ~use_env_conf_start
        fprintf('未启用环境conf起点读取，使用手工起点。\n');
        return;
    end

    sps = simulation_parameters;
    sps.carrier_frequency = env_conf.carrier_frequency;
    sps.setScenario(env_conf.scenario_name);

    cm = channel_model(sps);

    param_table.DS_mu.value        = get_param_value(cm.sim_params.scen_para, 'DS_mu',        1, param_table.DS_mu.value);
    param_table.DS_sigma.value     = get_param_value(cm.sim_params.scen_para, 'DS_sigma',     1, param_table.DS_sigma.value);
    param_table.r_DS.value         = get_param_value(cm.sim_params.scen_para, 'r_DS',         1, param_table.r_DS.value);
    param_table.LNS_ksi.value      = get_param_value(cm.sim_params.scen_para, 'LNS_ksi',      1, param_table.LNS_ksi.value);
    param_table.KF_mu.value        = get_param_value(cm.sim_params.scen_para, 'KF_mu',        1, param_table.KF_mu.value);
    param_table.KF_sigma.value     = get_param_value(cm.sim_params.scen_para, 'KF_sigma',     1, param_table.KF_sigma.value);

    if ~isempty(cm.clusters.num_clusters)
        param_table.num_clusters.value = cm.clusters.num_clusters;
    end

    if ~isempty(cm.clusters.num_rays_each_cluster)
        param_table.num_rays.value = cm.clusters.num_rays_each_cluster;
    end

    fprintf('已从场景conf读取起点: fc=%.4e, scenario=%s\n', ...
        env_conf.carrier_frequency, env_conf.scenario_name);
end

%% ========================================================================
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

%% ========================================================================
function cfg = param_table_to_cfg(param_table)

    names = fieldnames(param_table);
    cfg = struct();

    for i = 1:numel(names)
        name = names{i};
        cfg.(name) = param_table.(name).value;
    end
end

%% ========================================================================
function print_param_table(param_table)

    names = fieldnames(param_table);

    for i = 1:numel(names)
        name = names{i};
        item = param_table.(name);

        if is_integer_param(name)
            fprintf('%-12s = %d    [%g, %g]    is_search=%d\n', ...
                name, round(item.value), item.bounds(1), item.bounds(2), item.is_search);
        else
            fprintf('%-12s = %.6f    [%g, %g]    is_search=%d\n', ...
                name, item.value, item.bounds(1), item.bounds(2), item.is_search);
        end
    end
end

%% ========================================================================
function s = cfg_to_string(cfg)

    s = sprintf(['DS_mu=%.3f, DS_sigma=%.3f, r_DS=%.3f, ' ...
                 'C=%d, R=%d, LNS=%.2f, KF_mu=%.3f, KF_sigma=%.3f'], ...
                 cfg.DS_mu, cfg.DS_sigma, cfg.r_DS, ...
                 cfg.num_clusters, cfg.num_rays, cfg.LNS_ksi, ...
                 cfg.KF_mu, cfg.KF_sigma);
end

%% ========================================================================
function s = cfg_to_code_string(cfg)

    s = sprintf(['''DS_mu'',%.3f,''DS_sigma'',%.3f,''r_DS'',%.3f,' ...
                 '''num_clusters'',%d,''num_rays'',%d,''LNS_ksi'',%.2f,' ...
                 '''KF_mu'',%.3f,''KF_sigma'',%.3f'], ...
                 cfg.DS_mu, cfg.DS_sigma, cfg.r_DS, ...
                 cfg.num_clusters, cfg.num_rays, cfg.LNS_ksi, ...
                 cfg.KF_mu, cfg.KF_sigma);
end