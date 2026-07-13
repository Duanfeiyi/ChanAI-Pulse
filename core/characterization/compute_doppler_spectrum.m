function spectrum = compute_doppler_spectrum(timeSeries)
%COMPUTE_DOPPLER_SPECTRUM Compute the normalized App Doppler display curve.

timeSeries = double(timeSeries(:).');
if isempty(timeSeries)
    error("compute_doppler_spectrum:EmptyInput", "Time series must not be empty.");
end

centered = timeSeries - mean(timeSeries);
nfft = 2 ^ nextpow2(numel(centered));
powerSpectrum = fftshift(abs(fft(centered, nfft)).^2);

spectrum = struct();
spectrum.x = linspace(-1, 1, nfft);
spectrum.y = 10 * log10(powerSpectrum / max(powerSpectrum(:)) + 1e-20);
end
