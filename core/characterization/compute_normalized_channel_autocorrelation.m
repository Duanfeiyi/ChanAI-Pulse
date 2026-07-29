function correlation = compute_normalized_channel_autocorrelation( ...
        sequences, spacing, spacingUnit)
%COMPUTE_NORMALIZED_CHANNEL_AUTOCORRELATION Complex normalized ACF.
%   SEQUENCES is [N, Nobservation]. Lags are nonnegative.

arguments
    sequences {mustBeNumeric}
    spacing (1, 1) double {mustBeFinite, mustBePositive}
    spacingUnit (1, 1) string
end

sequences = double(sequences);
if isvector(sequences)
    sequences = sequences(:);
end
if size(sequences, 1) < 2
    error("compute_normalized_channel_autocorrelation:TooShort", ...
        "At least two ordered values are required.");
end
if any(~isfinite(real(sequences(:)))) || ...
        any(~isfinite(imag(sequences(:))))
    error("compute_normalized_channel_autocorrelation:NonFinite", ...
        "Sequences must contain only finite values.");
end

lengthValue = size(sequences, 1);
denominator = mean(abs(sequences(:)).^2);
values = complex(zeros(lengthValue, 1));
if denominator <= 0
    values(:) = NaN;
else
    for lag = 0:lengthValue - 1
        left = sequences(1:lengthValue-lag, :);
        right = sequences(1+lag:lengthValue, :);
        values(lag + 1) = mean(left(:) .* conj(right(:))) / denominator;
    end
end

correlation = struct( ...
    "lag", (0:lengthValue - 1).' * spacing, ...
    "lag_unit", spacingUnit, ...
    "complex", values, ...
    "magnitude", abs(values), ...
    "phase_rad", angle(values), ...
    "normalization", "R(k)/R(0)");
end
