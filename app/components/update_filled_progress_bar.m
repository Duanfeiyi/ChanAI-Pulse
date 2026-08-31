function update_filled_progress_bar(bar, value, options)
%UPDATE_FILLED_PROGRESS_BAR Update value, text and semantic state.

arguments
    bar (1, 1) struct
    value (1, 1) double
    options.Text (1, 1) string = ""
    options.State (1, 1) string = "running"
end

if ~all(isfield(bar, ["Track", "Fill", "Label"])) || ...
        isempty(bar.Track) || ~isvalid(bar.Track)
    return;
end
value = max(0, min(1, double(value)));
setappdata(bar.Track, "FilledProgressFraction", value);

colors = struct( ...
    "neutral", [0.43, 0.52, 0.62], ...
    "running", [0.06, 0.35, 0.64], ...
    "success", [0.08, 0.55, 0.29], ...
    "warning", [0.88, 0.52, 0.08], ...
    "error", [0.78, 0.18, 0.18]);
state = lower(strtrim(options.State));
if ~isfield(colors, char(state))
    state = "running";
end
if isfield(bar, "Kind") && string(bar.Kind) == "weighted_grid"
    bar.Fill.BackgroundColor = colors.(char(state));
    bar.FillGrid.BackgroundColor = colors.(char(state));
    filledWeight = max(0.001, value);
    remainingWeight = max(0.001, 1 - value);
    bar.Track.ColumnWidth = { ...
        sprintf("%.6fx", filledWeight), ...
        sprintf("%.6fx", remainingWeight)};
elseif isfield(bar, "Kind") && string(bar.Kind) == "normalized_axes"
    bar.Fill.FaceColor = colors.(char(state));
    bar.Fill.XData = [0, value, value, 0];
else
    bar.Fill.BackgroundColor = colors.(char(state));
end
if strlength(options.Text) == 0
    options.Text = sprintf("%.0f%%", 100 * value);
end
if isfield(bar, "Kind") && string(bar.Kind) == "normalized_axes"
    bar.Label.String = options.Text;
else
    bar.Label.Text = options.Text;
end
layout_filled_progress_bar(bar);
end
