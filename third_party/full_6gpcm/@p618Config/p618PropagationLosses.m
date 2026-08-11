function [pl,xpd,tsky] = p618PropagationLosses(cfg,varargin)
%p618PropagationLosses Propagation losses as per ITU-R P.618
%   [PL,XPD,TSKY] = p618PropagationLosses(CFG) returns a structure PL with
%   fields as propagation losses, cross-polarization discrimination XPD in
%   dB, and sky noise temperature TSKY in kelvin, calculated as per the
%   ITU-R P.618 recommendation.
%
%   PL is a structure containing the fields:
%   Ag - Gaseous attenuation (in dB)
%   Ac - Cloud and fog attenuation (in dB)
%   Ar - Rain attenuation (in dB)
%   As - Attenuation due to tropospheric scintillation (in dB)
%   At - Total atmospheric attenuation (in dB)
%
%   CFG is a P.618 configuration object as described in <a href="matlab:help('p618Config')">p618Config</a>.
%
%   This function requires MAT-files with digital maps from ITU documents.
%   If they are not available on the path, download and uncompress the data
%   files from
%   https://www.mathworks.com/supportfiles/spc/P618/ITURDigitalMaps.tar.gz
%   to a location on the MATLAB path.
%
%   [PL,XPD,TSKY] = p618PropagationLosses(...,NAME,VALUE,...) specifies
%   additional name-value pair arguments described below. When a name-value
%   pair is not specified, its default value is used.
%   
%   'StationHeight' - Height of the earth station above mean sea level (in
%   km). If local data is not available as input, its value is obtained 
%   using digital maps in ITU-R P.1511.
%   
%   'Temperature' - Temperature at the surface of the earth, in kelvin. If
%   local data is not available as an input, its value is obtained using
%   the map of mean annual surface temperature in ITU-R P.1510.
%
%   'Pressure' - Dry air pressure at the surface of the earth (in hPa). If 
%   local data is not available as an input, its value is obtained from the
%   mean annual global reference atmosphere in ITU-R P.835 recommendation.
%
%   'WaterVaporDensity' - Surface water vapor density (in g/m^3). If local
%   data is not available as an input, its value is estimated using 
%   digital maps in ITU-R P.836.
%
%   'IntegratedWaterVaporContent' - Integrated water vapor content exceeded
%   for GasAnnualExceedance% of an average year (kg/m^2 or mm). If local
%   data is not available as input, its value is obtained from the digital
%   maps in recommendation ITU-R P.836.
%
%   'TotalColumnarContent' - Total columnar content of cloud liquid water
%   (kg/m^2 or mm). If local data is not available as input, total columnar
%   content of reduced cloud liquid water (kg/m^2) exceeded for
%   GasAnnualExceedance%  of an average year is estimated from the digital
%   maps in recommendation ITU-R P.840.
%
%   'RainRate' - Point rainfall rate for the location for 0.01% of an 
%   average year (mm/hr). If local data is not available as input, its
%   value is estimated from the digital maps in recommendation ITU-R P.837.
%
%   'WetSurfaceRefractivity' - Median value of the wet term of the surface
%   refractivity (ppm). If local data is not available as input, its value
%   is obtained from the digital maps in recommendation ITU-R P.453.
%
%   'MeanRadiatingTemperature' - Atmospheric mean radiating temperature (in
%   kelvin). If it is not available as input, an atmospheric mean radiating
%   temperature of 275K will be used.
%
%   Example 1:
%   % Calculate the propagation losses, xpd and sky noise temperature.
%   cfg = p618Config; %P.618 configuration object with default properties
%   [pl,xpd,tsky] = p618PropagationLosses(cfg)
%
%   Example 2:
%   % Calculate the propagation losses in a light rainfall of 1 mm/hr for 
%   % a 20 GHz signal.
%
%   cfg = p618Config('Frequency', 20e9);
%   pl =  p618PropagationLosses(cfg,'RainRate',1)
%
%   Example 3:
%   % Calculate the propagation losses for a 0.001% TotalAnnualExceedance
%   % and 0.01% RainAnnualExceedance with a station height of 412 meters.
%
%   cfg = p618Config('RainAnnualExceedance', 0.01,...
%                   'TotalAnnualExceedance', 0.001);
%   pl =  p618PropagationLosses(cfg,'StationHeight',0.412)
%
%   Example 4:
%   % Calculate the propagation losses, cross-polarization discrimination
%   % and sky noise temperature for a 0.5% GasAnnualExceedance and 0.2%
%   % CloudAnnualExceedance.
%
%   cfg = p618Config('GasAnnualExceedance', 0.5,...
%                   'CloudAnnualExceedance', 0.2);
%   [pl,xpd,tsky] =  p618PropagationLosses(cfg)
%
%   See also p618Config, p618SiteDiversityOutage, p618SiteDiversityConfig.

%   Copyright 2019-2020 The MathWorks, Inc.

% References
% [1] International Telecommunication Union, ITU-R Recommendation P.618 (12/2017)
% [2] International Telecommunication Union, ITU-R Recommendation P.676 (08/2019)
% [3] International Telecommunication Union, ITU-R Recommendation P.1511 (08/2019)
% [4] International Telecommunication Union, ITU-R Recommendation P.1510 (06/2017)
% [5] International Telecommunication Union, ITU-R Recommendation P.836 (12/2017)
% [6] International Telecommunication Union, ITU-R Recommendation P.840 (08/2019)
% [7] International Telecommunication Union, ITU-R Recommendation P.837 (06/2017)
% [8] International Telecommunication Union, ITU-R Recommendation P.453 (08/2019)
% [9] International Telecommunication Union, ITU-R Recommendation P.839 (09/2013)
% [10] International Telecommunication Union, ITU-R Recommendation P.835 (12/2017)
% [11] International Telecommunication Union, ITU-R Recommendation P.838 (03/2005)

%#codegen
narginchk(1,19);

% Validate configuration object
validateattributes(cfg,{'p618Config'},{'scalar'},mfilename,'P.618 configuration object');

if coder.target('MATLAB')
    coder.internal.errorIf(~exist('maps.mat','file'),...
        'MATFileNotFound');
    coder.internal.errorIf(~exist('p836.mat','file'), ...
        'MATFileNotFound');
    coder.internal.errorIf(~exist('p837.mat','file'), ...
        'MATFileNotFound');
    coder.internal.errorIf(~exist('p840.mat','file'), ...
        'MATFileNotFound');
end

% Load digital maps from the MAT files
persistent iturMaps p836Maps p837Maps p840Maps
if isempty(iturMaps)||isempty(p836Maps)||isempty(p837Maps)||isempty(p840Maps)
    iturMaps = load('maps.mat');
    p836Maps = load('p836.mat');
    p837Maps = load('p837.mat');
    p840Maps = load('p840.mat');
end
digitalMaps.R001 = iturMaps.R001;
digitalMaps.p1510 = iturMaps.p1510;
digitalMaps.p1511 = iturMaps.p1511;
digitalMaps.p453 = iturMaps.p453;
digitalMaps.p839 = iturMaps.p839;
digitalMaps.p836 = p836Maps;
digitalMaps.p837 = p837Maps;
digitalMaps.p840 = p840Maps;

% Parse and validate optional name-value input arguments
opts = validateOptionalInputArgs(cfg,digitalMaps,varargin{:});

pl = struct('Ag',0,'Ac',0,'Ar',0,'As',0,'At',0);

