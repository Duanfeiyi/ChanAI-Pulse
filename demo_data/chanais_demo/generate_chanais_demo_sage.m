%GENERATE_CHANAIS_DEMO_SAGE Generate a synthetic SAGE-like ChanAIs demo.
% This script creates small public demo files only. It does not use,
% inspect, copy, or transform private measured datasets.

scriptDir = fileparts(mfilename("fullpath"));
rawDir = fullfile(scriptDir, "data", "raw");
processedDir = fullfile(scriptDir, "data", "processed");
featuresDir = fullfile(scriptDir, "data", "features");
labelsDir = fullfile(scriptDir, "labels");
splitsDir = fullfile(scriptDir, "splits");

dirs = {rawDir, processedDir, featuresDir, labelsDir, splitsDir};
for i = 1:numel(dirs)
    if ~isfolder(dirs{i})
        mkdir(dirs{i});
    end
end

rng(110, "twister");

numAntennas = 16;
numSnapshots = 128;
numPaths = 8;

sage = cell(1, 1);
record = struct();
record.alpha = (randn(numPaths, numSnapshots) + 1i * randn(numPaths, numSnapshots)) .* exp(-linspace(0, 2, numPaths)');
record.doa = -60 + 120 * rand(numPaths, 2);
record.delay = sort(20e-9 + 180e-9 * rand(numPaths, 1));

arrayPhase = exp(1i * 2 * pi * (0:numAntennas - 1)' * sind(record.doa(:, 1)') / 2);
pathEvolution = record.alpha .* exp(1i * 2 * pi * (0:numSnapshots - 1) / numSnapshots);
record.cir = arrayPhase * pathEvolution;
record.cir_e = record.cir + 0.02 * (randn(size(record.cir)) + 1i * randn(size(record.cir)));
record.likelihood = 0.92 + 0.03 * rand();

sage{1} = record;

metadata = struct();
metadata.schema_version = "ChanAIs-Dataset-v1.0-draft";
metadata.dataset_version = "1.0.0-demo";
metadata.dataset_id = "chanais_synthetic_sage_demo";
metadata.scenario = "synthetic_demo_scenario";
metadata.environment = "synthetic_indoor_like";
metadata.frequency_band = "synthetic_mmwave_like";
metadata.carrier_frequency = 28e9;
metadata.bandwidth = 100e6;
metadata.antenna_configuration = "synthetic_16_element_virtual_array";
metadata.polarization = "Pol_0";
metadata.mobility = "synthetic_moving_receiver";
metadata.trajectory = "MovingR1";
metadata.los_condition = "synthetic_mixed";
metadata.sampling_interval = 1e-3;
metadata.time_window = "0-1s";
metadata.data_source = "synthetic_demo";
metadata.data_type = "SAGE";
metadata.license = "Apache-2.0 for code; synthetic demo data for public testing";
metadata.visibility = "public_demo";
metadata.notes = "Synthetic SAGE-like demo data. Not measured data and not benchmark evidence.";

rawFile = fullfile(rawDir, "Pol_0_SAGE_F7_MovingR1_0-1s_synthetic.mat");
save(rawFile, "sage", "metadata");

chanais = struct();
chanais.metadata = metadata;
chanais.records = struct();
chanais.records.record_id = "synthetic_sage_0001";
chanais.records.source_file = "data/raw/Pol_0_SAGE_F7_MovingR1_0-1s_synthetic.mat";
chanais.records.time_window = metadata.time_window;
chanais.records.polarization = metadata.polarization;
chanais.records.frequency_id = "F7";
chanais.records.trajectory = metadata.trajectory;
chanais.records.data_type = "SAGE";
chanais.records.path_parameters = struct("alpha", record.alpha, "doa", record.doa, "delay", record.delay);
chanais.records.cir = record.cir;
chanais.records.cir_estimated = record.cir_e;
chanais.records.quality = struct("likelihood", record.likelihood);
chanais.features = struct();
chanais.features.pdp = mean(abs(record.cir).^2, 1);
chanais.features.delay_axis = linspace(0, 1e-6, numSnapshots);
chanais.labels = struct("scenario", metadata.scenario, "visibility", metadata.visibility);

processedFile = fullfile(processedDir, "chanais_synthetic_sage_demo.mat");
save(processedFile, "chanais");

splitFile = fullfile(splitsDir, "demo_split.json");
splitText = [ ...
    "{", newline, ...
    "  ""train"": [""synthetic_sage_0001""],", newline, ...
    "  ""validation"": [],", newline, ...
    "  ""test"": []", newline, ...
    "}", newline];
fid = fopen(splitFile, "w");
fprintf(fid, "%s", splitText);
fclose(fid);

labelFile = fullfile(labelsDir, "labels.json");
labelText = [ ...
    "{", newline, ...
    "  ""synthetic_sage_0001"": {", newline, ...
    "    ""scenario"": ""synthetic_demo_scenario"",", newline, ...
    "    ""visibility"": ""public_demo""", newline, ...
    "  }", newline, ...
    "}", newline];
fid = fopen(labelFile, "w");
fprintf(fid, "%s", labelText);
fclose(fid);

fprintf("Generated ChanAIs synthetic SAGE demo under: %s\n", scriptDir);

