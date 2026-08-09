% Run focused Step 14 regression checks.
clearvars;
clc;
repoRoot = fileparts(fileparts(mfilename("fullpath")));
cd(repoRoot);
run("tests/test_step14_mat_conversion.m");
run("tests/test_step12_formal_ui.m");
run("tests/run_step13_regression.m");
fprintf("PASS: Step 14 focused regression suite.\n");
