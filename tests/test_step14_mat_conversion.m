% Step 14 MAT conversion contract and formal-wizard smoke tests.
clearvars;
clc;
repoRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, "app")));
addpath(genpath(fullfile(repoRoot, "core")));

temporaryRoot = string(tempname);
mkdir(temporaryRoot);
cleanup = onCleanup(@() removeTemporaryRoot(temporaryRoot)); %#ok<NASGU>

%% High-confidence five-dimensional complex CTF.
rng(1401, "twister");
Tx = 2; Rx = 3; Nf = 8; Nt = 4; Nsample = 6;
H = complex(randn(Tx, Rx, Nf, Nt, Nsample), ...
    randn(Tx, Rx, Nf, Nt, Nsample)); %#ok<NASGU>
frequency_hz = (28e9 + (0:(Nf - 1)) * 120e3).'; %#ok<NASGU>
time_s = (0:(Nt - 1)).' * 1e-3; %#ok<NASGU>
sample_index = (101:(100 + Nsample)).'; %#ok<NASGU>
sample_position_m = [(0:(Nsample - 1)).', zeros(Nsample, 1)]; %#ok<NASGU>
autoMat = fullfile(temporaryRoot, "auto_ctf.mat");
save(autoMat, "H", "frequency_hz", "time_s", ...
    "sample_index", "sample_position_m", "-v7.3");

inspection = inspect_mat_channel_source(autoMat);
assert(inspection.status == "PASS" && inspection.is_convertible, ...
    "Canonical complex CTF should be auto-convertible.");
assert(inspection.mat_version == "v7.3", "MAT v7.3 detection failed.");
assert(isequal(inspection.suggested_mapping.source_dimension_order, ...
    ["Tx", "Rx", "Nf", "Nt", "N_sample"]), ...
    "Canonical dimension suggestion is incorrect.");
sourceHash = compute_benchmark_file_sha256(autoMat);
autoOutput = fullfile(temporaryRoot, "auto_ctf_v3.h5");
autoResult = convert_channel_source_to_v3(autoMat, autoOutput, ...
    inspection.suggested_mapping);
assert(autoResult.validation.is_valid, "Converted CTF did not validate.");
assert(compute_benchmark_file_sha256(autoMat) == sourceHash, ...
    "Source MAT changed during conversion.");
roundTrip = read_channel_dataset_hdf5(autoOutput);
assert(roundTrip.domain == "ctf", "Converted domain is not CTF.");
assert(isequal(roundTrip.dimensions, struct("Tx", Tx, "Rx", Rx, ...
    "Nf", Nf, "Nt", Nt, "Npath", 0, "N_sample", Nsample)), ...
    "Converted CTF dimensions are incorrect.");
assert(max(abs(roundTrip.ctf.H(:) - H(:))) < 1e-11, ...
    "Complex CTF values changed during conversion.");
assert(isfile(autoResult.manifest_file), "Conversion manifest was not created.");

chunkOutput = fullfile(temporaryRoot, "auto_ctf_chunked_v3.h5");
chunkResult = convert_channel_source_to_v3(autoMat, chunkOutput, ...
    inspection.suggested_mapping, ChunkReadThresholdBytes=1, SampleChunkSize=2);
chunkRoundTrip = read_channel_dataset_hdf5(chunkOutput);
assert(chunkResult.read_mode == "sample_chunked_v73" && ...
    max(abs(chunkRoundTrip.ctf.H(:) - H(:))) < 1e-11, ...
    "Forced v7.3 sample-chunk reading changed the CTF.");

didRefuseOverwrite = false;
try
    convert_channel_source_to_v3(autoMat, autoOutput, ...
        inspection.suggested_mapping);
catch exception
    didRefuseOverwrite = contains(string(exception.identifier), "OutputExists");
end
assert(didRefuseOverwrite, "Converter must refuse to overwrite an existing H5.");

%% Ambiguous, permuted CIR requires explicit mapping confirmation.
Tx = 2; Rx = 2; Npath = 5; Nsample = 7;
canonicalCir = complex(randn(Tx, Rx, Npath, 1, Nsample), ...
    randn(Tx, Rx, Npath, 1, Nsample));
cir_payload = permute(canonicalCir, [5, 3, 2, 1, 4]); %#ok<NASGU>
delay_ns = (0:(Npath - 1)).' * 10; %#ok<NASGU>
manualMat = fullfile(temporaryRoot, "manual_permuted_cir.mat");
save(manualMat, "cir_payload", "delay_ns");
manualInspection = inspect_mat_channel_source(manualMat);
assert(manualInspection.status == "NEEDS_MAPPING", ...
    "Ambiguous four-dimensional CIR must require mapping.");
mapping = manualInspection.suggested_mapping;
mapping.domain = "cir";
mapping.complex_variable = "cir_payload";
mapping.source_dimension_order = ["N_sample", "Npath", "Rx", "Tx"];
mapping.delay_variable = "delay_ns";
mapping.delay_unit = "ns";
mapping.advanced_mapping_confirmed = true;
manualOutput = fullfile(temporaryRoot, "manual_cir_v3.h5");
manualResult = convert_channel_source_to_v3(manualMat, manualOutput, mapping);
manualRoundTrip = read_channel_dataset_hdf5(manualOutput);
assert(manualResult.validation.is_valid && manualRoundTrip.domain == "cir", ...
    "Explicit CIR conversion failed validation.");
assert(max(abs(manualRoundTrip.cir.coefficient(:) - canonicalCir(:))) < 1e-11, ...
    "Explicit dimension permutation did not preserve CIR values.");
assert(max(abs(squeeze(manualRoundTrip.cir.delay_s) - delay_ns * 1e-9)) < 1e-18, ...
    "Delay-unit conversion is incorrect.");
assert(isequal(manualRoundTrip.axes.sample_index, (1:Nsample).'), ...
    "Missing sample IDs should receive the documented 1:N fallback.");

%% Explicit real/imaginary pair.
Npath = 4; Nsample = 5;
coefficient_real = randn(Npath, Nsample); %#ok<NASGU>
coefficient_imag = randn(Npath, Nsample); %#ok<NASGU>
delay_s = (0:(Npath - 1)).' * 5e-9; %#ok<NASGU>
pairMat = fullfile(temporaryRoot, "pair_cir.mat");
save(pairMat, "coefficient_real", "coefficient_imag", "delay_s");
pairInspection = inspect_mat_channel_source(pairMat);
assert(pairInspection.is_convertible, "Real/imaginary pair was not recognized.");
pairOutput = fullfile(temporaryRoot, "pair_cir_v3.h5");
pairResult = convert_channel_source_to_v3(pairMat, pairOutput, ...
    pairInspection.suggested_mapping);
pairRoundTrip = read_channel_dataset_hdf5(pairOutput);
expectedPair = reshape(complex(coefficient_real, coefficient_imag), ...
    [1, 1, Npath, 1, Nsample]);
assert(pairResult.validation.is_valid && ...
    max(abs(pairRoundTrip.cir.coefficient(:) - expectedPair(:))) < 1e-11, ...
    "Real/imaginary pair conversion changed complex values.");

%% Power-only data remains inspectable but cannot enter CIR prediction.
pdp_power = abs(randn(16, 10)).^2; %#ok<NASGU>
powerMat = fullfile(temporaryRoot, "power_only.mat");
save(powerMat, "pdp_power");
powerInspection = inspect_mat_channel_source(powerMat);
assert(powerInspection.status == "FAIL" && powerInspection.is_power_only && ...
    ~powerInspection.is_convertible, ...
    "Power-only MAT must be rejected for complete complex-channel conversion.");

unknown_tensor = complex(randn(2, 2, 3, 4, 5), randn(2, 2, 3, 4, 5)); %#ok<NASGU>
unknownMat = fullfile(temporaryRoot, "unknown_complex_tensor.mat");
save(unknownMat, "unknown_tensor");
unknownInspection = inspect_mat_channel_source(unknownMat);
assert(unknownInspection.status == "NEEDS_MAPPING" && ...
    unknownInspection.requires_mapping, ...
    "An unfamiliar five-dimensional complex variable must not be auto-approved.");

%% Known SAGE-folder and legacy WiFo adapters remain available through one dispatcher.
sageFolder = fullfile(temporaryRoot, "sage_folder");
mkdir(sageFolder);
for sageIndex = 1:3
    sage = {struct("cir", complex(randn(2, 2, 5), randn(2, 2, 5)))}; %#ok<NASGU>
    save(fullfile(sageFolder, sprintf("route_%02d.mat", sageIndex)), "sage");
end
sageInspection = inspect_mat_channel_source(sageFolder);
assert(sageInspection.source_kind == "sage_folder" && sageInspection.is_convertible, ...
    "Known SAGE folder was not detected by the Step 14 dispatcher.");
sageMapping = sageInspection.suggested_mapping;
sageMapping.delay_bin_spacing_s = 1e-9;
sageOutput = fullfile(temporaryRoot, "sage_v3.h5");
sageResult = convert_channel_source_to_v3(sageFolder, sageOutput, sageMapping);
assert(sageResult.validation.is_valid && sageResult.source_file_unchanged, ...
    "Known SAGE adapter did not produce a valid source-preserving v3 H5.");

legacyFile = fullfile(temporaryRoot, "legacy_wifo.h5");
legacyReal = randn(2, 2, 5, 4);
legacyImag = randn(2, 2, 5, 4);
legacyDelay = (0:4).' * 2e-9;
h5create(legacyFile, "/csi/real", size(legacyReal));
h5write(legacyFile, "/csi/real", legacyReal);
h5create(legacyFile, "/csi/imag", size(legacyImag));
h5write(legacyFile, "/csi/imag", legacyImag);
h5create(legacyFile, "/delay", size(legacyDelay));
h5write(legacyFile, "/delay", legacyDelay);
legacyInspection = inspect_mat_channel_source(legacyFile);
assert(legacyInspection.source_kind == "legacy_wifo_hdf5" && ...
    legacyInspection.is_convertible, ...
    "Known legacy WiFo HDF5 was not recognized.");
legacyMapping = legacyInspection.suggested_mapping;
legacyMapping.sequence_axis = "sample";
legacyOutput = fullfile(temporaryRoot, "legacy_wifo_v3.h5");
legacyResult = convert_channel_source_to_v3( ...
    legacyFile, legacyOutput, legacyMapping);
assert(legacyResult.validation.is_valid && legacyResult.source_file_unchanged, ...
    "Known legacy WiFo adapter did not produce a valid source-preserving v3 H5.");

%% Formal wizard follows the same core adapter and supports both languages.
wizardMat = fullfile(temporaryRoot, "wizard_ctf.mat");
save(wizardMat, "H", "frequency_hz", "time_s", ...
    "sample_index", "sample_position_m");
wizard = ChannelMatConversionWizard(RootPath=repoRoot, ...
    SourcePath=wizardMat, Language="en", Visible="off");
wizardCleanup = onCleanup(@() delete(wizard)); %#ok<NASGU>
wizardState = wizard.getReviewState();
assert(wizardState.language == "en" && ...
    wizardState.inspection.is_convertible, ...
    "Formal wizard did not inspect the source in English mode.");
wizardResult = wizard.convertCurrent();
assert(wizardResult.validation.is_valid && wizard.getReviewState().progress == 1, ...
    "Formal wizard did not complete and publish a valid H5.");

fprintf("PASS: Step 14 MAT inspection, explicit mapping, conversion, source preservation, and wizard contracts.\n");

%% Formal platform exposes the wizard and uses fill-style progress in both languages.
platform = ChannelSimulator(Visible="off");
platformCleanup = onCleanup(@() delete(platform)); %#ok<NASGU>
platformState = platform.getReviewState();
assert(platformState.progress_style == "horizontal_fill" && ...
    platformState.progress_fraction == 0, ...
    "Formal platform did not expose the new horizontal fill progress contract.");
assert(hasButton(platform.UIFigure, "MAT 数据转换向导…"), ...
    "Formal Module 1 is missing the MAT conversion-wizard entry.");
platform.setLanguage("en");
assert(hasButton(platform.UIFigure, "MAT conversion wizard…"), ...
    "MAT conversion-wizard entry was not localized to English.");

function removeTemporaryRoot(folderPath)
if isfolder(folderPath)
    rmdir(folderPath, "s");
end
end

function tf = hasButton(figureHandle, expectedText)
buttons = findall(figureHandle, "Type", "uibutton");
tf = any(string({buttons.Text}) == expectedText);
end
