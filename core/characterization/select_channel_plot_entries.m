function entries = select_channel_plot_entries(registry)
%SELECT_CHANNEL_PLOT_ENTRIES Return plots exposed by module UI.
%   Standard 1/3/6/9 classifications expose only their standard plots plus
%   declared additional plots. Non-standard dimension combinations expose
%   all scientifically available plots, but do not claim a standard count.

arguments
    registry (1, 1) struct
end

requiredFields = ["entries", "is_standard_classification"];
missingFields = requiredFields(~isfield(registry, requiredFields));
if ~isempty(missingFields)
    error("ChanAIPulse:Step5:InvalidPlotRegistry", ...
        "Plot registry is missing required fields: %s.", ...
        strjoin(missingFields, ", "));
end

allEntries = registry.entries;
available = [allEntries.available].';
if registry.is_standard_classification
    allowed = [allEntries.is_standard].' | ...
        [allEntries.is_additional].';
else
    allowed = true(size(available));
end
entries = allEntries(available & allowed);
end