% Gaseous attenuation due to water vapor and oxygen
pl.Ag = earthSpaceGasAtt(cfg,opts);
% Cloud and fog attenuation
pl.Ac = earthSpaceFogAtt(cfg,opts);
% Attenuation due to rain
opts.Exceedance = cfg.RainAnnualExceedance;
pl.Ar = earthSpaceRainAtt(cfg,opts,digitalMaps);
% Attenuation due to tropospheric scintillation
opts.Exceedance = cfg.ScintillationAnnualExceedance;
pl.As = earthSpaceScintAtt(cfg,opts);

% Estimation of total attenuation with rain, gas, clouds and scintillation
if cfg.TotalAnnualExceedance < 1
    % Ac(CloudAnnualExceedance)= Ac(1%) for CloudAnnualExceedance < 1% and
    % Ag(GasAnnualExceedance)= Ag(1%) for GasAnnualExceedance < 1%, due to
    % the fact that a large part of the cloud attenuation and gaseous
    % attenuation is already included in the rain attenuation prediction
    % for exceedance percentages below 1%.
    cfg.GasAnnualExceedance = 1;
    cfg.CloudAnnualExceedance = 1;
else
    cfg.GasAnnualExceedance = cfg.TotalAnnualExceedance;
    cfg.CloudAnnualExceedance = cfg.TotalAnnualExceedance;
end

% Parse and validate exceedance dependent optional name-value input arguments 
optsExceedance = validateExceedanceDependantArgs(cfg,digitalMaps,varargin{:});
opts.WaterVaporDensity = optsExceedance.WaterVaporDensity;
opts.IntegratedWaterVaporContent = optsExceedance.IntegratedWaterVaporContent;
opts.TotalColumnarContent = optsExceedance.TotalColumnarContent;
    
% Gaseous attenuation for the estimation of total attenuation
Ag = earthSpaceGasAtt(cfg,opts);
% Cloud and fog attenuation for the estimation of total attenuation
Ac = earthSpaceFogAtt(cfg,opts);
% Rain attenuation for the estimation of total attenuation
opts.Exceedance = cfg.TotalAnnualExceedance;
Ar = earthSpaceRainAtt(cfg,opts,digitalMaps);
% Scintillation attenuation for the estimation of total attenuation
As = earthSpaceScintAtt(cfg,opts);
% Total attenuation with rain, gas, clouds and scintillation attenuation
pl.At = Ag+sqrt((Ar+ Ac)^2+(As)^2); % eq(60)in ITU-R P.618

% Cross-polarization discrimination
xpd = earthSpaceXPD(cfg,pl.Ar);

% Total atmospheric attenuation excluding scintillation fading
A = Ag+(Ar+ Ac);
% Sky noise temperature
tsky = skynoise(A,opts);

end

function Ac = earthSpaceFogAtt(cfg,opts)
%Cloud attenuation calculation as per ITU-R P.840

% Cloud liquid water specific attenuation coefficient
Kl = fogatt(cfg.Frequency,0,opts.localColumnarData);
lred = opts.TotalColumnarContent;
% Slant path cloud attenuation
Ac = lred*Kl/sind(cfg.ElevationAngle);

end

function Ag = earthSpaceGasAtt(cfg,opts)
%Gaseous attenuation calculation as per ITU-R P.676

hs = opts.StationHeight;
rou = opts.WaterVaporDensity;
T = opts.Temperature;
Tc = T-273.15;
pr = 100*opts.Pressure;
% Specific attenuation (dB/km) due to dry air (oxygen, pressure-induced
% nitrogen and non-resonant Debye attenuation)
[gammao,~] = gasatt(cfg.Frequency,Tc,pr,rou);
% Integrated water vapor content
Vt = opts.IntegratedWaterVaporContent;
% Frequency in GHz
fGHz = cfg.Frequency/1e9;

fRef = 20.6;
pRef = 100*845;
rouRef = Vt/2.38;
TRef = 14*log(0.22*Vt/2.38)+3;
% Specific attenuation due to water vapor
[~,gammaw] = gasatt(cfg.Frequency,TRef,pRef,rouRef);
[~,gammawRef] = gasatt(fRef*1e9,TRef,pRef,rouRef);

a = 0.2048*exp(-((fGHz-22.43)/3.097)^2) + ...
    0.2326*exp(-((fGHz-183.5)/4.096)^2) +...
    0.2073*exp(-((fGHz-325)/3.651)^2)-0.1113;
b = 8.741e4*exp(-0.587*fGHz)+312.2*(fGHz^-2.38)+0.723;

if hs < 0
    h = 0;
elseif (hs >= 0) && (hs <= 4)
    h = hs;
else
    h = 4;
end
% Total water-vapor attenuation can be estimated as follows,
Aw = 0;
if (fGHz >= 1) && (fGHz <= 20) && (gammawRef~=0)
    Aw = 0.0176*Vt*gammaw/gammawRef;
elseif (fGHz > 20) && (fGHz <= 350) && (gammawRef~=0)
    Aw = 0.0176*Vt*gammaw*(a*(h^b)+1)/gammawRef;
end

e = rou*T/216.7;
rp = ((pr/100)+e)/1013.25;
% For dry air, the equivalent height is calculated as,
t1 = (5.1040/(1+0.066*(rp^-2.3)))*exp(-((fGHz-59.7)/(2.87+12.4*(exp(-7.9*rp))))^2);% eq(31)
ci = [0.1597 0.1066 0.1325 0.1242 0.0938 0.1448 0.1374];
fi = [118.750334 368.498246 424.763020 487.249273....
            715.392902 773.839490 834.145546];
t2 = sum((ci.*exp(2.12*rp))./((fGHz-fi).^2+0.025*exp(2.2*rp)));% eq(32)
t3 = (0.0114*fGHz/(1+0.14*(rp^-2.6)))*...
    ((15.02*(fGHz^2)-1353*fGHz+5.333*1e4)/((fGHz^3)-151.3*(fGHz^2)+9629*fGHz-6803));% eq(33)
A = 0.7832+0.00709*(T-273.15);% eq(34)
ho = (6.1*A/(1+0.17*(rp^-1.1)))*(1+t1+t2+t3); % eq(30)
thrshld = 10.7*(rp^0.3);

coder.internal.errorIf((fGHz < 70 && ho > thrshld),...
  'InvalidGasAttEquivalentHeight',thrshld,fGHz);

Ao = gammao*ho; 
Ag = (Ao+Aw)/(sind(cfg.ElevationAngle));% eq(41)

end

function As = earthSpaceScintAtt(cfg,opts)
%Attenuation due to tropospheric scintillation calculation as per ITU-R
%P.618

% Height of the turbulent layer
hL = 1000 ;
% Frequency in GHz
fGHz =  cfg.Frequency/1e9;
% Wet term of the radio refractivity, Nwet
Nwet = opts.WetSurfaceRefractivity;
% Calculation of the standard deviation of the reference signal amplitude
sigmaRef = 3.6e-3 + 1e-4 * Nwet;
% Calculation of the effective path length
L = (2*hL)/(sqrt((sind(cfg.ElevationAngle)^2) + 2.35e-4) + sind(cfg.ElevationAngle));
% Estimate the effective antenna diameter
Deff = sqrt(cfg.AntennaEfficiency) * cfg.AntennaDiameter;
% Calculation of the antenna averaging factor 'gx' and the fade depth, As,
% exceeded for ScintillationAnnualExceedance% of the time:
x = 1.22 * (Deff^2) * fGHz/L;
arg = 3.86 * (x^2 + 1)^(11/12) * sind((11 * atand(1/x))/6) - 7.08 * x^(5/6);
if arg < 0
    As = 0;
    return;
