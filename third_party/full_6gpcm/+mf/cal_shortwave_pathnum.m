function path_num = cal_shortwave_pathnum(fc_MHz, MUF_E, MUF_F1, MUF_F2, d_3d)

%%  判可分子径数，即天波中的簇数
if fc_MHz<MUF_E                         %小于E层最大反射频率
    E_flag = 1;
    F1_flag = 1;
    F2_flag = 1;
elseif fc_MHz>MUF_E&&fc_MHz<MUF_F1      %介于E层和F1层最大反射频率之间，E层不反射
    E_flag = 0;
    F1_flag = 1;
    F2_flag = 1;
elseif fc_MHz>MUF_F1&&fc_MHz<MUF_F2     %介于F1层和F2层最大反射频率之间，F1层不反射
    E_flag = 0;
    F1_flag = 0;
    F2_flag = 1;
else                                    %该状态下没有天波
    E_flag = 0;
    F1_flag = 0;
    F2_flag = 0;
end
try
    if d_3d>=700000&&d_3d<1200000
        path_num = E_flag;
    elseif d_3d>=1200000&&d_3d<2000000
        path_num = E_flag+F1_flag;
    elseif d_3d>=2000000&&d_3d<2400000
        path_num = 2*E_flag+F1_flag+F2_flag;
    elseif d_3d>=2400000&&d_3d<3000000
        path_num = 2*E_flag+2*F1_flag+F2_flag;
    elseif d_3d>=3000000&&d_3d<3500000
        path_num = E_flag+2*F1_flag+F2_flag;
    elseif d_3d>=3500000&&d_3d<4000000
        path_num = E_flag+F1_flag+F2_flag;
    elseif d_3d>=4000000&&d_3d<6000000
        path_num = E_flag+F1_flag+2*F2_flag;
    elseif d_3d>=6000000&&d_3d<7000000
        path_num = F1_flag+2*F2_flag;
    elseif d_3d>=7000000&&d_3d<12000000
        path_num = F2_flag;
    else
        error('The distance should larger than 700km, but less than 12000km in shortWave SkyWave scenario');
    end

    if path_num == 0
        error(['There is no propagation path for the current distance and frequency settings.' ...
            'Carrier frequency used exceeds maximum ionospheric reflection frequency']);
    end

catch ME
    % 捕获错误并弹窗提示
    uiwait(warndlg(ME.message, 'Warning', 'modal'));
    return;
end
