function paths = prepare_step14_review_data(outputRoot)
%PREPARE_STEP14_REVIEW_DATA Create deterministic public Step 14 review data.
%   The generated files are synthetic and exist only for UI/manual review.

arguments
    outputRoot (1, 1) string = ""
end
repoRoot = string(fileparts(fileparts(mfilename("fullpath"))));
if outputRoot == ""
    outputRoot = fullfile(repoRoot, "review_data", "step14");
end
if isfolder(outputRoot)
    outputRoot = outputRoot + "_" + ...
        string(datetime("now", "Format", "yyyyMMdd_HHmmss_SSS"));
end
mkdir(outputRoot);
rng(1414, "twister");

% Auto-recognizable five-dimensional CTF.
Tx = 2; Rx = 2; Nf = 16; Nt = 6; N_sample = 12;
H = complex(randn(Tx, Rx, Nf, Nt, N_sample), ...
    randn(Tx, Rx, Nf, Nt, N_sample)); %#ok<NASGU>
frequency_hz = (28e9 + (0:(Nf - 1)) * 120e3).'; %#ok<NASGU>
time_s = (0:(Nt - 1)).' * 1e-3; %#ok<NASGU>
sample_index = (1:N_sample).'; %#ok<NASGU>
sample_position_m = [(0:(N_sample - 1)).' * 0.5, ...
    zeros(N_sample, 1)]; %#ok<NASGU>
autoCtfMat = fullfile(outputRoot, "01_auto_wideband_dynamic_mimo_ctf.mat");
save(autoCtfMat, "H", "frequency_hz", "time_s", ...
    "sample_index", "sample_position_m", "-v7.3");

% Ambiguous source order that a user must confirm explicitly.
Tx = 2; Rx = 2; Npath = 6; N_sample = 12;
canonical = complex(randn(Tx, Rx, Npath, 1, N_sample), ...
    randn(Tx, Rx, Npath, 1, N_sample));
cir_payload = permute(canonical, [5, 3, 2, 1, 4]); %#ok<NASGU>
delay_ns = (0:(Npath - 1)).' * 8; %#ok<NASGU>
manualCirMat = fullfile(outputRoot, "02_manual_permuted_cir.mat");
save(manualCirMat, "cir_payload", "delay_ns");

% An intentionally unsupported power-only file.
pdp_power = abs(randn(24, N_sample)).^2; %#ok<NASGU>
powerOnlyMat = fullfile(outputRoot, "03_power_only_rejected.mat");
save(powerOnlyMat, "pdp_power");

% Known SAGE folder adapter.
sageFolder = fullfile(outputRoot, "04_known_sage_folder");
mkdir(sageFolder);
for index = 1:4
    sage = {struct("cir", complex(randn(2, 2, 6), randn(2, 2, 6)))}; %#ok<NASGU>
    save(fullfile(sageFolder, sprintf("route_%02d.mat", index)), "sage");
end

paths = struct( ...
    "output_root", outputRoot, ...
    "auto_ctf_mat", autoCtfMat, ...
    "manual_cir_mat", manualCirMat, ...
    "power_only_mat", powerOnlyMat, ...
    "sage_folder", sageFolder, ...
    "direct_standard_h5", fullfile(repoRoot, "demo_data", ...
        "v3_standard_fixtures", "wideband_dynamic_mimo_cir.h5"), ...
    "manual_domain", "cir", ...
    "manual_complex_variable", "cir_payload", ...
    "manual_dimension_order", "N_sample,Npath,Rx,Tx", ...
    "manual_delay_variable", "delay_ns", ...
    "manual_delay_unit", "ns");

fprintf("Step 14 review data prepared in:\n%s\n", outputRoot);
fprintf("Auto MAT: %s\nManual MAT: %s\nPower-only MAT: %s\n", ...
    autoCtfMat, manualCirMat, powerOnlyMat);
end
