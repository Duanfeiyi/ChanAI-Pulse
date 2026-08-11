function h_qd_arrayant = gen_arrayant_cylindrical_array_dual_pol
%GEN_ARRAYANT_cylindrical_array_dual_pol
%
%   An isotropic radiator with vertical polarization.
%
% 
% QuaDRiGa Copyright (C) 2011-2019
% Fraunhofer-Gesellschaft zur Foerderung der angewandten Forschung e.V. acting on behalf of its
% Fraunhofer Heinrich Hertz Institute, Einsteinufer 37, 10587 Berlin, Germany
% All rights reserved.
%
% e-mail: quadriga@hhi.fraunhofer.de
%
% This file is part of QuaDRiGa.
%
% The Quadriga software is provided by Fraunhofer on behalf of the copyright holders and
% contributors "AS IS" and WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, including but not limited to
% the implied warranties of merchantability and fitness for a particular purpose.
%
% You can redistribute it and/or modify QuaDRiGa under the terms of the Software License for 
% The QuaDRiGa Channel Model. You should have received a copy of the Software License for The
% QuaDRiGa Channel Model along with QuaDRiGa. If not, see <http://quadriga-channel-model.de/>. 

% load('rx_pattern_5.5.mat','f_rx_h','f_rx_v') ;
% % The order in the antenna domain: 4V, 4H, 4V, 4H......
% f_rx = zeros(64,2,181,91);
% count = 0;
% for i = 1:64
%     if mod(i,8) == 1
%         count = count + 1;
%         f_rx((count-1)*8+1:(count-1)*8+4,:,:,:) = f_rx_v((count-1)*4+1:count*4,:,:,:);
%         f_rx((count-1)*8+5:count*8,:,:,:) = f_rx_h((count-1)*4+1:count*4,:,:,:);
%     end
% end

h_qd_arrayant = antenna_array( [] );
h_qd_arrayant.name              = 'cylindrical-array-dual-pol';
% h_qd_arrayant.center_frequency  = simulation_parameters.speed_of_light;
% h_qd_arrayant.elevation_grid    = (-90:2:90)*pi/180;
% h_qd_arrayant.azimuth_grid      = (-180:2:180)*pi/180;
h_qd_arrayant.no_elements       = 64;

radius = 0.123/2;       %radius of cylindrical antenna array
delta_y = 0.029;       %the spacing between two layers of antenna

% % Measurement antenna, dual polarization
% antenna_position = zeros(h_qd_arrayant.no_elements,3);
% % Set vertical positions
% N = 4;M=8;
% tmp = (0:N-1) * delta_y;
% posv = tmp - mean(tmp);
% tmp = reshape( posv(ones(1,M),:).' , 1 , [] );
% antenna_position(:,3) = reshape(tmp(ones(2,1),:).',1,[]);
% 
% theta1 = [-180 -135 -90 -45 0 45 90 135];
% for i = 1:length(theta1)
%     theta((i-1)*8+1:i*8) = theta1(i);
% end
% for i = 1:h_qd_arrayant.no_elements
%     if (mod(i,2) == 0)
%         antenna_position(i,1:2) = antenna_position(i-1,1:2);
%     else
%         antenna_position(i,1:2) = [radius*cosd(theta(i)),radius*sind(theta(i))]; %天线元件的位置矢量
%     end
% end
% antenna_position_v = antenna_position(1:2:end,:);
% antenna_position_h = antenna_position(2:2:end,:);
% antenna_position = zeros(64,3);
% count = 0;
% for i = 1:64
%     if mod(i,8) == 1
%         count = count + 1;
%         antenna_position((count-1)*8+1:(count-1)*8+4,:) = antenna_position_v((count-1)*4+1:count*4,:);
%         antenna_position((count-1)*8+5:count*8,:) = antenna_position_h((count-1)*4+1:count*4,:);
%     end
% end   

antenna_position = zeros(h_qd_arrayant.no_elements,3);
% Set vertical positions
N = 8;M=8;
tmp = (0:N-1) * delta_y;
posv = tmp - mean(tmp);
tmp = reshape( posv(ones(1,M),:).' , 1 , [] );
antenna_position(:,3) = tmp;

theta1 = [-180 -135 -90 -45 0 45 90 135];
for i = 1:length(theta1)
    theta((i-1)*8+1:i*8) = theta1(i);
end
for i = 1:h_qd_arrayant.no_elements
      antenna_position(i,1:2) = [radius*cosd(theta(i)),radius*sind(theta(i))]; %天线元件的位置矢量
end

% figure;stem3(antenna_position(1,1),antenna_position(1,2),antenna_position(1,3),'r*')
% hold on;stem3(antenna_position(:,1),antenna_position(:,2),antenna_position(:,3),'bo')
% hold on;stem3(antenna_position(9,1),antenna_position(9,2),antenna_position(9,3),'md')
% xlabel('x');ylabel('y');zlabel('z')
h_qd_arrayant.element_position  = antenna_position';

% h_qd_arrayant.Fa                = permute(squeeze(f_rx(:,1,:,:)),[3 2 1]);
% h_qd_arrayant.Fb                = permute(squeeze(f_rx(:,2,:,:)),[3 2 1]);
% 
% h_qd_arrayant.Fa = h_qd_arrayant.Fa(end:-1:1,[91:180,1:91],:);
% h_qd_arrayant.Fb = h_qd_arrayant.Fb(end:-1:1,[91:180,1:91],:);

h_qd_arrayant.elevation_angle    = 0;
h_qd_arrayant.azimuth_angle      = 0;
end
