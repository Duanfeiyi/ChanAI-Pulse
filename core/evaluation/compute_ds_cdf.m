function [xp, fp, xo, fo] = compute_ds_cdf(preds_dbm, gt_dbm, bandwidthHz)
%COMPUTE_DS_CDF Delay-spread CDF approximation used by prediction plots.

curr_dim = size(gt_dbm, 2);
pre_W = 10 .^ (preds_dbm / 10 - 3);
ori_W = 10 .^ (gt_dbm / 10 - 3);
pre_total_power = sum(pre_W, 2);
ori_total_power = sum(ori_W, 2);

idx_ax = 0:(curr_dim-1);
dt_ns = (1 / bandwidthHz) * 1e9;
if curr_dim > 1
    ptau = sqrt(sum((idx_ax - (sum(idx_ax.*pre_W,2)./pre_total_power)).^2 .* pre_W, 2)./pre_total_power) * dt_ns;
    otau = sqrt(sum((idx_ax - (sum(idx_ax.*ori_W,2)./ori_total_power)).^2 .* ori_W, 2)./ori_total_power) * dt_ns;
    p_mu = mean(ptau(:));
    p_sig = std(ptau(:));
    o_mu = mean(otau(:));
    o_sig = std(otau(:));
    cx = linspace(min([ptau(:); otau(:)]), max([ptau(:); otau(:)]), 1000);
    fp = 0.5 * (1 + erf((cx - p_mu) ./ (max(1e-6, p_sig) * sqrt(2))));
    xp = cx;
    fo = 0.5 * (1 + erf((cx - o_mu) ./ (max(1e-6, o_sig) * sqrt(2))));
    xo = cx;
else
    fp = [0 1];
    xp = [0 0];
    fo = [0 1];
    xo = [0 0];
end
end

