function [phiR_A, phiR_E] = cal_Rx_angle_from_Tx(phiT_A, phiT_E, D, dT)
%------------------------------------------------------------------------------
% CAL_RX_ANGLE_FROM_TX: Calculate the angles of Rx from parameters of Tx side
%------------------------------------------------------------------------------
% Input:
% phiT_A, phiT_E: AAoD and EAoD of a cluster
% D: distance of LoS path from Tx to Rx
% dT: distance from Tx to the center of a cluster
%
% Output:
% phiR_A, phiR_E: AAoA and EAoA of the cluster
%------------------------------------------------------------------------------

phiR_A = pi-atan((dT.*cos(phiT_E).*sin(phiT_A))./(D-dT.*cos(phiT_E).*cos(phiT_A)));
phiR_E = atan(dT.*sin(phiT_E)./(sqrt((dT.*cos(phiT_E)).^2+D.^2-2*dT.*cos(phiT_E).*D.*cos(phiT_A))));

end

