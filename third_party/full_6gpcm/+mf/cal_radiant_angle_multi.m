function [azimuth,elevation,r] = cal_radiant_angle_multi(x, y, z, betaH_A, betaH_E, betaV_A, betaV_E, ii, jj, delta_H, delta_V)
%------------------------------------------------------------------------------
% CAL_RADIANT_ANGLE_MULTI: Calculate radiant AAoDs and EAoDs of multiple scatterers
% Note: The values of all input parameters are the values at a time instant
%------------------------------------------------------------------------------
% Input:
% x, y, z: Cartesian coordinates of scatterers in GCS 
% betaH_A, betaH_E: azimuth and elevation angle of LED array in H direction
% betaV_A, betaV_E: azimuth and elevation angle of LED array in V direction
% ii, jj: index of LED unit 
% delta_H, delta_V: interval of LED unit in horizontal and vertical axis
%
% Output:
% azimuth, elevation, r: spherical coordinates of scatterers in LCS under L_ij
%------------------------------------------------------------------------------
    Num = length(x); % number of scatterers
    azimuth = zeros(1, Num);
    elevation = zeros(1, Num);
    r = zeros(1, Num);

    P=[cos(betaV_E)*sin(betaV_A)*sin(betaH_E)-sin(betaV_E)*cos(betaH_E)*sin(betaH_A), cos(betaV_E)*cos(betaV_A), cos(betaH_E)*cos(betaH_A);
       sin(betaV_E)*cos(betaH_E)*cos(betaH_A)-cos(betaV_E)*cos(betaV_A)*sin(betaH_E), cos(betaV_E)*sin(betaV_A), cos(betaH_E)*sin(betaH_A);
       cos(betaV_E)*cos(betaH_E)*sin(betaH_A-betaV_A), sin(betaV_E), sin(betaH_E)];

    for k=1:Num
        coord_rotate = P^(-1)*[x(k); y(k); z(k)];
        coord_translate = coord_rotate - [0; (jj-1)*delta_V; (ii-1)*(delta_H)];
        [azimuth(k),elevation(k),r(k)] = cart2sph(coord_translate(1),coord_translate(2),coord_translate(3));
    end
end