else
    gx = sqrt(arg);
    % Standard deviation of the signal for the applicable period and
    % propagation path
    sigma = sigmaRef * (fGHz^(7/12)) * gx/(sind(cfg.ElevationAngle)^1.2);
    % Calculate the time percentage factor 'ap'
    ap = -0.061 * (log10(opts.Exceedance )^3) +...
        0.072*(log10(opts.Exceedance )^2) -1.71 * log10(opts.Exceedance )+ 3;
    % Calculate the fade depth exceeded for ScintillationAnnualExceedance% of the time:
    As = ap * sigma;
end

end

function tsky = skynoise(A,opts)
%Sky noise temperature calculation at a ground station antenna as per 
%ITU-R P.618

tmr = opts.MeanRadiatingTemperature;
tsky = tmr*(1-10^(-A/10))+2.7*10^(-A/10);

end

function xpd = earthSpaceXPD(cfg,Ap)
%Cross-polarization discrimination calculation as per ITU-R P.618

if Ap == 0
    xpd = 0;
    return;
end

% For less than 4 GHz frequencies, the nearest valid value is used
if cfg.Frequency < 4e9
    cfg.Frequency = 4e9;
    mf.add_logs('p618PropagationLosses', 'For less than 4 GHz frequencies, cfg.Frequency = 4e9');
end

% Frequency in GHz
fGHz = cfg.Frequency/1e9;

% Frequency scaling formula is used to calculate the XPD  between 4 and
% 6 GHz. Cross-polarization statistics calculated for 6 GHz is scaled to
% a lower frequency between 4 and 6 GHz.
scaleXPD = false; %Flag to enable the frequency scaling in 4 to 6 GHz
if fGHz >= 4 && fGHz < 6
    fGHz = 6;
    scaleXPD = true;
end

% Frequency-dependent term
if fGHz >= 9 && fGHz < 36
    Cf = 26*log10(fGHz)+4.1;
elseif fGHz >= 36 && fGHz <= 55
    Cf = 35.9*log10(fGHz)-11.3;
else
    Cf = 60*log10(fGHz)-28.3;
end

% Rain attenuation dependent term
if fGHz >= 9 && fGHz < 20
    V = 12.8*fGHz^(0.19);
elseif fGHz >= 20 && fGHz < 40
    V = 22.6;
elseif fGHz >= 40 && fGHz <= 55
    V = 13.0*fGHz^(0.15);
else
    V = 30.8*fGHz^(-0.21);
end
Ca = V*log10(Ap);

% Polarization improvement factor
Ctau = -10*log10(1-0.484*(1+cosd(4*cfg.PolarizationTiltAngle)));
% Elevation angle-dependent term
Ctheta = -40*log10(cosd(cfg.ElevationAngle));

% Effective standard deviation of the raindrop canting angle distribution,
% expressed in degrees
if cfg.RainAnnualExceedance >= 0.1 && cfg.RainAnnualExceedance < 1
    sigma = 5;
elseif cfg.RainAnnualExceedance >= 0.01 && cfg.RainAnnualExceedance < 0.1
    sigma = 10;
elseif cfg.RainAnnualExceedance >= 0.001 && cfg.RainAnnualExceedance < 0.01
    sigma = 15;
else
    sigma = 0;
end

% Canting angle dependent term:
Csigma = 0.0053*sigma^2;
% Rain XPD not exceeded for RainAnnualExceedance% of the time:
XPDrain = Cf-Ca+Ctau+Ctheta+Csigma;
% Ice crystal dependent term:
Cice = XPDrain*(0.3+0.1*log10(cfg.RainAnnualExceedance))/2;
% XPD not exceeded for RainAnnualExceedance% of the time, including the
% effects of ice
xpd = XPDrain-Cice;

if scaleXPD
    % Long-term XPD statistics obtained at one frequency and polarization
    % tilt angle can be scaled to another frequency and polarization tilt
    % angle using a semi-empirical formula
    xpd1 = xpd;
    f1 = fGHz;
    f2 = (cfg.Frequency)/1e9;
    tau = cfg.PolarizationTiltAngle;
    xpd2 = xpd1-20*log10((f2*sqrt(1-0.484*(1+cosd(4*tau))))...
        /(f1*sqrt(1-0.484*(1+cosd(4*tau)))));
    xpd = xpd2;
end

end

function [gammao,gammaw] = gasatt(f,Tc,p,den)
%Specific attenuation calculation for dry air and moist air as per ITU-R
%P.676

fGHz = f(:).'/1e9; % frequency in GHz
PhPa = p/100;
T = Tc + 273.15; % Convert C to K
theta = 300/T;
e = den*T/216.7; % eq(4) in P.676-12

[svecOxy,fmatOxy] = dryaircoeff(fGHz,theta,PhPa,e);
[svecWatvap,fmatWatvap] = watvapcoeff(fGHz,theta,PhPa,e);

d = 5.6e-4*(PhPa+e)*theta^0.8;
NDdp = fGHz*PhPa*theta.^2.*(6.14e-5./(d.*(1+(fGHz./d).^2))+...
    1.4e-12*PhPa*theta^1.5./(1+1.9e-5.*fGHz.^1.5));

gammao = sum(svecOxy.*fmatOxy);
gammao = 0.1820*fGHz.*(gammao+NDdp);

gammaw = sum(svecWatvap.*fmatWatvap);
gammaw = 0.1820*fGHz.*gammaw;

end

function [Sivec,Fimat] = watvapcoeff(fGHz,theta,PhPa,e)
%Strength of the i-th water vapor line and water vapor line shape factor 
%calculation as per ITU-R P.676 

watvaptab = [...
    % f0 ,b1 ,b2 ,b3 ,b4 ,b5 ,b6
    22.235080 ,0.1079 ,2.144 ,26.38 ,0.76 ,5.087 ,1.00 ;...
    67.803960 ,.0011 ,8.732 ,28.58 ,.69 ,4.930 ,.82 ;...
    119.995940 ,.0007 ,8.353 ,29.48 ,.70 ,4.780 ,.79 ;...
    183.310087 ,2.273 ,0.668 ,29.06 ,.77 ,5.022 ,.85 ;...
    321.225630 ,.0470 ,6.179 ,24.04 ,.67 ,4.398 ,.54 ;...
    325.152888 ,1.514 ,1.541 ,28.23 ,.64 ,4.893 ,.74 ;...
    336.227764 ,.0010 ,9.825 ,26.93 ,.69 ,.740 ,.61 ;...
    380.197353 ,11.67 ,1.048 ,28.11 ,.54 ,5.063 ,.89 ;...
    390.134508 ,.0045 ,7.347 ,21.52 ,.63 ,4.810 ,.55 ;...
    437.346667 ,.0632 ,5.048 ,18.45 ,.60 ,4.230 ,.48 ;...
    439.150807 ,.9098 ,3.595 ,20.07 ,.63 ,4.483 ,.52 ;...
    443.018343 ,.1920 ,5.048 ,15.55 ,.60 ,5.083 ,.50 ;...
    448.001085 ,10.41 ,1.405 ,25.64 ,.66 ,5.028 ,.67 ;...
    470.888999 ,.3254 ,3.597 ,21.34 ,.66 ,4.506 ,.65 ;...
    474.689092 ,1.260 ,2.379 ,23.20 ,.65 ,4.804 ,.64 ;...
    488.490108 ,.2529 ,2.852 ,25.86 ,.69 ,5.201 ,.72 ;...
    503.568532 ,.0372 ,6.731 ,16.12 ,.61 ,3.980 ,.43 ;...
    504.482692 ,.0124 ,6.731 ,16.12 ,.61 ,4.010 ,.45 ;...
    547.676440 ,.9785 ,.158 ,26.00 ,.70 ,4.500 ,1.00 ;...
    552.020960 ,.1840 ,.158 ,26.00 ,.70 ,4.500 ,1.00 ;...
    556.935985 ,497.0 ,.159 ,30.86 ,.69 ,4.552 ,1.00 ;...
    620.700807 ,5.015 ,2.391 ,24.38 ,.71 ,4.856 ,.68 ;...
    645.766085 ,.0067 ,8.633 ,18.00 ,.60 ,4.000 ,.50 ;...
    658.005280 ,.2732 ,7.816 ,32.10 ,.69 ,4.140 ,1.00 ;...   
    752.033113 ,243.4 ,.396 ,30.86 ,.68 ,4.352 ,.84 ;...
    841.051732 ,.0134 ,8.177 ,15.90 ,.33 ,5.760 ,.45 ;...
    859.965698 ,.1325 ,8.055 ,30.60 ,.68 ,4.090 ,.84 ;...
    899.303175 ,.0547 ,7.914 ,29.85 ,.68 ,4.530 ,.90 ;...
    902.611085 ,.0386 ,8.429 ,28.65 ,.70 ,5.100 ,.95 ;...
    906.205957 ,.1836 ,5.110 ,24.08 ,.70 ,4.700 ,.53 ;...
    916.171582 ,8.400 ,1.441 ,26.73 ,.70 ,5.150 ,.78 ;...
    923.112692 ,.0079 ,10.293 ,29.00 ,.70 ,5.000 ,.80 ;...
    970.315022 ,9.009 ,1.919 ,25.50 ,.64 ,4.940 ,.67 ;...
    987.926764 ,134.6 ,.257 ,29.85 ,.68 ,4.550 ,.90 ;...
    1780.000000 ,17506,.952 ,196.3 ,2.00,24.15 ,5.00 ];

