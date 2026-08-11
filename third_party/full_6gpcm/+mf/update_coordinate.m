function [xt, yt, zt] = update_coordinate(x, y, z, v, alphav_A, alphav_E, t)
%----------------------------------------------------------------------------------------------
% UPDATE_COORDINATE: Update coordinates of points in GCS at time t
%----------------------------------------------------------------------------------------------
% Input:
% x, y, z: initial coordinate of the point
% v0: speed of the point at initial time
% alphav_A, alphav_E: travel azimuth angle and elevation angle of the point
% t: time instant
%
% Output:
% xt, yt, zt: the updated coordinate of the point in GCS at time t
%----------------------------------------------------------------------------------------------

xt = x + v.* cos(alphav_E).* cos(alphav_A).*t;
yt = y + v.* cos(alphav_E).* sin(alphav_A).*t;
zt = z + v.* sin(alphav_E).*t;

end