function metrics = compare_v31_6_channels(reference, estimate, delayBinCount)
%COMPARE_V31_6_CHANNELS Compare two channels on one fixed complex CTF grid.
%   Covers complex, magnitude, phase, PDP/delay, spatial, temporal,
%   frequency, and short-window Doppler diagnostics. Angular metrics remain
%   unavailable because the Full 6GPCM public adapter omits ray angles.

arguments
    reference (1, 1) struct
    estimate (1, 1) struct
    delayBinCount (1, 1) double {mustBeInteger, mustBePositive} = ...
        size(reference.ctf_dataset.ctf.H, 3)
end
referenceH = reference.ctf_dataset.ctf.H;
estimateH = estimate.ctf_dataset.ctf.H;
if ~isequal(size5(referenceH), size5(estimateH))
    error("compare_v31_6_channels:ShapeMismatch", ...
        "Truth and prediction CTF arrays must use the same fixed grid.");
end
delta = estimateH - referenceH;
referencePower = sum(abs(referenceH(:)).^2);
metrics = struct();
metrics.complex_nmse = sum(abs(delta(:)).^2) / max(referencePower, eps);
metrics.complex_nrmse = sqrt(metrics.complex_nmse);
metrics.magnitude_nrmse = norm(abs(estimateH(:)) - abs(referenceH(:))) / ...
    max(norm(abs(referenceH(:))), eps);
powerFloor = max(abs(referenceH(:))) * 1e-6;
mask = abs(referenceH(:)) >= powerFloor;
phaseDelta = angle(estimateH(mask) .* conj(referenceH(mask)));
metrics.phase_mae_rad = mean(abs(phaseDelta), "omitnan");
metrics.complex_correlation = abs(sum(conj(referenceH(:)) .* estimateH(:))) / ...
    max(sqrt(referencePower * sum(abs(estimateH(:)).^2)), eps);
[referencePdp, delayS] = fixedGridPdp(referenceH, ...
    reference.ctf_dataset.axes.frequency_hz, delayBinCount);
[estimatePdp, ~] = fixedGridPdp(estimateH, ...
    estimate.ctf_dataset.axes.frequency_hz, delayBinCount);
metrics.pdp_nrmse = norm(estimatePdp - referencePdp) / ...
    max(norm(referencePdp), eps);
metrics.rms_delay_spread_abs_error_s = abs( ...
    rmsDelay(referencePdp, delayS) - rmsDelay(estimatePdp, delayS));
metrics.spatial_correlation_delta = spatialDelta(referenceH, estimateH);
metrics.temporal_coherence_delta = sequenceCoherenceDelta(referenceH, estimateH, 4);
metrics.frequency_coherence_delta = sequenceCoherenceDelta(referenceH, estimateH, 3);
metrics.doppler_power_nrmse = dopplerPowerNrmse(referenceH, estimateH);
metrics.angular_metric_available = false;
metrics.angular_spectrum_nrmse = NaN;
end

function [pdp, delayS] = fixedGridPdp(H, frequencyHz, delayBinCount)
frequencyHz = double(frequencyHz(:));
if numel(frequencyHz) < 2
    error("compare_v31_6_channels:FrequencyGridTooShort", ...
        "At least two frequency bins are required.");
end
spacing = median(diff(frequencyHz));
if any(abs(diff(frequencyHz) - spacing) > max(1, abs(spacing)) * 1e-8)
    error("compare_v31_6_channels:NonuniformFrequencyGrid", ...
        "The frozen CTF grid must be uniformly spaced.");
end
impulse = ifft(H, delayBinCount, 3);
pdp = squeeze(sum(abs(impulse).^2, [1, 2, 4, 5]));
pdp = double(pdp(:));
delayS = (0:numel(pdp) - 1).' / (numel(pdp) * abs(spacing));
end

function value = rmsDelay(power, delayS)
power = double(power(:));
weight = sum(power);
if weight <= eps, value = NaN; return; end
meanDelay = sum(power .* delayS) / weight;
value = sqrt(sum(power .* (delayS - meanDelay).^2) / weight);
end

function value = spatialDelta(reference, estimate)
shape = size5(reference);
if shape(1) * shape(2) < 2, value = NaN; return; end
first = reshape(reference, shape(1) * shape(2), []);
second = reshape(estimate, shape(1) * shape(2), []);
firstR = first * first' / max(1, size(first, 2));
secondR = second * second' / max(1, size(second, 2));
firstR = firstR / max(eps, trace(firstR));
secondR = secondR / max(eps, trace(secondR));
value = norm(secondR - firstR, "fro") / max(eps, norm(firstR, "fro"));
end

function value = sequenceCoherenceDelta(reference, estimate, dimension)
if size(reference, dimension) < 2, value = NaN; return; end
value = abs(sequenceCoherence(estimate, dimension) - ...
    sequenceCoherence(reference, dimension));
end

function value = sequenceCoherence(H, dimension)
scores = zeros(size(H, dimension) - 1, 1);
for index = 1:numel(scores)
    first = sliceDimension(H, dimension, index);
    second = sliceDimension(H, dimension, index + 1);
    scores(index) = abs(sum(conj(first(:)) .* second(:))) / ...
        max(eps, norm(first(:)) * norm(second(:)));
end
value = mean(scores);
end

function value = sliceDimension(H, dimension, index)
subscripts = repmat({':'}, 1, max(5, ndims(H)));
subscripts{dimension} = index;
value = H(subscripts{:});
end

function value = dopplerPowerNrmse(reference, estimate)
if size(reference, 4) < 2, value = NaN; return; end
referencePower = abs(fft(reference, [], 4)).^2;
estimatePower = abs(fft(estimate, [], 4)).^2;
value = norm(estimatePower(:) - referencePower(:)) / ...
    max(eps, norm(referencePower(:)));
end

function shape = size5(value)
shape = ones(1, 5);
actual = size(value);
shape(1:numel(actual)) = actual;
end
