function plotData = render_prediction_plots(axesHandles, predictionResults, style)
%RENDER_PREDICTION_PLOTS Render all Prediction & Training result charts.
%   This function owns presentation only. Training, inference, App state,
%   dialogs, and dataset selection remain outside the plotting layer.

requiredAxes = ["capacity", "rmse", "raw_data", "spread", "angular", "doppler"];
for fieldName = requiredAxes
    if ~isfield(axesHandles, fieldName)
        error("render_prediction_plots:MissingAxes", ...
            "Missing axes handle: %s", fieldName);
    end
end

requiredStyle = ["language", "dataset_label", "prefix", "true_color", ...
    "primary_color", "tcn_color", "lstm_color", "gru_color", ...
    "text_color", "text_dim_color"];
for fieldName = requiredStyle
    if ~isfield(style, fieldName)
        error("render_prediction_plots:MissingStyle", ...
            "Missing style value: %s", fieldName);
    end
end

allAlgorithms = fieldnames(predictionResults);
if isempty(allAlgorithms)
    plotData = emptyPlotData();
    return;
end

datasetTag = datasetTagFor(style.dataset_label);
algorithms = {};
for algorithmIndex = 1:length(allAlgorithms)
    if endsWith(allAlgorithms{algorithmIndex}, datasetTag)
        algorithms{end+1} = allAlgorithms{algorithmIndex}; %#ok<AGROW>
    end
end
if isempty(algorithms)
    plotData = emptyPlotData();
    return;
end

baseResult = predictionResults.(algorithms{1});
labels = localizedLabels(style.language, style.prefix, baseResult);
legendOptions = {'Location', 'best', 'TextColor', style.text_color, ...
    'Color', 'none', 'EdgeColor', 'none', 'FontName', 'Times New Roman', ...
    'FontSize', 12};

% 1. Capacity.
capacityAxes = axesHandles.capacity;
delete(capacityAxes.Children);
hold(capacityAxes, 'on');
capacityMarkerIndices = round(linspace(1, length(baseResult.SNR), 5));
originalCapacity = plot(capacityAxes, baseResult.SNR, baseResult.C_ori, '--s', ...
    'Color', style.true_color, 'LineWidth', 1.5, 'MarkerSize', 6, ...
    'MarkerIndices', capacityMarkerIndices, 'MarkerFaceColor', style.true_color);
capacityHandles = {originalCapacity};
capacityLegend = {labels.capacity_true};
capacityValues = baseResult.C_ori;
for algorithmIndex = 1:length(algorithms)
    key = algorithms{algorithmIndex};
    result = predictionResults.(key);
    [algorithm, color, marker] = algorithmStyle(key, style);
    predictedCapacity = plot(capacityAxes, result.SNR, result.C_pre, ['-', marker], ...
        'Color', color, 'LineWidth', 1.5, 'MarkerFaceColor', color, ...
        'MarkerSize', 6, 'MarkerIndices', round(linspace(1, length(result.SNR), 5)));
    capacityHandles{end+1} = predictedCapacity; %#ok<AGROW>
    capacityLegend{end+1} = predictionLegend(labels.capacity_predicted, ...
        algorithm, style.language); %#ok<AGROW>
    capacityValues = [capacityValues; result.C_pre(:)]; %#ok<AGROW>
end
hold(capacityAxes, 'off');
legend(capacityAxes, [capacityHandles{:}], capacityLegend, legendOptions{:});
apply_axes_style(capacityAxes, labels.capacity_title, labels.capacity_x, ...
    labels.capacity_y, style.text_color);
apply_y_limit_margin(capacityAxes, capacityValues);
set_full_width_axes(capacityAxes, baseResult.SNR);

