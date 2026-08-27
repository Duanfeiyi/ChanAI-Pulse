function export_v32_1_frequency_to_hdf5(inputMat, outputH5)
%EXPORT_V32_1_FREQUENCY_TO_HDF5 Export the Frequency corpus to a Python-friendly
%   plain-numeric HDF5 (no MATLAB cell arrays). Writes:
%     /ctf_real  [360, 64, 4, 2]  (N_spectrum, Nf, Rx, Tx)
%     /ctf_imag  [360, 64, 4, 2]
%     /pattern           string array [360]
%     /scenario          string array [360]
%     /known_index       [360, K] int64 (padded, NaN where shorter)
%     /target_index      [360, T] int64 (padded)
%     /frequency_hz      [360, 64] double
%   This is a data-export helper; it never modifies the source MAT.

arguments
    inputMat (1, 1) string
    outputH5 (1, 1) string
end

data = load(inputMat);
ctfCells = data.ctfCells;
n = numel(ctfCells);
freqHz = data.freqHzCell;
patterns = string(data.patternLabel(:)).';
scenarios = string(data.scenarioLabel(:)).';
knownCells = data.knownIdxCells;
targetCells = data.targetIdxCells;

nf = size(ctfCells{1}, 3);
rxCount = size(ctfCells{1}, 2);
txCount = size(ctfCells{1}, 1);

ctfReal = zeros(n, nf, rxCount, txCount);
ctfImag = zeros(n, nf, rxCount, txCount);
frequencyHz = zeros(n, nf);
for index = 1:n
    h = ctfCells{index};            % [Tx, Rx, Nf] complex
    h = permute(h, [3, 2, 1]);      % [Nf, Rx, Tx]
    ctfReal(index, :, :, :) = real(h);
    ctfImag(index, :, :, :) = imag(h);
    frequencyHz(index, :) = freqHz{index}(:).';
end

knownCount = max(cellfun(@numel, knownCells));
targetCount = max(cellfun(@numel, targetCells));
knownIndex = nan(n, knownCount);
targetIndex = nan(n, targetCount);
for index = 1:n
    k = double(knownCells{index}(:)).';
    t = double(targetCells{index}(:)).';
    knownIndex(index, 1:numel(k)) = k;
    targetIndex(index, 1:numel(t)) = t;
end

if isfile(outputH5)
    delete(outputH5);
end
% MATLAB h5create sizes are column-major; h5py reads row-major. We declare the
% flipped (column-major) size and permute data to that layout so h5py reads
% back the intended logical shape [N, Nf, Rx, Tx].
writeFlippedDataset(outputH5, "/ctf_real", ctfReal);
writeFlippedDataset(outputH5, "/ctf_imag", ctfImag);
writeFlippedDataset(outputH5, "/known_index", knownIndex);
writeFlippedDataset(outputH5, "/target_index", targetIndex);
writeFlippedDataset(outputH5, "/frequency_hz", frequencyHz);
h5writeatt(outputH5, "/", "schema_version", "v3.2-1-frequency-hdf5-export.1");
h5writeatt(outputH5, "/", "dimension_order", "N_spectrum,Nf,Rx,Tx");
h5writeatt(outputH5, "/", "complex_split", "ctf_real+1j*ctf_imag");

% Strings: write as UTF-8 char arrays in a fixed-size dataset.
maxPattern = max(strlength(patterns));
maxScenario = max(strlength(scenarios));
patternBytes = zeros(n, maxPattern, "uint8");
scenarioBytes = zeros(n, maxScenario, "uint8");
for index = 1:n
    p = unicode2native(char(patterns(index)), "UTF-8");
    s = unicode2native(char(scenarios(index)), "UTF-8");
    patternBytes(index, 1:numel(p)) = uint8(p);
    scenarioBytes(index, 1:numel(s)) = uint8(s);
end
writeFlippedDataset(outputH5, "/pattern", patternBytes);
writeFlippedDataset(outputH5, "/scenario", scenarioBytes);
h5writeatt(outputH5, "/pattern", "encoding", "utf-8");
h5writeatt(outputH5, "/scenario", "encoding", "utf-8");

fprintf("Exported %d spectra to %s\n", n, outputH5);
end

function writeFlippedDataset(fileName, datasetPath, value)
% Declare the HDF5 dataset with the column-major (reversed) size and write
% the value permuted to that layout, so h5py reads the intended row-major
% logical shape.
sz = size(value);
h5create(fileName, datasetPath, fliplr(sz), "Datatype", class(value));
h5write(fileName, datasetPath, permute(value, numel(sz):-1:1));
end
