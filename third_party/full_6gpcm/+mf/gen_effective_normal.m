function [azimuth, elevation] = gen_effective_normal(dT0 ,phiT_A0, phiT_E0)
%------------------------------------------------------------------------------
% GEN_EFFECTIVE_NORMAL: Generate the effective normal of a cluster
% Note: the time evolution of the effective normal is not considered
%------------------------------------------------------------------------------
% Input:
% phiT_A, phiT_E: AAoD and EAoD of a cluster
% phiR_A, phiR_E: AAoA and EAoA of a cluster
%
% Output:
% azimuth, elevation: azimuth and elevation angle of the effective normal
%------------------------------------------------------------------------------

x = dT0.*cos(phiT_A0).*cos(phiT_E0);

[AAoA, EAoA] = mf.cal_Rx_angle_from_Tx(phiT_A0, phiT_E0, x, dT0);

azimuth = mod(AAoA+pi, 2*pi);
%elevation = -EAoA;
elevation = mod(-EAoA, 2*pi);


end