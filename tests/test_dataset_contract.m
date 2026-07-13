% ChanAI Pulse dataset-contract smoke test.
% Uses only public synthetic demo data and does not modify any dataset.

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));
addpath(genpath(fullfile(repoRoot, "tools")));

demoRoot = fullfile(repoRoot, "demo_data", "chanais_demo");
rawFile = fullfile(demoRoot, "data", "raw", "Pol_0_SAGE_F7_MovingR1_0-1s_synthetic.mat");

validation = validate_chanais_dataset(demoRoot);
assert(validation.is_valid, "Synthetic ChanAIs demo failed dataset validation.");
assert(validation.status == "PASS", "Complete synthetic demo must return PASS.");

dataset = load_chanais_dataset(demoRoot);
assert(string(dataset.metadata.visibility) == "public_demo", "Demo visibility must remain public_demo.");
assert(dataset.status == "PASS", "Dataset loader must preserve validation status.");

sageData = read_sage_mat(rawFile);
assert(sageData.record_count >= 1, "Synthetic SAGE demo must contain at least one record.");
assert(sageData.summary(1).has_cir, "Synthetic SAGE record must include CIR.");
assert(numel(sageData.summary(1).cir_canonical_size) == 3, "Canonical CIR must be three-dimensional.");

sourceCIR = reshape(complex(zeros(16, 683)), 1, 16, 683);
[canonicalCIR, info] = canonicalize_cir(sourceCIR);
assert(size(canonicalCIR, 1) == 16 && size(canonicalCIR, 2) == 683 && ...
    size(canonicalCIR, 3) == 1, "Unexpected canonical CIR size.");
assert(isequal(info.canonical_size, [16, 683, 1]), "Unexpected canonical CIR metadata.");
assert(info.is_complex, "Complex CIR flag was not preserved.");

metadataTemplate = build_metadata_template();
assert(isfield(metadataTemplate, "dataset_id") && isfield(metadataTemplate, "units"), ...
    "Metadata template must expose core and recommended fields.");

temporaryRoot = string(tempname);
cleanup = onCleanup(@() removeTemporaryDataset(temporaryRoot)); %#ok<NASGU>
mkdir(fullfile(temporaryRoot, "data", "raw"));
minimalMetadata = struct( ...
    "dataset_id", "temporary_minimal_demo", ...
    "scenario", "synthetic_test", ...
    "data_source", "synthetic_demo", ...
    "data_type", "CIR", ...
    "visibility", "public_demo");
writeJson(fullfile(temporaryRoot, "metadata.json"), minimalMetadata);
sampleCIR = complex(ones(4, 8)); %#ok<NASGU>
save(fullfile(temporaryRoot, "data", "raw", "sample_cir.mat"), "sampleCIR");

warningValidation = validate_chanais_dataset(temporaryRoot);
assert(warningValidation.is_valid && warningValidation.status == "WARNING", ...
    "Minimal usable dataset must return WARNING instead of FAIL.");
assert(any(warningValidation.missing_recommended_fields == "frequency_band"), ...
    "Missing recommended metadata must be reported.");

failedMetadata = rmfield(minimalMetadata, "data_type");
writeJson(fullfile(temporaryRoot, "metadata.json"), failedMetadata);
failedValidation = validate_chanais_dataset(temporaryRoot);
assert(~failedValidation.is_valid && failedValidation.status == "FAIL", ...
    "Missing core metadata must return FAIL.");

converted = convert_sage_to_chanais(rawFile, "", ...
    build_metadata_template("dataset_id", "temporary_conversion", ...
    "scenario", "synthetic_demo", "data_source", "synthetic_demo", ...
    "visibility", "internal_only"));
assert(numel(converted.records) >= 1 && converted.converter.conversion_status == "PASS", ...
    "Complete synthetic SAGE input must convert with PASS status.");

completeRecord = struct( ...
    "alpha", 1, "doa", 0, "delay", 1e-9, ...
    "cir", complex(ones(1, 4)), "cir_e", complex(ones(1, 4)), ...
    "likelihood", 0.9);
incompleteRecord = rmfield(completeRecord, "doa");
sage = {completeRecord, incompleteRecord}; %#ok<NASGU>
mixedSageFile = fullfile(temporaryRoot, "mixed_sage.mat");
save(mixedSageFile, "sage");
mixedConverted = convert_sage_to_chanais(mixedSageFile, "", ...
    build_metadata_template("dataset_id", "mixed_conversion", ...
    "scenario", "synthetic_demo", "data_source", "synthetic_demo", ...
    "visibility", "internal_only"));
assert(numel(mixedConverted.records) == 2, ...
    "Mixed SAGE records must convert without a struct-field mismatch.");
assert(mixedConverted.converter.conversion_status == "WARNING", ...
    "Mixed complete and incomplete SAGE records must report WARNING.");
assert(mixedConverted.records(1).warning == "" && ...
    contains(mixedConverted.records(2).warning, "doa"), ...
    "Only the incomplete SAGE record should carry the missing-field warning.");

fprintf("PASS: ChanAIs dataset contracts and synthetic SAGE demo are valid.\n");

function writeJson(filePath, value)
fid = fopen(filePath, "w");
assert(fid ~= -1, "Unable to write temporary metadata.json.");
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, "%s", jsonencode(value));
end

function removeTemporaryDataset(folderPath)
if isfolder(folderPath)
    rmdir(folderPath, "s");
end
end
