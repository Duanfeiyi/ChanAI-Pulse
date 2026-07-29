function render_channel_characteristic(axesHandle, analysis, metricId)
%RENDER_CHANNEL_CHARACTERISTIC Render one Step 5 registered metric.

arguments
    axesHandle (1, 1)
    analysis (1, 1) struct
    metricId (1, 1) string
end

cla(axesHandle, "reset");
axesHandle.Box = "on";
axesHandle.FontName = "Microsoft YaHei UI";
axesHandle.FontSize = 10;
grid(axesHandle, "on");

if ~isfield(analysis, "metrics") || ...
        ~isfield(analysis.metrics, metricId)
    renderUnavailable(axesHandle, metricId, ...
        "图表未在 Step 5 注册表中登记。");
    return;
end

metric = analysis.metrics.(metricId);
if ~metric.available
    renderUnavailable(axesHandle, metric.title_zh, metric.reason);
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
                "DisplayName", metric.series_labels(index));
        end
        hold(axesHandle, "off");
        legend(axesHandle, "Location", "best");
    case "multi_cdf"
        hold(axesHandle, "on");
        series = metric.raw.series;
        for index = 1:numel(series)
            stairs(axesHandle, series(index).x, series(index).y, ...
                "LineWidth", 1.7, ...
                "DisplayName", series(index).label);
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
            "当前绘图器尚不支持该 metric.kind。");
        return;
end

title(axesHandle, metric.title_zh, "FontWeight", "bold");
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

function renderUnavailable(axesHandle, titleText, reason)
axis(axesHandle, "off");
title(axesHandle, titleText, "FontWeight", "bold");
text(axesHandle, 0.5, 0.56, "当前数据不支持", ...
    "Units", "normalized", "HorizontalAlignment", "center", ...
    "FontWeight", "bold", "FontSize", 13, ...
    "Color", [0.55, 0.18, 0.12]);
text(axesHandle, 0.5, 0.42, reason, ...
    "Units", "normalized", "HorizontalAlignment", "center", ...
    "FontSize", 10, "Color", [0.35, 0.37, 0.40], ...
    "Interpreter", "none");
end
