function distribution = compute_empirical_distribution(values, unit, ...
        recommendedCount)
%COMPUTE_EMPIRICAL_DISTRIBUTION Compute an auditable empirical CDF.

arguments
    values {mustBeNumeric}
    unit (1, 1) string = ""
    recommendedCount (1, 1) double {mustBeInteger, mustBePositive} = 20
end

values = double(values(:));
values = values(isfinite(values));
values = sort(values);

distribution = struct( ...
    "available", numel(values) >= 2, ...
    "x", values, ...
    "y", (1:numel(values)).' / max(numel(values), 1), ...
    "unit", unit, ...
    "sample_count", numel(values), ...
    "recommended_count", recommendedCount, ...
    "recommended_met", numel(values) >= recommendedCount, ...
    "median", NaN, ...
    "percentile_90", NaN, ...
    "warning", "");

if isempty(values)
    distribution.warning = "No finite samples are available.";
elseif isscalar(values)
    distribution.warning = ...
        "An empirical CDF requires at least two samples.";
else
    distribution.median = linearPercentile(values, 0.50);
    distribution.percentile_90 = linearPercentile(values, 0.90);
    if numel(values) < recommendedCount
        distribution.warning = sprintf( ...
            "CDF uses %d samples; Step 5 recommends at least %d.", ...
            numel(values), recommendedCount);
    end
end
end

function value = linearPercentile(sortedValues, probability)
count = numel(sortedValues);
if isscalar(sortedValues)
    value = sortedValues(1);
    return;
end
position = 1 + (count - 1) * probability;
lowerIndex = floor(position);
upperIndex = ceil(position);
weight = position - lowerIndex;
value = sortedValues(lowerIndex) * (1 - weight) + ...
    sortedValues(upperIndex) * weight;
end
