function val = acfi( h_sos, dist )
%ACFI Linear interpolation of the ACF
%
% Calling object:
%   Single object
%
% Input:
%   dist
%   Vector containing the distances in [m] for which the ACF should be interpolated.
%
% Output:
%   val
%   Interpolated ACF at the given distances

if numel( h_sos ) > 1 
   error('qd_sos:acfi','acfi not definded for object arrays.');
else
    h_sos = h_sos(1,1); % workaround for octave
end

s   = size( dist );
D   = reshape( dist, 1,[] );
D( D>h_sos.dist(end) ) = h_sos.dist(end);
val = mf.interp( h_sos.dist, 0, h_sos.acf, D );
val = reshape( val,s );

end
