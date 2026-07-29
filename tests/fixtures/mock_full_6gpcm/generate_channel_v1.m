function [HAll, delayAll] = generate_channel_v1( ...
    DS_mu, DS_sigma, r_DS, numClusters, numRays, ...
    LNS_ksi, KF_mu, KF_sigma, sampleCount)
%GENERATE_CHANNEL_V1 Test double for the external Step 3 probe.
%   This file is project-owned synthetic test code, not full 6GPCM.

pathCount = numClusters * numRays;
timeCount = 2;
HAll = cell(sampleCount, 1);
delayAll = cell(sampleCount, 1);
scale = abs(DS_mu) + DS_sigma + r_DS + LNS_ksi + ...
    abs(KF_mu) + KF_sigma;
for sample = 1:sampleCount
    H = complex(randn(2, 2, timeCount, pathCount), ...
        randn(2, 2, timeCount, pathCount)) / scale;
    baseDelay = reshape(linspace(5e-9, 80e-9, pathCount), ...
        [1, 1, 1, pathCount]);
    delay = repmat(baseDelay + sample * 0.1e-9, ...
        [2, 2, timeCount, 1]);
    HAll{sample} = H;
    delayAll{sample} = delay;
end
end
