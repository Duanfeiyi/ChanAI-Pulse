% ChanAI Pulse v3 CIR/CTF data-contract tests.

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

rng(42);

%% Valid CTF: Tx x Rx x Nf x Nt x N_sample
ctfShape = [2, 2, 4, 3, 10];
H = complex(randn(ctfShape), randn(ctfShape));
ctfAxes = struct( ...
    "frequency_hz", (28e9 + (0:3) * 120e3).', ...
    "time_s", (0:2).' * 1e-3, ...
    "sample_index", (1:10).', ...
    "sample_position_m", [(0:9).', zeros(10, 2)]);
ctfMetadata = struct( ...
    "source", "synthetic_contract_test", ...
    "sample_semantics", "ordered_route", ...
    "random_seed", 42);
ctf = create_channel_dataset("ctf", struct("H", H), ...
    ctfAxes, ctfMetadata);

assert(isequal(ctf.dimension_order, ...
    ["Tx", "Rx", "Nf", "Nt", "N_sample"]));
assert(isequal(size5(ctf.ctf.H), ctfShape));
ctfReport = validate_channel_dataset(ctf);
assert(ctfReport.status == "PASS", ...
    "Complete CTF fixture should pass: %s", strjoin(ctfReport.errors, " | "));

ctfCapabilities = infer_channel_capabilities(ctf);
assert(ctfCapabilities.classification == "wideband_dynamic_mimo");
assert(ctfCapabilities.pdp && ctfCapabilities.frequency_autocorrelation);
assert(ctfCapabilities.doppler_power_spectrum);
assert(ctfCapabilities.delay_sample_heatmap);
assert(~ctfCapabilities.angular_power_spectrum);

%% Valid path-domain CIR
cirShape = [2, 2, 3, 2, 4];
coefficient = complex(randn(cirShape), randn(cirShape));
delayS = reshape([0, 20e-9, 60e-9, 1e-9, 21e-9, 61e-9, ...
    2e-9, 22e-9, 62e-9, 3e-9, 23e-9, 63e-9, ...
    4e-9, 24e-9, 64e-9, 5e-9, 25e-9, 65e-9, ...
    6e-9, 26e-9, 66e-9, 7e-9, 27e-9, 67e-9], [1, 1, 3, 2, 4]);
pathValid = true(size(delayS));
aoaRad = reshape(linspace(-0.5, 0.5, numel(delayS)), size(delayS));
cirAxes = struct( ...
    "time_s", [0; 1e-3], ...
    "sample_index", (1:4).', ...
    "sample_position_m", [(0:3).', zeros(4, 2)]);
cirPayload = struct( ...
    "coefficient", coefficient, ...
    "delay_s", delayS, ...
    "path_valid", pathValid, ...
    "aoa_rad", aoaRad);
cirMetadata = struct( ...
    "source", "synthetic_contract_test", ...
    "sample_semantics", "ordered_route");
cir = create_channel_dataset("cir", cirPayload, cirAxes, cirMetadata);

assert(isequal(cir.dimension_order, ...
    ["Tx", "Rx", "Npath", "Nt", "N_sample"]));
cirReport = validate_channel_dataset(cir);
assert(cirReport.status == "PASS", ...
    "Complete CIR fixture should pass: %s", strjoin(cirReport.errors, " | "));
cirCapabilities = infer_channel_capabilities(cir);
assert(cirCapabilities.pdp && cirCapabilities.angular_power_spectrum);
assert(cirCapabilities.doppler_power_spectrum);

%% Invalid dimensions, units, and missing physical axes
badDimensions = ctf;
badDimensions.dimensions.Nf = 99;
badDimensionReport = validate_channel_dataset(badDimensions);
assert(~badDimensionReport.is_valid && ...
    any(contains(badDimensionReport.errors, "dimensions.Nf")));

badUnits = ctf;
badUnits.units.frequency = "GHz";
badUnitReport = validate_channel_dataset(badUnits);
assert(~badUnitReport.is_valid && ...
    any(contains(badUnitReport.errors, "units.frequency")));

missingFrequency = ctf;
missingFrequency.axes = rmfield(missingFrequency.axes, "frequency_hz");
missingFrequencyReport = validate_channel_dataset(missingFrequency);
assert(missingFrequencyReport.status == "WARNING");
assert(any(contains(missingFrequencyReport.warnings, "frequency_hz")));
missingFrequencyCapabilities = infer_channel_capabilities(missingFrequency);
assert(~missingFrequencyCapabilities.frequency_autocorrelation);

%% Interpolation and extrapolation task rules
interpolation = create_channel_task("interpolation", "sample", ...
    [1:4, 7:10], [5, 6], struct("axis_values", 1:10));
interpolationReport = validate_channel_task(ctf, interpolation);
assert(interpolationReport.is_valid);

extrapolation = create_channel_task("extrapolation", "sample", ...
    1:8, 9:10, struct("axis_values", 1:10));
extrapolationReport = validate_channel_task(ctf, extrapolation);
assert(extrapolationReport.is_valid);

overlapTask = interpolation;
overlapTask.target_indices = [4; 5];
overlapReport = validate_channel_task(ctf, overlapTask);
assert(~overlapReport.is_valid && ...
    any(contains(overlapReport.errors, "must not overlap")));

outsideInterpolation = interpolation;
outsideInterpolation.target_indices = 10;
outsideInterpolation.known_indices = (1:8).';
outsideReport = validate_channel_task(ctf, outsideInterpolation);
assert(~outsideReport.is_valid && ...
    any(contains(outsideReport.errors, "strictly inside")));

%% MATLAB HDF5 round trip preserves complex values and canonical shape
temporaryFile = string(tempname) + ".h5";
temporaryCirFile = string(tempname) + ".h5";
cleanupHandle = onCleanup(@() deleteTemporaryFiles( ...
    [temporaryFile, temporaryCirFile]));
write_channel_dataset_hdf5(temporaryFile, ctf);
ctfReloaded = read_channel_dataset_hdf5(temporaryFile);
assert(isequal(size5(ctfReloaded.ctf.H), ctfShape));
assert(isequal(ctfReloaded.ctf.H, ctf.ctf.H));
assert(isequal(ctfReloaded.axes.sample_position_m, ...
    ctf.axes.sample_position_m));
assert(string(ctfReloaded.metadata.source) == ...
    string(ctf.metadata.source));

write_channel_dataset_hdf5(temporaryCirFile, cir);
cirReloaded = read_channel_dataset_hdf5(temporaryCirFile);
assert(isequal(cirReloaded.cir.coefficient, cir.cir.coefficient));
assert(isequal(cirReloaded.cir.delay_s, cir.cir.delay_s));
assert(isequal(cirReloaded.cir.path_valid, cir.cir.path_valid));
assert(isequal(cirReloaded.cir.aoa_rad, cir.cir.aoa_rad));

clear cleanupHandle
fprintf("PASS: v3 CIR/CTF data, task, capability, and HDF5 contracts.\n");

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end

function deleteTemporaryFiles(filePaths)
for filePath = filePaths
    if isfile(filePath)
        delete(filePath);
    end
end
end