Sivec = watvaptab(:,2)*1e-1*e*theta^3.5.*exp(watvaptab(:,3)*(1-theta)); % eq(3)
deltafvec = watvaptab(:,4)*1e-4.*(PhPa*theta.^watvaptab(:,5)+watvaptab(:,6)*e.*theta.^watvaptab(:,7)); % eq(6a)
deltafvec = 0.535*deltafvec+sqrt(0.217*deltafvec.^2+2.1316e-12*watvaptab(:,1).^2/theta); % eq(6b)
deltavec = zeros(size(deltafvec)); % eq(7)

fdiff = watvaptab(:,1)- fGHz;
fsum = watvaptab(:,1)+ fGHz;

Fimat = ((deltafvec-(deltavec.*fdiff))./(fdiff.^2+deltafvec.^2))+...
    ((deltafvec-(deltavec.*fsum))./(fsum.^2+deltafvec.^2));

Fimat = (fGHz./watvaptab(:,1)).*Fimat; % eq(5)

end

function [Sivec,Fimat] = dryaircoeff(fGHz,theta,PhPa,e)
%Strength of the i-th oxygen line and oxygen line shape factor calculation
%as per ITU-R P.676 

oxytab = [...
    % f0 ,a1 ,a2 ,a3 ,a4 ,a5 ,a6
    50.474214 ,0.975 ,9.651 ,6.690 ,0.0 ,2.566 ,6.850 ;...
    50.987745 ,2.529 ,8.653 ,7.170 ,0.0 ,2.246 ,6.800 ;...
    51.503360 ,6.193 ,7.709 ,7.640 ,0.0 ,1.947 ,6.729 ;...
    52.021429 ,14.320 ,6.819 ,8.110 ,0.0 ,1.667 ,6.640 ;...
    52.542418 ,31.240 ,5.983 ,8.580 ,0.0 ,1.388 ,6.526 ;...
    53.066934 ,64.290 ,5.201 ,9.060 ,0.0 ,1.349 ,6.206 ;...
    53.595775 ,124.600 ,4.474 ,9.550 ,0.0 ,2.227 ,5.085 ;...
    54.130025 ,227.300 ,3.800 ,9.960 ,0.0 ,3.170 ,3.750 ;...
    54.671180 ,389.700 ,3.182 ,10.370 ,0.0 ,3.558 ,2.654 ;...
    55.221384 ,627.100 ,2.618 ,10.890 ,0.0 ,2.560 ,2.952 ;...
    55.783815 ,945.300 ,2.109 ,11.340 ,0.0 ,-1.172 ,6.135 ;...
    56.264774 ,543.400 ,0.014 ,17.030 ,0.0 ,3.525 ,-0.978 ;...
    56.363399 ,1331.800 ,1.654 ,11.890 ,0.0 ,-2.378 ,6.547 ;...
    56.968211 ,1746.600 ,1.255 ,12.230 ,0.0 ,-3.545 ,6.451 ;...
    57.612486 ,2120.100 ,0.910 ,12.620 ,0.0 ,-5.416 ,6.056 ;...
    58.323877 ,2363.700 ,0.621 ,12.950 ,0.0 ,-1.932 ,0.436 ;...
    58.446588 ,1442.100 ,0.083 ,14.910 ,0.0 ,6.768 ,-1.273 ;...
    59.164204 ,2379.900 ,0.387 ,13.530 ,0.0 ,-6.561 ,2.309 ;...
    59.590983 ,2090.700 ,0.207 ,14.080 ,0.0 ,6.957 ,-0.776 ;...
    60.306056 ,2103.400 ,0.207 ,14.150 ,0.0 ,-6.395 ,0.699 ;...
    60.434778 ,2438.000 ,0.386 ,13.390 ,0.0 ,6.342 ,-2.825 ;...
    61.150562 ,2479.500 ,0.621 ,12.920 ,0.0 ,1.014 ,-0.584 ;...
    61.800158 ,2275.900 ,0.910 ,12.630 ,0.0 ,5.014 ,-6.619 ;...
    62.411220 ,1915.400 ,1.255 ,12.170 ,0.0 ,3.029 ,-6.759 ;...
    62.486253 ,1503.000 ,0.083 ,15.130 ,0.0 ,-4.499 ,0.844 ;...
    62.997984 ,1490.200 ,1.654 ,11.740 ,0.0 ,1.856 ,-6.675 ;...
    63.568526 ,1078.000 ,2.108 ,11.340 ,0.0 ,0.658 ,-6.139 ;...
    64.127775 ,728.700 ,2.617 ,10.880 ,0.0 ,-3.036 ,-2.895 ;...
    64.678910 ,461.300 ,3.181 ,10.380 ,0.0 ,-3.968 ,-2.590 ;...
    65.224078 ,274.000 ,3.800 ,9.960 ,0.0 ,-3.528 ,-3.680 ;...
    65.764779 ,153.000 ,4.473 ,9.550 ,0.0 ,-2.548 ,-5.002 ;...
    66.302096 ,80.400 ,5.200 ,9.060 ,0.0 ,-1.660 ,-6.091 ;...
    66.836834 ,39.800 ,5.982 ,8.580 ,0.0 ,-1.680 ,-6.393 ;...
    67.369601 ,18.560 ,6.818 ,8.110 ,0.0 ,-1.956 ,-6.475 ;...
    67.900868 ,8.172 ,7.708 ,7.640 ,0.0 ,-2.216 ,-6.545 ;...
    68.431006 ,3.397 ,8.652 ,7.170 ,0.0 ,-2.492 ,-6.600 ;...
    68.960312 ,1.334 ,9.650 ,6.690 ,0.0 ,-2.773 ,-6.650 ;...
    118.750334 ,940.300 ,0.010 ,16.640 ,0.0 ,-0.439 ,0.079 ;...
    368.498246 ,67.400 ,0.048 ,16.400 ,0.0 ,0.000 ,0.000 ;...
    424.763020 ,637.700 ,0.044 ,16.400 ,0.0 ,0.000 ,0.000 ;...
    487.249273 ,237.400 ,0.049 ,16.000 ,0.0 ,0.000 ,0.000 ;...
    715.392902 ,98.100 ,0.145 ,16.000 ,0.0 ,0.000 ,0.000 ;...
    773.839490 ,572.300 ,0.141 ,16.200 ,0.0 ,0.000 ,0.000 ;...
    834.145546 ,183.100 ,0.145 ,14.700 ,0.0 ,0.000 ,0.000 ];

