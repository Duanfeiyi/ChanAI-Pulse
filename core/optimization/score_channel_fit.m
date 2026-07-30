function score = score_channel_fit(target, candidateDataset, scoring)
%SCORE_CHANNEL_FIT Compare one generated CIR with frozen target features.

arguments
    target (1, 1) struct
    candidateDataset (1, 1) struct
    scoring (1, 1) struct
end

score = emptyScore();
analysis = analyze_channel_characteristics(candidateDataset, ...
    Region="all", ModuleRole="review");
score.analysis = analysis;
score.warnings = string(analysis.warnings(:));
if analysis.status == "FAIL"
    score.errors = "Candidate analysis failed: " + ...
        strjoin(analysis.errors, " | ");
    return;
end
if ~analysis.metrics.pdp.available
    score.errors = "Candidate PDP is unavailable: " + ...
        analysis.metrics.pdp.reason;
    return;
end

pdp = analysis.metrics.pdp.raw;
delayS = double(pdp.delay_s(:));
power = double(pdp.linear_power(:));
valid = isfinite(delayS) & delayS >= 0 & ...
    isfinite(power) & power >= 0;
delayS = delayS(valid);
power = power(valid);
if isempty(delayS) || sum(power) <= 0
    score.errors = "Candidate PDP has no finite positive-power paths.";
    return;
end
candidateProbability = weightedDelayHistogram( ...
    delayS, power, target.pdp.edges_s);
pdpScore = jensenShannonDistance( ...
    target.pdp.probability, candidateProbability, scoring.epsilon);

delaySpread = double(analysis.raw.delay_spread_s(:));
delaySpread = delaySpread(isfinite(delaySpread) & delaySpread >= 0);
if isempty(delaySpread)
    score.errors = ...
        "Candidate has no finite RMS delay-spread values.";
    return;
end
[delaySpreadScore, targetQuantiles, candidateQuantiles, ...
    probabilities] = delaySpreadDistance( ...
    target.delay_spread_s, delaySpread, scoring);

totalScore = scoring.pdp_weight * pdpScore + ...
    scoring.delay_spread_weight * delaySpreadScore;
score.status = "PASS";
if ~isempty(score.warnings)
    score.status = "WARNING";
end
score.success = true;
score.total = totalScore;
score.components = struct( ...
    "pdp", pdpScore, ...
    "delay_spread", delaySpreadScore, ...
    "weights", struct( ...
        "pdp", scoring.pdp_weight, ...
        "delay_spread", scoring.delay_spread_weight));
score.features = struct( ...
    "pdp_centers_s", target.pdp.centers_s, ...
    "target_pdp_probability", target.pdp.probability, ...
    "candidate_pdp_probability", candidateProbability, ...
    "quantile_probability", probabilities, ...
    "target_delay_spread_quantile_s", targetQuantiles, ...
    "candidate_delay_spread_quantile_s", candidateQuantiles, ...
    "candidate_delay_spread_s", delaySpread);
score.summary = struct( ...
    "candidate_delay_spread_median_s", median(delaySpread), ...
    "candidate_delay_spread_p90_s", ...
        empiricalQuantiles(delaySpread, 0.9));
end

function score = emptyScore()
score = struct( ...
    "status", "FAIL", ...
    "success", false, ...
    "total", Inf, ...
    "components", struct( ...
        "pdp", Inf, ...
        "delay_spread", Inf, ...
        "weights", struct()), ...
    "features", struct(), ...
    "summary", struct(), ...
    "analysis", struct(), ...
    "warnings", strings(0, 1), ...
    "errors", strings(0, 1));
end

function probability = weightedDelayHistogram(delayS, power, edgesS)
clipped = min(max(delayS(:), edgesS(1)), edgesS(end));
[~, ~, bins] = histcounts(clipped, edgesS);
valid = bins > 0;
histogram = accumarray(bins(valid), power(valid), ...
    [numel(edgesS) - 1, 1], @sum, 0);
total = sum(histogram);
if total <= 0
    error("score_channel_fit:EmptyHistogram", ...
        "Candidate PDP histogram has zero total power.");
end
probability = histogram / total;
end

function distance = jensenShannonDistance(p, q, epsilon)
p = double(p(:));
q = double(q(:));
p = (p + epsilon) / sum(p + epsilon);
q = (q + epsilon) / sum(q + epsilon);
midpoint = 0.5 * (p + q);
divergence = 0.5 * sum(p .* log2(p ./ midpoint)) + ...
    0.5 * sum(q .* log2(q ./ midpoint));
distance = sqrt(max(0, min(1, divergence)));
end

function [distance, targetQuantiles, candidateQuantiles, probabilities] = ...
        delaySpreadDistance(targetValues, candidateValues, scoring)
probabilities = linspace(0, 1, 101).';
targetQuantiles = empiricalQuantiles(targetValues, probabilities);
candidateQuantiles = empiricalQuantiles(candidateValues, probabilities);
floorValue = scoring.epsilon;
targetLog = log10(max(targetQuantiles, floorValue));
candidateLog = log10(max(candidateQuantiles, floorValue));
meanDistanceDecades = mean(abs(targetLog - candidateLog));
distance = min(1, meanDistanceDecades / ...
    scoring.delay_spread_log_scale_decades);
end

function result = empiricalQuantiles(values, probabilities)
values = sort(double(values(:)));
probabilities = double(probabilities(:));
if isscalar(values)
    result = repmat(values(1), size(probabilities));
    return;
end
positions = 1 + (numel(values) - 1) * probabilities;
lowerIndices = floor(positions);
upperIndices = ceil(positions);
fractions = positions - lowerIndices;
result = values(lowerIndices) .* (1 - fractions) + ...
    values(upperIndices) .* fractions;
end
