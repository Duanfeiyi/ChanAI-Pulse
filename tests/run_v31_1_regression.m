% Run the v3.1-1 bundled Full 6GPCM regression.
clearvars;
clc;
repoRoot = fileparts(fileparts(mfilename("fullpath")));
cd(repoRoot);
run("tests/test_v31_1_bundled_full_6gpcm.m");
fprintf("PASS: v3.1-1 regression suite.\n");
