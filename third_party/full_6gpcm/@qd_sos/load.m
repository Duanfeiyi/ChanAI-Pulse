function h_sos = load( filename )
%LOAD Loads coefficients from mat file
%
% Sinusoid coefficients can be stored in a mat-file by calling qd\_sos.save. This (static) method
% loads them again. In this way, it is possible to precompute the sinusoid coefficients and save
% some significant time when initializing the method. It is possible to adjust the decorrelation
% distance of a precomputed function without needing to perform the calculations again.
%
% Input:
%   filename 	Path or filename to the coefficient file. 
%
% Output:
%   h_sos   A qd_sos object.

load(filename);

h_sos                   = qd_sos([]);
h_sos.name              = filename;
h_sos.Pdist_decorr      = single( dist( find( acf < (exp(-1) + 1e-6) ,1 ) ) );
h_sos.dist              = single( dist );
h_sos.acf               = single( acf );
h_sos.sos_freq          = single( fr );
h_sos.sos_amp           = sqrt( single( 2 / size(fr,1) ) );

h_sos.init;

end