Sivec = oxytab(:,2)*1e-7*PhPa*theta^3.*exp(oxytab(:,3)*(1-theta)); % eq(3)
deltafvec = oxytab(:,4)*1e-4.*(PhPa*theta.^(0.8-oxytab(:,5))+1.1*e*theta); % eq(6a)
deltafvec = sqrt(deltafvec.^2+2.25e-6); % eq(6b)
deltavec = (oxytab(:,6)+oxytab(:,7)*theta)*1e-4*(PhPa+e)*theta^0.8; % eq(7)

fdiff = oxytab(:,1)- fGHz;
fsum =  oxytab(:,1)+ fGHz;

Fimat = ((deltafvec-(deltavec.*fdiff))./(fdiff.^2+deltafvec.^2))+...
    ((deltafvec-(deltavec.*fsum))./(fsum.^2+deltafvec.^2));
Fimat = (fGHz./oxytab(:,1)).*Fimat; % eq(5)

end

function temp = p1510temp(Latitude,Longitude,digitalMaps)
%Surface mean temperature using ITU-R P.1510

% Extract the following grids from the digital maps
%  1. Latitude and longitude grids
%  2. Grid with annual mean surface temperature data
data = digitalMaps.p1510;
temp = double(interp2(data.lon,data.lat,data.temp_file,Longitude,Latitude,'linear'));

end

function Pr = p835pressure(h)
%Dry air pressure at the surface of the earth using ITU-R P.835

% Geopotential height 'hdash' from geometric height 'h'
hdash = (6356.766*h)/(6356.766+h);
Pr = 0;

% Pressure values using the mean annual global reference atmosphere
if (h < 0)
    hdash = 0;
    Pr = 1013.25*((288.15/(288.15-6.5*hdash))^(-34.1632/6.5));
    mf.add_logs('p618PropagationLosses', 'invalid height, hdash = 0;');
elseif (hdash >= 0) && (hdash <= 11)
    Pr = 1013.25*((288.15/(288.15-6.5*hdash))^(-34.1632/6.5));
elseif (11 < hdash) && (hdash <= 20)
    Pr = 226.3226*exp(-34.1632*(hdash-11)/216.65);
elseif (20 < hdash) && (hdash <= 32)
    Pr = 54.74980*(216.65/(216.65+(hdash-20)))^34.1632;
elseif (32 < hdash) && (hdash <= 47)
    Pr = 8.680422*(228.65/(228.65+(hdash-32)))^(34.1632/2.8);
elseif (47 < hdash) && (hdash <= 51)
    Pr = 1.109106*exp(-34.1632*(hdash-47)/270.65);
elseif (51 < hdash) && (hdash <= 71)
    Pr = 0.6694167*(270.65/(270.65-2.8*(hdash-51)))^(-34.1632/2.8);
elseif (71 < hdash) && (hdash <= 84.852)
    Pr = 0.03956649*(214.65/(214.65-2.0*(hdash-71)))^(-34.1632/2.0);
elseif (86 <= h) && (h <= 100)
    a0 = 95.571899;
    a1 = -4.011801;
    a2 = 6.424731e-2;
    a3 = -4.789660e-4;
    a4 = 1.340543e-6;
    Pr = exp(a0+a1*h+a2*h^2+a3*h^3+a4*h^4);
end

end

function rho = p836rho(Latitude,Longitude,p,digitalMaps,varargin)
%Surface water vapor density estimation using ITU-R P.836

% Extract the following grids from the digital maps
%  1. Latitude and longitude grids
%  2. Grid with annual values of surface water vapor density for each 
%     of the exceedance percentages,
%     [0.1 0.2 0.3 0.5 1 2 3 5 10 20 30 50 60 70 80 90 95 99]
%  3. Grid with annual water vapor scale height data. 
%  4. Grid with values of topographical height (km) above mean sea level  
%     of the surface of the earth. 
p836Maps = digitalMaps.p836;
matData = p836Maps.Rho;

rho = p836Prediction(Latitude,Longitude,p,matData,digitalMaps,varargin);

end

function vt = p836Vt(Latitude,Longitude,p,digitalMaps,varargin)
%Integrated water vapor content estimation using ITU-R P.836

% Extract the following grids from the digital maps
%  1. Latitude and longitude grids
%  2. Grid with annual values of total columnar water vapor content for
%     each of the exceedance percentages,  
%     [0.1 0.2 0.3 0.5 1 2 3 5 10 20 30 50 60 70 80 90 95 99]
%  3. Grid with values of topographical height (km) above mean sea level  
%     of the surface of the earth. 
p836Maps = digitalMaps.p836;
matData = p836Maps.Vt;

vt = p836Prediction(Latitude,Longitude,p,matData,digitalMaps,varargin);

end

function lred = p840lred(Latitude,Longitude,p,digitalMaps)
%Total columnar content of reduced cloud liquid water estimation using
%ITU-R P.840

Longitude = mod(Longitude,360);
% Extract the following grids from the digital maps
%  1. Latitude and longitude grids
%  2. Grid with annual values of total columnar content of reduced cloud 
%     liquid water for each of the exceedance percentages,  
%     [0.1 0.2 0.3 0.5 1 2 3 5 10 20 30 50 60 70 80 90 95 99]
p840Maps  = digitalMaps.p840;
matData =  p840Maps.Lred;

pList = [0.1 0.2 0.3 0.5 1 2 3 5 10 20 30 50 60 70 80 90 95 99];
ind = 0;
upperIdx = 0;

if any(pList == p)
    
    ind(1) = find(pList == p);
    lred = double(interp2(matData{2},matData{1},...
        matData{ind+2},Longitude,Latitude));
   
else
    
    upperIdx(1) = find(pList>p,1,'first');
    pabove = pList(upperIdx);
    
    lredPabove =  double(interp2(matData{2},matData{1},...
        matData{upperIdx+2},Longitude,Latitude));
    
    lowerIdx = upperIdx-1;
    pbelow = pList(lowerIdx);
   
    lredPbelow = double(interp2(matData{2},matData{1},...
        matData{lowerIdx+2},Longitude,Latitude));
    
    % Logarithmic curve fitting
    x = [log(pbelow) log(pabove)];
    y = [lredPbelow lredPabove];
    A = [sum(x.^2) sum(x.^1);sum(x.^1) sum(x.^0)];
    B = [sum(x.*y);sum(y)];
    coeff = A\B;
    
    lred = coeff(1)*log(p) + coeff(2);
    
end

end

function estRhoVt = p836Prediction(Latitude,Longitude,p,matData,digitalMaps,varargin)

% Latitude, longitude and altitude grids
lat = matData{1};
lon = matData{2};
alti = matData{3};

