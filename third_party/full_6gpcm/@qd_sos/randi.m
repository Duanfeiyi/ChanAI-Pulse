function [ s, h_sos ] = randi( dist_decorr, ca, imax, cb, acf_type )
%RANDI Generates spatially correlated random integers between 1 and imax
%
% Calling object:
%   None (static method)
%
% Input:
%   dist_decorr
%   Vector of decorrelation distances  [1 x M] or [ M x 1 ]
%
%   ca
%   Coordinates for the first mobile device in [m] given as [3 x N] matrix. The rows correspond to
%   the x,y and z coordinate.
%
%   imax
%   The maximum value [ 1 x 1 ]
%
%   cb
%   Coordinates for the corresponding second mobile device in [m] given as [3 x N] matrix. The rows
%   correspond to the x,y and z coordinate. This variable must either be empty or have the same
%   size as "ca".
%
%   acf_type
%   String describing the shape of the autocorrelation function and the number of sinusoids,
%   Default: 'Comb300'
%
% Output:
%   s
%   Random spatially correlated numbers [ M x N ]
%
%   h_sos
%   A handle to the used qd_sos object


s = zeros( numel( dist_decorr ), size(ca,2) );
h_sos = qd_sos([]);

if ~exist( 'cb','var' ) || isempty( cb )
   cb = []; 
end

if ~exist( 'acf_type','var' ) || isempty( acf_type )
   acf_type = 'Comb300'; 
end

for n = 1 : numel( dist_decorr )
    if dist_decorr(n) == 0
        dist_decorr(n) = 0.1;
    end
    h_sos(1,n) = qd_sos( acf_type, 'Uniform',dist_decorr(n) );
    s(n,:) = h_sos(1,n).val( ca, cb );
end

s = ceil( s * imax );

end
