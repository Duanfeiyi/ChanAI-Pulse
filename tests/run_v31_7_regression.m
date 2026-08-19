% Focused v3.1-7 product-integration regression.
repoRoot = fileparts(fileparts(mfilename("fullpath")));
run(fullfile(repoRoot, "tests", "test_v31_7_product_integration.m"));
run(fullfile(repoRoot, "tests", "test_step12_formal_ui.m"));
run(fullfile(repoRoot, "tests", "test_step11_prediction_generation.m"));
