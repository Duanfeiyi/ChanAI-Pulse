% ChanAI Pulse dataset-contract smoke test.
% Uses only public synthetic demo data and does not modify any dataset.

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

demoRoot = fullfile(repoRoot, "demo_data", "chanais_demo");
rawFile = fullfile(demoRoot, "data", "raw", "Pol_0_SAGE_F7_MovingR1_0-1s_synthetic.mat");

validation = validate_chanais_dataset(demoRoot);
assert(validation.is_valid, "Synthetic ChanAIs demo failed dataset validation.");

dataset = load_chanais_dataset(demoRoot);
assert(string(dataset.metadata.visibility) == "public_demo", "Demo visibility must remain public_demo.");

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

fprintf("PASS: ChanAIs dataset contracts and synthetic SAGE demo are valid.\n");
