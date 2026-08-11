function visualize_earth( h_satellite, observation_time, i_sat )
%VISUALIZE_EARTH Plots the satellite position in the rotating reference frame
%
% Calling object:
%   Single object
%
% Description:
%   Plots the satellite position in 3D Cartesian coordinates with the Earth at the center. Earth's
%   rotation is taken into account.
%
% Input:
%   observation_time
%   Vector containing the T time points in seconds relative to the epoch (simulation start).
%   Alternatively, it is possible to use the current clock-time by providing a string describing
%   the clock offset relative to UTC time, e.g. 'utc+02' stands for Central European Summer Time
%   (CEST). When clock-time is used, satellite names are plotted next to the satellite position. If
%   'observation_time' is not given, satellite trajectories are plotted for one full orbit and
%   names are not plotted.
%
%   i_sat
%   Vector containing the S satellite indices that should be included in the plot. By default, all
%   satellites are used. If only one satellite position requested for a single time point (e.g.
%   clock-time), the orbital track is shown in addition to the satellite position.


if numel( h_satellite ) > 1
    error('h_satellite:visualize_earth','visualize_earth not definded for object arrays.');
else
    h_satellite = h_satellite(1,1); % workaround for octave
end

if ~exist('i_sat','var') || isempty( i_sat )
    i_sat = 1 : h_satellite.n_satellites;
end
nS = numel( i_sat );

% If observation time is not given, use the smalles orbital period
if ~exist('observation_time','var') || isempty( observation_time )
    tmp = min(h_satellite.orbit_period(i_sat));
    observation_time = (0:0.01:1)*tmp;
elseif ischar(observation_time) && numel(observation_time) == 6 && strcmp(observation_time(1:3),'utc') && ~isempty( h_satellite.epoch )
    observation_time = ( now - str2double(observation_time(4:6))/24 - h_satellite.epoch)*86400;
end
observation_time = reshape( observation_time,[],1 );

% Load earth texture
information = what('6GSatCM');
earth_texture = [information.path,'private',filesep,'800px-Nasa_land_ocean_ice_8192.jpg'];
cdata = imread(earth_texture);

% add Earth
phi = -180:10:180;
theta = (0:10:180);
[Phi, Theta] = meshgrid(phi, theta);
earth_x = (satellite.R_e*cosd(Phi).*sind(Theta));
earth_y = (satellite.R_e*sind(Phi).*sind(Theta));
earth_z = (satellite.R_e*ones(size(Phi)).*cosd(Theta));

figure
s = surf(earth_x, earth_y, earth_z, ones(size(earth_z)),'EdgeColor','b','FaceColor','b');
set(s, 'FaceColor', 'texturemap', 'CData', double(cdata)/255, 'FaceAlpha', 1, 'EdgeColor', 'none');

axis equal
hold on

% Get the observation time
tim = observation_time;

% Draw orpit-path for single satellite
if nS == 1 && numel( tim ) == 1
    tt = (-h_satellite.orbit_period(i_sat)/2 : 60 : h_satellite.orbit_period(i_sat)/2) + tim;
    [ ~, xyz_pos_orb] = orbit_predictor( h_satellite, tt, i_sat );
    plot3( xyz_pos_orb(1,:), xyz_pos_orb(2,:), xyz_pos_orb(3,:),'-m');
end

[ ~, xyz_pos ] = orbit_predictor( h_satellite, tim, i_sat );
[ ~, Dxyz_pos ] = orbit_predictor( h_satellite, tim+0.1, i_sat );

s_min = Inf;
s_max = 0;
for n = 1 : nS
    speed_v = sqrt(sum((Dxyz_pos(:,:,n) - xyz_pos(:,:,n)).^2,1))*10;
    if numel( speed_v ) < 4
        scatter3( xyz_pos(1,:,n), xyz_pos(2,:,n), xyz_pos(3,:,n), 'g','filled');
    else
        scatter3( xyz_pos(1,:,n), xyz_pos(2,:,n), xyz_pos(3,:,n), [], speed_v,'filled');
    end
    plot3(xyz_pos(1,:,n), xyz_pos(2,:,n), xyz_pos(3,:,n),'-k');
    s_min = min( [s_min,speed_v] );
    s_max = max( [s_max,speed_v] );
    if numel(tim) == 1 && ~isempty( h_satellite.sat_name )
        text( xyz_pos(1,1,n), xyz_pos(2,1,n), xyz_pos(3,1,n), [' ',h_satellite.sat_name{i_sat(n)}], 'Color','r' );
    end
end

caxis([s_min*0.99999,s_max*1.00001])

xlabel('x-axis (km)')
ylabel('y-axis (km)')
zlabel('z-axis (km)')
hold off
axis equal
view([110, 10])
rotate3d on
title('\fontsize{16}The trajectory of the satellite (km)');
end