% 2. RMSE.
rmseAxes = axesHandles.rmse;
delete(rmseAxes.Children);
hold(rmseAxes, 'on');
if length(baseResult.GroupRMSE) > 1
    rmseHandles = {};
    rmseLegend = {};
    rmseValues = [];
    for algorithmIndex = 1:length(algorithms)
        key = algorithms{algorithmIndex};
        result = predictionResults.(key);
        [algorithm, color, marker] = algorithmStyle(key, style);
        rmseLine = plot(rmseAxes, 1:length(result.GroupRMSE), result.GroupRMSE, ...
            ['-', marker], 'Color', color, 'LineWidth', 1.5, 'MarkerSize', 5, ...
            'MarkerIndices', round(linspace(1, length(result.GroupRMSE), ...
            min(10, length(result.GroupRMSE)))), 'MarkerFaceColor', color);
        rmseHandles{end+1} = rmseLine; %#ok<AGROW>
        rmseLegend{end+1} = algorithm; %#ok<AGROW>
        rmseValues = [rmseValues; result.GroupRMSE(:)]; %#ok<AGROW>
    end
    legend(rmseAxes, [rmseHandles{:}], rmseLegend, legendOptions{:});
    apply_axes_style(rmseAxes, labels.rmse_group_title, labels.rmse_x, ...
        labels.rmse_y, style.text_color);
    apply_y_limit_margin(rmseAxes, rmseValues);
    set_full_width_axes(rmseAxes, 1:length(baseResult.GroupRMSE));
else
    values = zeros(1, length(algorithms));
    for algorithmIndex = 1:length(algorithms)
        values(algorithmIndex) = predictionResults.(algorithms{algorithmIndex}).RMSE;
    end
    bars = bar(rmseAxes, 1:length(algorithms), values, 0.4, ...
        'FaceColor', 'flat', 'EdgeColor', 'none');
    tickLabels = {};
    for algorithmIndex = 1:length(algorithms)
        [algorithm, color] = algorithmStyle(algorithms{algorithmIndex}, style);
        bars.CData(algorithmIndex, :) = color;
        tickLabels{end+1} = algorithm; %#ok<AGROW>
    end
    rmseAxes.XTick = 1:length(algorithms);
    rmseAxes.XTickLabel = tickLabels;
    apply_axes_style(rmseAxes, labels.rmse_overall_title, 'Algorithm', ...
        labels.rmse_y, style.text_color);
    apply_y_limit_margin(rmseAxes, values);
end
hold(rmseAxes, 'off');

% 3. Raw PSD at the worst RMSE group.
[~, worstGroup] = max(baseResult.GroupRMSE);
rawAxes = axesHandles.raw_data;
delete(rawAxes.Children);
hold(rawAxes, 'on');
totalSnapshots = size(baseResult.Raw_Ori, 1);
groupSize = max(1, floor(totalSnapshots / 10));
startIndex = (worstGroup - 1) * groupSize + 1;
endIndex = min(totalSnapshots, worstGroup * groupSize);
delayAxis = baseResult.Metrics.delay.x(:);
originalPower = mean(10.^(baseResult.Raw_Ori(startIndex:endIndex, :) / 10), 1);
originalPdp = 10 * log10(originalPower(:) + 1e-20);
psdMarkerIndices = round(linspace(1, length(delayAxis), 20));
originalPsd = plot(rawAxes, delayAxis, originalPdp, '--s', ...
    'Color', [style.true_color, 0.7], 'LineWidth', 1.5, 'MarkerSize', 6, ...
    'MarkerIndices', psdMarkerIndices, 'MarkerFaceColor', style.true_color);
psdHandles = {originalPsd};
psdLegend = {labels.psd_true};
psdValues = originalPdp(:);
for algorithmIndex = 1:length(algorithms)
    key = algorithms{algorithmIndex};
    result = predictionResults.(key);
    [algorithm, color, marker] = algorithmStyle(key, style);
    predictedSnapshots = size(result.Raw_Pre, 1);
    predictedGroupSize = max(1, floor(predictedSnapshots / 10));
    predictedStart = (worstGroup - 1) * predictedGroupSize + 1;
    predictedEnd = min(predictedSnapshots, worstGroup * predictedGroupSize);
    predictedPower = mean(10.^(result.Raw_Pre(predictedStart:predictedEnd, :) / 10), 1);
    predictedPdp = 10 * log10(predictedPower(:) + 1e-20);
    predictedPsd = plot(rawAxes, delayAxis, predictedPdp, ['-', marker], ...
        'Color', color, 'LineWidth', 1.5, 'MarkerSize', 6, ...
        'MarkerIndices', psdMarkerIndices, 'MarkerFaceColor', color);
    psdHandles{end+1} = predictedPsd; %#ok<AGROW>
    psdLegend{end+1} = predictionLegend(labels.psd_predicted, ...
        algorithm, style.language); %#ok<AGROW>
    psdValues = [psdValues; predictedPdp(:)]; %#ok<AGROW>
