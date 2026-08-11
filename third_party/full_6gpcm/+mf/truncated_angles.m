function z=truncated_angles(l,u,N,mean,var)
%--------------------------------------------------------------------------
% TRUNCATED_ANGLES: Generate angles following truncated Gaussian distribution
%--------------------------------------------------------------------------
% Input:
% l: maximum angle
% u: minimum angle
% N: the number of angles that need to be generated
% mean: mean value
% var: angular spread
%
% Output:
% z: angles following truncated Gaussian distribution
%--------------------------------------------------------------------------
tmax=repmat(l,N,1);
tmin=repmat(u,N,1);
x=mf.trandn((tmin-mean)/var,(tmax-mean)/var);
z=mean+var.*x;
end
