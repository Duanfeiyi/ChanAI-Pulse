% Generate small synthetic demo datasets for ChanAI Pulse.
% These files are synthetic and do not contain real measured channel data.

clearvars;
clc;

demoDir = fileparts(mfilename("fullpath"));
if demoDir == ""
    demoDir = pwd;
end

rng(604, "twister");

makeDemo(fullfile(demoDir, "demo_sub6_scenario1.mat"), ...
    "Sub-6", "Scenario 1", 128, 60, 100, 0.020, 0.15);

makeDemo(fullfile(demoDir, "demo_mmwave_scenario2.mat"), ...
    "mmWave", "Scenario 2", 256, 72, 400, 0.045, 0.28);

fprintf("Synthetic demo data generated in: %s\n", demoDir);

function makeDemo(outputPath, band, scenario, nBins, nSnaps, bandwidthMHz, decayRate, motionScale)
delayAxis = (0:nBins-1).';
timeAxis = 1:nSnaps;

basePdp = exp(-delayAxis * decayRate);
basePdp = basePdp / max(basePdp);

slowFading = 1 + motionScale * sin(2*pi*timeAxis/18);
fastFading = 0.08 * randn(nBins, nSnaps);
delayRipple = 0.05 * sin(2*pi*delayAxis/max(8, nBins/8));

powerLinear = max(basePdp .* slowFading + delayRipple + fastFading, 1e-8);
noiseFloor = 10^(-13);
powerLinear = powerLinear + noiseFloor;
DPSD_dB = 10 * log10(powerLinear / 1e-3);

metadata = struct();
metadata.project = "ChanAI Pulse";
metadata.demo_type = "synthetic";
metadata.is_measured_data = false;
metadata.band = band;
metadata.scenario = scenario;
metadata.bandwidth_mhz = bandwidthMHz;
metadata.description = "Small synthetic demo data for GUI loading and visualization tests.";
metadata.warning = "This file is not a real measured dataset and must not be used as benchmark evidence.";

save(outputPath, "DPSD_dB", "metadata");
end

