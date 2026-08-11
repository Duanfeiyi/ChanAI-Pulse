function freq = get_Freq_SW(D)
%   D的单位是千米
%   freq的单位是 MHz
    %% Frequency Prediction Method
    % Author: Fan Lai
    %% Initialization
    f0E = 3; % E-layer critical frequency (foE) / MHz
    f0F1 = 3; % F1-layer critical frequency (foF1) / MHz
    f0F2 = 10; % F2-layer critical frequency (foF2) / MHz
    M3000F2 = 3; % Numerical representations of the monthly median ionospheric characteristics
    Fl = 0.79; % the MUF-OWF conversion factor
    n0 = 2; % the minimum hop propagation at F2-layer
    fCE = 1.119; % the magnetic rotation frequency at the midpoint of the path
    Rop = 1.2; % the ratio of working MUF and basic MUF at F2-layer
    R12 = 100; % solar-index values

    %% dmax
    x1 = max(f0F2/f0E,2);
    B = M3000F2-0.124+(M3000F2^2-4)*(0.0215+0.005*sin(7.854/x1-1.9635));
    % maximum hop length for F2 mode calculated at the mid-path control point
    dmax = 4780+(12610+2140/x1^2-49720/x1^4+688900/x1^6)*(1/B-0.303); 

    %% Basic MUF of E-Layer
    x2 = min(D/1150-1,0.74);
    ME = 3.94+2.80*x2-1.70*x2^2-0.60*x2^3+0.96*x2^4;
    E_MUF = ME * f0E;

    %% Basic MUF of F1-Layer
    J0 = 0.16+2.64*10^(-3)* D -0.40 * 10^(-6)* D^2;
    J100 = -0.52+2.69*10^(-3)* D - 0.39*10^(-6)* D^2;
    MF1 = J0-0.01*(J0-J100)*R12;
    F1_MUF = MF1 * f0F1;

    %% Basic MUF of F2-Layer
    if D <= dmax
        dn=D/n0;
        Z=1-2*dn/dmax;
        Cd=0.74-0.591*Z-0.424*Z^2-0.090*Z^3+0.088*Z^4+0.181*Z^5+0.096*Z^6;
        dn3000=3000/n0;
        Z3000=1-2*dn3000/dmax;
        C3000=0.74-0.591*Z3000-0.424*Z3000^2-0.090*Z3000^3+0.088*Z3000^4+...
            0.181*Z3000^5+0.096*Z3000^6;
        F2_MUF=(1+Cd/C3000*(B-1))*f0F2+fCE/2*(1-dn/dmax);
    else
        dn=dmax;
        Z=1-2*dn/n0;
        Cd=0.74-0.591*Z-0.424*Z^2-0.090*Z^3+0.088*Z^4+0.181*Z^5+0.096*Z^6;
        dn3000=3000/n0;
        Z3000=1-2*dn3000/dmax;
        C3000=0.74-0.591*Z3000-0.424*Z3000^2-0.090*Z3000^3+0.088*Z3000^4+...
            0.181*Z3000^5+0.096*Z3000^6;
        F2_MUF=(1+Cd/C3000*(B-1))*f0F2+fCE/2*(1-dn/dmax);
    end

    %% Operational MUF
    MUF=max([E_MUF,F1_MUF,F2_MUF*Rop]);

    %% OWF
    E_OWF=0.95*E_MUF;
    F1_OWF=0.95*F1_MUF;
    F2_OWF=Rop*F2_MUF*Fl;
    OWF=max([E_OWF,F1_OWF,F2_OWF]);
    freq = OWF;
end