% ChanAI Pulse v3 Step 4 input-pipeline and legacy-adapter tests.

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

temporaryRoot = string(tempname);
mkdir(temporaryRoot);
cleanupHandle = onCleanup(@() rmdir(temporaryRoot, "s"));

%% Standard v3 HDF5 input and 80/20 task preset
rng(404);
shape = [1, 2, 8, 4, 10];
H = complex(randn(shape), randn(shape));
axes = struct( ...
    "frequency_hz", (3.5e9 + (0:7).' * 15e3), ...
    "time_s", (0:3).' * 1e-3, ...
    "sample_index", (1:10).');
metadata = struct( ...
    "source", "step4_standard_test", ...
    "sample_semantics", "independent");
ctf = create_channel_dataset("ctf", struct("H", H), axes, metadata);
standardFile = fullfile(temporaryRoot, "standard_ctf.h5");
write_channel_dataset_hdf5(standardFile, ctf);

standardResult = import_channel_dataset(standardFile, struct( ...
    "task_mode", "interpolation", ...
    "task_axis", "sample", ...
    "task_preset", "80_20"));
assert(standardResult.status == "PASS");
assert(standardResult.validation.is_valid);
assert(standardResult.dataset.domain == "ctf");
assert(isequal(size5(standardResult.dataset.ctf.H), shape));
assert(standardResult.task.mode == "interpolation");
assert(all(standardResult.task.target_indices > ...
    min(standardResult.task.known_indices)));
assert(all(standardResult.task.target_indices < ...
    max(standardResult.task.known_indices)));
assert(standardResult.provenance.read_only_import);
assert(standardResult.provenance.original_file_unchanged);

manualFrequency = import_channel_dataset(standardFile, struct( ...
    "task_mode", "extrapolation", ...
    "task_axis", "frequency", ...
    "task_preset", "manual", ...
    "known_indices", 1:6, ...
    "target_indices", 7:8));
assert(manualFrequency.status == "PASS");

noTask = import_channel_dataset(standardFile);
assert(noTask.status == "WARNING");
assert(any(contains(noTask.validation.warnings, ...
    "no interpolation/extrapolation task")));

%% Known non-channel MAT input is rejected with an actionable category
dpsdFile = fullfile(temporaryRoot, "DPSD_1_1.mat");
dpsd = ones(200, 1) * 1e-8;
save(dpsdFile, "dpsd");
dpsdResult = import_channel_dataset(dpsdFile);
assert(dpsdResult.status == "FAIL");
assert(dpsdResult.file.category == "power_feature_mat");
assert(any(contains(dpsdResult.validation.errors, "Lost phase")));

%% Legacy WiFo HDF5 fails preflight, then passes after explicit conversion
legacyFile = fullfile(temporaryRoot, "3D_CSI_01.h5");
legacyShape = [2, 3, 4, 5];
legacyReal = single(randn(legacyShape));
legacyImag = single(randn(legacyShape));
h5create(legacyFile, "/csi/real", legacyShape, "Datatype", "single");
h5write(legacyFile, "/csi/real", legacyReal);
h5create(legacyFile, "/csi/imag", legacyShape, "Datatype", "single");
h5write(legacyFile, "/csi/imag", legacyImag);
h5create(legacyFile, "/delay", [1, legacyShape(3)]);
h5write(legacyFile, "/delay", linspace(0, 200e-9, legacyShape(3)));
h5create(legacyFile, "/doppler", [1, legacyShape(3)]);
h5write(legacyFile, "/doppler", linspace(-20, 20, legacyShape(3)));
h5writeatt(legacyFile, "/", "center_freq", 3.5e9);
h5writeatt(legacyFile, "/", "bandwidth", 20e6);
h5writeatt(legacyFile, "/", "n_subcarriers", 1024);
h5writeatt(legacyFile, "/", "dataset_id", "CSI_TEST");
h5writeatt(legacyFile, "/", "scenario", "test_scenario");

legacyResult = import_channel_dataset(legacyFile);
assert(legacyResult.status == "FAIL");
assert(legacyResult.file.category == "legacy_wifo_hdf5");

convertedWiFoFile = fullfile(temporaryRoot, "3D_CSI_01_v3_cir.h5");
wifoConversion = convert_legacy_wifo_hdf5_to_v3( ...
    legacyFile, convertedWiFoFile, struct( ...
        "sequence_axis", "sample", ...
        "sample_semantics", "other_ordered"));
assert(isfile(convertedWiFoFile));
assert(wifoConversion.dataset.dimensions.Tx == legacyShape(1));
assert(wifoConversion.dataset.dimensions.Rx == legacyShape(2));
assert(wifoConversion.dataset.dimensions.Npath == legacyShape(3));
assert(wifoConversion.dataset.dimensions.N_sample == legacyShape(4));
assert(any(contains(wifoConversion.conversion_warnings, ...
    "n_subcarriers")));

convertedWiFo = import_channel_dataset(convertedWiFoFile, struct( ...
    "task_mode", "extrapolation", ...
    "task_axis", "sample", ...
    "task_preset", "80_20"));
assert(convertedWiFo.status == "PASS");
assert(convertedWiFo.capabilities.delay_sample_heatmap);

%% Ordered SAGE MAT files are packed into one read-only v3 CIR HDF5
sageFolder = fullfile(temporaryRoot, "sage_road");
mkdir(sageFolder);
for sampleIndex = [1, 2, 10, 3, 4]
    sage = struct();
    sage.cir = complex( ...
        ones(1, 2, 6) * sampleIndex, ...
        ones(1, 2, 6) * (sampleIndex / 10));
    sage.alpha = complex(ones(2, 1), ones(2, 1));
    sage.delay = [10; 20];
    sage.doa = zeros(2, 2);
    save(fullfile(sageFolder, ...
        sprintf("SAGE_snap%d.mat", sampleIndex)), "sage");
end

missingDelayFile = fullfile(temporaryRoot, "missing_delay.h5");
assertError(@() convert_sage_folder_to_v3_hdf5( ...
    sageFolder, missingDelayFile), ...
    "convert_sage_folder_to_v3_hdf5:MissingDelayDefinition");

convertedSageFile = fullfile(temporaryRoot, "road_v3_cir.h5");
sageConversion = convert_sage_folder_to_v3_hdf5( ...
    sageFolder, convertedSageFile, struct( ...
        "bandwidth_hz", 200e6, ...
        "sample_semantics", "other_ordered", ...
        "source_id", "step4_test_road"));
assert(isfile(convertedSageFile));
assert(isequal(size5(sageConversion.dataset.cir.coefficient), ...
    [1, 2, 6, 1, 5]));
assert(abs(sageConversion.dataset.cir.delay_s(1, 1, 2) - 5e-9) < eps);
orderedValues = squeeze(real( ...
    sageConversion.dataset.cir.coefficient(1, 1, 1, 1, :))).';
assert(isequal(orderedValues, [1, 2, 3, 4, 10]));

convertedSage = import_channel_dataset(convertedSageFile, struct( ...
    "task_mode", "interpolation", ...
    "task_axis", "sample", ...
    "task_preset", "80_20"));
assert(convertedSage.status == "PASS");
assert(convertedSage.dataset.metadata.source == ...
    "measured_sage:step4_test_road");
assert(convertedSage.capabilities.pdp);
assert(convertedSage.capabilities.delay_sample_heatmap);

invalidTimeTask = import_channel_dataset(convertedSageFile, struct( ...
    "task_mode", "extrapolation", ...
    "task_axis", "time", ...
    "task_preset", "80_20"));
assert(invalidTimeTask.status == "FAIL");
assert(any(contains(invalidTimeTask.validation.errors, ...
    "at least two values")));

clear cleanupHandle
fprintf("PASS: Step 4 input pipeline, task presets, and legacy adapters.\n");

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end

function assertError(functionHandle, expectedIdentifier)
didThrow = false;
try
    functionHandle();
catch exception
    didThrow = true;
    assert(string(exception.identifier) == string(expectedIdentifier), ...
        "Expected %s but received %s.", ...
        expectedIdentifier, exception.identifier);
end
assert(didThrow, "Expected error %s was not raised.", expectedIdentifier);
end
