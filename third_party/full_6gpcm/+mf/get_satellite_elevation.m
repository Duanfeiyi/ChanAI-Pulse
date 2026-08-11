function EOA = get_satellite_elevation(tx_track, rx_track)
tx_pos = tx_track.positions;
rx_pos = rx_track.positions;

d_2d = hypot( tx_pos(:,1) - rx_pos(:,1), tx_pos(:,2) - rx_pos(:,2) );
d_2d( d_2d<1e-5 ) = 1e-5;

%计算收发端之间的角度
angles = zeros( length(d_2d),4);
angles(:,1) = atan2( rx_pos(:,2) - tx_pos(:,2) , rx_pos(:,1) - tx_pos(:,1) );           % Azimuth at BS
angles(:,2) = mod( pi + angles(:,1) + 3.141592653589792, 2*pi ) - 3.141592653589792;    % Azimuth at MT
angles(:,3) = atan( ( rx_pos(:,3) - tx_pos(:,3) ) ./ d_2d );                            % Elevation at BS
angles(:,4) = -angles(:,3);                                                             % Elevation at MT
%angles = angles.';
EOA = angles(:,4)*180/pi;
end