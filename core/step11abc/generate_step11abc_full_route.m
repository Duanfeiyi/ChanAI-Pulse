function output = generate_step11abc_full_route(engineRoot, options)
%GENERATE_STEP11ABC_FULL_ROUTE Generate a continuous full-6GPCM CIR route.
%   This is deliberately separate from the product adapter: it is a
%   training/validation wrapper and keeps the supplied Full 6GPCM untouched.

arguments
    engineRoot (1, 1) string
    options.ScenarioName (1, 1) string = "sub-6 GHz_UMa_LoS"
    options.CarrierFrequencyHz (1, 1) double {mustBePositive} = 3.5e9
    options.DurationS (1, 1) double {mustBePositive} = 24
    options.SpeedMps (1, 1) double {mustBePositive} = 1
    options.TxCount (1, 1) double {mustBeInteger, mustBePositive} = 2
    options.RxCount (1, 1) double {mustBeInteger, mustBePositive} = 4
end

if ~isfolder(engineRoot)
    error("generate_step11abc_full_route:EngineNotFound", ...
        "Full 6GPCM root does not exist: %s", engineRoot);
end
oldPath = path;
oldRng = rng;
cleanup = onCleanup(@() restoreState(oldPath, oldRng)); %#ok<NASGU>
addpath(genpath(engineRoot));
sps = simulation_parameters();
sps.carrier_frequency = options.CarrierFrequencyHz;
sps.setScenario(char(options.ScenarioName));
% This historical public API dispatches on char vectors, not string scalars.
tx = track('static', options.DurationS, 0, 0, [10 120 1.5], [1 0 0], 1);
rx = track('linear', options.DurationS, options.SpeedMps, 0, [0 0 20], [1 0 0], 1);
cm = channel_model(sps);
cm.tx_array = antenna_array('linear', options.TxCount, sps.carrier_frequency, 0.5, [], [], 0, 0, 0);
cm.rx_array = antenna_array('linear', options.RxCount, sps.carrier_frequency, 0.5, [], [], 0, 0, 0);
cm.tx_track = tx;
cm.rx_track = rx;
[result, delay] = cm.get_CIR([], "", []);
[cir, pathDelayS] = mf.result2H(result(1, 1, :), delay(1, 1, :));
output = struct( ...
    "schema_version", "v3.0-step11abc-full-route.1", ...
    "cir", cir, ...
    "path_delay_s", pathDelayS, ...
    "dimension_order", ["Tx", "Rx", "N_time_snapshot", "N_path"], ...
    "scenario_name", options.ScenarioName, ...
    "carrier_frequency_hz", options.CarrierFrequencyHz, ...
    "route_duration_s", options.DurationS, ...
    "route_speed_mps", options.SpeedMps, ...
    "engine", "full_6gpcm_public_api", ...
    "core_modified", false);
end

function restoreState(oldPath, oldRng)
path(oldPath);
rng(oldRng);
end
