function cir = ifft_ctf_to_cir(ctfDataset)
%IFFT_CTF_TO_CIR Deterministic IFFT of a CTF dataset to the time-delay domain.
%   Shared by the v3.2-3c Frequency chain and the v3.2-4a App frequency
%   generation path. The derived CIR uses its own clean axes (sample_index
%   only, no frequency_hz); metadata marks the deterministic derivation.
%   Never modifies the input dataset.

arguments
    ctfDataset (1, 1) struct
end

report = validate_channel_dataset(ctfDataset);
if ~report.is_valid
    error("ifft_ctf_to_cir:InvalidCtf", ...
        "%s", strjoin(report.errors, " | "));
end

H = ctfDataset.ctf.H;                    % [Tx, Rx, Nf, Nt, N_sample]
coefficient = ifft(H, [], 3);
nf = size(H, 3);
frequencyHz = double(ctfDataset.axes.frequency_hz(:));
if numel(frequencyHz) < 2
    error("ifft_ctf_to_cir:NeedFrequencyAxis", ...
        "CTF must carry at least two frequency samples for the IFFT delay axis.");
end
spacing = median(diff(frequencyHz));
delayAxis = reshape((0:nf - 1) / (nf * spacing), [1, 1, nf, 1, 1]);
delayS = repmat(delayAxis, [size(coefficient, 1), size(coefficient, 2), ...
    1, size(coefficient, 4), size(coefficient, 5)]);
pathValid = true(size(coefficient));
payload = struct( ...
    "coefficient", coefficient, ...
    "delay_s", delayS, ...
    "path_valid", pathValid);
cirAxes = struct("sample_index", 1);
cirMetadata = ctfDataset.metadata;
cirMetadata.source = string(cirMetadata.source) + "_deterministic_ifft";
cir = create_channel_dataset("cir", payload, cirAxes, cirMetadata);
end
