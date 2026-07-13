function dpsdDbm = prepare_dpsd_snapshot(data, scenarioName, targetLength)
%PREPARE_DPSD_SNAPSHOT Convert one channel snapshot to the App DPSD vector.
%   This is the non-UI equivalent of the original data-loading logic. It
%   intentionally preserves the App's scenario-specific handling so the
%   displayed characteristics and downstream prediction input stay stable.

arguments
    data {mustBeNumeric}
    scenarioName (1, 1) string
    targetLength (1, 1) double {mustBeInteger, mustBePositive}
end

if isreal(data)
    dpsdDbm = squeeze(data);
    if size(dpsdDbm, 1) == 1 && size(dpsdDbm, 2) > 1
        dpsdDbm = dpsdDbm.';
    end
    if all(dpsdDbm(:) >= 0) && max(dpsdDbm(:)) < 1e5
        dpsdDbm = 10 * log10(dpsdDbm / 1e-3 + 1e-20);
    end
else
    if contains(scenarioName, "RIS")
        if ndims(data) == 5
            hFreq = squeeze(sum(sum(sum(data, 1), 2), 3));
        elseif ndims(data) == 4
            hFreq = squeeze(sum(sum(data, 1), 2));
        elseif ndims(data) == 3
            hFreq = squeeze(sum(data, 1));
        else
            hFreq = squeeze(data);
        end
        if size(hFreq, 1) == 1 && size(hFreq, 2) > 1
            hFreq = hFreq.';
        end
        hTime = ifft(hFreq);
        dpsdDbm = 10 * log10(abs(hTime).^2 / 1e-3 + 1e-20);
    elseif contains(scenarioName, "Sub-6")
        if ndims(data) >= 3
            pdpLinear = squeeze(sum(sum(abs(data).^2, 1), 2));
        else
            pdpLinear = abs(data).^2;
        end
        if size(pdpLinear, 1) == 1 && size(pdpLinear, 2) > 1
            pdpLinear = pdpLinear.';
        end
        dpsdDbm = 10 * log10(pdpLinear / 1e-3 + 1e-20);
    else
        if ndims(data) >= 4
            cirSlice = squeeze(data(1, 1, :, :));
        elseif ndims(data) == 3
            cirSlice = squeeze(data(1, 1, :));
        else
            cirSlice = squeeze(data);
        end
        if size(cirSlice, 1) == 1 && size(cirSlice, 2) > 1
            cirSlice = cirSlice.';
        end
        dpsdDbm = 10 * log10(abs(cirSlice).^2 / 1e-3 + 1e-20);
    end
end

dpsdDbm = real(dpsdDbm(:));
if numel(dpsdDbm) >= targetLength
    dpsdDbm = dpsdDbm(1:targetLength);
else
    dpsdDbm = [dpsdDbm; repmat(-130, targetLength - numel(dpsdDbm), 1)];
end
end
