function output = generate_v32_1_space_route(engineRoot, options)
%GENERATE_V32_1_SPACE_ROUTE Generate one position-evolving CIR route for v3.2-1.
%   Produces a canonical v3 CIR whose N_sample axis carries positions along a
%   linear track (real sample_position_m). This is the Space-axis analogue of
%   the Time-axis route: the receiver moves, and each snapshot is a distinct
%   spatial position, so large-scale parameters evolve along space. This is a
%   data-synthesis wrapper and never modifies the engine.

arguments
    engineRoot (1, 1) string
    options.ScenarioName (1, 1) string = "sub-6 GHz_UMa_LoS"
    options.CarrierFrequencyHz (1, 1) double {mustBePositive} = 3.5e9
    options.NSample (1, 1) double {mustBeInteger, mustBePositive} = 96
    options.SpeedMps (1, 1) double {mustBePositive} = 8.0
    options.SnapshotIntervalS (1, 1) double {mustBePositive} = 0.100
    options.TxCount (1, 1) double {mustBeInteger, mustBePositive} = 2
    options.RxCount (1, 1) double {mustBeInteger, mustBePositive} = 4
    options.Seed (1, 1) double = 11011
end

if ~isfolder(engineRoot)
    error("generate_v32_1_space_route:EngineNotFound", ...
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
nSample = options.NSample;
moveTimeS = max(0, (nSample - 1) * intervalS);
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
% cir is [Tx, Rx, N_time_snapshot, N_path]; treat each time snapshot as one
% spatial position => permute to [Tx, Rx, Npath, Nt=1, N_sample].
coefficient = permute(cir, [1, 2, 4, 3]);
coefficient = reshape(coefficient, ...
    [size(coefficient, 1), size(coefficient, 2), size(coefficient, 3), 1, ...
     size(coefficient, 4)]);
delayS = permute(pathDelayS, [1, 2, 4, 3]);
delayS = reshape(delayS, ...
    [size(delayS, 1), size(delayS, 2), size(delayS, 3), 1, size(delayS, 4)]);
pathValid = true(size(coefficient));

% Position coordinates: the rx track positions (x component, or full 3D).
rxPositions = rx.positions;
nTrack = size(rxPositions, 1);
if nTrack >= nSample
    positionSample = rxPositions(1:nSample, :);
else
    positionSample = rxPositions;
end
% Use the along-track x-coordinate (plus y,z kept as columns) for the axis.
samplePositionM = positionSample;  % N_sample x 3

axes = struct( ...
    "sample_index", (1:size(coefficient, 5)).', ...
    "sample_position_m", samplePositionM);

metadata = struct( ...
    "source", "full_6gpcm_public_api_space_route", ...
    "sample_semantics", "ordered_route", ...
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
    "schema_version", "v3.2-1-space-route.1", ...
    "dataset", dataset, ...
    "scenario_name", options.ScenarioName, ...
    "carrier_frequency_hz", options.CarrierFrequencyHz, ...
    "route_speed_mps", speedMps, ...
    "n_sample", size(coefficient, 5), ...
    "seed", options.Seed, ...
    "engine", "full_6gpcm_public_api", ...
    "core_modified", false);
end

function restoreState(oldPath, oldRng)
path(oldPath);
rng(oldRng);
end
