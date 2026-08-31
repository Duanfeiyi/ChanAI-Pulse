function HRecovered = recover_inband_ctf_delay_sparse(H, knownIndices, options)
%RECOVER_INBAND_CTF_DELAY_SPARSE Delay-domain OMP in-band CTF recovery.
%   Recovers missing subcarriers by exploiting the physical structure that a
%   CTF is a superposition of few multipath complex exponentials, so its
%   delay-domain (IFFT) representation is approximately sparse. The known
%   subcarriers are frequency-domain puncturing of that sparse vector:
%
%       b = F_known * x ,   x sparse in the delay domain.
%
%   Solved with orthogonal matching pursuit (OMP) with a fixed support size;
%   the full CTF is then F_full * x_hat. Best on contiguous (block) missing
%   patterns; on uniform half-sampling the delay domain aliases and this
%   method degrades (use recover_inband_ctf_hybrid to dispatch instead).
%
%   H is [Tx, Rx, Nf] complex, KNOWNINDICES are 1-based. The function reads
%   only the known-subcarrier values (never target samples).

arguments
    H (:, :, :) double
    knownIndices (:, 1) double {mustBePositive}
    options.Support (1, 1) double {mustBeInteger, mustBePositive} = 8
end

txCount = size(H, 1);
rxCount = size(H, 2);
nf = size(H, 3);
known = sort(round(double(knownIndices(:))));
known = known(known >= 1 & known <= nf);
if numel(known) < 2
    error("recover_inband_ctf_delay_sparse:TooFewKnown", ...
        "At least two known subcarriers are required.");
end
support = min(double(options.Support), numel(known) - 1);

frequencies = (0:nf - 1).';
fKnown = double(known) - 1;
dictionary = dftRows(fKnown, frequencies, nf);      % [M, N]

HRecovered = zeros(size(H));
for tx = 1:txCount
    for rx = 1:rxCount
        values = squeeze(H(tx, rx, :));
        knownValues = values(known);
        if any(~isfinite(knownValues))
            error("recover_inband_ctf_delay_sparse:NonFiniteKnown", ...
                "Known subcarrier values must be finite.");
        end
        HRecovered(tx, rx, :) = recoverOne(dictionary, ...
            knownValues(:), nf, support);
    end
end
end

function hFull = recoverOne(dictionary, b, nf, support)
b = double(b(:));
residual = b;
supportSet = zeros(support, 1);
supportCount = 0;
normB = norm(b);
for iteration = 1:support
    correlation = abs(dictionary' * residual);
    [~, bestIndex] = max(correlation);
    if any(supportSet(1:supportCount) == bestIndex)
        break;
    end
    supportCount = supportCount + 1;
    supportSet(supportCount) = bestIndex;
    columns = dictionary(:, supportSet(1:supportCount));
    coefficients = columns \ b;
    residual = b - columns * coefficients;
    if norm(residual) <= 1e-9 * normB
        break;
    end
end
delayResponse = zeros(nf, 1);
if supportCount > 0
    columns = dictionary(:, supportSet(1:supportCount));
    delayResponse(supportSet(1:supportCount)) = columns \ b;
end
frequencies = (0:nf - 1).';
hFull = dftRows(frequencies, frequencies, nf) * delayResponse;
end

function rows = dftRows(rowFrequencies, columnDelays, nf)
% Orthonormal DFT rows: exp(-j*2*pi*f*k/nf)/sqrt(nf).
rows = exp(-2j * pi * rowFrequencies * columnDelays.' / nf) / sqrt(nf);
end
