function features = compute_step11abc_cir_features(dataset, delayEdges)
%COMPUTE_STEP11ABC_CIR_FEATURES Compute PDP/DS on one frozen delay grid.
%   The last bin is an explicit overflow bin ending at Inf. Delays are never
%   silently discarded and truth/prediction remain directly comparable.

arguments
    dataset (1, 1) struct
    delayEdges (1, :) double
end
if numel(delayEdges) < 3 || delayEdges(1) ~= 0 || ...
        ~isinf(delayEdges(end)) || any(diff(delayEdges) <= 0)
    error("compute_step11abc_cir_features:InvalidDelayGrid", ...
        "Delay edges must start at zero, increase, and end at Inf.");
end
power = abs(dataset.cir.coefficient).^2;
delay = dataset.cir.delay_s;
pathPower = squeeze(sum(power, [1, 2, 4, 5]));
pathDelay = squeeze(mean(delay, [1, 2, 4, 5]));
pathPower = double(pathPower(:));
pathDelay = double(pathDelay(:));
if any(~isfinite(pathPower)) || any(~isfinite(pathDelay)) || ...
        any(pathPower < 0) || any(pathDelay < 0)
    error("compute_step11abc_cir_features:InvalidCIR", ...
        "CIR power/delay values must be finite and nonnegative.");
end
weight = pathPower / max(eps, sum(pathPower));
meanDelay = sum(weight .* pathDelay);
rmsDelay = sqrt(max(0, sum(weight .* (pathDelay - meanDelay).^2)));
[~, ~, bins] = histcounts(pathDelay, delayEdges);
if any(bins == 0)
    error("compute_step11abc_cir_features:DelayOutsideGrid", ...
        "A CIR delay fell outside the declared common grid.");
end
pdp = accumarray(bins, pathPower, [numel(delayEdges) - 1, 1], @sum, 0);
overflowPower = sum(pathPower(bins == numel(delayEdges) - 1));
features = struct( ...
    "pdp", pdp / max(eps, sum(pdp)), ...
    "rms_delay_s", rmsDelay, ...
    "delay_overflow_power_fraction", ...
        overflowPower / max(eps, sum(pathPower)));
end
