function [HRecovered, method] = recover_inband_ctf_hybrid(H, knownIndices, targetIndices)
%RECOVER_INBAND_CTF_HYBRID Structure-based recovery dispatch (v3.2-4a 1A).
%   Chooses the recovery method from the SHAPE of the missing subcarriers
%   only (never from target values), so the dispatch is leakage-free:
%
%     contiguous block of >= 4 missing subcarriers -> delay-domain OMP
%       sparse recovery (best on block_8: complex NMSE 0.59 vs 0.80
%       linear-complex in the v3.2-4a study)
%     otherwise (uniform/random holes)              -> complex linear
%       interpolation (best on uniform_half: 0.18; sparse aliases there)
%
%   METHOD is returned for audit/manifest recording ("delay_domain_sparse"
%   or "linear_interpolation"). H is [Tx, Rx, Nf] complex; indices 1-based.

arguments
    H (:, :, :) double
    knownIndices (:, 1) double {mustBePositive}
    targetIndices (:, 1) double {mustBePositive}
end

if maxContiguousRun(double(targetIndices(:))) >= 4
    method = "delay_domain_sparse";
    HRecovered = recover_inband_ctf_delay_sparse(H, knownIndices);
else
    method = "linear_interpolation";
    HRecovered = recover_inband_ctf_spectrum(H, knownIndices);
end
end

function longest = maxContiguousRun(indices)
indices = sort(unique(round(indices)));
if isempty(indices)
    longest = 0;
    return;
end
longest = 1;
run = 1;
for index = 2:numel(indices)
    if indices(index) == indices(index - 1) + 1
        run = run + 1;
        longest = max(longest, run);
    else
        run = 1;
    end
end
end
