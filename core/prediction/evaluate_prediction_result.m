function result = evaluate_prediction_result(predictionsDbm, truthDbm, bandwidthHz, options)
%EVALUATE_PREDICTION_RESULT Compute the App's existing prediction metrics.
%   Metric definitions intentionally match the current App behavior.

arguments
    predictionsDbm {mustBeNumeric, mustBeNonempty}
    truthDbm {mustBeNumeric, mustBeNonempty}
    bandwidthHz (1, 1) double {mustBePositive}
    options.NoiseDbm {mustBeNumeric} = [-95, -100, -105, -110, -115]
    options.ValidationRMSE (1, 1) double = NaN
    options.ValidationNRMSE (1, 1) double = NaN
end

if ~isequal(size(predictionsDbm), size(truthDbm))
    error("evaluate_prediction_result:DimensionMismatch", ...
        "Prediction and truth arrays must have the same size.");
end

[sampleCount, ~] = size(truthDbm);
result = struct();
[result.CapAcc, result.SNR, result.C_pre, result.C_ori] = ...
    compute_capacity_accuracy(predictionsDbm, truthDbm, bandwidthHz, options.NoiseDbm);

groupSize = max(1, floor(sampleCount / 10));
groupCount = floor(sampleCount / groupSize);
if groupCount >= 1
    groupRmse = zeros(groupCount, 1);
    for groupIndex = 1:groupCount
        startIndex = (groupIndex - 1) * groupSize + 1;
        endIndex = groupIndex * groupSize;
        groupRmse(groupIndex) = compute_rmse( ...
            predictionsDbm(startIndex:endIndex, :), truthDbm(startIndex:endIndex, :));
    end
    result.GroupRMSE = groupRmse;
else
    result.GroupRMSE = compute_rmse(predictionsDbm, truthDbm);
end

result.RMSE = compute_rmse(predictionsDbm, truthDbm);
result.NRMSE = compute_nrmse(result.RMSE, truthDbm);
result.ValidationRMSE = options.ValidationRMSE;
result.ValidationNRMSE = options.ValidationNRMSE;
[result.xp, result.fp, result.xo, result.fo] = ...
    compute_ds_cdf(predictionsDbm, truthDbm, bandwidthHz);
result.Raw_Pre = predictionsDbm;
result.Raw_Ori = truthDbm;
end
