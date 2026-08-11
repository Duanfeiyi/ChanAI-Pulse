function init( h_sos, use_same )
%INIT Initializes the random phases
%
% Calling object:
%   Object array
%
% Input:
%   use_same
%   If set to 1 (default), identical phases are used for the dual-mobility option, assuming that
%   devices are on the same radio-map. If set to 0, different values are used.


if ~exist( 'use_same','var' ) 
    use_same = true;
end

if numel(h_sos) > 1
    
    sic = size( h_sos );
    prc = false( sic );
    for n = 1 : prod( sic )
        if ~prc( n )
            [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
            init( h_sos(i1,i2,i3,i4), use_same );
            prc( qf.eqo( h_sos(i1,i2,i3,i4), h_track ) ) = true;
        end
    end
    
else
    if use_same
        h_sos(1,1).sos_phase = single( 2*pi*(rand(h_sos(1,1).no_coefficients,1)-0.5) ) * single([1,1]);
    else
        h_sos(1,1).sos_phase = single( 2*pi*(rand(h_sos(1,1).no_coefficients,2)-0.5) );
    end
end

end
