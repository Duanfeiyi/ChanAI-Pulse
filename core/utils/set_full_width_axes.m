function set_full_width_axes(ax, xData)
%SET_FULL_WIDTH_AXES Match the App's existing full-width x-axis behavior.
try
    if isempty(xData), return; end
    xmin = min(xData(:));
    xmax = max(xData(:));
    if xmin == xmax, xmax = xmin + 1; end
    ax.XLim = [xmin, xmax];
    try ax.XLimitMethod = 'tight'; catch, end
catch
end
end
