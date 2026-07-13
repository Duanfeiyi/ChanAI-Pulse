function metrics = analyze_channel_data(dpsd_dbm, B_hz)
%ANALYZE_CHANNEL_DATA Compute channel characterization curves.
% Mirrors ChannelSimulatorApp.analyzeChannelData_Generic.

metrics = struct();
[nL, nSnaps] = size(dpsd_dbm);
pdp_lin = 10.^(dpsd_dbm/10);
avg_pdp = mean(pdp_lin, 2).';
taus = (0 : nL - 1) / B_hz;
metrics.delay.x = taus * 1e9;
metrics.delay.y = 10*log10(avg_pdp + 1e-20);

taus_mat = taus(:);
ds_vec = zeros(1, nSnaps);
for snapshotIdx = 1:nSnaps
    ds_vec(snapshotIdx) = compute_delay_spread(taus_mat, pdp_lin(:, snapshotIdx));
end

[f_ds, x_ds] = ecdf(ds_vec * 1e9);
metrics.delay.cdf_x = x_ds;
metrics.delay.cdf_y = f_ds;
metrics.space.angle = 0:1;
metrics.space.psd = 0:1;
metrics.space.cdf_x = 0;
metrics.space.cdf_y = 0;
metrics.hasDoppler = true;
metrics.time = compute_doppler_spectrum(dpsd_dbm(floor(nL/2)+1, :));
end

