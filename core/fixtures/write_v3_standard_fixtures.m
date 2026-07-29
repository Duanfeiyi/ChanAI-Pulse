function manifest = write_v3_standard_fixtures(outputDirectory)
%WRITE_V3_STANDARD_FIXTURES Write all four deterministic CIR/CTF pairs.
%   MANIFEST = WRITE_V3_STANDARD_FIXTURES(OUTPUTDIRECTORY) writes eight
%   portable HDF5 files plus manifest.json. Existing files are never
%   overwritten.

arguments
    outputDirectory (1, 1) string
end

if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
scenarios = load_v3_standard_scenarios();
entries = repmat(struct(), numel(scenarios), 1);

for index = 1:numel(scenarios)
    scenario = scenarios(index);
    pair = generate_v3_standard_pair(scenario);
    capabilities = infer_standard_pair_capabilities(pair);
    cirName = string(scenario.id) + "_cir.h5";
    ctfName = string(scenario.id) + "_ctf.h5";
    cirPath = fullfile(outputDirectory, cirName);
    ctfPath = fullfile(outputDirectory, ctfName);
    write_channel_dataset_hdf5(cirPath, pair.cir);
    write_channel_dataset_hdf5(ctfPath, pair.ctf);

    entries(index).id = string(scenario.id);
    entries(index).display_name_zh = string(scenario.display_name_zh);
    entries(index).seed = double(scenario.seed);
    entries(index).cir_file = cirName;
    entries(index).ctf_file = ctfName;
    entries(index).cir_shape = [double(scenario.Tx), ...
        double(scenario.Rx), double(scenario.Npath), ...
        double(scenario.Nt), double(scenario.N_sample)];
    entries(index).ctf_shape = [double(scenario.Tx), ...
        double(scenario.Rx), double(scenario.Nf), ...
        double(scenario.Nt), double(scenario.N_sample)];
    entries(index).classification = capabilities.classification;
    entries(index).standard_plot_count = ...
        capabilities.standard_plot_count;
    entries(index).standard_plots = capabilities.standard_plots;
    entries(index).delay_sample_heatmap = ...
        capabilities.delay_sample_heatmap;
end

manifest = struct( ...
    "schema_version", "v3.0-standard-fixtures.1", ...
    "data_contract_version", "v3.0-data-contract.1", ...
    "generated_utc", "2026-07-29T00:00:00Z", ...
    "deterministic", true, ...
    "sample_semantics", "ordered_route", ...
    "heatmap_is_additional", true, ...
    "entries", entries);
manifestPath = fullfile(outputDirectory, "manifest.json");
if isfile(manifestPath)
    error("write_v3_standard_fixtures:FileExists", ...
        "Refusing to overwrite existing file: %s", manifestPath);
end
writelines(string(jsonencode(manifest, "PrettyPrint", true)), ...
    manifestPath);
end
