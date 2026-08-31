function HRecovered = recover_inband_ctf_spectrum(H, knownIndices)
%RECOVER_INBAND_CTF_SPECTRUM Linear-interpolation in-band CTF recovery.
%   H is [Tx, Rx, Nf] complex. For each (tx, rx) pair, the known-subcarrier
%   values (1-based indices in KNOWNINDICES) are linearly interpolated over
%   the full frequency grid with extrapolation. This is the v3.2-2b
%   recommended Frequency method and never reads target-region samples
%   (target subcarriers must be NaN holes in the imported dataset).
%
%   Shared by the v3.2-3c Frequency chain, run_v32_axis_prediction and the
%   v3.2-4a App frequency generation path.

arguments
    H (:, :, :) double
    knownIndices (:, 1) double {mustBePositive}
end

txCount = size(H, 1);
rxCount = size(H, 2);
nf = size(H, 3);
known = sort(round(double(knownIndices(:))));
known = known(known >= 1 & known <= nf);
if numel(known) < 2
    error("recover_inband_ctf_spectrum:TooFewKnown", ...
        "At least two known subcarriers are required for interpolation.");
end

HRecovered = zeros(size(H));
for tx = 1:txCount
    for rx = 1:rxCount
        values = squeeze(H(tx, rx, :));
        knownValues = values(known);
        if any(~isfinite(knownValues))
            error("recover_inband_ctf_spectrum:NonFiniteKnown", ...
                "Known subcarrier values must be finite.");
        end
        HRecovered(tx, rx, :) = interp1(known, knownValues, ...
            (1:nf).', "linear", "extrap");
    end
end
end
