function pair = generate_quadriga_v3_example( ...
    quadrigaRoot, outputDirectory)
%GENERATE_QUADRIGA_V3_EXAMPLE Run an optional external QuaDRiGa example.
%   PAIR = GENERATE_QUADRIGA_V3_EXAMPLE(QUADRIGAROOT, OUTPUTDIRECTORY)
%   uses an external, unmodified QuaDRiGa checkout. QUADRIGAROOT must
%   contain quadriga_src. The function writes one CIR/CTF pair when
%   OUTPUTDIRECTORY is supplied. No QuaDRiGa source is copied to this repo.

arguments
    quadrigaRoot (1, 1) string
    outputDirectory (1, 1) string = ""
end

sourceDirectory = fullfile(quadrigaRoot, "quadriga_src");
if ~isfolder(sourceDirectory) || ...
        ~isfile(fullfile(quadrigaRoot, "QuaDRiGa_License.txt"))
    error("generate_quadriga_v3_example:InvalidRoot", ...
        "Expected quadriga_src and QuaDRiGa_License.txt under: %s", ...
        quadrigaRoot);
end

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));
oldPath = path;
cleanupPath = onCleanup(@() path(oldPath));
addpath(sourceDirectory);

rng(3202, "twister");
simulation = qd_simulation_parameters;
simulation.center_frequency = 3.5e9;
simulation.sample_density = 1;
simulation.use_absolute_delays = true;
simulation.use_random_initial_phase = false;
simulation.show_progress_bars = false;

layout = qd_layout(simulation);
layout.tx_position = [0; 0; 10];
layout.tx_array = qd_arrayant('omni');
layout.tx_array.copy_element(1, 2);
layout.tx_array.element_position(2, :) = ...
    [-0.25, 0.25] * simulation.wavelength;
layout.rx_array = qd_arrayant('omni');
layout.rx_array.copy_element(1, 2:4);
layout.rx_array.element_position(2, :) = ...
    (-1.5:1:1.5) * 0.5 * simulation.wavelength;

routeSpacingM = 0.95 / simulation.samples_per_meter;
routeLengthM = 31 * routeSpacingM;
route = qd_track('linear', routeLengthM, 0);
route.positions = [linspace(0, routeLengthM, 32); ...
    zeros(1, 32); zeros(1, 32)];
route.initial_position = [20; 0; 1.5];
route.name = 'Step2Route';
layout.rx_track = route;
layout.set_scenario('3GPP_38.901_UMi_NLOS');

channels = layout.get_channels;
if numel(channels) > 1
    channel = merge(channels);
else
    channel = channels;
end
if channel.no_snap ~= 32
    error("generate_quadriga_v3_example:UnexpectedSnapshots", ...
        "Expected 32 QuaDRiGa snapshots but received %d.", ...
        channel.no_snap);
end

frequencyHz = simulation.center_frequency + ...
    ((0:63).' - 31.5) * 120e3;
samplePositionM = [route.positions(1:2, :).', ...
    route.positions(3, :).'];
metadata = struct( ...
    "generator", "QuaDRiGa", ...
    "generator_version", string(simulation.version), ...
    "random_seed", 3202, ...
    "upstream_repository", ...
        "https://github.com/fraunhoferhhi/QuaDRiGa", ...
    "upstream_commit", ...
        "277866650eb115adb5b3e8ac252b0d1df073596d", ...
    "license", "QuaDRiGa non-commercial software license", ...
    "scenario_id", "3GPP_38.901_UMi_NLOS");
pair = convert_quadriga_channel_to_v3_pair( ...
    channel, frequencyHz, samplePositionM, metadata);

if strlength(outputDirectory) > 0
    if ~isfolder(outputDirectory)
        mkdir(outputDirectory);
    end
    write_channel_dataset_hdf5( ...
        fullfile(outputDirectory, "quadriga_umi_nlos_cir.h5"), ...
        pair.cir);
    write_channel_dataset_hdf5( ...
        fullfile(outputDirectory, "quadriga_umi_nlos_ctf.h5"), ...
        pair.ctf);
end

clear cleanupPath
end
