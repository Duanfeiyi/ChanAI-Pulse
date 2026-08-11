function h_satellite = gen_constellation_custom( semimajor_axis, eccentricity, ...
    inclination, lon_asc_node, arg_periapsis, true_anomaly  )
%GEN_CONSTELLATION_CUSTOM Generates a custom satellite constellation

% Set defaults
if ~exist('semimajor_axis','var') || isempty( semimajor_axis )
    semimajor_axis = satellite.R_geo;
end
semimajor_axis = semimajor_axis(:).';
z = zeros( size( semimajor_axis ));
if ~exist('eccentricity','var') || isempty( eccentricity )
    eccentricity = z;
end
if ~exist('inclination','var') || isempty( inclination )
    inclination = z;
end
if ~exist('lon_asc_node','var') || isempty( lon_asc_node )
    lon_asc_node = z;
end
if ~exist('arg_periapsis','var') || isempty( arg_periapsis )
    arg_periapsis = z;
end
if ~exist('true_anomaly','var') || isempty( true_anomaly )
    true_anomaly = z; 
end

h_satellite = satellite([]);
h_satellite.name = 'custom constellation';
h_satellite.semimajor_axis   = semimajor_axis;
h_satellite.eccentricity     = eccentricity(:).';
h_satellite.inclination      = inclination(:).';
h_satellite.lon_asc_node     = lon_asc_node(:).';
h_satellite.arg_periapsis    = arg_periapsis(:).';
h_satellite.true_anomaly     = true_anomaly(:).';

for n = 1 : h_satellite.n_satellites
    h_satellite.sat_name{1,n} = ['sat',num2str(n,'%04d')];
end

end
