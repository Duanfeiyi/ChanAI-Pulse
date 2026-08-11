function corpus = create_v31_2_training_corpus(options)
%CREATE_V31_2_TRAINING_CORPUS Build a route-group corpus for v3.1-2.
%   Parameter labels retain the established Full-6GPCM profile provenance.
%   Full CIR generation remains an independent later benchmark activity;
%   this function does not claim that labels are measured data.

arguments
    options.Config (1, 1) struct = default_v31_2_corpus_config()
    options.EngineRoot (1, 1) string = ""
    options.UseExternalProfiles (1, 1) logical = true
end

config = options.Config;
validateConfig(config);
installation = resolve_full_6gpcm_root("EngineRoot", options.EngineRoot);
if options.UseExternalProfiles && ~installation.has_public_api
    error("create_v31_2_training_corpus:FullEngineUnavailable", ...
        "Full 6GPCM public API is unavailable at %s.", installation.root);
end

legacyConfig = config;
legacyConfig.schema_version = "v3.0-step11abc-config.1";
corpus = create_step11abc_training_corpus(installation.root, ...
    "Config", legacyConfig, ...
    "UseExternalProfiles", options.UseExternalProfiles);

groupCount = config.route.group_count;
groupIndex = (1:groupCount).';
cycleLength = numel(config.route.scenario_cycle);
cycleIndex = mod(groupIndex - 1, cycleLength) + 1;
catalog = corpus.group_catalog;
catalog.route_speed_mps = config.route.speed_mps_cycle(cycleIndex).';
catalog.tx_count = config.route.tx_count_cycle(cycleIndex).';
catalog.rx_count = config.route.rx_count_cycle(cycleIndex).';
catalog.route_duration_s = repmat(config.route.route_duration_s, groupCount, 1);

corpus.schema_version = "v3.1-2-training-corpus.1";
corpus.corpus_id = config.corpus_id;
corpus.config = config;
corpus.group_catalog = catalog;
corpus.sequence.provenance.v31_2 = struct( ...
    "corpus_id", config.corpus_id, ...
    "source", "full_6gpcm_public_api_profile_with_deterministic_route_perturbation", ...
    "measured_data", false, ...
    "core_modified", false);
corpus.generator = struct( ...
    "id", "full_6gpcm_bundled", ...
    "version", "260317", ...
    "source_package_sha256", "fcf151adf94038a6cf10d86c6dd687938b085a8f78a64d6829b5439c1d6c5875", ...
    "expected_tree_sha256", "369d778674004bbda6231b89b967b12c1fecacdddf9306b842db8982309a8ae9", ...
    "root_source", installation.source, ...
    "external_profiles_used", options.UseExternalProfiles, ...
    "core_modified", false);
corpus.summary.corpus_id = config.corpus_id;
corpus.summary.split_group_counts = config.data.split_group_counts;
corpus.summary.asset_policy = config.asset_policy.storage;
end

function validateConfig(config)
required = ["schema_version", "corpus_id", "route", "data", "asset_policy"];
for name = required
    if ~isfield(config, name)
        error("create_v31_2_training_corpus:InvalidConfig", ...
            "Missing configuration field %s.", name);
    end
end
if string(config.schema_version) ~= "v3.1-2-corpus-config.1"
    error("create_v31_2_training_corpus:InvalidConfig", ...
        "Unsupported corpus configuration schema.");
end
if config.route.group_count < 3 || config.route.samples_per_group < 20
    error("create_v31_2_training_corpus:InvalidConfig", ...
        "At least three route groups and 20 samples per route are required.");
end
if numel(config.route.speed_mps_cycle) ~= numel(config.route.scenario_cycle) || ...
        numel(config.route.tx_count_cycle) ~= numel(config.route.scenario_cycle) || ...
        numel(config.route.rx_count_cycle) ~= numel(config.route.scenario_cycle)
    error("create_v31_2_training_corpus:InvalidConfig", ...
        "Every scenario must have speed and antenna metadata.");
end
if any(config.route.speed_mps_cycle <= 0) || any(config.route.tx_count_cycle < 1) || ...
        any(config.route.rx_count_cycle < 1)
    error("create_v31_2_training_corpus:InvalidConfig", ...
        "Route speed and antenna counts must be positive.");
end
if numel(config.data.split_group_counts) ~= 3 || ...
        sum(config.data.split_group_counts) ~= config.route.group_count
    error("create_v31_2_training_corpus:InvalidConfig", ...
        "Split group counts must sum to route.group_count.");
end
end
