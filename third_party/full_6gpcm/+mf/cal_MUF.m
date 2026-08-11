function [MUF_E, MUF_F1, MUF_F2]=cal_MUF(latitude,solar_declination,Fai12,R12,SZA,hour)
%%  计算MUF_E
    if abs(latitude-solar_declination)<deg2rad(80)
        N = latitude - solar_declination;
    else
        N = deg2rad(80);
    end

    if abs(latitude)<deg2rad(32)
        m = -1.93 + 1.92*cos(latitude);
        X = 23;
        Y = 116;
    else
        m = 0.11 - 0.49*cos(latitude);
        X = 92;
        Y = 35;
    end
    
    if SZA<=deg2rad(73)
        if latitude<deg2rad(12)
            p = 1.31;
        else
            p = 1.2;
        end
        D = cos(SZA)^p;
    elseif (deg2rad(73)<SZA)&&(SZA<=deg2rad(90))
        temp_delta = 6.27*1e-13*(SZA-50)^8;
        D = cos(SZA-temp_delta)^p;
    else
        if latitude<deg2rad(12)
            p = 1.31;
        else
            p = 1.2;
        end
        D = (0.72)^p*exp(-1.4*(hour-18));
    end

    A = 1+0.0094*(Fai12-66);
    B = cos(N)^m;
    C = X +Y*cos(latitude);

    MUF_E = sqrt(sqrt(A*B*C*D));

%%  计算MUF_F1
    fs0 = 4.35+0.0058*abs(rad2deg(latitude))-0.00012*abs(rad2deg(latitude))^2;
    fs100 = 5.35+0.11*abs(rad2deg(latitude))-0.00023*abs(rad2deg(latitude))^2;
    q = 0.093+0.00461*abs(rad2deg(latitude))-0.000054*abs(rad2deg(latitude))^2+0.00031*R12;
    SZA_X = 50.0 + 0.348*abs(rad2deg(latitude))+0.01*(-11.3+0.161*abs(rad2deg(latitude)))*R12;

    fs = fs0+0.01*(fs100-fs0);

    MUF_F1 = fs*(cos(deg2rad(SZA_X)))^q;

%%  计算MUF_F2 
% http://www.sepc.ac.cn/cgyFof2.php  网站可查询
% 经验公式
    w = 0.2435;
    MUF_F2 = 8.1187 - 3.4652*cos(hour*w) - 0.9652*sin(hour*w) + 0.1621*cos(2*hour*w) - 0.1525*sin(2*hour*w) + 0.4139*cos(3*hour*w) + 0.4248*sin(3*hour*w);

end