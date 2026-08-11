function h_satellite = gen_constellation_gso( n_satellites, phase_offset )
%GEN_CONSTELLATION_GSO Generates equally spaced GSO satellite

% Set defaults
if ~exist('n_satellites','var') || isempty( n_satellites )
    n_satellites = 3;
elseif numel( n_satellites ) ~= 1
    error('satellite:gen_constellation_gso',...
        '??? "n_satellites" must be ascalar.');
end
if ~exist('phase_offset','var') || isempty( phase_offset )
    phase_offset = 0;
end

semimajor_axis = ones(1, n_satellites)*satellite.R_geo;
true_anomaly = (0:360/n_satellites:359) + phase_offset;

h_satellite = gen_constellation_custom( semimajor_axis, [], [], [], [], true_anomaly);
h_satellite.name = 'gso constellation';
h_satellite.station_keeping = 1;

end
