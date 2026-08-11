function positionLCS = gcs2lcs(positionGCS,h_antenna_array,d)
% 全局坐标转局部坐标
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
% positionGCS = reshape(positionGCS,3,1);
% d = reshape(d,3,1);
positionLCS = inv(RotaMatZ*RotaMatY*RotaMatX)*(positionGCS-d);