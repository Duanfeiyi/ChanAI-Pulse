function layout_filled_progress_bar(bar)
%LAYOUT_FILLED_PROGRESS_BAR Keep fill and text inside the track bounds.

if ~isstruct(bar) || ~all(isfield(bar, ["Track", "Fill", "Label"])) || ...
        isempty(bar.Track) || ~isvalid(bar.Track)
    return;
end
if isfield(bar, "Kind") && ismember(string(bar.Kind), ...
        ["normalized_axes", "weighted_grid"])
    return;
end
position = bar.Track.Position;
width = max(1, position(3));
height = max(1, position(4));
fraction = 0;
if isappdata(bar.Track, "FilledProgressFraction")
    fraction = getappdata(bar.Track, "FilledProgressFraction");
end
fillWidth = max(1, round((width - 2) * max(0, min(1, fraction))));
bar.Fill.Position = [1, 1, fillWidth, max(1, height - 2)];
bar.Label.Position = [1, 1, max(1, width - 2), max(1, height - 2)];
end