% Extract the grids with annual water vapor scale height data for each of
% the exceedance percentages, [0.1 0.2 0.3 0.5 1 2 3 5 10 20 30 50 60 70 80
% 90 95 99]
p836Maps = digitalMaps.p836;
vschData = p836Maps.Vsch;

% Altitude of the given location
% If local data for the height above mean sea level at the desired location
% is not available, the map in Recommendation ITU-R P.1511 is used.
temp = varargin{:};
if isempty(temp)
    alt = p1511alt(Latitude,Longitude,digitalMaps);
else
    alt = temp{1};
end
pList = [0.1 0.2 0.3 0.5 1 2 3 5 10 20 30 50 60 70 80 90 95 99];
ind = 0;
upperIdx = 0;

Longitude = mod(Longitude,360);

if any(pList == p)
    
    ind(1) = find(pList == p);
    
    datai = matData{ind+3};
    vschi = vschData{ind};
    
    dataGrid = datai.*exp(-(alt-alti)./vschi);
    
    estRhoVt = double(interp2(lon,lat,dataGrid,Longitude,Latitude));
    
else   
    upperIdx(1) = find(pList>p,1,'first');
    pabove = pList(upperIdx);
    % Load data grid for respective p%
    dataiPabove = matData{upperIdx+3};
    vschiPabove = vschData{upperIdx};
        
    dataiGridPabove = dataiPabove.*exp(-(alt-alti)./vschiPabove);
    dataPabove = double(interp2(lon,lat,dataiGridPabove,Longitude,Latitude));

    lowerIdx = upperIdx-1;
    pbelow = pList(lowerIdx);
    % Load data grid for respective p%
    dataiPbelow = matData{lowerIdx+3};
    vschiPbelow = vschData{lowerIdx};   
    
    dataiGridPbelow = dataiPbelow.*exp(-(alt-alti)./vschiPbelow);
    dataPbelow = double(interp2(lon,lat,dataiGridPbelow,Longitude,Latitude));
    
    % Logarithmic curve fitting
    x = [log(pbelow) log(pabove)];
    y = [dataPbelow dataPabove];
    A = [sum(x.^2) sum(x.^1);sum(x.^1) sum(x.^0)];
    B = [sum(x.*y);sum(y)];
    coeff = A\B;
    
    estRhoVt = coeff(1)*log(p) + coeff(2);
    
end
end

function nwet = p453nwet(Latitude,Longitude,digitalMaps)
%Median value of wet term of the surface refractivity estimation using
%ITU-R P.453

% Extract the following grids from the digital maps
%  1. Latitude and longitude grids
%  2. Grid with median value (50%) of wet term of the surface refractivity 
%     exceeded for the average year.
data = digitalMaps.p453;
nwet = double(interp2(data.LON_N,data.LAT_N,data.NWET_Annual_50,Longitude,Latitude));

end

function Kl = fogatt(f,Tc,localColumnarData)
%Cloud liquid water specific attenuation coefficient calculation as per
%ITU-R P.840

fGHz = f/1e9; % frequency in GHz
T = Tc + 273.15; % Convert Celsius to Kelvin

theta = 300/T;
epsilon0 = 77.66+103.3*(theta-1);
epsilon1 = 0.0671*epsilon0;
epsilon2 = 3.52;

fpGHz = 20.20-146*(theta-1)+316*(theta-1).^2;
fsGHz = 39.8*fpGHz;

epsilon2p = fGHz.*(epsilon0-epsilon1)./(fpGHz.*(1+(fGHz./fpGHz).^2)) + ...
    fGHz.*(epsilon1-epsilon2)./(fsGHz.*(1+(fGHz./fsGHz).^2));
epsilon1p = (epsilon0-epsilon1)./(1+(fGHz./fpGHz).^2) + ...
    (epsilon1-epsilon2)./(1+(fGHz./fsGHz).^2) + epsilon2;

eta = (2+epsilon1p)./epsilon2p;

if localColumnarData
    % cloud liquid water specific attenuation coefficient for slant paths
    % based on local measured data of the total columnar content of cloud
    % liquid water
    Kl = 0.819*((1.9479*1e-4*(fGHz).^(2.308))+...
        (2.9424*(fGHz).^(0.7436))-4.9451)./(epsilon2p.*(1+eta.*eta));%eq(14)
else
    % cloud liquid water specific attenuation coefficient for slant paths
    % based on global digital maps
    Kl = 0.819*fGHz./(epsilon2p.*(1+eta.*eta));%eq(2)
end

end

function opts = validateOptionalInputArgs(cfg,digitalMaps,varargin)
%Parse and validate optional name-value input arguments

opts =  struct('StationHeight', 0, 'Temperature',0, 'Pressure', 0, ...
    'RainRate', 0,'WetSurfaceRefractivity', 0,'MeanRadiatingTemperature',...
     0,'WaterVaporDensity',0,'IntegratedWaterVaporContent', 0,...
    'TotalColumnarContent',0,'localColumnarData',false,'Exceedance',0);

StationHeight = p1511alt(cfg.Latitude,cfg.Longitude,digitalMaps);
Temperature = p1510temp(cfg.Latitude,cfg.Longitude,digitalMaps);
Pressure = p835pressure(StationHeight);
RainRate = p837rain(cfg.Latitude,cfg.Longitude,0.01,digitalMaps);
Nwet = p453nwet(cfg.Latitude,cfg.Longitude,digitalMaps);
WaterVaporDensity = p836rho(cfg.Latitude,cfg.Longitude,cfg.GasAnnualExceedance,digitalMaps);
IntegratedWaterVaporContent = p836Vt(cfg.Latitude,cfg.Longitude,cfg.GasAnnualExceedance,digitalMaps);
TotalColumnarContent =  p840lred(cfg.Latitude,cfg.Longitude,cfg.CloudAnnualExceedance,digitalMaps);

if coder.target('MATLAB') % Simulation path
    
    % Construct input parser object 'p' 
    p = inputParser; % empty inputParser object
    addParameter(p,'StationHeight',StationHeight);
    addParameter(p,'Temperature',Temperature);
    addParameter(p,'Pressure',Pressure);
    addParameter(p,'RainRate',RainRate);
    addParameter(p,'WetSurfaceRefractivity',Nwet);
    addParameter(p,'MeanRadiatingTemperature',275);
    addParameter(p,'WaterVaporDensity',WaterVaporDensity);
    addParameter(p,'IntegratedWaterVaporContent',IntegratedWaterVaporContent);
    addParameter(p,'TotalColumnarContent',TotalColumnarContent);
    
    parse(p,varargin{:});
    opts = p.Results;
    
else % Codegen path
    nvPairs = struct('StationHeight', uint32(0), ...
        'Temperature',uint32(0), 'Pressure', uint32(0), ...
        'RainRate', uint32(0),'WetSurfaceRefractivity', uint32(0),...
        'MeanRadiatingTemperature', uint32(0),'WaterVaporDensity',uint32(0),...
        'IntegratedWaterVaporContent', uint32(0),...
        'TotalColumnarContent',uint32(0));
    % Select parsing options
    popts = struct('PartialMatching', true,...
        'CaseSensitivity',true);
    % Parse inputs
    pStruct = coder.internal.parseParameterInputs(nvPairs,popts,varargin{:});
    
    opts.StationHeight = coder.internal.getParameterValue(....
        pStruct.StationHeight, StationHeight, varargin{:});
    opts.Temperature = coder.internal.getParameterValue(....
        pStruct.Temperature, Temperature, varargin{:});
    opts.Pressure = coder.internal.getParameterValue(....
        pStruct.Pressure, Pressure, varargin{:});
    opts.RainRate = coder.internal.getParameterValue(....
        pStruct.RainRate, RainRate, varargin{:});
    opts.WetSurfaceRefractivity = coder.internal.getParameterValue(....
        pStruct.WetSurfaceRefractivity, Nwet, varargin{:});
    opts.MeanRadiatingTemperature = coder.internal.getParameterValue(....
        pStruct.MeanRadiatingTemperature, 275, varargin{:});
    opts.WaterVaporDensity = coder.internal.getParameterValue(....
        pStruct.WaterVaporDensity, WaterVaporDensity, varargin{:});
    opts.IntegratedWaterVaporContent = coder.internal.getParameterValue(....
        pStruct.IntegratedWaterVaporContent, IntegratedWaterVaporContent, varargin{:});
    opts.TotalColumnarContent = coder.internal.getParameterValue(....
        pStruct.TotalColumnarContent, TotalColumnarContent, varargin{:});
    
