% Generate the four Step 2 standard CIR/CTF fixture pairs.

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));
outputDirectory = fullfile(repoRoot, "demo_data", ...
    "v3_standard_fixtures");

manifestPath = fullfile(outputDirectory, "manifest.json");
if isfile(manifestPath)
    error("generate_v3_standard_fixtures:AlreadyGenerated", ...
        ["Fixture output already exists. The generator refuses to " ...
        "overwrite it: %s"], outputDirectory);
end

manifest = write_v3_standard_fixtures(outputDirectory);
fprintf("Generated %d deterministic CIR/CTF fixture pairs in:\n%s\n", ...
    numel(manifest.entries), outputDirectory);
