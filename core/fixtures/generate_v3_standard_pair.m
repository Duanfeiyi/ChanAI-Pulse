function pair = generate_v3_standard_pair(scenario)
%GENERATE_V3_STANDARD_PAIR Generate one deterministic CIR/CTF fixture pair.
%   PAIR = GENERATE_V3_STANDARD_PAIR(SCENARIO) returns PAIR.cir and
%   PAIR.ctf. Both datasets describe the same synthetic channel and follow
%   the v3.0 Step 1 contract. The same scenario always produces the same
%   numerical values.

arguments
    scenario (1, 1) struct
end

validateScenario(scenario);

txCount = double(scenario.Tx);
rxCount = double(scenario.Rx);
frequencyCount = double(scenario.Nf);
timeCount = double(scenario.Nt);
pathCount = double(scenario.Npath);
sampleCount = double(scenario.N_sample);

centerFrequencyHz = double(scenario.center_frequency_hz);
spacingHz = double(scenario.subcarrier_spacing_hz);
snapshotIntervalS = double(scenario.snapshot_interval_s);
wavelengthM = 299792458 / centerFrequencyHz;
elementSpacingM = wavelengthM / 2;

sampleIndex = (1:sampleCount).';
routeX = (sampleIndex - 1) * double(scenario.route_spacing_m);
routeY = 0.25 * sin(2 * pi * (sampleIndex - 1) / sampleCount);
samplePositionM = [routeX, routeY, zeros(sampleCount, 1)];
timeS = (0:timeCount - 1).' * snapshotIntervalS;
frequencyOffsetsHz = ((0:frequencyCount - 1).' - ...
    (frequencyCount - 1) / 2) * spacingHz;
frequencyHz = centerFrequencyHz + frequencyOffsetsHz;

baseDelayS = linspace(0, 260e-9, pathCount);
if pathCount == 1
    baseDelayS = 0;
end
basePower = 10 .^ (-(0:pathCount - 1) * 3.5 / 10);
basePower = basePower / sum(basePower);
baseAoa = linspace(-0.75, 0.85, pathCount);
baseAod = linspace(0.65, -0.55, pathCount);
if timeCount > 1
    baseDopplerHz = linspace(-90, 110, pathCount);
else
    baseDopplerHz = zeros(1, pathCount);
end
% Do not rely on a language-specific pseudo-random implementation. This
% deterministic phase rule can be reproduced exactly by MATLAB and Python.
initialPhase = mod(double(scenario.seed) * 0.0137 + ...
    (1:pathCount) * 1.61803398875, 2 * pi);

shape = [txCount, rxCount, pathCount, timeCount, sampleCount];
coefficient = complex(zeros(shape, "single"));
delayS = zeros([1, 1, pathCount, timeCount, sampleCount], "single");
aoaRad = zeros(size(delayS), "single");
aodRad = zeros(size(delayS), "single");
dopplerHz = zeros(size(delayS), "single");

for sample = 1:sampleCount
    routePhase = 2 * pi * (sample - 1) / sampleCount;
    for time = 1:timeCount
        timeValue = timeS(time);
        for path = 1:pathCount
            pathDelay = baseDelayS(path) + ...
                (4e-9 + path * 0.7e-9) * sin( ...
                routePhase + 0.45 * path) + ...
                baseDopplerHz(path) * timeValue * 2e-12;
            pathDelay = max(pathDelay, 0);
            aoa = baseAoa(path) + 0.08 * sin(routePhase + 0.3 * path);
            aod = baseAod(path) + 0.07 * cos(routePhase + 0.2 * path);
            routeFading = 0.82 + 0.18 * cos( ...
                routePhase * (1 + 0.08 * path) + 0.6 * path);
            amplitude = sqrt(basePower(path) * max(routeFading, 0.05));
            temporalPhase = 2 * pi * baseDopplerHz(path) * timeValue;
            routePhaseTerm = 0.24 * (sample - 1) * path;

            delayS(1, 1, path, time, sample) = single(pathDelay);
            aoaRad(1, 1, path, time, sample) = single(aoa);
            aodRad(1, 1, path, time, sample) = single(aod);
            dopplerHz(1, 1, path, time, sample) = ...
                single(baseDopplerHz(path));

            for tx = 1:txCount
                txPhase = 2 * pi * (tx - 1) * elementSpacingM * ...
                    sin(aod) / wavelengthM;
                for rx = 1:rxCount
                    rxPhase = 2 * pi * (rx - 1) * elementSpacingM * ...
                        sin(aoa) / wavelengthM;
                    phase = initialPhase(path) + temporalPhase + ...
                        routePhaseTerm + txPhase + rxPhase;
                    coefficient(tx, rx, path, time, sample) = ...
                        single(amplitude * exp(1i * phase));
                end
            end
        end
    end
