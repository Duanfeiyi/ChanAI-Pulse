function asset = create_v31_2_local_assets(assetRoot)
%CREATE_V31_2_LOCAL_ASSETS Create the public synthetic v3.1-2 local corpus.
%   This function writes only below ASSETROOT, which is outside the Git
%   worktree by design. Existing corpus ids are rejected rather than
%   overwritten. The result is suitable for later v3.1-3/4 experiments.

arguments
    assetRoot (1, 1) string = ""
end
repositoryRoot = fileparts(fileparts(mfilename("fullpath")));
if strlength(assetRoot) == 0
    assetRoot = fullfile(fileparts(repositoryRoot), "ChanAI-Pulse-v3.1-assets");
end
addpath(genpath(fullfile(repositoryRoot, "core")));
config = default_v31_2_corpus_config();
corpus = create_v31_2_training_corpus( ...
    "Config", config, "UseExternalProfiles", true);
asset = write_v31_2_training_corpus(corpus, assetRoot);
report = validate_v31_2_corpus_asset(asset.manifest_path);
if ~report.is_valid
    error("create_v31_2_local_assets:VerificationFailed", ...
        "%s", strjoin(report.errors, " | "));
end
fprintf("PASS: created v3.1-2 local corpus %s\n", asset.manifest_path);
end
