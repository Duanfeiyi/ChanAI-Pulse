function [angle_ans] = cal_angle_sph_vectors(angle1_A, angle1_E, angle2_A, angle2_E)
%------------------------------------------------------------------------------
% CAL_ANGLE_SPH_VECTORS: Calculate the angle between two vectors (rad)
%------------------------------------------------------------------------------
% Input:
% angle1_A, angle1_E: azimuth and elevation angle of vector 1
% angle2_A, angle2_E: azimuth and elevation angle of vector 2
% 
% Output:
% angle_ans: the angle between vector AB and vector CD
%------------------------------------------------------------------------------

angle_ans = acos(cos(angle1_E).*cos(angle2_E).*cos(angle1_A-angle2_A)+sin(angle1_E).*sin(angle2_E));

end
    
    
    