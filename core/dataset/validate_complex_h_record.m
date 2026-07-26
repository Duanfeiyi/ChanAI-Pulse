function result = validate_complex_h_record(dataset)
%VALIDATE_COMPLEX_H_RECORD Validate the content of a Canonical Complex-H struct.
%   result = validate_complex_h_record(dataset) strictly checks if the dataset
%   contains a valid H matrix with the correct [T, F, Nr, Nt] dimensions
%   and valid physical axes.

result = struct();
result.is_valid = true;
result.status = "PASS";
result.errors = strings(0, 1);
result.warnings = strings(0, 1);

% 1. Check if H exists and is numeric
if ~isfield(dataset, 'H') || isempty(dataset.H)
    result = addError(result, "Missing or empty H matrix.");
    result = finalizeResult(result);
    return;
end

if ~isnumeric(dataset.H)
    result = addError(result, "H matrix must be numeric.");
    result = finalizeResult(result);
    return;
end

% 2. Check for NaN or Inf
if any(isnan(dataset.H(:))) || any(isinf(dataset.H(:)))
    result = addError(result, "H matrix contains NaN or Inf values.");
end

% 3. Check dimensions [T, F, Nr, Nt]
sz = size(dataset.H);
% Pad size to 4D if trailing dimensions are 1
while length(sz) < 4
    sz(end+1) = 1; %#ok<AGROW>
end
if length(sz) > 4
    result = addError(result, "H matrix has more than 4 dimensions. Expected [T, F, Nr, Nt].");
end

T = sz(1);
F = sz(2);
Nr = sz(3);
Nt = sz(4);

% 4. Validate Axes against H dimensions
if isfield(dataset, 'axes')
    if isfield(dataset.axes, 'time_s') && length(dataset.axes.time_s) ~= T
        result = addError(result, "Length of time axis does not match H snapshot dimension (T).");
    end
    if isfield(dataset.axes, 'frequency_hz') && length(dataset.axes.frequency_hz) ~= F
        result = addError(result, "Length of frequency axis does not match H frequency dimension (F).");
    end
else
    result.warnings(end + 1, 1) = "Missing physical axes (time_s, frequency_hz).";
end

% 5. Validate Antenna configurations
if isfield(dataset, 'antenna')
    if isfield(dataset.antenna, 'num_rx') && dataset.antenna.num_rx ~= Nr
        result = addError(result, "num_rx does not match H dimension (Nr).");
    end
    if isfield(dataset.antenna, 'num_tx') && dataset.antenna.num_tx ~= Nt
        result = addError(result, "num_tx does not match H dimension (Nt).");
    end
end

result = finalizeResult(result);
end

function result = addError(result, message)
result.is_valid = false;
result.errors(end + 1, 1) = message; %#ok<AGROW>
end

function result = finalizeResult(result)
if ~isempty(result.errors)
    result.status = "FAIL";
elseif ~isempty(result.warnings)
    result.status = "WARNING";
else
    result.status = "PASS";
end
end
