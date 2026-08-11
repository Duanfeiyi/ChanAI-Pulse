% v3.1-3 cumulative regression.

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));
run(fullfile(repoRoot, "tests", "run_v31_2_regression.m"));
run(fullfile(repoRoot, "tests", "test_v31_3_parameter_evidence.m"));
fprintf("PASS: v3.1-3 regression suite.\n");
