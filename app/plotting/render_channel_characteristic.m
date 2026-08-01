function render_channel_characteristic(axesHandle, analysis, metricId, options)
%RENDER_CHANNEL_CHARACTERISTIC Render one Step 5 registered metric.

arguments
    axesHandle (1, 1)
    analysis (1, 1) struct
    metricId (1, 1) string
    options.Language (1, 1) string = "zh"
end

cla(axesHandle, "reset");
axesHandle.Box = "on";
axesHandle.FontName = "Microsoft YaHei UI";
axesHandle.FontSize = 10;
grid(axesHandle, "on");

if ~isfield(analysis, "metrics") || ...
        ~isfield(analysis.metrics, metricId)
    renderUnavailable(axesHandle, metricId, ...
        "图表未在 Step 5 注册表中登记。", options.Language);
    return;
end

metric = analysis.metrics.(metricId);
if ~metric.available
    renderUnavailable(axesHandle, metric.title_zh, metric.reason, options.Language);
    return;
end

switch metric.kind
    case {"line", "complex_correlation"}
        plotLine(axesHandle, metric.x, metric.y);
    case "cdf"
        stairs(axesHandle, metric.x, metric.y, ...
            "LineWidth", 1.8, "Color", [0.08, 0.40, 0.76]);
        ylim(axesHandle, [0, 1]);
    case "multi_line"
        hold(axesHandle, "on");
        for index = 1:size(metric.y, 2)
            plot(axesHandle, metric.x, metric.y(:, index), ...
                "LineWidth", 1.6, ...
                "DisplayName", translate_channel_simulator_text( ...
                    metric.series_labels(index), options.Language));
        end
        hold(axesHandle, "off");
        legend(axesHandle, "Location", "best");
    case "multi_cdf"
        hold(axesHandle, "on");
        series = metric.raw.series;
        for index = 1:numel(series)
            stairs(axesHandle, series(index).x, series(index).y, ...
                "LineWidth", 1.7, ...
                "DisplayName", translate_channel_simulator_text( ...
                    series(index).label, options.Language));
        end
        hold(axesHandle, "off");
        ylim(axesHandle, [0, 1]);
        legend(axesHandle, "Location", "best");
    case "matrix"
        imagesc(axesHandle, metric.x, metric.y, metric.z);
        axis(axesHandle, "image");
        colorbar(axesHandle);
        clim(axesHandle, [0, 1]);
    case "heatmap"
        imagesc(axesHandle, metric.x, metric.y, metric.z);
        set(axesHandle, "YDir", "normal");
        colorbar(axesHandle);
        clim(axesHandle, [-60, 0]);
    otherwise
        renderUnavailable(axesHandle, metric.title_zh, ...
            "当前绘图器尚不支持该 metric.kind。", options.Language);
        return;
end

title(axesHandle, metricTitle(metricId, metric.title_zh, options.Language), ...
    "FontWeight", "bold");
xlabel(axesHandle, axisLabel(metric.x_unit));
ylabel(axesHandle, axisLabel(metric.y_unit));
end

function plotLine(axesHandle, x, y)
if isscalar(x)
    scatter(axesHandle, x, y, 54, [0.08, 0.40, 0.76], "filled");
else
    plot(axesHandle, x, y, "LineWidth", 1.8, ...
        "Color", [0.08, 0.40, 0.76]);
end
end

function label = axisLabel(unit)
if unit == ""
    label = "";
else
    label = "[" + unit + "]";
end
end

function renderUnavailable(axesHandle, titleText, reason, language)
axis(axesHandle, "off");
title(axesHandle, translate_channel_simulator_text(titleText, language), ...
    "FontWeight", "bold");
text(axesHandle, 0.5, 0.56, translate_channel_simulator_text("当前数据不支持", language), ...
    "Units", "normalized", "HorizontalAlignment", "center", ...
    "FontWeight", "bold", "FontSize", 13, ...
    "Color", [0.55, 0.18, 0.12]);
text(axesHandle, 0.5, 0.42, translate_channel_simulator_text(reason, language), ...
    "Units", "normalized", "HorizontalAlignment", "center", ...
    "FontSize", 10, "Color", [0.35, 0.37, 0.40], ...
    "Interpreter", "none");
end

function titleText = metricTitle(metricId, fallback, language)
if language ~= "en"
    titleText = fallback;
    return;
end
names = struct( ...
    "power", "Power", ...
    "pdp", "Power delay profile (PDP)", ...
    "frequency_autocorrelation", "Frequency autocorrelation", ...
    "delay_spread_cdf", "Delay-spread CDF", ...
    "angular_power_spectrum", "Angular power spectrum", ...
    "spatial_correlation", "Spatial correlation", ...
    "angular_spread_cdf", "Angular-spread CDF", ...
    "doppler_power_spectrum", "Doppler power spectrum", ...
    "time_autocorrelation", "Time autocorrelation", ...
    "doppler_spread_cdf", "Doppler-spread CDF", ...
    "delay_sample_heatmap", "Delay–sample power heatmap");
field = char(metricId);
if isfield(names, field)
    titleText = string(names.(field));
else
    titleText = translate_channel_simulator_text(fallback, language);
end
end
