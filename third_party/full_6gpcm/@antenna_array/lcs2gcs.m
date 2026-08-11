function positionGCS = lcs2gcs(h_antenna_array, positionLCS)
% 局部坐标转全局坐标，以[0,0,0]为参考点
beta_z = h_antenna_array.beta_z;
beta_y = h_antenna_array.beta_y;
beta_x = h_antenna_array.beta_x;
RotaMatZ = [cos(beta_z),-sin(beta_z),0;
                sin(beta_z),cos(beta_z),0;
                0,0,1];
RotaMatY = [cos(beta_y),0,sin(beta_y);
                0,1,0;
                -sin(beta_y),0,cos(beta_y)];
RotaMatX = [1,0,0;
                0,cos(beta_x),-sin(beta_x);
                0,sin(beta_x),cos(beta_x)];
% refAntennaPos = reshape(refAntennaPos,3,1);

positionGCS = RotaMatZ*RotaMatY*RotaMatX*positionLCS + zeros(1,size(positionLCS,2));