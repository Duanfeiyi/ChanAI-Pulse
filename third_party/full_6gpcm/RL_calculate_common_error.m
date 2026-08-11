function [nrmse, ks_distance, sim_cdf, target_cdf_common, x_common] = ...
    RL_calculate_common_error(sim_data, x_target, target_cdf)
% RL_calculate_common_error
% 输入：
%   sim_data    - 仿真原始样本
%   x_target    - 目标数据横坐标
%   target_cdf  - 目标累计CDF
%
% 输出：
%   nrmse             - 两条CDF之间的归一化均方根误差
%   ks_distance       - 两条CDF之间的最大绝对差
%   sim_cdf           - 公共横坐标上的仿真CDF
%   target_cdf_common - 公共横坐标上的目标CDF
%   x_common          - 公共横坐标

    % ---------- 数据整理 ----------
    sim_data = sim_data(:);
    sim_data = sim_data(isfinite(sim_data) & isreal(sim_data));

    x_target = x_target(:);
    target_cdf = target_cdf(:);
    valid = isfinite(x_target) & isfinite(target_cdf) & isreal(x_target) & isreal(target_cdf);
    x_target = x_target(valid);
    target_cdf = target_cdf(valid);

    if isempty(sim_data) || isempty(x_target) || isempty(target_cdf)
        error('输入数据为空或包含无效值。');
    end
    if numel(x_target) ~= numel(target_cdf)
        error('x_target 和 target_cdf 长度必须一致。');
    end

    % ---------- 排序、去重、规范CDF ----------
    [x_target, idx] = sort(x_target);
    target_cdf = target_cdf(idx);

    [x_target, ia] = unique(x_target, 'stable');
    target_cdf = target_cdf(ia);

    target_cdf = max(target_cdf, 0);
    target_cdf = min(target_cdf, 1);
    target_cdf = cummax_local(target_cdf);

    if target_cdf(end) > target_cdf(1)
        target_cdf = (target_cdf - target_cdf(1)) / (target_cdf(end) - target_cdf(1));
    else
        target_cdf = zeros(size(target_cdf));
    end

    % ---------- 公共横坐标 ----------
    xmin = min([sim_data; x_target]);
    xmax = max([sim_data; x_target]);
    x_common = unique([x_target; linspace(xmin, xmax, 400).']);

    % ---------- 仿真CDF ----------
    sim_sorted = sort(sim_data);
    sim_cdf = arrayfun(@(x) mean(sim_sorted <= x), x_common);

    % ---------- 目标CDF插值到公共横坐标 ----------
    target_cdf_common = interp1(x_target, target_cdf, x_common, 'linear', 'extrap');
    target_cdf_common(x_common < x_target(1)) = 0;
    target_cdf_common(x_common > x_target(end)) = 1;
    target_cdf_common = max(target_cdf_common, 0);
    target_cdf_common = min(target_cdf_common, 1);
    target_cdf_common = cummax_local(target_cdf_common);

    % ---------- 误差 ----------
    diff_cdf = sim_cdf - target_cdf_common;
    ks_distance = max(abs(diff_cdf));
    nrmse = sqrt(mean(diff_cdf.^2));   % 因CDF范围本身是[0,1]，这里直接就是NRMSE
end

function y = cummax_local(x)
    y = x;
    for i = 2:numel(y)
        if y(i) < y(i-1)
            y(i) = y(i-1);
        end
    end
end