function corpus = create_step11abc_training_corpus(engineRoot, options)
%CREATE_STEP11ABC_TRAINING_CORPUS Build the 40-route Step 11A corpus.
%   Labels are scenario-derived generator truth with a deterministic smooth
%   route perturbation. They are not reverse-engineered measured labels.

arguments
    engineRoot (1, 1) string
    options.Config (1, 1) struct = default_step11abc_config()
    options.UseExternalProfiles (1, 1) logical = true
end

stepConfig = options.Config;
dataConfig = step11abc_predictor_data_config(stepConfig);
names = stepConfig.parameter_names;
bounds = stepConfig.parameter_bounds;
routeConfig = stepConfig.route;
groupCount = routeConfig.group_count;
rowsPerGroup = routeConfig.samples_per_group;
allValues = nan(groupCount * rowsPerGroup, numel(names));
groupId = strings(groupCount * rowsPerGroup, 1);
sampleIndex = nan(groupCount * rowsPerGroup, 1);
scenarioByGroup = strings(groupCount, 1);
frequencyByGroup = nan(groupCount, 1);
profileRows = cell(groupCount, 1);

fallback = struct("values", mean(bounds, 2).', "parameter_names", names);
for groupIndex = 1:groupCount
    cycleIndex = mod(groupIndex - 1, numel(routeConfig.scenario_cycle)) + 1;
    scenario = routeConfig.scenario_cycle(cycleIndex);
    frequency = routeConfig.carrier_frequency_hz(cycleIndex);
    profile = struct( ...
        "scenario_name", scenario, "carrier_frequency_hz", frequency, ...
        "values", fallback.values, "parameter_names", names, ...
        "source", "embedded_reference_profile", "fallback_used", true);
    if options.UseExternalProfiles
        profile = read_step11abc_full_profile(engineRoot, scenario, frequency, fallback);
    end
    indices = (groupIndex - 1) * rowsPerGroup + (1:rowsPerGroup);
    allValues(indices, :) = createSmoothRoute(profile.values, bounds, groupIndex, routeConfig.seed);
    groupId(indices) = "route-" + compose("%02d", groupIndex);
    sampleIndex(indices) = (1:rowsPerGroup).';
    scenarioByGroup(groupIndex) = scenario;
    frequencyByGroup(groupIndex) = frequency;
    profileRows{groupIndex} = profile;
end

sequence = create_parameter_sequence(allValues, names, struct( ...
    "bounds", bounds, ...
    "group_id", groupId, ...
    "parameter_sample_index", sampleIndex, ...
    "raw_window_start", sampleIndex, ...
    "raw_window_end", sampleIndex, ...
    "raw_window_center", sampleIndex, ...
    "label_source", routeConfig.label_source, ...
    "quality_status", "PASS", ...
    "provenance", struct( ...
        "step", "11A", ...
        "label_definition", "Full 6GPCM scenario profile plus deterministic smooth route perturbation", ...
        "engine_root_external", engineRoot, ...
        "core_modified", false, ...
        "paired_cir_generation", "available separately through generate_step11abc_full_route")));

bundles = struct();
taskNames = stepConfig.data.tasks;
bundleNames = string(fieldnames(stepConfig.parameter_bundles)).';
for task = taskNames
    taskField = char(task);
    bundles.(taskField) = struct();
    for bundleName = bundleNames
        selectedNames = stepConfig.parameter_bundles.(bundleName);
        selected = ismember(names, selectedNames);
        selectedSequence = sequence;
        selectedSequence.values = sequence.values(:, selected);
        selectedSequence.parameter_names = sequence.parameter_names(selected);
        selectedSequence.parameter_units = sequence.parameter_units(selected);
        selectedSequence.parameter_bounds = sequence.parameter_bounds(selected, :);
        selectedSequence.summary.P = sum(selected);
        dataset = build_predictor_dataset(selectedSequence, task, dataConfig);
        split = split_predictor_dataset_by_group(dataset, dataConfig);
        normalized = normalize_predictor_dataset( ...
            dataset, selectedSequence, split, dataConfig);
        bundles.(taskField).(bundleName) = struct( ...
            "sequence", selectedSequence, "dataset", normalized, "split", split, ...
            "bundle_name", bundleName, "parameter_names", selectedNames);
    end
end

catalogRouteId = "route-" + compose("%02d", (1:groupCount).');
catalogRouteId = catalogRouteId(:);
groupCatalog = table((1:groupCount).', catalogRouteId, scenarioByGroup(:), ...
    frequencyByGroup(:), 'VariableNames', {'group_index', 'group_id', ...
    'scenario_name', 'carrier_frequency_hz'});
corpus = struct( ...
    "schema_version", "v3.0-step11abc-training-corpus.1", ...
    "config", stepConfig, ...
    "sequence", sequence, ...
    "bundles", bundles, ...
    "group_catalog", groupCatalog, ...
    "profiles", {profileRows}, ...
    "summary", struct( ...
        "route_group_count", groupCount, ...
        "samples_per_route", rowsPerGroup, ...
        "expected_examples_per_route", rowsPerGroup - 20 + 1, ...
        "expected_train_examples", stepConfig.data.split_group_counts(1) * (rowsPerGroup - 20 + 1)));
end

function values = createSmoothRoute(baseValues, bounds, groupIndex, masterSeed)
rng(masterSeed + groupIndex, "twister");
sampleCount = 120;
parameterCount = numel(baseValues);
values = zeros(sampleCount, parameterCount);
for column = 1:parameterCount
    lower = bounds(column, 1);
    upper = bounds(column, 2);
    center = min(max(baseValues(column), lower), upper);
    scale = 0.10 * (upper - lower);
    noise = zeros(sampleCount, 1);
    for row = 2:sampleCount
        noise(row) = 0.92 * noise(row - 1) + 0.08 * randn();
    end
    phase = 2 * pi * rand();
    time = (0:(sampleCount - 1)).' / max(1, sampleCount - 1);
    values(:, column) = center + scale * (0.65 * sin(2 * pi * time + phase) + 0.35 * noise);
    values(:, column) = min(max(values(:, column), lower), upper);
end
values(:, [7, 8]) = round(values(:, [7, 8]));
end
