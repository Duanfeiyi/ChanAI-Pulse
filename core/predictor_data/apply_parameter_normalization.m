function normalized = apply_parameter_normalization(values, manifest)
%APPLY_PARAMETER_NORMALIZATION Apply one Step 9 z-score manifest.

parameterCount = numel(manifest.parameter_names);
if parameterCount > 1 && size(values, ndims(values)) ~= parameterCount
    error("apply_parameter_normalization:ParameterCountMismatch", ...
        "The final tensor dimension must equal P.");
end
if parameterCount == 1
    shape = [1, 1];
else
    shape = ones(1, max(2, ndims(values)));
    shape(end) = parameterCount;
end
mu = reshape(double(manifest.mean), shape);
sigma = reshape(double(manifest.standard_deviation), shape);
normalized = (double(values) - mu) ./ sigma;
end
