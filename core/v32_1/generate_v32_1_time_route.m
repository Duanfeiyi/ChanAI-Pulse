function output = generate_v32_1_time_route(engineRoot, options)
%GENERATE_V32_1_TIME_ROUTE Generate one time-evolving CIR route for v3.2-1.
%   Produces a canonical v3 CIR whose Nt axis carries a true Doppler-evolving
%   time sequence (rx moves along a linear track), with a real time_s axis.
%   This is a v3.2-1 data-synthesis wrapper and never modifies the engine.

arguments
    engineRoot (1, 1) string
    options.ScenarioName (1, 1) string = "sub-6 GHz_UMa_LoS"
    options.CarrierFrequencyHz (1, 1) double {mustBePositive} = 3.5e9
    options.SnapshotIntervalS (1, 1) double {mustBePositive} = 0.001
    options.Nt (1, 1) double {mustBeInteger, mustBePositive} = 96
    options.SpeedMps (1, 1) double {mustBePositive} = 1
    options.TxCount (1, 1) double {mustBeInteger, mustBePositive} = 2
    options.RxCount (1, 1) double {mustBeInteger, mustBePositive} = 4
    options.Seed (1, 1) double = 11011
end

if ~isfolder(engineRoot)
    error("generate_v32_1_time_route:EngineNotFound", ...
        "Full 6GPCM root does not exist: %s", engineRoot);
end

oldPath = path;
oldRng = rng;
cleanup = onCleanup(@() restoreState(oldPath, oldRng)); %#ok<NASGU>
addpath(genpath(engineRoot));
rng(options.Seed, "twister");

sps = simulation_parameters();
sps.carrier_frequency = options.CarrierFrequencyHz;
sps.setScenario(char(options.ScenarioName));

intervalS = options.SnapshotIntervalS;
sampleRateHz = 1 / intervalS;
moveTimeS = max(0, (options.Nt - 1) * intervalS);
speedMps = options.SpeedMps;

tx = track('static', moveTimeS, 0, 0, [10 120 1.5], [1 0 0], sampleRateHz);
rx = track('linear', moveTimeS, speedMps, 0, [0 0 20], [1 0 0], sampleRateHz);

cm = channel_model(sps);
cm.tx_array = antenna_array('linear', options.TxCount, ...
    sps.carrier_frequency, 0.5, [], [], 0, 0, 0);
cm.rx_array = antenna_array('linear', options.RxCount, ...
    sps.carrier_frequency, 0.5, [], [], 0, 0, 0);
cm.tx_track = tx;
cm.rx_track = rx;

[result, delay] = cm.get_CIR([], "", []);
[cir, pathDelayS] = mf.result2H(result(1, 1, :), delay(1, 1, :));
% cir is [Tx, Rx, N_time_snapshot, N_path]; permute to canonical
% [Tx, Rx, Npath, Nt] and treat the route as a single N_sample=1 sample.
coefficient = permute(cir, [1, 2, 4, 3]);
delayS = permute(pathDelayS, [1, 2, 4, 3]);
pathValid = true(size(coefficient));

axes = struct( ...
    "time_s", (0:(options.Nt - 1)).' * intervalS, ...
    "sample_index", 1);

metadata = struct( ...
    "source", "full_6gpcm_public_api_time_route", ...
    "sample_semantics", "ordered_time", ...
    "scenario_id", options.ScenarioName, ...
    "center_frequency_hz", options.CarrierFrequencyHz, ...
    "snapshot_interval_s", intervalS, ...
    "route_speed_mps", speedMps, ...
    "seed", options.Seed, ...
    "core_modified", false);

payload = struct( ...
    "coefficient", coefficient, ...
    "delay_s", delayS, ...
    "path_valid", pathValid);
dataset = create_channel_dataset("cir", payload, axes, metadata);

output = struct( ...
    "schema_version", "v3.2-1-time-route.1", ...
    "dataset", dataset, ...
    "scenario_name", options.ScenarioName, ...
    "carrier_frequency_hz", options.CarrierFrequencyHz, ...
    "snapshot_interval_s", intervalS, ...
    "route_speed_mps", speedMps, ...
    "nt", options.Nt, ...
    "seed", options.Seed, ...
    "engine", "full_6gpcm_public_api", ...
    "core_modified", false);
end

function restoreState(oldPath, oldRng)
path(oldPath);
rng(oldRng);
end
