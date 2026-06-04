function [capAcc, snr, cPre, cOri] = compute_capacity_accuracy(preds_dbm, gt_dbm, bandwidthHz, noise_dBm)
%COMPUTE_CAPACITY_ACCURACY Capacity matching metric used by the App.

curr_dim = size(gt_dbm, 2);
pre_W = 10 .^ (preds_dbm / 10 - 3);
ori_W = 10 .^ (gt_dbm / 10 - 3);
pre_total_power = sum(pre_W, 2);
ori_total_power = sum(ori_W, 2);

snr = zeros(numel(noise_dBm), 1);
cPre = zeros(numel(noise_dBm), 1);
cOri = zeros(numel(noise_dBm), 1);
for i = 1:numel(noise_dBm)
    N_W = 10^(noise_dBm(i)/10 - 3);
    cPre(i) = mean(bandwidthHz * log2(1 + (pre_total_power/curr_dim) / N_W)) / 1e9;
    cOri(i) = mean(bandwidthHz * log2(1 + (ori_total_power/curr_dim) / N_W)) / 1e9;
    snr(i) = 10*log10(mean(ori_total_power/curr_dim)/N_W);
end
error_ratio = mean(abs(cPre - cOri) ./ cOri);
capAcc = max(0, (1 - error_ratio)) * 100;
end

