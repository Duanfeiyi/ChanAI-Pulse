function h_satellite = generate( constellation, Ain, Bin, Cin, Din, Ein, Fin )
%GENERATE Generates predefined satellite constellations
%
% Calling object:
%   None (constructor)
%
% Description:
%   The constructor creates new satellite constellations with a number of S satellites. The input
%   parameter 'constellation' defines the constellation type. Additional parameters are specific to
%   the constellation. They are defined by the following list. If no input is specified, an empty
%   object is created.
%
% Constellation:
%   custom
%   A custom constellation. All input parameters must be given as vectors having the dimensions [ 1
%   x S ].
%    * Ain - Semimajor axis in [km]; Default: 42164 km, GEO orbit
%    * Bin - Orbital eccentricity [0-1]; Default: 0
%    * Cin - Orbital inclination in [degree]; Default: 0
%    * Din - Longitude of the ascending node in [degree]; Default: 0
%    * Ein - Argument of periapsis in [degree]; Default: 0
%    * Fin - True anomaly in [degree]; Default: 0
%
%
%   gso
%   A constellation of equally spaced geostationary satellites.
%    * Ain - Number of satellites S; Scalar variable; Default: 3
%    * Bin - Phase offset of the first satellite in [degree]; Scalar variable
%
%
%   walker-delta
%   Walker-Delta pattern constellation is used for a global coverage of the Earth's surface by a
%   minimum number of satellites in circular orbits. A Walker-Delta pattern contains of total of
%   'S' satellites in 'p' orbital planes with 't=S/p' satellites in each orbital plane. All orbital
%   planes are assumed to be in same inclination with reference to the equator. The phase
%   difference between satellites in adjacent plane is defined as the angle in the direction of
%   motion from the ascending node to the nearest satellite at a time when a satellite in the next
%   most westerly plane is at its ascending node. In order for all of the orbit planes to have the
%   same phase difference with each other, the phase difference between adjacent satellites must be
%   a multiple of 'f*360/S', where 'f' can be an integer between 0 to p-1.
%    * Ain - Semimajor axis for all satellites in [km]; Scalar variable
%    * Bin - Orbital inclination in [degree]; Scalar variable
%    * Cin - Number of orbital planes 'p'; Scalar variable
%    * Din - Number of satellites per plane 't'; Scalar variable
%    * Ein - Phase difference in [degree]; Scalar variable
%
%
% Output:
%   h_satellite
%   Handle to the created 'satellite' object.

var_names = {'Ain','Bin','Cin','Din','Ein','Fin'};
for n = 1:numel( var_names )
    if ~exist( var_names{n},'var' )
        eval([ var_names{n},' = [];' ]);
    end
end

switch lower( constellation )
    case 'custom'
        h_satellite = gen_constellation_custom( Ain, Bin, Cin, Din, Ein, Fin );
    case 'gso'
        h_satellite = gen_constellation_gso( Ain, Bin );
    case 'walker-delta'
        h_satellite = gen_constellation_walker_delta( Ain, Bin, Cin, Din, Ein );
    otherwise
        error('satellite:generate',['??? Constellation type "',constellation,'" is not supported.']);
end

end
