function [FV,FH] = efield2FVFH(h_antenna_array,phiE,phiA,i_no_elements)
phiE = mod(floor(90-phiE),360)+1;
phiA = mod(floor(phiA),360)+1;
Etheta = reshape(diag(h_antenna_array.PFTheta(phiE,phiA,i_no_elements)),size(phiE,2),1);
Ephi = reshape(diag(h_antenna_array.PFPhi(phiE,phiA,i_no_elements)),size(phiE,2),1);
% size(Etheta)
phiE = phiE/180*pi;
phiA = phiA/180*pi;

Ex = Etheta.*cos(phiE').*cos(phiA')-Ephi.*sin(phiA');
Ey = Etheta.*cos(phiE').*sin(phiA'/180*pi)+Ephi.*cos(phiA');
Ez = -Etheta.*sin(phiE');
Eaverage = sqrt(sin((0:1:180)/180*pi)*abs(( ...
    h_antenna_array.PFTheta(:,:,i_no_elements).* ...
    conj(h_antenna_array.PFTheta(:,:,i_no_elements))+ ...
    h_antenna_array.PFPhi(:,:,i_no_elements).*conj(h_antenna_array.PFPhi(:,:,i_no_elements))))*ones(360,1))/4/pi;
% 需要先转化为全局坐标再算FH FV
E = [Ex,Ey,Ez].';
% size(Ex)
Egcs = lcs2gcs(h_antenna_array, E);

FV = abs(Egcs(3))/Eaverage;
FH = (abs(Egcs(1))+abs(Egcs(2)))/Eaverage;