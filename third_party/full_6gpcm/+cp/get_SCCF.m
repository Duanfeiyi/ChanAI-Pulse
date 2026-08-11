function [ccf, scd] = get_SCCF(h,t_ind,antenna_side,ant_index)
% Input: 
% h : CIR, no_rxant*no_txant*no_snaps*no_carriers
% t_ind: the selected snapshot
% antenna_side: Tx or Rx
% ant_index: the selected antenna index
% Output: 
% ccf: spatial cross-correlation function
% scd: spatial coherence distance
if length(t_ind) > 1
    error('The SCCF should be computed at one snapshot at one time.')
end

switch antenna_side
    case 'Tx'
        h_ccf = squeeze(sum(h(ant_index, :, t_ind, :), 4)); % narrowband cir
        no_ant = size(h, 2);
    case 'Rx'
        h_ccf = squeeze(sum(h(:, ant_index, t_ind, :), 4)); % narrowband cir
        no_ant = size(h, 1);
end
ccf_temp = xcorr(h_ccf, 'coeff');
ccf = abs(ccf_temp(no_ant: end));
tmp = ccf > 0.5;
scd = tmp(1);
