% Run the frozen ChanAI Pulse v3 Step 1-9 regression suite.
% Explicit calls are intentional because historical script tests may clear
% caller variables.

run("test_v3_data_contract.m");
run("test_v3_standard_fixtures.m");
run("test_full_6gpcm_probe.m");
run("test_step4_input_pipeline.m");
run("test_step5_characteristics_engine.m");
run("test_generation_6gpcm_lite.m");
run("test_step6_generator_adapter.m");
run("test_step6_full_6gpcm_external.m");
run("test_step7_grid_search.m");
run("test_step7_lite_grid_search.m");
run("test_step7_full_6gpcm_external.m");
run("test_step8_optimization.m");
run("test_step8_lite_optimization.m");
run("test_step8_full_6gpcm_external.m");
run("test_step9_predictor_data.m");
fprintf("PASS: Step 1-9 complete MATLAB regression.\n");
