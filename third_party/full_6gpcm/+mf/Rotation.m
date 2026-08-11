function [R_Y,R_Z] = Rotation(beta,alpha)

R_Y = [cos(beta) 0 sin(beta)
    0 1 0
    -sin(beta) 0 cos(beta)];
R_Z = [cos(alpha) -sin(alpha) 0
    sin(alpha) cos(alpha) 0
     0 0 1];