end
        
validateattributes(opts.StationHeight,{'double','single'},...
    {'nonempty','finite','scalar','real','<=',100},mfilename,'StationHeight');
validateattributes(opts.Temperature,{'double','single'},...
    {'nonempty','finite','scalar','real','positive'},mfilename,'Temperature');
validateattributes(opts.RainRate,{'double','single'},...
    {'nonempty','finite','scalar','real','nonnegative'},mfilename,'RainRate');
validateattributes(opts.WetSurfaceRefractivity,{'double','single'},...
    {'nonempty','finite','scalar','real','nonnegative'},mfilename,'WetSurfaceRefractivity');
validateattributes(opts.MeanRadiatingTemperature,{'double','single'},...
    {'nonempty','finite','scalar','real','nonnegative'},mfilename,'MeanRadiatingTemperature');

% Flag to check whether  local measured data of the total columnar content 
% of cloud liquid water is provided as an optional name-value input argument
opts.localColumnarData = false;
% Flags to check whether  local measured data is provided as optional
% name-value input arguments for WaterVaporDensity, StationHeight, Pressure 
% and IntegratedWaterVaporContent.
localWaterVaporDensity = false;
localStationHeight = false;
localIntegratedData= false;
localPressureData= false;

if nargin>2
    
    for ii = 1:2:length(varargin)
        if ~opts.localColumnarData
            opts.localColumnarData = strncmpi(varargin{ii},'TotalColumnarContent',4);
        end
        if ~localStationHeight
            localStationHeight = strncmpi(varargin{ii},'StationHeight',4);
        end
        if ~localWaterVaporDensity
            localWaterVaporDensity = strncmpi(varargin{ii},'WaterVaporDensity',4);
        end
        if ~localIntegratedData
            localIntegratedData = strncmpi(varargin{ii},'IntegratedWaterVaporContent',4);
        end
        if ~localPressureData
            localPressureData = strncmpi(varargin{ii},'Pressure',4);
        end
    end
    
    if localStationHeight && ~localWaterVaporDensity
        opts.WaterVaporDensity =  p836rho(cfg.Latitude,...
            cfg.Longitude,cfg.GasAnnualExceedance,digitalMaps,opts.StationHeight);
    end
    if localStationHeight && ~localIntegratedData
        opts.IntegratedWaterVaporContent =  p836Vt(cfg.Latitude,...
            cfg.Longitude,cfg.GasAnnualExceedance,digitalMaps,opts.StationHeight);
    end
    if localStationHeight && ~localPressureData
        opts.Pressure = p835pressure(opts.StationHeight);
    end
end

% Verify whether estimated water vapor density, integrated water vapor
% content and total columnar content of cloud liquid water using digital
% maps provides valid values at the specified location.
if ~localWaterVaporDensity && isnan(opts.WaterVaporDensity)
    coder.internal.error(...
        'InvalidEstimatedParameter',...
        'water vapor density','ITU-R P.836','WaterVaporDensity');
end
if ~localIntegratedData && isnan(opts.IntegratedWaterVaporContent)
    coder.internal.error(...
        'InvalidEstimatedParameter',...
        'integrated water vapor content','ITU-R P.836',...
        'IntegratedWaterVaporContent');
end
if ~opts.localColumnarData && isnan(opts.TotalColumnarContent)
    coder.internal.error(...
        'InvalidEstimatedParameter',...
        'total columnar content of cloud liquid water','ITU-R P.840',...
        'TotalColumnarContent');
end
    
validateattributes(opts.IntegratedWaterVaporContent,{'double','single'},...
    {'nonempty','finite','scalar','real','positive'},mfilename,'IntegratedWaterVaporContent');

% The reference temperature based on integrated water vapor content must be
% greater than 0 kelvin. If integrated water vapor content is less than
% 2.9356e-08, then the reference temperature will be less than or equal to
% 0 kelvin. In the above scenario, the nearest valid value of 2.9356e-08
% will be used in the computation.
if opts.IntegratedWaterVaporContent < 2.9356e-08
    opts.IntegratedWaterVaporContent = 2.9356e-08;
end

validateattributes(opts.Pressure,{'double','single'},...
    {'nonempty','finite','scalar','real','nonnegative'},mfilename,'Pressure');
validateattributes(opts.WaterVaporDensity,{'double','single'},...
    {'nonempty','finite','scalar','real','nonnegative'},mfilename,'WaterVaporDensity');
validateattributes(opts.TotalColumnarContent,{'double','single'},...
    {'nonempty','finite','scalar','real','nonnegative'},mfilename,'TotalColumnarContent');

end

function optsExceedance = validateExceedanceDependantArgs(cfg,digitalMaps,varargin)
%Parse and validate exceedance dependent optional name-value input arguments

optsExceedance =  struct('StationHeight', 0, 'Temperature',0, 'Pressure', 0, ...
    'RainRate', 0,'WetSurfaceRefractivity', 0,'MeanRadiatingTemperature', 0,...
    'WaterVaporDensity',0,'IntegratedWaterVaporContent', 0,'TotalColumnarContent',0);

StationHeight = p1511alt(cfg.Latitude,cfg.Longitude,digitalMaps);
WaterVaporDensity = p836rho(cfg.Latitude,cfg.Longitude,cfg.GasAnnualExceedance,digitalMaps);
IntegratedWaterVaporContent = p836Vt(cfg.Latitude,cfg.Longitude,cfg.GasAnnualExceedance,digitalMaps);
TotalColumnarContent =  p840lred(cfg.Latitude,cfg.Longitude,cfg.CloudAnnualExceedance,digitalMaps);

if coder.target('MATLAB') % Simulation path
    
    p = inputParser;
    addParameter(p,'StationHeight',StationHeight);
    addParameter(p,'Temperature',0);
    addParameter(p,'Pressure',0);
    addParameter(p,'RainRate',0);
    addParameter(p,'WetSurfaceRefractivity',0);
    addParameter(p,'MeanRadiatingTemperature',0);
    addParameter(p,'WaterVaporDensity',WaterVaporDensity);
    addParameter(p,'IntegratedWaterVaporContent',IntegratedWaterVaporContent);
    addParameter(p,'TotalColumnarContent',TotalColumnarContent);
    
    parse(p,varargin{:});
    optsExceedance = p.Results;
    
