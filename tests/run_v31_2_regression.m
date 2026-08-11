% Run the v3.1-2 data and Experiment Manager regression.
clearvars;
clc;
repoRoot = fileparts(fileparts(mfilename("fullpath")));
cd(repoRoot);
run("tests/test_v31_1_bundled_full_6gpcm.m");
run("tests/test_v31_2_data_experiments.m");
fprintf("PASS: v3.1-2 regression suite.\n");
