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
pm = sum(pdp_lin, 1);
pm(pm == 0) = 1e-20;
mx = sum(taus_mat .* pdp_lin, 1) ./ pm;
ds_vec = sqrt(abs(sum((taus_mat.^2) .* pdp_lin, 1) ./ pm - mx.^2));

[f_ds, x_ds] = ecdf(ds_vec * 1e9);
metrics.delay.cdf_x = x_ds;
metrics.delay.cdf_y = f_ds;
metrics.space.angle = 0:1;
metrics.space.psd = 0:1;
metrics.space.cdf_x = 0;
metrics.space.cdf_y = 0;
metrics.hasDoppler = true;
h_t = dpsd_dbm(floor(nL/2)+1, :);
h_t = h_t - mean(h_t);
Nfft = 2^nextpow2(nSnaps);
d_spec = fftshift(abs(fft(h_t, Nfft)).^2);
metrics.time.x = linspace(-1, 1, Nfft);
metrics.time.y = 10*log10(d_spec/max(d_spec(:))+1e-20);
end