else % Codegen path
    nvPairs = struct('StationHeight', uint32(0), ...
        'Temperature',uint32(0), 'Pressure', uint32(0), ...
        'RainRate', uint32(0),'WetSurfaceRefractivity', uint32(0),...
        'MeanRadiatingTemperature', uint32(0),'WaterVaporDensity',...
        uint32(0),'IntegratedWaterVaporContent', uint32(0),'TotalColumnarContent',uint32(0));
    % Select parsing options
    popts = struct('PartialMatching', true,'CaseSensitivity',true);
    % Parse inputs
    pStruct = coder.internal.parseParameterInputs(nvPairs,popts,varargin{:});
    
    optsExceedance.StationHeight = coder.internal.getParameterValue(....
        pStruct.StationHeight, StationHeight, varargin{:});
    optsExceedance.WaterVaporDensity = coder.internal.getParameterValue(....
        pStruct.WaterVaporDensity, WaterVaporDensity, varargin{:});
    optsExceedance.IntegratedWaterVaporContent = coder.internal.getParameterValue(....
        pStruct.IntegratedWaterVaporContent, IntegratedWaterVaporContent, varargin{:});
    optsExceedance.TotalColumnarContent = coder.internal.getParameterValue(....
        pStruct.TotalColumnarContent, TotalColumnarContent, varargin{:});
    
end

% Flags to check whether local measured data is provided as optional
% name-value input arguments for WaterVaporDensity, StationHeight and
% IntegratedWaterVaporContent.
localWaterVaporDensity = false;
localStationHeight = false;
localIntegratedData= false;

if nargin>2
    
    for ii = 1:2:length(varargin)

        if ~localStationHeight
            localStationHeight = strncmpi(varargin{ii},'StationHeight',4);
        end
        if ~localWaterVaporDensity
            localWaterVaporDensity = strncmpi(varargin{ii},'WaterVaporDensity',4);
        end
        if ~localIntegratedData
            localIntegratedData = strncmpi(varargin{ii},'IntegratedWaterVaporContent',4);
        end
    end
    
    if localStationHeight && ~localWaterVaporDensity
        optsExceedance.WaterVaporDensity =  p836rho(cfg.Latitude,...
            cfg.Longitude,cfg.GasAnnualExceedance,digitalMaps,optsExceedance.StationHeight);
    end
    if localStationHeight && ~localIntegratedData
        optsExceedance.IntegratedWaterVaporContent =  p836Vt(cfg.Latitude,...
            cfg.Longitude,cfg.GasAnnualExceedance,digitalMaps,optsExceedance.StationHeight);
    end
    
end

validateattributes(optsExceedance.IntegratedWaterVaporContent,{'double','single'},...
    {'nonempty','finite','scalar','real','positive'},mfilename,'IntegratedWaterVaporContent');

% The reference temperature based on integrated water vapor content must be
% greater than 0 kelvin. If integrated water vapor content is less than
% 2.9356e-08, then the reference temperature will be less than or equal to
% 0 kelvin. In the above scenario, the nearest valid value of 2.9356e-08
% will be used in the computation.
if optsExceedance.IntegratedWaterVaporContent < 2.9356e-08
    optsExceedance.IntegratedWaterVaporContent = 2.9356e-08;
end

validateattributes(optsExceedance.WaterVaporDensity,{'double','single'},...
    {'nonempty','finite','scalar','real','nonnegative'},mfilename,'WaterVaporDensity');
validateattributes(optsExceedance.TotalColumnarContent,{'double','single'},...
    {'nonempty','finite','scalar','real','nonnegative'},mfilename,'TotalColumnarContent');

end

function alt = p1511alt(Latitude,Longitude,digitalMaps)
% Earth station height above mean sea level(km) using the digital maps in
% ITU-R P.1511
%
% Note: This is an internal undocumented function and its API and/or
% functionality may change in subsequent releases.

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% Extract the following grids from the digital maps
%  1. Latitude and longitude grids
%  2. Grid with values of topographical height (km) above mean sea level  
%     of the surface of the earth. 
data = digitalMaps.p1511;
alt = 1e-3*double(interp2(data.lon,data.lat,data.alt_file,Longitude,Latitude,'cubic'));

end

function [Rp,P0annual] = p837rain(Latitude,Longitude,p,digitalMaps)
% Rainfall rate exceeded for the desired annual exceedance and annual
% probability of rain as per ITU-R P.837
%
% Note: This is an internal undocumented function and its API and/or
% functionality may change in subsequent releases.

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% Extract the following grids from the digital maps
%  1. Latitude and longitude grids
%  2. Grids with monthly mean total rainfall data
%  3. Grids with the monthly mean surface temperature data
p837Maps = digitalMaps.p837;
matData = p837Maps.Rp;
latT = matData{1};
lonT = matData{2};
latMT = matData{3};
lonMT = matData{4};

% Number of days in each month
N = [31 28.25 31 30 31 30 31 31 30 31 30 31];

% Initialize the variables
T = zeros(1,12);
MT = zeros(1,12);
P0 = zeros(1,12);
r = zeros(1,12);
t = zeros(1,12);
PiiRRef = zeros(1,12);
    
for ii = 1:12
    TiiGrid = matData{ii+4};
    MiiGrid = matData{ii+16};
    % For each month number, ii,determine the monthly mean surface
    % temperatures, Tii (K),and monthly mean total rainfall, MTii (mm), at
    % the desired location (Lat, Lon) from reliable long-term local data.
    T(ii) = double(interp2(lonT,latT,TiiGrid,Longitude,Latitude,'linear'));
    MT(ii) = double(interp2(lonMT,latMT,MiiGrid,Longitude,Latitude,'linear'));
    % For each month number, ii, convert Tii (K) to tii (°C).
    t(ii)= T(ii)-273.15;
    % For each month number, ii, calculate rii
    if t(ii) >= 0
        r(ii) = 0.5874*exp(0.0883*t(ii));
    else
        r(ii) = 0.5874;
    end
    % For each month number, ii, calculate the monthly probability of rain
    P0(ii) = 100*MT(ii)/(24*N(ii)*r(ii));
    if P0(ii)>70
        P0(ii) = 70;
        r(ii) = 100*MT(ii)/(70*24*N(ii));
    end
end
% Calculate the annual probability of rain as,
P0annual = sum(N.*P0)/365.25;

% Calculate the rainfall rate at the desired annual exceedance using the
% full rainfall rate prediction method(Step 8 in P.837)
if p> P0annual
    Rp = 0;
else
    b = 0; a = 500;
    if p == 0.01
        % Extract the following grids from the digital maps
        %  1. Latitude and longitude grids
        %  2. Grid with rainfall rate for 0.01% exceedance
        data = digitalMaps.R001;
        % Rainfall rate at the 0.01% exceedance using the pre-computed map
        Rref = double(interp2(data.LON_R001,data.LAT_R001,data.R001,...
            Longitude,Latitude,'linear'));
    else
        Rref = (b+a)/2;
    end  
    
    for ii = 1:12
        PiiRRef(ii) = P0(ii)*0.5*erfc((1/sqrt(2))*(log(Rref)+0.7938-log(r(ii)))/1.26);
    end
    PRRef = sum(N.*PiiRRef)/365.25; %eq(4)
    
    % Adjust the rainfall rate, Rref, until 100*abs((PRRef/p)-1)< 0.001
    iter = 0;
    while iter< 500 && (100*abs((PRRef/p)-1)>=0.001)
        if PRRef< p
            a = Rref;
        else
            b = Rref;
        end
        Rref = (b+a)/2;
        
        for ii = 1:12
            PiiRRef(ii) = P0(ii)*0.5*erfc((1/sqrt(2))*(log(Rref)+0.7938-log(r(ii)))/1.26);
        end
        PRRef = sum(N.*PiiRRef)/365.25;
        iter = iter+1; 
        
        coder.internal.errorIf((iter == 500), ...
            'InvalidRainfallRate');
    end
    % Rainfall rate exceeded for the desired annual exceedance
    Rp = Rref;
   
end
end