% Step 12 four-class formal UI/service end-to-end acceptance.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, "core")));
fixtureRoot = fullfile(repoRoot, "demo_data", "v3_standard_fixtures");
engineRoot = fullfile(fileparts(repoRoot), ...
    "ChanAI-Pulse-v3-step11abc-assets", "full6gpcm", "source");
hasFull = isfile(fullfile(engineRoot, "@channel_model", "channel_model.m"));

scenarios = struct( ...
    "file", { ...
        "narrowband_static_siso_cir.h5", ...
        "wideband_static_siso_cir.h5", ...
        "wideband_static_mimo_cir.h5", ...
        "wideband_dynamic_mimo_cir.h5"}, ...
    "backend", {"lite_6gpcm", "lite_6gpcm", ...
        "full_6gpcm", "full_6gpcm"}, ...
    "standard_plots", {1, 3, 6, 9});

exportRoot = string(tempname);
mkdir(exportRoot);
cleanupExport = onCleanup(@() rmdir(exportRoot, "s"));
app = ChannelSimulator(Visible="off");
cleanupApp = onCleanup(@() delete(app));

for index = 1:numel(scenarios)
    scenario = scenarios(index);
    scenarioFile = string(scenario.file);
    scenarioBackend = string(scenario.backend);
    if startsWith(scenarioBackend, "full") && ~hasFull
        fprintf("SKIP: %s requires the external configurable Full engine.\n", ...
            scenarioFile);
        continue;
    end
    app.loadChannelFile(fullfile(fixtureRoot, scenarioFile));
    before = app.getReviewState();
    assert(before.backend_selection.success);
    assert(before.backend_selection.selected_backend == scenarioBackend);
    if scenarioBackend == "full_6gpcm"
        assert(before.backend_selection.selected_adapter_variant == "public_api");
    end

    app.runCurrentTask();
    after = app.getReviewState();
    assert(after.calibration_success, scenarioFile + " calibration failed.");
    assert(after.prediction_success, scenarioFile + " prediction failed.");
    assert(after.prediction_dimensions.Tx == after.input_dimensions.Tx);
    assert(after.prediction_dimensions.Rx == after.input_dimensions.Rx);
    assert(after.prediction_dimensions.Nt == after.input_dimensions.Nt);
    assert(after.prediction_standard_plot_count == scenario.standard_plots, ...
        scenarioFile + " did not preserve its 1/3/6/9 plot class.");

    output = fullfile(exportRoot, "case_" + index);
    files = app.exportCurrentPrediction(output);
    assert(isfile(files.cir_hdf5));
    assert(isfile(files.ctf_hdf5));
    assert(isfile(files.result_json));
    exportedSummary = jsondecode(fileread(files.result_json));
    assert(isfield(exportedSummary, "benchmark_context"));
    assert(~exportedSummary.benchmark_context. ...
        target_ground_truth_read_by_prediction);
    assert(strcmpi(string(exportedSummary.benchmark_context. ...
        original_file_sha256), compute_benchmark_file_sha256( ...
        fullfile(fixtureRoot, scenarioFile))));
    roundTrip = read_channel_dataset_hdf5(files.cir_hdf5);
    assert(roundTrip.dimensions.Tx == after.input_dimensions.Tx);
    assert(roundTrip.dimensions.Rx == after.input_dimensions.Rx);
    assert(roundTrip.dimensions.Nt == after.input_dimensions.Nt);
end

fprintf("PASS: Step 12 four-class input-to-CIR-to-1/3/6/9 acceptance.\n");
