function dpsd_dbm = quadriga_result_to_dpsd(result)
%QUADRIGA_RESULT_TO_DPSD Convert Complex-H result to delay-power PSD.
%   dpsd_dbm = quadriga_result_to_dpsd(result) computes the power delay
%   profile from H(t,f) by IFFT and converts to dBm scale.
%
%   This provides legacy compatibility with v1.0 DPSD-based pipelines.
%
%   Inputs:
%       result - Struct with field 'complex_h' [nSnapshots x nSubcarriers].
%
%   Outputs:
%       dpsd_dbm - [1 x nDelays] delay-power PSD in dBm-like scale.

arguments
    result (1, 1) struct
end

complex_h = result.complex_h;
[nSnapshots, nSubcarriers] = size(complex_h);

% Compute PDP via IFFT for each snapshot
nDelays = nSubcarriers;
dpsd_linear = zeros(nSnapshots, nDelays);

for t = 1:nSnapshots
    h_freq = complex_h(t, :);
    h_time = ifft(ifftshift(h_freq));
    pdp = abs(h_time).^2;
    dpsd_linear(t, :) = pdp;
end

% Average across snapshots and convert to dBm-like scale
avg_pdp = mean(dpsd_linear, 1);
avg_pdp = avg_pdp / max(avg_pdp + eps);
dpsd_dbm = 10 * log10(avg_pdp + 1e-20);
end
