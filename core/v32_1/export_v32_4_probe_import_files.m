function export_v32_4_probe_import_files(outputDir)
%EXPORT_V32_4_PROBE_IMPORT_FILES Write v3.2-4a App-import probe files.
%   Produces three v3 channel-dataset HDF5 files for the three-axis UI:
%     v32_4_frequency_import.h5  CTF spectrum 0 of the Frequency corpus
%                                (full 64-subcarrier in-band CTF; the task
%                                partition decides known/target).
%     v32_4_time_import.h5       Time-axis CIR route (Nt=96 snapshots,
%                                time_s axis, 8 m/s).
%     v32_4_space_import.h5      Space-axis CIR route (N_sample=96
%                                positions, sample_position_m axis).
%   The Space position axis is normalized to N_sample-by-(1|2|3) as the
%   channel contract requires. This is probe/test-data tooling; it never
%   modifies the corpus or Full 6GPCM.

arguments
    outputDir (1, 1) string = pwd
end

corpusRoot = "D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\chanaipulse-v3.2-corpus.1";
if ~isfolder(outputDir)
    mkdir(outputDir);
end

%% 1. Frequency: block_8 spectrum (index 2) of the in-band CTF corpus.
%    block_8 targets (subcarriers 29..36) lie strictly inside the known
%    range, so the imported task can be an interpolation task.
frequencyH5 = fullfile(corpusRoot, "frequency_inband_ctf.h5");
[realPart, imagPart, ~, ~, freqHz] = readSpectrum(frequencyH5, 2);
H = realPart + 1j * imagPart;               % [Tx, Rx, Nf]
HCanonical = reshape(H, [size(H, 1), size(H, 2), size(H, 3), 1, 1]);
frequencyFile = fullfile(outputDir, "v32_4_frequency_import.h5");
axes = struct("frequency_hz", freqHz(:), "sample_index", 1);
metadata = struct( ...
    "source", "chanaipulse_v32_1_frequency_corpus", ...
    "sample_semantics", "ordered_frequency", ...
    "center_frequency_hz", mean(freqHz), ...
    "subcarrier_spacing_hz", median(diff(freqHz)));
dataset = create_channel_dataset("ctf", struct("H", HCanonical), ...
    axes, metadata);
dataset = enrichProbeMetadata(dataset);
writeProbeFile(frequencyFile, dataset);

%% 2. Time: raw time-route CIR sample (cell 1).
timeDataset = loadTimeRoute();
timeDataset = enrichProbeMetadata(timeDataset);
timeFile = fullfile(outputDir, "v32_4_time_import.h5");
writeProbeFile(timeFile, timeDataset);

%% 3. Space: raw space-route CIR sample (cell 1), positions normalized.
spaceDataset = loadSpaceRoute();
spaceDataset = enrichProbeMetadata(spaceDataset);
spaceFile = fullfile(outputDir, "v32_4_space_import.h5");
writeProbeFile(spaceFile, spaceDataset);

fprintf("PASS: v3.2-4a probe import files exported to %s\n", outputDir);
fprintf("  %s (frequency, Nf=%d)\n", frequencyFile, size(H, 3));
fprintf("  %s (time, Nt=%d)\n", timeFile, timeDataset.dimensions.Nt);
fprintf("  %s (space, N_sample=%d)\n", spaceFile, ...
    spaceDataset.dimensions.N_sample);
end

function dataset = loadTimeRoute()
data = load(fullfile( ...
    "D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\chanaipulse-v3.2-corpus.1", ...
    "raw_cir_probe_samples.mat"));
dataset = data.rawCirSamples{1};
end

function writeProbeFile(filePath, dataset)
% Probe files are deterministic review artifacts: always regenerate them so
% metadata fixes take effect; write_channel_dataset_hdf5 refuses to
% overwrite, so delete first.
if isfile(filePath)
    delete(filePath);
end
write_channel_dataset_hdf5(filePath, dataset);
end

function dataset = enrichProbeMetadata(dataset)
% v3.2-4a review data completeness: the raw route CIRs carry only
% center_frequency_hz. Add the frequency grid definition and ULA geometry
% so the platform's capability engine can render the full 6 standard plots
% (frequency autocorrelation via the derived CTF; angular power spectrum
% and angular-spread CDF via Rx/Tx beamspace over the ULA). These fields
% describe the generator configuration that produced the data; they never
% fabricate per-path angles.
frequencyCount = 64;
spacingHz = 120e3;
if ~isfield(dataset.metadata, "frequency_count")
    dataset.metadata.frequency_count = frequencyCount;
end
if ~isfield(dataset.metadata, "subcarrier_spacing_hz")
    dataset.metadata.subcarrier_spacing_hz = spacingHz;
end
centerHz = double(dataset.metadata.center_frequency_hz);
wavelengthM = 299792458 / centerHz;
geometry = struct( ...
    "type", "ULA", ...
    "element_spacing_m", 0.5 * wavelengthM, ...
    "element_spacing_wavelength", 0.5, ...
    "geometry_source", "v32_1_route_generator_ULA");
if ~isfield(dataset.metadata, "tx_array")
    dataset.metadata.tx_array = geometry;
end
if ~isfield(dataset.metadata, "rx_array")
    dataset.metadata.rx_array = geometry;
end
end

function dataset = loadSpaceRoute()
data = load(fullfile( ...
    "D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\chanaipulse-v3.2-corpus.1", ...
    "raw_cir_probe_samples.mat"));
dataset = data.spaceRawCirSamples{1};
if isfield(dataset.axes, "sample_position_m")
    positions = dataset.axes.sample_position_m;
    nSample = dataset.dimensions.N_sample;
    if size(positions, 1) ~= nSample && size(positions, 2) == nSample
        % QuaDRiGa-style [3, N] layout -> contract N-by-(1|2|3).
        positions = positions.';
    end
    dataset.axes.sample_position_m = positions;
end
end

function [realPart, imagPart, knownIdx, targetIdx, freqHz] = ...
        readSpectrum(filePath, spectrumIndex)
% Exported HDF5 stores [Tx, Rx, Nf, N_spectrum] for CTF and [Nf, N] for
% frequency_hz (MATLAB column-major write; see export script).
realAll = h5read(filePath, "/ctf_real");    % [Tx, Rx, Nf, N]
imagAll = h5read(filePath, "/ctf_imag");
realPart = squeeze(realAll(:, :, :, spectrumIndex + 1));  % [Tx, Rx, Nf]
imagPart = squeeze(imagAll(:, :, :, spectrumIndex + 1));
knownAll = h5read(filePath, "/known_index");   % [K, N]
knownIdx = knownAll(:, spectrumIndex + 1);
knownIdx = knownIdx(~isnan(knownIdx));
targetAll = h5read(filePath, "/target_index"); % [T, N]
targetIdx = targetAll(:, spectrumIndex + 1);
targetIdx = targetIdx(~isnan(targetIdx));
freqAll = h5read(filePath, "/frequency_hz");   % [Nf, N]
freqHz = freqAll(:, spectrumIndex + 1);
end
