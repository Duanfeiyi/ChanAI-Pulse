function delaySpread = compute_delay_spread(delayAxisSeconds, pdpLinear)
%COMPUTE_DELAY_SPREAD Compute RMS delay spread from a linear PDP.

delayAxisSeconds = double(delayAxisSeconds(:));
pdpLinear = double(pdpLinear(:));

if numel(delayAxisSeconds) ~= numel(pdpLinear)
    error("compute_delay_spread:SizeMismatch", ...
        "Delay axis and PDP must have the same number of samples.");
end
if any(pdpLinear < 0)
    error("compute_delay_spread:NegativePower", "PDP values must be nonnegative.");
end

totalPower = sum(pdpLinear);
if totalPower == 0
    delaySpread = 0;
    return;
end

meanDelay = sum(delayAxisSeconds .* pdpLinear) / totalPower;
delaySpread = sqrt(abs(sum((delayAxisSeconds .^ 2) .* pdpLinear) / totalPower - meanDelay ^ 2));
end
