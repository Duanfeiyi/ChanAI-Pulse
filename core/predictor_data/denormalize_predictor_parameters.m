function values = denormalize_predictor_parameters(normalized, manifest)
%DENORMALIZE_PREDICTOR_PARAMETERS Restore units and optionally bound values.

parameterCount = numel(manifest.parameter_names);
if parameterCount > 1 && ...
        size(normalized, ndims(normalized)) ~= parameterCount
    error("denormalize_predictor_parameters:ParameterCountMismatch", ...
        "The final tensor dimension must equal P.");
end
if parameterCount == 1
    shape = [1, 1];
else
    shape = ones(1, max(2, ndims(normalized)));
    shape(end) = parameterCount;
end
mu = reshape(double(manifest.mean), shape);
sigma = reshape(double(manifest.standard_deviation), shape);
values = double(normalized) .* sigma + mu;
if logical(manifest.project_to_physical_bounds)
    lower = reshape(double(manifest.physical_bounds(:, 1)), shape);
    upper = reshape(double(manifest.physical_bounds(:, 2)), shape);
    values = min(max(values, lower), upper);
end
if isfield(manifest, "integer_parameter")
    integerMask = logical(manifest.integer_parameter(:)).';
    if parameterCount == 1 && integerMask(1)
        values = round(values);
    elseif any(integerMask)
        subscripts = repmat({':'}, 1, ndims(values));
        for parameterIndex = find(integerMask)
            subscripts{end} = parameterIndex;
            values(subscripts{:}) = round(values(subscripts{:}));
        end
    end
end
end
