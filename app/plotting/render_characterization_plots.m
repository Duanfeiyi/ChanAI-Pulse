function render_characterization_plots(axesHandles, metrics, style)
%RENDER_CHARACTERIZATION_PLOTS Render the four characterization charts.
%   This function owns presentation only. Channel data loading and metric
%   calculations remain outside the plotting layer.

requiredAxes = ["angular", "delay", "spread", "doppler"];
for fieldName = requiredAxes
    if ~isfield(axesHandles, fieldName)
        error("render_characterization_plots:MissingAxes", ...
            "Missing axes handle: %s", fieldName);
    end
end

requiredStyle = ["language", "primary_color", "text_color", "text_dim_color"];
for fieldName = requiredStyle
    if ~isfield(style, fieldName)
        error("render_characterization_plots:MissingStyle", ...
            "Missing style value: %s", fieldName);
    end
end

labels = localizedLabels(style.language);
primaryColor = style.primary_color;
textColor = style.text_color;
textDimColor = style.text_dim_color;

angularAxes = axesHandles.angular;
delete(angularAxes.Children);
if max(metrics.space.psd) > -900
    markerIndices = round(linspace(1, length(metrics.space.angle), 20));
    plot(angularAxes, metrics.space.angle, metrics.space.psd, '-o', ...
        'Color', primaryColor, 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'MarkerIndices', markerIndices, 'MarkerFaceColor', primaryColor);
    apply_axes_style(angularAxes, labels.angular_title, labels.angular_x, ...
        labels.angular_y, textColor);
    applyYLimMargin(angularAxes, metrics.space.psd);
    setFullWidthAxes(angularAxes, metrics.space.angle);
else
    set(angularAxes, 'XTick', [], 'YTick', []);
    showNoData(angularAxes, labels.no_data, textDimColor);
    apply_axes_style(angularAxes, labels.angular_title, labels.angular_x, ...
        labels.angular_y, textColor);
end

delayAxes = axesHandles.delay;
delayPower = metrics.delay.y;
delete(delayAxes.Children);
markerIndices = round(linspace(1, length(metrics.delay.x), 20));
plot(delayAxes, metrics.delay.x, delayPower, '-o', ...
    'Color', primaryColor, 'LineWidth', 1.5, 'MarkerSize', 5, ...
    'MarkerIndices', markerIndices, 'MarkerFaceColor', primaryColor);
apply_axes_style(delayAxes, labels.delay_title, labels.delay_x, ...
    labels.delay_y, textColor);
setFullWidthAxes(delayAxes, metrics.delay.x);
applyYLimMargin(delayAxes, delayPower);

spreadAxes = axesHandles.spread;
delete(spreadAxes.Children);
markerIndices = round(linspace(1, length(metrics.delay.cdf_x), 20));
plot(spreadAxes, metrics.delay.cdf_x, metrics.delay.cdf_y, '-o', ...
    'Color', primaryColor, 'LineWidth', 1.5, 'MarkerSize', 5, ...
    'MarkerIndices', markerIndices, 'MarkerFaceColor', primaryColor);
apply_axes_style(spreadAxes, labels.spread_title, labels.spread_x, ...
    labels.spread_y, textColor);
spreadAxes.YLim = [0, 1];
setFullWidthAxes(spreadAxes, metrics.delay.cdf_x);

dopplerAxes = axesHandles.doppler;
delete(dopplerAxes.Children);
if isfield(metrics, 'time') && max(metrics.time.y) > -900
    markerIndices = round(linspace(1, length(metrics.time.x), 20));
    plot(dopplerAxes, metrics.time.x, metrics.time.y, '-o', ...
        'Color', primaryColor, 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'MarkerIndices', markerIndices, 'MarkerFaceColor', primaryColor);
    apply_axes_style(dopplerAxes, labels.doppler_title, labels.doppler_x, ...
        labels.doppler_y, textColor);
    applyYLimMargin(dopplerAxes, metrics.time.y);
    setFullWidthAxes(dopplerAxes, metrics.time.x);
else
    set(dopplerAxes, 'XTick', [], 'YTick', []);
    showNoData(dopplerAxes, labels.no_data, textDimColor);
    apply_axes_style(dopplerAxes, labels.doppler_title, labels.doppler_x, ...
        labels.doppler_y, textColor);
end

drawnow limitrate;
end

function labels = localizedLabels(language)
if strcmpi(string(language), "CN")
    labels = struct( ...
        'no_data', '无数据', ...
        'angular_title', '角度功率谱 (Angle Power Spectrum)', ...
        'delay_title', '时延功率谱密度 (Delay PSD)', ...
        'spread_title', '扩展累积分布函数 (Spread CDF)', ...
        'doppler_title', '多普勒谱 (Doppler)', ...
        'angular_x', '角度 (deg)', ...
        'angular_y', '归一化功率 (dB)', ...
        'delay_x', 'ns', ...
        'delay_y', 'dB', ...
        'spread_x', 'Val', ...
        'spread_y', 'CDF', ...
        'doppler_x', 'Hz', ...
        'doppler_y', 'dB');
else
    labels = struct( ...
        'no_data', 'No Data', ...
        'angular_title', 'Angle Power Spectrum', ...
        'delay_title', 'Delay PSD', ...
        'spread_title', 'Spread CDF', ...
        'doppler_title', 'Doppler', ...
        'angular_x', 'Angle (deg)', ...
        'angular_y', 'Norm Power (dB)', ...
        'delay_x', 'ns', ...
        'delay_y', 'dB', ...
        'spread_x', 'Val', ...
        'spread_y', 'CDF', ...
        'doppler_x', 'Hz', ...
        'doppler_y', 'dB');
end
end

function showNoData(ax, message, textDimColor)
text(ax, 0.5, 0.5, message, 'Units', 'normalized', ...
    'HorizontalAlignment', 'center', 'FontSize', 14, ...
    'FontWeight', 'bold', 'Color', textDimColor, ...
    'FontName', 'Times New Roman');
end

function setFullWidthAxes(ax, xData)
try
    if isempty(xData), return; end
    xmin = min(xData(:));
    xmax = max(xData(:));
    if xmin == xmax, xmax = xmin + 1; end
    ax.XLim = [xmin, xmax];
    try ax.XLimitMethod = 'tight'; catch; end
catch
end
end

function applyYLimMargin(ax, yData)
try
    if isempty(yData), return; end
    yValues = double(yData(isfinite(yData(:))));
    if isempty(yValues), return; end
    minY = min(yValues);
    maxY = max(yValues);
    hasBar = ~isempty(findobj(ax, 'Type', 'bar'));
    if hasBar, minY = min(0, minY); end
    yRange = maxY - minY;
    if yRange == 0, yRange = max(1, abs(maxY) * 0.1); end
    ax.YLim = [minY - 0.1*yRange, maxY + 0.1*yRange];
catch
end
end
