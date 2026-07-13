function provenance = record_data_provenance(sourceType, sampleCount, options)
%RECORD_DATA_PROVENANCE Create explicit provenance for prepared samples.
%   The provenance record is metadata only; it does not copy source data.

arguments
    sourceType (1, 1) string
    sampleCount (1, 1) double {mustBeInteger, mustBeNonnegative}
    options.SourceId (1, 1) string = "unspecified"
    options.Visibility (1, 1) string = "local_only"
end

allowedTypes = ["real_train", "real_validation", "real_test", ...
    "synthetic_generated", "measurement_calibrated_synthetic"];
if ~any(sourceType == allowedTypes)
    error("record_data_provenance:InvalidSourceType", ...
        "Unsupported source type: %s", sourceType);
end

provenance = struct();
provenance.source_type = sourceType;
provenance.sample_count = sampleCount;
provenance.source_id = options.SourceId;
provenance.visibility = options.Visibility;
provenance.created_at = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
end