end
hold(rawAxes, 'off');
legend(rawAxes, [psdHandles{:}], psdLegend, legendOptions{:});
apply_axes_style(rawAxes, labels.psd_title, labels.psd_x, labels.psd_y, ...
    style.text_color);
apply_y_limit_margin(rawAxes, psdValues);
set_full_width_axes(rawAxes, delayAxis);

% 4. Delay-spread CDF.
spreadAxes = axesHandles.spread;
delete(spreadAxes.Children);
hold(spreadAxes, 'on');
cdfMarkerIndices = round(linspace(1, length(baseResult.xo), 15));
originalCdf = plot(spreadAxes, baseResult.xo, baseResult.fo, '--s', ...
    'Color', style.true_color, 'LineWidth', 1.5, 'MarkerSize', 5, ...
    'MarkerIndices', cdfMarkerIndices, 'MarkerFaceColor', style.true_color);
cdfHandles = {originalCdf};
cdfLegend = {labels.cdf_true};
for algorithmIndex = 1:length(algorithms)
    key = algorithms{algorithmIndex};
    result = predictionResults.(key);
    [algorithm, color, marker] = algorithmStyle(key, style);
    predictedCdf = plot(spreadAxes, result.xp, result.fp, ['-', marker], ...
        'Color', color, 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'MarkerIndices', round(linspace(1, length(result.xp), 15)), ...
        'MarkerFaceColor', color);
    cdfHandles{end+1} = predictedCdf; %#ok<AGROW>
    cdfLegend{end+1} = predictionLegend(labels.cdf_predicted, ...
        algorithm, style.language); %#ok<AGROW>
end
hold(spreadAxes, 'off');
legend(spreadAxes, [cdfHandles{:}], cdfLegend, legendOptions{:});
apply_axes_style(spreadAxes, labels.cdf_title, labels.cdf_x, labels.cdf_y, ...
    style.text_color);
spreadAxes.YLim = [0, 1];
set_full_width_axes(spreadAxes, baseResult.xp);

% 5. Angular and Doppler plots.
metrics = baseResult.Metrics;
renderOptionalSpectrum(axesHandles.angular, metrics, 'space', 'angle', 'psd', ...
    labels.angular_title, labels.angular_x, labels.angular_y, labels.no_data, style);
renderOptionalSpectrum(axesHandles.doppler, metrics, 'time', 'x', 'y', ...
    labels.doppler_title, labels.doppler_x, labels.doppler_y, labels.no_data, style);

plotData = struct( ...
    'algorithms', {algorithms}, ...
    'dataset_tag', datasetTag, ...
    'worst_group', worstGroup, ...
    'capacity_values', capacityValues, ...
    'psd_values', psdValues);
drawnow limitrate;
end

function renderOptionalSpectrum(ax, metrics, fieldName, xFieldName, yFieldName, titleText, xLabelText, yLabelText, noDataText, style)
delete(ax.Children);
if isfield(metrics, fieldName) && max(metrics.(fieldName).(yFieldName)) > -900
    spectrum = metrics.(fieldName);
    xData = spectrum.(xFieldName);
    yData = spectrum.(yFieldName);
    plot(ax, xData, yData, '-o', 'Color', style.primary_color, ...
        'LineWidth', 1.5, 'MarkerSize', 5, ...
        'MarkerIndices', round(linspace(1, length(xData), 20)), ...
        'MarkerFaceColor', style.primary_color);
    apply_axes_style(ax, titleText, xLabelText, yLabelText, style.text_color);
    apply_y_limit_margin(ax, yData);
    set_full_width_axes(ax, xData);
else
    set(ax, 'XTick', [], 'YTick', []);
    text(ax, 0.5, 0.5, noDataText, 'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', ...
        'Color', style.text_dim_color, 'FontName', 'Times New Roman');
    apply_axes_style(ax, titleText, xLabelText, yLabelText, style.text_color);
end
end

function tag = datasetTagFor(datasetLabel)
if contains(datasetLabel, '[增强]') || contains(datasetLabel, '[Augmented]')
    tag = '_Aug';
