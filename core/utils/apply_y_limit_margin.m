function apply_y_limit_margin(ax, yData)
%APPLY_Y_LIMIT_MARGIN Match the App's existing data-aware y-axis margin.
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
