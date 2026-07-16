function plotData = render_generation_plots(axesHandles, generationResult, style)
%RENDER_GENERATION_PLOTS Render the generation PDP and delay-spread CDF.
%   This function owns presentation only. Channel generation, timing, App
%   state, and the Send to AI workflow remain outside the plotting layer.

requiredAxes = ["pdp", "cdf"];
for fieldName = requiredAxes
    if ~isfield(axesHandles, fieldName)
        error("render_generation_plots:MissingAxes", ...
            "Missing axes handle: %s", fieldName);
    end
end

requiredResult = ["config", "delay_spread_ns", "preview"];
for fieldName = requiredResult
    if ~isfield(generationResult, fieldName)
        error("render_generation_plots:MissingResult", ...
            "Missing generation result field: %s", fieldName);
    end
end

requiredStyle = ["language", "model_label", "primary_color", ...
    "secondary_color", "text_color"];
for fieldName = requiredStyle
    if ~isfield(style, fieldName)
        error("render_generation_plots:MissingStyle", ...
            "Missing style value: %s", fieldName);
    end
end

preview = generationResult.preview;
delayAxisNs = preview.delay_axis_ns;

averagePdpLinear = abs(preview.cir).^2;
averagePdpLinear = averagePdpLinear / max(averagePdpLinear + eps);

noiseFloorDb = -60;
noiseAmplitudeDb = 5.0;
noiseTraceDb = noiseFloorDb + noiseAmplitudeDb * ...
    (2 * rand(size(delayAxisNs)) - 1);
noiseLinear = 10.^(noiseTraceDb / 10);
pdpPlotDb = 10 * log10(averagePdpLinear + noiseLinear + eps);

pdpAxes = axesHandles.pdp;
delete(pdpAxes.Children);
markerIndices = round(linspace(1, length(delayAxisNs), 20));
pdpLine = plot(pdpAxes, delayAxisNs, pdpPlotDb, '-o', ...
    'Color', style.primary_color, 'LineWidth', 1.5, 'MarkerSize', 5, ...
    'MarkerIndices', markerIndices, 'MarkerFaceColor', style.primary_color);

tapPowerLinear = abs(preview.cluster_gains).^2;
tapPowerLinear = tapPowerLinear / max(tapPowerLinear + eps);
tapPowerDb = 10 * log10(tapPowerLinear + eps);
hold(pdpAxes, 'on');
pathLine = plot(pdpAxes, preview.cluster_delays_s * 1e9, tapPowerDb, 's', ...
    'Color', style.secondary_color, 'LineWidth', 1.2, 'MarkerSize', 6, ...
    'MarkerFaceColor', style.secondary_color);
hold(pdpAxes, 'off');

labels = localizedLabels(style.language, style.model_label);
apply_axes_style(pdpAxes, labels.pdp_title, labels.pdp_x, ...
    labels.pdp_y, style.text_color);
pdpLegend = legend(pdpAxes, [pdpLine, pathLine], ...
    {labels.pdp_legend, labels.path_legend}, 'Location', 'best');
pdpLegend.Color = 'none';
pdpLegend.EdgeColor = 'none';
pdpLegend.TextColor = style.text_color;
pdpLegend.FontName = 'Times New Roman';
pdpLegend.FontSize = 12;
xlim(pdpAxes, [0 generationResult.config.delay_max_ns]);

delaySpreadSorted = sort(generationResult.delay_spread_ns(:));
cdfY = (1:numel(delaySpreadSorted))' / numel(delaySpreadSorted);
[delaySpreadUnique, uniqueIndices] = unique(delaySpreadSorted, 'stable');
cdfUnique = cdfY(uniqueIndices);

if length(delaySpreadUnique) > 1
    cdfX = linspace(delaySpreadUnique(1), delaySpreadUnique(end), 500);
    cdfSmooth = interp1(delaySpreadUnique, cdfUnique, cdfX, 'pchip');
    cdfSmooth = cummax(cdfSmooth);
    cdfSmooth = min(max(cdfSmooth, 0), 1);
else
    cdfX = [0, delaySpreadUnique, max(1, delaySpreadUnique*2)];
    cdfSmooth = [0, 1, 1];
end

cdfAxes = axesHandles.cdf;
delete(cdfAxes.Children);
markerIndices = round(linspace(1, length(cdfX), 20));
plot(cdfAxes, cdfX, cdfSmooth, '-o', ...
    'Color', style.primary_color, 'LineWidth', 1.8, 'MarkerSize', 5, ...
    'MarkerIndices', markerIndices, 'MarkerFaceColor', style.primary_color);
apply_axes_style(cdfAxes, labels.cdf_title, labels.cdf_x, ...
    labels.cdf_y, style.text_color);
xlim(cdfAxes, [cdfX(1), cdfX(end)]);
ylim(cdfAxes, [0, 1]);

plotData = struct( ...
    'delay_axis_ns', delayAxisNs, ...
    'pdp_db', pdpPlotDb, ...
    'path_delays_ns', preview.cluster_delays_s * 1e9, ...
    'path_power_db', tapPowerDb, ...
    'cdf_x', cdfX, ...
    'cdf_y', cdfSmooth);

drawnow limitrate;
end

function labels = localizedLabels(language, modelLabel)
if strcmpi(string(language), "CN")
    labels = struct( ...
        'pdp_legend', 'PDP 带噪声底', ...
        'path_legend', '多径分量', ...
        'pdp_title', sprintf('时延功率谱 (%s)', modelLabel), ...
        'pdp_x', '时延 (ns)', ...
        'pdp_y', '功率 (dB)', ...
        'cdf_title', '时延扩展的累积分布函数', ...
        'cdf_x', '时延扩展 (ns)', ...
        'cdf_y', 'CDF');
else
    labels = struct( ...
        'pdp_legend', 'PDP with noise floor', ...
        'path_legend', 'Multipath components', ...
        'pdp_title', sprintf('Delay Power Spectrum (%s)', modelLabel), ...
        'pdp_x', 'Delay (ns)', ...
        'pdp_y', 'Power (dB)', ...
        'cdf_title', 'CDF of DS', ...
        'cdf_x', 'DS (ns)', ...
        'cdf_y', 'CDF');
end
end
