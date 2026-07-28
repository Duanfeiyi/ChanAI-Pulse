function [mag, mag_db] = compute_complex_h_magnitude(dataset, refVal)
%COMPUTE_COMPLEX_H_MAGNITUDE Calculate magnitude from Complex-H dataset.
%   [mag, mag_db] = compute_complex_h_magnitude(dataset, refVal) computes
%   the absolute value and dB scale, explicitly handling zero values.

disp('::');

if ~isfield(dataset, 'H') || ~isnumeric(dataset.H)
    error("Invalid dataset: Missing numeric H matrix.");
end

if nargin < 2
    refVal = 1; % Default reference for dB
end

% Calculate linear magnitude
mag = abs(dataset.H);

% Calculate dB (safeguard against log of zero)
safeMag = max(mag, eps);
mag_db = 20 * log10(safeMag / refVal);

end
