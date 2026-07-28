function dataset = canonicalize_complex_h(H, timeAxis, freqAxis, sourceInfo, representationType)
%CANONICALIZE_COMPLEX_H Construct the canonical Complex-H dataset struct.
%   dataset = canonicalize_complex_h(H, timeAxis, freqAxis, sourceInfo, representationType)
%   ensures the unified H[T,F,Nr,Nt] layout and standard metadata.

disp('::');

dataset = struct();
dataset.schema_version = "2.0";

% Determine representation type (e.g., "Direct Complex H", "Derived H from SAGE")
if nargin < 5 || isempty(representationType)
    dataset.representation = "Direct Complex H";
else
    dataset.representation = string(representationType);
end

% Assign core matrix
dataset.H = H;

% Assign physical axes
dataset.axes = struct();
dataset.axes.time_s = timeAxis(:);
dataset.axes.frequency_hz = freqAxis(:);

% Determine antenna dimensions strictly from H[T,F,Nr,Nt]
sz = size(H);
while length(sz) < 4
    sz(end+1) = 1; %#ok<AGROW>
end
dataset.antenna = struct();
dataset.antenna.num_rx = sz(3);
dataset.antenna.num_tx = sz(4);

% Assign source and provenance
dataset.source = sourceInfo;
dataset.preprocessing = struct('history', strings(0, 1));
end