end

axesCommon = struct( ...
    "sample_index", sampleIndex, ...
    "sample_position_m", samplePositionM);
cirAxes = axesCommon;
cirAxes.time_s = timeS;
metadata = buildMetadata(scenario, elementSpacingM);
cirPayload = struct( ...
    "coefficient", coefficient, ...
    "delay_s", delayS, ...
    "path_valid", true(size(delayS)), ...
    "aoa_rad", aoaRad, ...
    "aod_rad", aodRad, ...
    "doppler_hz", dopplerHz);
cirDataset = create_channel_dataset("cir", cirPayload, ...
    cirAxes, metadata);

H = cir_to_ctf(coefficient, delayS, frequencyOffsetsHz);
ctfAxes = axesCommon;
ctfAxes.frequency_hz = frequencyHz;
ctfAxes.time_s = timeS;
ctfDataset = create_channel_dataset("ctf", struct("H", H), ...
    ctfAxes, metadata);

pair = struct();
pair.scenario = scenario;
pair.cir = cirDataset;
pair.ctf = ctfDataset;
pair.expected = expectedCapabilities(string(scenario.id));
end

function metadata = buildMetadata(scenario, elementSpacingM)
metadata = struct( ...
    "source", "deterministic_v3_standard_fixture", ...
    "sample_semantics", string(scenario.sample_semantics), ...
    "created_utc", "2026-07-29T00:00:00Z", ...
    "generator", "ChanAI Pulse deterministic fixture generator", ...
    "generator_version", "v3.0-step2.1", ...
    "random_seed", double(scenario.seed), ...
    "scenario_id", string(scenario.id), ...
    "scenario_name_zh", string(scenario.display_name_zh), ...
    "center_frequency_hz", double(scenario.center_frequency_hz), ...
    "subcarrier_spacing_hz", double(scenario.subcarrier_spacing_hz), ...
    "snapshot_interval_s", double(scenario.snapshot_interval_s), ...
    "tx_array", struct("type", "ULA", "element_count", ...
        double(scenario.Tx), "element_spacing_m", elementSpacingM), ...
    "rx_array", struct("type", "ULA", "element_count", ...
        double(scenario.Rx), "element_spacing_m", elementSpacingM), ...
    "config", scenario);
end

function expected = expectedCapabilities(scenarioId)
allPlots = ["power", "pdp", "frequency_autocorrelation", ...
    "delay_spread_cdf", "angular_power_spectrum", ...
    "spatial_correlation", "angular_spread_cdf", ...
    "doppler_power_spectrum", "time_autocorrelation", ...
    "doppler_spread_cdf"];
switch scenarioId
    case "narrowband_static_siso"
        classification = scenarioId;
        standardPlots = allPlots(1);
    case "wideband_static_siso"
        classification = scenarioId;
        standardPlots = allPlots(2:4);
    case "wideband_static_mimo"
        classification = scenarioId;
        standardPlots = allPlots(2:7);
    case "wideband_dynamic_mimo"
        classification = scenarioId;
        standardPlots = allPlots(2:10);
    otherwise
        error("generate_v3_standard_pair:UnknownScenario", ...
            "Unknown standard scenario: %s", scenarioId);
end
expected = struct( ...
    "classification", classification, ...
    "standard_plots", standardPlots, ...
    "standard_plot_count", numel(standardPlots), ...
    "delay_sample_heatmap", scenarioId ~= "narrowband_static_siso", ...
    "heatmap_is_additional", true);
end

function validateScenario(scenario)
required = ["id", "seed", "Tx", "Rx", "Nf", "Nt", "Npath", ...
    "N_sample", "center_frequency_hz", "subcarrier_spacing_hz", ...
    "snapshot_interval_s", "route_spacing_m", "sample_semantics"];
for fieldName = required
    if ~isfield(scenario, fieldName)
        error("generate_v3_standard_pair:InvalidScenario", ...
            "Missing scenario field: %s", fieldName);
    end
end
if string(scenario.sample_semantics) ~= "ordered_route"
    error("generate_v3_standard_pair:InvalidSampleSemantics", ...
        "Step 2 standard fixtures must use ordered_route samples.");
end
end
