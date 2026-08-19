function result = extract_known_region_p8_sequence( ...
        channelDataset, task, calibrationResult, backend, options)
%EXTRACT_KNOWN_REGION_P8_SEQUENCE Build target-free local P8 observations.
%   Each output row is derived directly from one or more contiguous known
%   channel samples. Target-region samples are never subset or inspected.

arguments
    channelDataset (1, 1) struct
    task (1, 1) struct
    calibrationResult (1, 1) struct
    backend (1, 1) string
    options (1, 1) struct = struct()
end

if ~isfield(task, "known_indices") || isempty(task.known_indices) || ...
        ~isfield(task, "target_indices") || isempty(task.target_indices)
    error("extract_known_region_p8_sequence:InvalidTask", ...
        "The task must provide nonempty known and target indices.");
end
if ~isfield(calibrationResult, "success") || ...
        ~calibrationResult.success || ...
        ~isfield(calibrationResult, "best") || ...
        ~isfield(calibrationResult.best, "parameters")
    error("extract_known_region_p8_sequence:NoCalibration", ...
        "A successful Module 2 calibration is required.");
end

names = ["DS_mu", "KF_mu", "DS_sigma", "KF_sigma", ...
    "r_DS", "LNS_ksi", "num_clusters", "num_rays"];
known = sort(double(task.known_indices(:)).');
segments = contiguousSegments(known);
windowLength = optionValue(options, "window_length", 1);
stride = optionValue(options, "stride", 1);
defaults = default_generator_config(backend).model;
for name = string(fieldnames(calibrationResult.best.parameters)).'
    if isfield(defaults, name)
        defaults.(name) = calibrationResult.best.parameters.(name);
    end
end
startsBySegment = cellfun(@(indices) validStarts(indices, ...
    windowLength, stride), segments, "UniformOutput", false);
total = sum(cellfun(@numel, startsBySegment));
if total < 1
    error("extract_known_region_p8_sequence:InsufficientKnownSamples", ...
        "No contiguous known-only segment has at least %d samples.", ...
        windowLength);
end

values = repmat(parameterValues(defaults, names), total, 1);
sampleIndex = zeros(total, 1);
rawStart = zeros(total, 1);
rawEnd = zeros(total, 1);
fitScore = nan(total, 1);
quality = repmat("FAIL", total, 1);
source = repmat("direct_channel_observed", total, 1);
group = strings(total, 1);
details = cell(total, 1);
observableNames = ["DS_mu", "KF_mu", "num_clusters"];
observableColumns = [1, 2, 7];
availableForAllRows = true(1, numel(observableNames));
row = 0;
for segmentNumber = 1:numel(segments)
    indices = segments{segmentNumber};
    starts = startsBySegment{segmentNumber};
    for start = starts
        checkCancellation(options);
        row = row + 1;
        localRows = start:(start + windowLength - 1);
        rawIndices = indices(localRows);
        localDataset = subset_channel_dataset_samples( ...
            channelDataset, rawIndices(:));
        estimate = estimate_local_p8_observables(localDataset);
        available = isfinite(estimate.values);
        values(row, observableColumns(available)) = estimate.values(available);
        availableForAllRows = availableForAllRows & available;
        sampleIndex(row) = rawIndices(ceil(numel(rawIndices) / 2));
        rawStart(row) = rawIndices(1);
        rawEnd(row) = rawIndices(end);
        fitScore(row) = estimate.quality_score;
        quality(row) = estimate.quality_status;
        group(row) = "known-segment-" + segmentNumber;
        details{row} = estimate;
        notifyProgress(options, row, total);
    end
end

% A field is advertised as locally observed only when every accepted row
% supplies it.  Otherwise the complete column returns to the calibrated
% value instead of mixing observations with hidden default substitutions.
unavailableObservableColumns = observableColumns(~availableForAllRows);
if ~isempty(unavailableObservableColumns)
    defaultValues = parameterValues(defaults, names);
    values(:, unavailableObservableColumns) = repmat( ...
        defaultValues(unavailableObservableColumns), total, 1);
end
observed = observableNames(availableForAllRows);
imputed = setdiff(names, observed, "stable");
sequence = create_parameter_sequence(values, names, struct( ...
    "group_id", group, ...
    "label_source", source, ...
    "fit_score", fitScore, ...
    "quality_status", quality, ...
    "parameter_sample_index", sampleIndex, ...
    "raw_window_start", rawStart, ...
    "raw_window_end", rawEnd, ...
    "raw_window_center", sampleIndex, ...
    "provenance", struct( ...
        "source", "known_region_direct_channel_observables", ...
        "target_channel_samples_read", false, ...
        "window_length", windowLength, ...
        "stride", stride, ...
        "locally_observed_parameter_names", observed, ...
        "imputed_parameter_names", imputed, ...
        "imputed_parameter_values", parameterValues(defaults, imputed), ...
        "identifiability_note", [ ...
            "Locally observable fields are determined from the uploaded " ...
            "channel capability. Any field unavailable for all known rows " ...
            "retains its calibrated/versioned value and is frozen during " ...
            "prediction."])));
result = struct( ...
    "schema_version", "v3.1-known-region-p8-extraction.2", ...
    "success", true, ...
    "sequence", sequence, ...
    "details", {details}, ...
    "known_indices", known(:), ...
    "target_indices", double(task.target_indices(:)), ...
    "target_channel_samples_read", false, ...
    "valid_row_count", sum(upper(sequence.quality_status) ~= "FAIL"), ...
    "failed_row_count", sum(upper(sequence.quality_status) == "FAIL"));
end

function starts = validStarts(indices, lengthValue, stride)
starts = 1:stride:(numel(indices) - lengthValue + 1);
if numel(indices) < lengthValue
    starts = zeros(1, 0);
end
end

function segments = contiguousSegments(indices)
breaks = [0, find(diff(indices) ~= 1), numel(indices)];
segments = cell(numel(breaks) - 1, 1);
for index = 1:numel(segments)
    segments{index} = indices(breaks(index) + 1:breaks(index + 1));
end
end

function values = parameterValues(model, names)
values = zeros(1, numel(names));
for index = 1:numel(names)
    values(index) = double(model.(names(index)));
end
end

function value = optionValue(options, name, fallback)
value = fallback;
if isfield(options, name)
    value = options.(name);
end
end

function notifyProgress(options, completed, total)
if isfield(options, "fit_progress_callback") && ...
        isa(options.fit_progress_callback, "function_handle")
    options.fit_progress_callback(struct( ...
        "completed_windows", completed, ...
        "total_windows", total, ...
        "fraction", completed / total));
end
end

function checkCancellation(options)
if isfield(options, "cancel_check") && ...
        isa(options.cancel_check, "function_handle") && ...
        logical(options.cancel_check())
    error("extract_known_region_p8_sequence:Cancelled", ...
        "Known-region P8 extraction was cancelled.");
end
end
