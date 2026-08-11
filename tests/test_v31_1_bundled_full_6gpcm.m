% ChanAI Pulse v3.1-1 bundled Full 6GPCM zero-configuration regression.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));

%% Resolve from source location, never from MATLAB's current directory.
originalFolder = pwd;
folderCleanup = onCleanup(@() cd(originalFolder)); %#ok<NASGU>
cd(tempdir);
installation = resolve_full_6gpcm_root(UseEnvironment=false);
assert(installation.source == "bundled");
assert(installation.is_bundled);
assert(installation.is_present);
assert(installation.has_fixed_entrypoint);
assert(installation.has_public_api);
assert(contains(installation.root, "third_party"));
cd(originalFolder);
clear folderCleanup

%% The bundled tree is a complete, fixed runtime artifact.
tree = hash_full_6gpcm_tree(installation.root);
assert(tree.file_count == 586);
assert(tree.total_bytes == 94491478);
assert(tree.aggregate_sha256 == ...
    "369d778674004bbda6231b89b967b12c1fecacdddf9306b842db8982309a8ae9");
assert(~isfile(fullfile(installation.root, "GUI", "6gpcs.tmp")));

%% Ordinary defaults need no EngineRoot. SISO keeps Lite first; MIMO uses
% the bundled Full public API after Lite is found dimension-incompatible.
fullConfig = default_generator_config("full_6gpcm");
assert(fullConfig.engine_root == installation.root);
assert(fullConfig.engine.id == "full_6gpcm_bundled");
assert(fullConfig.engine.expected_tree_sha256 == tree.aggregate_sha256);

siso = select_generator_backend("auto", ...
    struct("Tx", 1, "Rx", 1, "Nt", 2, "N_sample", 1));
assert(siso.success && siso.selected_backend == "lite_6gpcm");

mimo = select_generator_backend("auto", ...
    struct("Tx", 2, "Rx", 2, "Nt", 2, "N_sample", 1));
assert(mimo.success && mimo.selected_backend == "full_6gpcm");
assert(mimo.selected_adapter_variant == "public_api");
assert(mimo.candidates(1).compatible == false);

%% A one-sample Full call proves that the bundled public API runs through
% the unchanged-core adapter with no local configuration.
fullConfig.backend_options.full_interface = "public_api";
fullConfig.dimensions.N_sample = 1;
result = run_generator_adapter(fullConfig);
assert(result.success, strjoin(result.errors, " | "));
assert(result.backend == "full_6gpcm");
assert(result.backend_manifest.interface == "public_api");
assert(result.backend_manifest.core_unchanged);
assert(result.backend_manifest.tree_sha256_before == tree.aggregate_sha256);
assert(result.backend_manifest.tree_sha256_after == tree.aggregate_sha256);
assert(result.validation.dataset.is_valid);

%% An advanced explicit root remains an override rather than a hidden
% fallback to the bundled copy.
mockRoot = fullfile(repositoryRoot, "tests", "fixtures", "mock_full_6gpcm");
override = resolve_full_6gpcm_root( ...
    EngineRoot=mockRoot, UseEnvironment=false);
assert(override.source == "explicit_override");
assert(~override.is_bundled);
assert(override.root == string(mockRoot));

fprintf("PASS: v3.1-1 bundled Full 6GPCM zero-configuration regression.\n");
