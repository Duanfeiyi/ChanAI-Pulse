function phase = compute_complex_h_phase(dataset, capabilities, doUnwrap)
%COMPUTE_COMPLEX_H_PHASE Calculate phase from Complex-H dataset.
%   phase = compute_complex_h_phase(dataset, capabilities, doUnwrap)
%   strictly enforces phase capability before computing angle(H).

disp('::');

if nargin < 3
    doUnwrap = false;
end

% 核心防线：检查通行证，拒绝为 Legacy Power 等无相位数据伪造相位
if ~capabilities.has_phase
    error("Operation rejected: Data lacks valid phase (e.g., Legacy Power). Cannot compute phase.");
end

if ~isfield(dataset, 'H') || ~isnumeric(dataset.H)
    error("Invalid dataset: Missing numeric H matrix.");
end

% Calculate phase
phase = angle(dataset.H);

% Optional unwrap along time dimension (dimension 1)
if doUnwrap
    phase = unwrap(phase, [], 1);
end

end
