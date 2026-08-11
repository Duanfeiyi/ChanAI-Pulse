function Ap = earthSpaceRainAtt(cfg,opts,digitalMaps)
% Rain attenuation calculation as per ITU-R P.618
%
% Note: This is an internal undocumented function and its API and/or
% functionality may change in subsequent releases.

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% Effective radius of the earth in km
Re = 8500;

% Rain height as given in Recommendation ITU-R P.839
hr = p839hr(cfg.Latitude,cfg.Longitude,digitalMaps);

% Earth station height above mean sea level(km)
hs = opts.StationHeight;

% Rainfall rate exceeded for 0.01% of an average year
rr001 = opts.RainRate;
if rr001 == 0 || (hr-hs<=0)
    Ap = 0;
    return;
end

% Elevation Angle
elev = cfg.ElevationAngle;

% Specific attenuation due to rain
gammar = rainatt(cfg.Frequency,rr001,elev,...
    cfg.PolarizationTiltAngle);

% Ls (slant-path length) calculation
if cfg.ElevationAngle >= 5
    Ls = (hr-hs)/sind(elev);
else
    Ls = 2*(hr-hs)/(sqrt(sind(elev)^2 + ...
        2*(hr-hs)/Re) + sind(elev));
end
% Lg (horizontal projection of Ls) calculation
Lg = Ls*cosd(elev);

% Horizontal reduction factor calculation (with Annual exceedance as 0.01%)
fGHz = cfg.Frequency/1e9;
r001 = 1/(1+0.78*sqrt(Lg*gammar/fGHz)-0.38*(1-exp(-2*Lg)));

% Vertical adjustment factor calculation (with Annual exceedance as 0.01%)
if abs(cfg.Latitude) < 36
    chi = 36-abs(cfg.Latitude);
else
    chi = 0;
end
zeta = atand((hr-hs)/(Lg*r001));
if zeta > elev
    Lr = Lg*r001/cosd(elev);
else
    Lr = (hr-hs)/sind(elev);
end
v001 = 1/(1+sqrt(sind(elev))*(31*...
    (1-exp(-(elev/(1+chi))))*sqrt(Lr*gammar)/(fGHz^2) - 0.45));

% Effective path length
Le = Lr*v001;

% Rain attenuation exceeded for 0.01% of an average year
A001 = gammar*Le;
% Beta calculation
if opts.Exceedance  >= 1 || abs(cfg.Latitude) >= 36
    beta = 0;
elseif opts.Exceedance < 1 && abs(cfg.Latitude) < 36 && ...
        elev >= 25
    beta = -0.005*(abs(cfg.Latitude)-36);
else
    beta = -0.005*(abs(cfg.Latitude)-36) + 1.8 - 4.25*sind(elev);
end

% Rain attenuation exceeded for other percentages of an average year
if opts.Exceedance  == 0.01
    Ap = A001;
else
    Ap = A001*(opts.Exceedance /0.01)^(-(0.655+0.033*...
        log(opts.Exceedance )-0.045*log(A001)-beta*...
        (1-opts.Exceedance )*sind(elev)));
end

end

function gamma = rainatt(f,rr,el,tau)
%Specific attenuation (dB/km) calculation as per ITU-R P.838

[kH,kV,alphaH,alphaV] = rainattcoeff(f);

k = (kH+kV+(kH-kV).*(cosd(el).^2).*cosd(2*tau))/2;

alpha = (kH.*alphaH+kV.*alphaV+...
    (kH.*alphaH-kV.*alphaV).*(cosd(el).^2).*cosd(2*tau))./(2*k);

gamma = k.*rr.^alpha;

end

function [kH,kV,alphaH,alphaV] = rainattcoeff(f)
%Coefficients kH and alphaH for horizontal polarization and coefficients kV
%and alphaV for vertical polarization as per ITU-R P.838

fGHz = f/1e9;  % convert to GHz

kHtab = [-5.33980 -0.10008 1.13098; ...
    -0.35351 1.26970 0.45400; ...
    -0.23789 0.86036 0.15354; ...
    -0.94158 0.64552 0.16817];
kHm = -0.18961;
kHc = 0.71147;

kVtab = [-3.80595 0.56934 0.81061; ...
    -3.44965 -0.22911 0.51059; ...
    -0.39902 0.73042 0.11899; ...
    0.50167 1.07319 0.27195];
kVm = -0.16398;
kVc = 0.63297;

alphaHtab = [-0.14318 1.82442 -0.55187; ...
    0.29591 0.77564 0.19822; ...
    0.32177 0.63773 0.13164; ...
    -5.37610 -0.96230 1.47828; ...
    16.1721 -3.29980 3.43990];
alphaHm = 0.67849;
alphaHc = -1.95537;

alphaVtab = [-0.07771 2.33840 -0.76284; ...
    0.56727 0.95545 0.54039; ...
    -0.20238 1.14520 0.26809; ...
    -48.2991 0.791669 0.116226; ...
    48.5833 0.791459 0.116479];
alphaVm = -0.053739;
alphaVc = 0.83433;

tempkH = (log10(fGHz)-kHtab(:,2))./(kHtab(:,3));
log10kH = sum(kHtab(:,1).*exp(-tempkH.^2))+kHm.*log10(fGHz)+kHc;
kH = 10.^log10kH;

tempkV =  (log10(fGHz)-kVtab(:,2))./(kVtab(:,3));
log10kV = sum(kVtab(:,1).*exp(-tempkV.^2))+kVm.*log10(fGHz)+kVc;
kV = 10.^log10kV;

tempalphaH = (log10(fGHz)-alphaHtab(:,2))./(alphaHtab(:,3));
alphaH = sum(alphaHtab(:,1).*exp(-tempalphaH.^2))+...
    alphaHm.*log10(fGHz)+alphaHc;

tempalphaV = (log10(fGHz)-alphaVtab(:,2))./(alphaVtab(:,3));
alphaV = sum(alphaVtab(:,1).*exp(-tempalphaV.^2))+...
    alphaVm.*log10(fGHz)+alphaVc;

end

function hr = p839hr(Latitude,Longitude,digitalMaps)
%Rain height as per ITU-R P.839

Longitude = mod(Longitude,360);

data = digitalMaps.p839;
h0 = double(interp2(data.Lon,data.Lat,data.h0,Longitude,Latitude));

hr = h0 + 0.36;
end
