function report = run_v31_3_local_evidence(assetRoot)
%RUN_V31_3_LOCAL_EVIDENCE Run the default local v3.1-3 evidence study.

arguments
    assetRoot (1, 1) string = ""
end
repositoryRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repositoryRoot, "core")));
if strlength(assetRoot) == 0
    assetRoot = fullfile(fileparts(repositoryRoot), "ChanAI-Pulse-v3.1-assets");
end
manifestPath = fullfile(assetRoot, "corpora", ...
    "chanaipulse-v3.1-corpus.1", "corpus_manifest.json");
report = run_v31_3_parameter_evidence(assetRoot, ...
    "CorpusManifestPath", manifestPath);
end
