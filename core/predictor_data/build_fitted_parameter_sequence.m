function [sequence, details] = build_fitted_parameter_sequence( ...
        channelDataset, optimizationConfig, options)
%BUILD_FITTED_PARAMETER_SEQUENCE Fit one parameter row per local sample window.
%   The original channel dataset is never modified. Failed windows remain
%   auditable rows with quality_status FAIL and are excluded downstream.

arguments
    channelDataset (1, 1) struct
    optimizationConfig (1, 1) struct
    options (1, 1) struct = struct()
end

channelReport = validate_channel_dataset(channelDataset);
if ~channelReport.is_valid
    error("build_fitted_parameter_sequence:InvalidChannelDataset", ...
        "%s", strjoin(channelReport.errors, " | "));
end
config = default_predictor_data_config();
windowLength = optionValue(options, "window_length", ...
    config.local_fit_window.length);
stride = optionValue(options, "stride", config.local_fit_window.stride);
parameterNames = string(optionValue(options, "parameter_names", ...
    config.standard_parameter_names));
parameterNames = parameterNames(:).';
groupId = string(optionValue(options, "group_id", ...
    inferGroupId(channelDataset)));
sampleCount = double(channelDataset.dimensions.N_sample);
starts = 1:stride:(sampleCount - windowLength + 1);
if isempty(starts)
    error("build_fitted_parameter_sequence:InsufficientSamples", ...
        "N_sample=%d is smaller than local window length %d.", ...
        sampleCount, windowLength);
end

rowCount = numel(starts);
values = nan(rowCount, numel(parameterNames));
fitScores = inf(rowCount, 1);
quality = repmat("FAIL", rowCount, 1);
sources = repmat("grid_fitted", rowCount, 1);
results = cell(rowCount, 1);
for row = 1:rowCount
    indices = starts(row):(starts(row) + windowLength - 1);
    localDataset = subsetSamples(channelDataset, indices);
    result = run_parameter_optimization( ...
        localDataset, optimizationConfig, optimizerOptions(options));
    results{row} = result;
    if strlength(result.selected_strategy) > 0
        sources(row) = result.selected_strategy + "_fitted";
    end
    if result.success && isfield(result.best, "parameters")
        for column = 1:numel(parameterNames)
            name = parameterNames(column);
            if isfield(result.best.parameters, name)
                values(row, column) = ...
                    double(result.best.parameters.(name));
            elseif isfield(result.config.generator_config.model, name)
                values(row, column) = double( ...
                    result.config.generator_config.model.(name));
            end
        end
        fitScores(row) = double(result.best.total_score);
        quality(row) = upper(string(result.status));
        if ~all(isfinite(values(row, :)))
            quality(row) = "FAIL";
        end
    end
    notifyProgress(options, row, rowCount);
end

sequenceOptions = struct( ...
    "group_id", repmat(groupId, rowCount, 1), ...
    "label_source", sources, ...
    "fit_score", fitScores, ...
    "quality_status", quality, ...
    "parameter_sample_index", (1:rowCount).', ...
    "raw_window_start", starts(:), ...
    "raw_window_end", starts(:) + windowLength - 1, ...
    "raw_window_center", starts(:) + (windowLength - 1) / 2, ...
    "provenance", struct( ...
        "source", "local_channel_parameter_fit", ...
        "window_length", windowLength, ...
        "stride", stride, ...
        "optimizer_schema", optimizationConfig.schema_version, ...
        "recommended_usage", "Measured-data fine-tuning candidate"));
if isfield(options, "units")
    sequenceOptions.units = options.units;
end
if isfield(options, "bounds")
    sequenceOptions.bounds = options.bounds;
end
sequence = create_parameter_sequence( ...
    values, parameterNames, sequenceOptions);
details = struct( ...
    "schema_version", "v3.0-local-fit-details.1", ...
    "window_start", starts(:), ...
    "window_length", windowLength, ...
    "stride", stride, ...
    "optimization_results", {results}, ...
    "success_count", sum(quality ~= "FAIL"), ...
    "failure_count", sum(quality == "FAIL"));
end

function value = optionValue(options, fieldName, fallback)
value = fallback;
if isfield(options, fieldName)
    value = options.(fieldName);
end
end

function value = inferGroupId(dataset)
value = "channel-group-001";
if isfield(dataset, "metadata")
    candidates = ["group_id", "route_id", "scene_id", "dataset_id"];
    for name = candidates
        if isfield(dataset.metadata, name)
            value = string(dataset.metadata.(name));
            return;
        end
    end
end
end

function optionsOut = optimizerOptions(options)
optionsOut = struct();
for name = ["progress_callback", "cancel_check"]
    if isfield(options, name)
        optionsOut.(name) = options.(name);
    end
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

function selected = subsetSamples(dataset, indices)
selected = dataset;
fields = ["coefficient", "delay_s", "path_valid", ...
    "aoa_rad", "aod_rad", "doppler_hz"];
if lower(string(dataset.domain)) == "ctf"
    selected.ctf.H = subsetFifthDimension(dataset.ctf.H, indices);
else
    for name = fields
        if isfield(selected.cir, name)
            selected.cir.(name) = ...
                subsetFifthDimension(selected.cir.(name), indices);
        end
    end
end
selected.dimensions.N_sample = numel(indices);
for name = ["sample_index", "sample_position_m"]
    if isfield(selected.axes, name) && ...
            size(selected.axes.(name), 1) >= max(indices)
        axisValue = selected.axes.(name);
        selected.axes.(name) = axisValue(indices, :);
    end
end
end

function value = subsetFifthDimension(value, indices)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
if shape(5) == 1
    return;
end
value = value(:, :, :, :, indices);
shape(5) = numel(indices);
value = reshape(value, shape);
end
