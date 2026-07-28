function dataset = adapt_hdf5_re_im_to_complex_h(realPart, imagPart, timeAxis, freqAxis)
%ADAPT_HDF5_RE_IM_TO_COMPLEX_H Adapt split real/imaginary HDF5 data to Complex-H.
%   dataset = adapt_hdf5_re_im_to_complex_h(realPart, imagPart, timeAxis, freqAxis)
%   reconstructs the complex H matrix from its real and imaginary components.

disp('::');

% Validate inputs
if nargin < 2 || isempty(imagPart)
    % Warning: Missing imaginary part, fallback to real-only
    H = realPart;
    representation = "Real-only HDF5";
    provenance = "Adapted from HDF5 real array (missing imaginary part)";
else
    if ~isequal(size(realPart), size(imagPart))
        error("Dimension mismatch between real and imaginary arrays.");
    end
    % Reconstruct Complex H
    H = complex(realPart, imagPart);
    representation = "Direct Complex H";
    provenance = "Reconstructed from separate Re/Im HDF5 arrays";
end

if nargin < 3
    timeAxis = [];
end
if nargin < 4
    freqAxis = [];
end

% Construct source info
sourceInfo = struct('kind', "HDF5", 'dataset_id', "unknown", 'provenance', provenance);

% Call the canonicalizer to pack it into the standard struct
dataset = canonicalize_complex_h(H, timeAxis, freqAxis, sourceInfo, representation);
end
