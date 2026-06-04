function [angles, aps_dB] = calculate_angular_spectrum(raw_data)
%CALCULATE_ANGULAR_SPECTRUM Estimate a normalized angular power spectrum.
% Mirrors the original App helper behavior.

angles = linspace(-90, 90, 128);
aps_dB = zeros(128, 1) - 1000;

try
    if ~isreal(raw_data)
        sz = size(raw_data);
        spatial_dim = 0;
        for d = 1:length(sz)
            if sz(d) > 1 && sz(d) <= 64
                spatial_dim = d;
                break;
            end
        end
        if spatial_dim > 0
            aps = fftshift(fft(raw_data, 128, spatial_dim), spatial_dim);
            pwr = abs(aps).^2;
            dims_to_mean = setdiff(1:ndims(pwr), spatial_dim);
            for k = fliplr(dims_to_mean)
                pwr = mean(pwr, k);
            end
            aps_dB = 10*log10(pwr(:) + 1e-20);
            aps_dB = aps_dB - max(aps_dB);
        end
    end
catch
end
end

