function bar = create_filled_progress_bar(parent, options)
%CREATE_FILLED_PROGRESS_BAR Create a reusable horizontal fill progress bar.
%   The returned struct is intentionally lightweight so it can be owned by
%   ordinary MATLAB handle apps without introducing another app class.

arguments
    parent
    options.Value (1, 1) double = 0
    options.Text (1, 1) string = "0%"
    options.ShowText (1, 1) logical = true
    options.TrackColor (1, 3) double = [0.90, 0.93, 0.97]
    options.FillColor (1, 3) double = [0.06, 0.35, 0.64]
end

track = uigridlayout(parent, [1, 2], ...
    "ColumnWidth", {"0.001x", "0.999x"}, "RowHeight", {"1x"}, ...
    "Padding", [1, 1, 1, 1], "ColumnSpacing", 0, ...
    "BackgroundColor", [0.66, 0.72, 0.80]);
fill = uipanel(track, "BorderType", "none", ...
    "BackgroundColor", options.FillColor);
fill.Layout.Row = 1;
fill.Layout.Column = 1;
fillGrid = uigridlayout(fill, [1, 1], "Padding", [0, 0, 0, 0], ...
    "BackgroundColor", options.FillColor);
label = uilabel(fillGrid, "Text", options.Text, ...
    "HorizontalAlignment", "center", "VerticalAlignment", "center", ...
    "FontWeight", "bold", "FontColor", [1, 1, 1], ...
    "Visible", onOff(options.ShowText));
remainder = uipanel(track, "BorderType", "none", ...
    "BackgroundColor", options.TrackColor);
remainder.Layout.Row = 1;
remainder.Layout.Column = 2;

bar = struct("Kind", "weighted_grid", ...
    "Track", track, "Fill", fill, "Label", label, ...
    "Remainder", remainder, "FillGrid", fillGrid);
setappdata(track, "FilledProgressFraction", clamp(options.Value));
update_filled_progress_bar(bar, options.Value, Text=options.Text);
end

function value = clamp(value)
value = max(0, min(1, double(value)));
end

function value = onOff(tf)
if tf
    value = "on";
else
    value = "off";
end
end
