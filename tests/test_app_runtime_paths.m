% ChanAI Pulse runtime-path regression test.
% Simulates opening the App with only app/ on the MATLAB path.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
originalPath = path;
pathCleanup = onCleanup(@() path(originalPath));

restoredefaultpath;
addpath(fullfile(repoRoot, "app"));
rehash;

app = ChannelSimulatorApp;
appCleanup = onCleanup(@() delete(app));

assert(exist("render_characterization_plots", "file") == 2, ...
    "App startup must register app/plotting for characterization rendering.");
assert(exist("render_generation_plots", "file") == 2, ...
    "App startup must register app/plotting for generation rendering.");
assert(exist("render_prediction_plots", "file") == 2, ...
    "App startup must register app/plotting for prediction rendering.");
assert(exist("apply_y_limit_margin", "file") == 2, ...
    "App startup must register core utility functions.");

fprintf("PASS: App startup registers runtime dependencies from a minimal path.\n");
