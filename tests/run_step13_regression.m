% Run focused Step 13 regression checks.
clearvars;
clc;
repoRoot = fileparts(fileparts(mfilename("fullpath")));
cd(repoRoot);
run("tests/test_step13_benchmark.m");
run("tests/test_step13_dimension_capabilities.m");
run("tests/test_step12_formal_ui.m");
fprintf("PASS: Step 13 focused regression suite.\n");