elseif contains(datasetLabel, '[原始]') || contains(datasetLabel, '[Raw]')
    tag = '_Raw';
else
    tag = '_Sim';
end
end

function [algorithm, color, marker] = algorithmStyle(key, style)
if contains(key, 'TCN')
    algorithm = 'TCN';
    color = style.tcn_color;
    marker = 'o';
elseif contains(key, 'LSTM')
    algorithm = 'LSTM';
    color = style.lstm_color;
    marker = '^';
else
    algorithm = 'GRU';
    color = style.gru_color;
    marker = 'd';
end
end

function legendText = predictionLegend(predictionText, algorithm, language)
if strcmpi(string(language), "CN")
    legendText = predictionText;
else
    legendText = [algorithm ' ' predictionText];
end
end

function labels = localizedLabels(language, prefix, baseResult)
if strcmpi(string(language), "CN")
    labels = struct( ...
        'capacity_true', '真实容量 (虚线)', ...
        'capacity_predicted', 'AI 预测容量 (实线)', ...
        'psd_true', '测量值 (虚线)', ...
        'psd_predicted', '预测值 (实线)', ...
        'cdf_true', '真实 CDF (虚线)', ...
        'cdf_predicted', '预测 CDF (实线)', ...
        'capacity_title', sprintf('【%s】容量验证 (准确率: %.2f%%)', prefix, baseResult.CapAcc), ...
        'capacity_x', 'SNR (dB)', 'capacity_y', '容量 (Gbps)', ...
        'rmse_group_title', sprintf('【%s】分组 RMSE (NRMSE: %.2f%%)', prefix, baseResult.NRMSE), ...
        'rmse_overall_title', sprintf('【%s】整体 RMSE', prefix), ...
        'rmse_x', '分组索引', 'rmse_y', 'RMSE (dBm)', ...
        'psd_title', 'PSD 验证 (去噪后)', ...
        'psd_x', '时延 (ns)', 'psd_y', '功率 (dBm)', ...
        'cdf_title', sprintf('【%s】时延扩展 CDF', prefix), ...
        'cdf_x', '时延扩展 \tau (ns)', 'cdf_y', 'CDF', ...
        'angular_title', sprintf('【%s】角度功率谱', prefix), ...
        'angular_x', '角度 (deg)', 'angular_y', '功率 (dB)', ...
        'doppler_title', sprintf('【%s】多普勒', prefix), ...
        'doppler_x', 'Hz', 'doppler_y', 'dB', 'no_data', '无数据');
else
    [~, worstGroup] = max(baseResult.GroupRMSE);
    labels = struct( ...
        'capacity_true', 'Measurement', 'capacity_predicted', 'Predict', ...
        'psd_true', 'Measurement', 'psd_predicted', 'Predict', ...
        'cdf_true', 'Measurement CDF', 'cdf_predicted', 'Predict CDF', ...
        'capacity_title', sprintf('[%s] Capacity', prefix), ...
        'capacity_x', 'SNR (dB)', 'capacity_y', 'Capacity (Gbps)', ...
        'rmse_group_title', sprintf('[%s] Group RMSE', prefix), ...
        'rmse_overall_title', sprintf('[%s] Overall RMSE', prefix), ...
        'rmse_x', 'Group Index', 'rmse_y', 'RMSE (dBm)', ...
        'psd_title', sprintf('PSD Verification (Worst-Case Group %d)', worstGroup), ...
        'psd_x', 'Delay (ns)', 'psd_y', 'Power (dBm)', ...
        'cdf_title', sprintf('[%s] DS CDF', prefix), ...
        'cdf_x', 'DS \tau (ns)', 'cdf_y', 'CDF', ...
        'angular_title', sprintf('[%s] Angular PSD', prefix), ...
        'angular_x', 'Angle (deg)', 'angular_y', 'Power (dB)', ...
        'doppler_title', sprintf('[%s] Doppler', prefix), ...
        'doppler_x', 'Hz', 'doppler_y', 'dB', 'no_data', 'No Data');
end
end

function plotData = emptyPlotData()
plotData = struct('algorithms', {{}}, 'dataset_tag', '', ...
    'worst_group', [], 'capacity_values', [], 'psd_values', []);
end
