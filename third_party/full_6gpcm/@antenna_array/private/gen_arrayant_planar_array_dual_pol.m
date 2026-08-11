function h_qd_arrayant = gen_arrayant_planar_array_dual_pol
%GEN_ARRAYANT_planar_array_dual_pol 
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

% load('tx_pattern_5.5.mat','f_tx_h','f_tx_v') ;
% % The order in the antenna domain: 4V, 4H, 4V, 4H......
% f_tx = zeros(32,2,181,91);
% count = 0;
% for i = 1:32
%     if mod(i,8) == 1
%         count = count + 1;
%         f_tx((count-1)*8+1:(count-1)*8+4,:,:,:) = f_tx_v((count-1)*4+1:count*4,:,:,:);
%         f_tx((count-1)*8+5:count*8,:,:,:) = f_tx_h((count-1)*4+1:count*4,:,:,:);
%     end
% end

h_qd_arrayant = antenna_array( [] );
h_qd_arrayant.name              = 'planar-array-dual-pol';
% h_qd_arrayant.elevation_grid    = (-90:2:90)*pi/180;
% h_qd_arrayant.azimuth_grid      = (-180:2:180)*pi/180;
h_qd_arrayant.no_elements       = 32;
h_qd_arrayant.element_position  = zeros( 3,h_qd_arrayant.no_elements );

% % Measurement antenna, dual polarization
% % The origin is (0,0), correspnding to the QuaDRiGa methods.
% delta_x = 0.029;N = 4;M = 4;
% % Set vertical positions
% tmp = (0:N-1) * delta_x;
% posv = tmp - mean(tmp);
% tmp = reshape( posv(ones(1,N),:).' , 1 , [] );
% h_qd_arrayant.element_position(2,:) = reshape(tmp(ones(2,1),:).',1,[]);
% 
% % Set horizontal positions
% tmp = (0:M-1) * delta_x;
% posh = tmp - mean(tmp);
% tmp = reshape( posh(ones(1,M),:) , 1 , [] );
% h_qd_arrayant.element_position(1,:) = reshape( tmp(ones(2,1),:).' ,1,[] );

% The origin is (0,0), correspnding to the QuaDRiGa methods.
delta_x = 0.029;N = 8;M = 4;
% Set vertical positions
tmp = (0:N-1) * delta_x;
posv = tmp - mean(tmp);
tmp = reshape( posv(ones(1,4),:).' , 1 , [] );
h_qd_arrayant.element_position(2,:) = tmp;

% Set horizontal positions
tmp = (0:M-1) * delta_x;
posh = tmp - mean(tmp);
tmp = reshape( posh(ones(1,8),:) , 1 , [] );
h_qd_arrayant.element_position(1,:) = tmp;

% The origin is the position of the first antenna.
% h_qd_arrayant.element_position(1,:) = -kron( [0;1;2;3],ones(8,1)*delta_x);
% h_qd_arrayant.element_position(2,:) = repmat([3;2;1;0]*delta_x,8,1);

% Plot the element positions
% figure;stem(h_qd_arrayant.element_position(1,:),h_qd_arrayant.element_position(2,:))
% hold on;stem(h_qd_arrayant.element_position(1,1),h_qd_arrayant.element_position(2,1),'r*')
% hold on;stem(h_qd_arrayant.element_position(1,2),h_qd_arrayant.element_position(2,2),'md')

% h_qd_arrayant.Fa                = permute(squeeze(f_tx(:,1,:,:)),[3 2 1]);
% h_qd_arrayant.Fb                = permute(squeeze(f_tx(:,2,:,:)),[3 2 1]);
% h_qd_arrayant.Fa = h_qd_arrayant.Fa(end:-1:1,[91:180,1:91],:);
% % figure;imagesc(-90:2:90,-180:2:180,squeeze(20*log10(abs(h_qd_arrayant.Fa(:,:,1).'))));colormap jet;colorbar;
% h_qd_arrayant.Fb = h_qd_arrayant.Fb(end:-1:1,[91:180,1:91],:);
% % figure;imagesc(-90:2:90,-180:2:180,squeeze(20*log10(abs(h_qd_arrayant.Fb(:,:,1).'))));colormap jet;colorbar;
% % tx1 = 10*log10(abs(h_qd_arrayant.Fa(:,:,1)).^2 + abs(h_qd_arrayant.Fb(:,:,1)).^2);
% % figure;patternCustom(tx1.',180:-2:0,-180:2:180)
%     
% % h_qd_arrayant.rotate_pattern(-180,'x');
% % tx1 = 10*log10(abs(h_qd_arrayant.Fa(:,:,1)).^2 + abs(h_qd_arrayant.Fb(:,:,1)).^2);
% % figure;patternCustom(tx1.',180:-2:0,-180:2:180)

h_qd_arrayant.elevation_angle    = 0;
h_qd_arrayant.azimuth_angle      = 0;
end
