function exportBundle = create_step5_export_bundle(analysis, task)
%CREATE_STEP5_EXPORT_BUNDLE Build a portable Step 5 result package.
%   The returned structure contains analysis results, task definition,
%   dataset summary, and export time. It does not copy the source dataset
%   or modify the uploaded HDF5 file.

arguments
    analysis (1, 1) struct
    task (1, 1) struct = struct()
end

requiredFields = ["status", "dataset_summary", "metrics", "registry"];
missingFields = requiredFields(~isfield(analysis, requiredFields));
if ~isempty(missingFields)
    error("ChanAIPulse:Step5:InvalidExportAnalysis", ...
        "Step 5 analysis is missing required fields: %s.", ...
        strjoin(missingFields, ", "));
end
if string(analysis.status) == "FAIL"
    error("ChanAIPulse:Step5:FailedAnalysisExport", ...
        "A failed Step 5 analysis cannot be exported.");
end

exportBundle = struct( ...
    "schema", "chanai-pulse-step5-export-v1", ...
    "analysis", analysis, ...
    "task", task, ...
    "dataset_summary", analysis.dataset_summary, ...
    "exported_utc", string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'")));
end
