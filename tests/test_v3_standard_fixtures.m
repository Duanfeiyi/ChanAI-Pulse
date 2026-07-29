% Step 2 deterministic standard-fixture tests.

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

scenarios = load_v3_standard_scenarios();
assert(numel(scenarios) == 4);

expectedIds = ["narrowband_static_siso", "wideband_static_siso", ...
    "wideband_static_mimo", "wideband_dynamic_mimo"];
expectedCtfShapes = [ ...
    1, 1, 1, 1, 32; ...
    1, 1, 64, 1, 32; ...
    2, 4, 64, 1, 32; ...
    2, 4, 64, 16, 32];
expectedCirShapes = [ ...
    1, 1, 1, 1, 32; ...
    1, 1, 4, 1, 32; ...
    2, 4, 6, 1, 32; ...
    2, 4, 6, 16, 32];
expectedPlotCounts = [1, 3, 6, 9];
expectedHeatmap = [false, true, true, true];

for index = 1:numel(scenarios)
    scenario = scenarios(index);
    assert(string(scenario.id) == expectedIds(index));

    pairA = generate_v3_standard_pair(scenario);
    pairB = generate_v3_standard_pair(scenario);
    assert(isequal(pairA.cir.cir.coefficient, ...
        pairB.cir.cir.coefficient), ...
        "Repeated CIR generation must be bit-for-bit identical.");
    assert(isequal(pairA.ctf.ctf.H, pairB.ctf.ctf.H), ...
        "Repeated CTF generation must be bit-for-bit identical.");

    cirReport = validate_channel_dataset(pairA.cir);
    ctfReport = validate_channel_dataset(pairA.ctf);
    assert(cirReport.status == "PASS", ...
        "CIR validation failed for %s: %s", scenario.id, ...
        strjoin(cirReport.errors, " | "));
    assert(ctfReport.status == "PASS", ...
        "CTF validation failed for %s: %s", scenario.id, ...
        strjoin(ctfReport.errors, " | "));
    assert(isequal(size5(pairA.cir.cir.coefficient), ...
        expectedCirShapes(index, :)));
    assert(isequal(size5(pairA.ctf.ctf.H), ...
        expectedCtfShapes(index, :)));
    assert(string(pairA.cir.metadata.sample_semantics) == ...
        "ordered_route");
    assert(isequal(pairA.cir.axes.sample_position_m, ...
        pairA.ctf.axes.sample_position_m));

    centerIndex = (double(scenario.Nf) + 1) / 2;
    if mod(double(scenario.Nf), 2) == 0
        centerIndex = double(scenario.Nf) / 2;
    end
    frequencyOffset = pairA.ctf.axes.frequency_hz(centerIndex) - ...
        double(scenario.center_frequency_hz);
    direct = sum(pairA.cir.cir.coefficient .* exp( ...
        -1i * 2 * pi * single(frequencyOffset) .* ...
        pairA.cir.cir.delay_s), 3);
    fromCtf = pairA.ctf.ctf.H(:, :, centerIndex, :, :);
    assert(max(abs(direct(:) - fromCtf(:))) < 2e-5, ...
        "CIR-to-CTF consistency failed for %s.", scenario.id);

    capabilities = infer_standard_pair_capabilities(pairA);
    assert(capabilities.classification == expectedIds(index));
    assert(capabilities.standard_plot_count == ...
        expectedPlotCounts(index));
    assert(capabilities.delay_sample_heatmap == expectedHeatmap(index), ...
        "Heatmap capability does not match the scenario bandwidth.");
    assert(capabilities.heatmap_is_additional);
end

% Single-tap path data must remain narrowband.
narrowPair = generate_v3_standard_pair(scenarios(1));
narrowCirCapabilities = infer_channel_capabilities(narrowPair.cir);
assert(narrowCirCapabilities.classification == ...
    "narrowband_static_siso");
assert(~narrowCirCapabilities.pdp);

% HDF5 round trip for all eight files.
temporaryDirectory = string(tempname);
mkdir(temporaryDirectory);
cleanup = onCleanup(@() rmdir(temporaryDirectory, "s"));
manifest = write_v3_standard_fixtures(temporaryDirectory);
assert(numel(manifest.entries) == 4);
for index = 1:numel(manifest.entries)
    cir = read_channel_dataset_hdf5(fullfile(temporaryDirectory, ...
        manifest.entries(index).cir_file));
    ctf = read_channel_dataset_hdf5(fullfile(temporaryDirectory, ...
        manifest.entries(index).ctf_file));
    assert(isequal(size5(cir.cir.coefficient), ...
        manifest.entries(index).cir_shape));
    assert(isequal(size5(ctf.ctf.H), ...
        manifest.entries(index).ctf_shape));
end
clear cleanup

fprintf("PASS: four deterministic v3 standard CIR/CTF fixture pairs.\n");

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
