function value = get_filled_progress_value(bar)
%GET_FILLED_PROGRESS_VALUE Return the normalized value stored by the bar.

value = 0;
if isstruct(bar) && isfield(bar, "Track") && ...
        ~isempty(bar.Track) && isvalid(bar.Track) && ...
        isappdata(bar.Track, "FilledProgressFraction")
    value = double(getappdata(bar.Track, "FilledProgressFraction"));
end
value = max(0, min(1, value));
end
