function show_check_allsettings_Opti(app, scenario,d_Rx_min,d_Rx_mean,d_Tx_min,d_Tx_mean)
database_para = tools.database(app.CallingApp);%将数据库里的所有参数取出来
conf_filename = strcat('scen_',scenario,'.conf');
% 获取当前文件夹路径
currentFolder = fileparts(mfilename('fullpath'));
% 构建配置文件的完整路径，假设配置文件名为 'LoS.conf'
configFilePath = fullfile(currentFolder, 'config', conf_filename);
% 如果 'LoS.conf' 文件不存在，则尝试读取 'NLoS.conf'
if ~exist(configFilePath, 'file')
    configFilePath = conf_filename;
end

% 卫星仰角及多维参数
[initialPosTx, initialPosRx] = tools.get_initialPos_table(app.CallingApp);
link_pos = [ initialPosTx(1)- initialPosRx(1),  initialPosTx(2)- initialPosRx(2),  initialPosTx(3)- initialPosRx(3)];
link_eleAngle = atan2(abs(link_pos(3)),sqrt(link_pos(1).^2+link_pos(2).^2))/ pi * 180;
index_col =  min (9, max(1,round(link_eleAngle/10)));
name = ["DS_mu", "DS_sigma", "KF_mu","KF_sigma","SF_sigma","AS_D_mu","AS_D_sigma","AS_A_mu","AS_A_sigma","ES_D_mu","ES_D_sigma","ES_A_mu","ES_A_sigma","XPR_mu","XPR_sigma","r_DS","PerClusterAS_D","PerClusterAS_A","PerClusterES_A","CL"];

[scen_para, ~] = mf.read_scen_para(configFilePath);
fields = fieldnames(scen_para);
fieldValues = struct2cell(scen_para);

% 创建表格,匹配上参数的中文名
scen_para_Chinese = table(fields, fieldValues);
scen_para_Chinese = renamevars(scen_para_Chinese, {'fields', 'fieldValues'}, {'name', 'Var2'});
scen_para_Chinese = join(scen_para_Chinese, database_para, 'Keys', 'name');
%读文件，制造settings_14

% ... （您的现有代码）

% 修改需要的字段值
for i = 1:size(scen_para_Chinese, 1)
    fieldName = char(scen_para_Chinese{i,3}); % 将单元格转换为字符向量
    % 根据字段名修改相应的值
    switch fieldName
        case 'Minimum distance between the center of the last-bounce cluster and Rx [m]'
            scen_para_Chinese{i, 2} = {d_Rx_min}; % 将数值放入 cell 数组中
        case 'Average distance between the center of the last-bounce cluster and Rx [m]'
            scen_para_Chinese{i, 2} = {d_Rx_mean}; % 将数值放入 cell 数组中
        case 'Minimum distance between center point of the first-bounce cluster and Tx [m]'
            scen_para_Chinese{i, 2} = {d_Tx_min}; % 将数值放入 cell 数组中
        case 'Average distance between center point of the first-bounce cluster and Tx [m]'
            scen_para_Chinese{i, 2} = {d_Tx_mean}; % 将数值放入 cell 数组中
        % 可以根据需要添加更多的字段
    end
end

%读文件，制造settings_14
display = ' ';
for i=1:size(scen_para_Chinese, 1)
    fieldName = scen_para_Chinese{i,3};
    fieldValue = scen_para_Chinese{i,2};
    if ~isempty(strfind(scenario, app.CallingApp.sps.scenario_SATELLITE)) && ~all((strcmp(scen_para_Chinese{i,1},name))==0) && contains(conf_filename,'3GPP')
        fieldValue = cell2mat(fieldValue);
        fieldValue = string(fieldValue(index_col));
    else
    fieldValue = string(fieldValue);
    end
    display = strcat(display, fieldName,'： ',fieldValue, '\n');
end
settings_13 = sprintf('\nOther detailed channel parameters are:\n');
settings_14 = char(sprintf(display));

%%%%%%%%%%%%%%%%%%%%%%%%%读取conf文件，并显示相关参数%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%settings_10 = char(sprintf(display_1));
display_2 = ' ';
if iscell(app.CallingApp.UITable_tx.Data)
    C_tx = app.CallingApp.UITable_tx.Data;
else
    C_tx = table2cell(app.CallingApp.UITable_tx.Data);
end

for i = 1:size(C_tx, 1)
    % 使用sprintf格式化字符串
    tx_Data = sprintf('      number of Tx： %s;   name of Tx： %s;   Initial Position： %s;   Antenna number： %s;   Track Type： %s;   Velocity (m/s)： %s;   Acceleration (m/s^2)： %s;   Motion direction： %s\n', ...
        C_tx{i,1}, C_tx{i,2},C_tx{i,3}, C_tx{i,4}, C_tx{i,5}, C_tx{i,6}, C_tx{i,7}, C_tx{i,8});
    % 将格式化后的字符串添加到display_2中
    display_2 = [display_2, tx_Data];
end
% 将display_2转换为字符数组并存储在settings_11中
settings_11 = char(display_2);
settings_17 = strcat('    Number of Users at the transmitting end：  ' ,num2str(size(C_tx, 1)));

display_3 = ' ';
if iscell(app.CallingApp.UITable_rx.Data)
    C_rx = app.CallingApp.UITable_rx.Data;
else
    C_rx = table2cell(app.CallingApp.UITable_rx.Data);
end

for i=1:size(C_rx, 1)
    rx_Data = sprintf('      number of Rx： %s;   name of Rx： %s;   Initial Position： %s;   Antenna number： %s;   Track Type： %s;   Velocity (m/s)： %s;   Acceleration (m/s^2)： %s;   Motion direction： %s\n', ...
        C_rx{i,1}, C_rx{i,2},C_rx{i,3}, C_rx{i,4}, C_rx{i,5}, C_rx{i,6}, C_rx{i,7}, C_rx{i,8});
    % 将格式化后的字符串添加到display_3中
    display_3 = [display_3, rx_Data];
end
settings_12 = char(display_3);
settings_18 = strcat('    Number of users at the receiving end：  ' ,num2str(size(C_rx, 1)));
settings_15 = strcat('    Motion duration (s)：  ', num2str(app.CallingApp.trackLength.Value), '; Sampling rate (Hz)：  ',num2str(app.CallingApp.sampleRate.Value));

if tools.is_owc_band(scenario, app.CallingApp)
    settings_1 = strcat('  Frequency band,  Scenario, Transmission link status： ', app.CallingApp.scenarios);
    settings_2 = strcat('  LED color： ', app.CallingApp.LEDColor.Value, ', LED type： ', app.CallingApp.LEDType.Value);
    settings_3 = strcat('  The number of clusters： ', num2str(app.CallingApp.noCluster_6.Value), ', the number of scatterers in a cluster:', num2str(app.CallingApp.noRaysEachCluster_6.Value));
    settings_4 = strcat('  The number of subcarriers： ',num2str(app.CallingApp.freqSamples.Value));
    settings_5 = strcat('  The LED array configuration ',  num2str(app.CallingApp.noLEDRow.Value), 'rows, ', num2str(app.CallingApp.noLEDColumn.Value), 'columns, row spacing： ', num2str(app.CallingApp.spacingLEDRow.Value), '，column spacing： ', num2str(app.CallingApp.spacingLEDColumn.Value));
    settings_6 = strcat('  The LED array angle configuration： azimuth angle (row)： ',  num2str(app.CallingApp.azimuthAngleLEDRow.Value), '，elevation angle (row)： ', num2str(app.CallingApp.elevationAngleLEDRow.Value), ...
        '， azimuth angle (column)： ',  num2str(app.CallingApp.azimuthAngleLEDColumn.Value), '，elevation angle (column)： ', num2str(app.CallingApp.elevationAngleLEDColumn.Value));
    settings_7 = strcat('  The number of PD： ', num2str(1), ' , azimuth angle of PD placement： ', num2str(app.CallingApp.azimuthAnglePD.Value), ', elevation angle： ', num2str( app.CallingApp.elevationAnglePD.Value)...
        , ' , azimuth angle of PD rotation： ', num2str(app.CallingApp.PD_omegavR_A.Value), ', elevation angle： ', num2str( app.CallingApp.PD_omegavR_E.Value));

    app.CallingApp.settings.Value = {'User settings in GUI： '; settings_1; settings_2; settings_3; settings_4; settings_5; settings_6; settings_7; settings_15; settings_17;settings_11; settings_18;settings_12; settings_13; settings_14};

else
    %天线参数
    if iscell(app.CallingApp.UITable_antenna.Data)
        C_antenna = app.CallingApp.UITable_antenna.Data;
    else
        C_antenna = table2cell(app.CallingApp.UITable_antenna.Data);
    end
    display_1 = ' ';
    for i=1:size(C_antenna, 1)
        antenna_Data = sprintf('      Antenna number：%s;   name：%s;    Number of array elements(rows)：%s;     Number of array elements(columns)：%s;   Element spacing (rows)：%s;   Element spacing (column)：%s;   Z-axis rotation angle：%s;   Y-axis rotation angle：%s;   X-axis rotation angle：%s;   Polarization mode：%s;   Antenna type：%s\n', ...
            C_antenna{i,1}, C_antenna{i,2}, C_antenna{i,3}, C_antenna{i,4}, C_antenna{i,5}, C_antenna{i,6}, C_antenna{i,7}, C_antenna{i,8}, C_antenna{i,9}, C_antenna{i,10}, C_antenna{i,12});
        % 将拼接的字符串添加到display_1中
        display_1 = [display_1, antenna_Data];
    end
    settings_10 = char(display_1);
    settings_16 = strcat('   Number of configured antennas：  ' ,num2str(size(C_antenna, 1)));

    settings_7 = strcat('   Carrier frequency (GHz) ： ', num2str(app.CallingApp.EditField.Value), ' GHz, bandwidth： ', num2str(app.CallingApp.bandwidth.Value), ' MHz, the number of subcarriers： ',num2str(app.CallingApp.freqSamples.Value));
    if strfind(scenario, app.CallingApp.sps.scenario_RIS)
        settings_0 = strcat('   Frequency band,  Scenario, Transmission link status：  ', app.CallingApp.scenarios);
        settings_1 = strcat('   The configuration of RIS： ', num2str(app.CallingApp.EditField_RISx.Value), ' rows,', num2str(app.CallingApp.EditField_RISy.Value), ' columns, the row spacing： ', num2str(app.CallingApp.EditField_RISdelta_x.Value), 'times the wavelength, the column spacing： ', num2str(app.CallingApp.EditField_RISdelta_y.Value),'times the wavelength');
        settings_2 = strcat('   The height of RIS elements： ', num2str(app.CallingApp.EditField_RISheight.Value), 'times the wavelength, the width： ', num2str(app.CallingApp.EditField_RISwidth.Value), 'times the wavelength');
        settings_3 = strcat('   The central point position of RIS:[', num2str(app.CallingApp.EditField_RISposx.Value), ', ', num2str(app.CallingApp.EditField_RISposy.Value), ', ', num2str(app.CallingApp.EditField_RISposz.Value), ']');
        settings_4 = strcat('   The posture of RIS placement:[[', num2str(app.CallingApp.vectorEditField_0.Value), ', ', num2str(app.CallingApp.vectorEditField_1.Value), ', ', num2str(app.CallingApp.vectorEditField_2.Value), ']; [',...
            num2str(app.CallingApp.vectorEditField_3.Value), ', ', num2str(app.CallingApp.vectorEditField_4.Value), ', ', num2str(app.CallingApp.vectorEditField_5.Value), ']; [',...
            num2str(app.CallingApp.vectorEditField_6.Value), ', ', num2str(app.CallingApp.vectorEditField_7.Value), ', ', num2str(app.CallingApp.vectorEditField_8.Value), ']]');
        settings_5 = strcat('   the number of clusters of BS-RIS-UE： ',  num2str(app.CallingApp.noCluster_RIS1.Value), ', the number of scatterers in a cluster： ', num2str(app.CallingApp.noRaysEachCluster_RIS1.Value), ...
            '; the number of clusters of BS-UE： ',  num2str(app.CallingApp.noCluster_RIS3.Value), ', the number of scatterers in a cluster： ', num2str(app.CallingApp.noRaysEachCluster_RIS3.Value));

        app.settings.Value = {'User settings in GUI： '; settings_0; settings_1; settings_2; settings_3; settings_4; settings_5; settings_7;settings_16; settings_10;settings_15; settings_17;settings_11; settings_18;settings_12; settings_13; settings_14};

    elseif strfind(scenario, app.CallingApp.sps.scenario_MARITIME)
        settings_1 = strcat('   Frequency band,  Scenario, Transmission link status：  ', app.CallingApp.scenarios);
        settings_2 = strcat('   The number of waveguide clusters over the sea： ',  num2str(app.CallingApp.noCluster_2.Value), ', the number of scatterers in a waveguide cluster over the sea： ', num2str(app.CallingApp.noRaysEachCluster_2.Value), '; ', ...
            ' the number of sea cluster： ',  num2str(app.CallingApp.noCluster_3.Value), ', the number of scatterers in a sea cluster： ', num2str(app.CallingApp.noRaysEachCluster_3.Value));
        settings_3 = strcat('   The height of evaporative waveguide over the sea (m)： ',  num2str(app.CallingApp.EditField_7.Value),', the wind speed： ', num2str(app.CallingApp.wind_speed.Value));
        app.settings.Value = {'User settings in GUI： '; settings_1; settings_2; settings_3; settings_7; settings_16;settings_10; settings_15; settings_17;settings_11; settings_18;settings_12; settings_13; settings_14};

    elseif strfind(scenario, app.CallingApp.sps.scenario_SATELLITE)
        settings_1 = strcat('   Frequency band,  Scenario, Transmission link status：  ', app.CallingApp.scenarios);
        settings_2 = strcat('   The satellite altitude (km)： ',  num2str(app.CallingApp.satHeight.Value), ', the eccentricity of the elliptical orbit： ', num2str(app.CallingApp.BinEditField.Value),...
            ', the satellite orbital plane inclination (°)： ',  num2str(app.CallingApp.CinEditField.Value), ', the right ascension path (°)： ', num2str(app.CallingApp.DinEditField.Value),...
            ', the perigee Angle (°)： ',  num2str(app.CallingApp.EinEditField.Value), ', the true near-point angle (°)： ', num2str(app.CallingApp.FinEditField.Value),', the rainfall rate (mm/h)： ', num2str(app.CallingApp.rainRate.Value),', the elevation (°)： ',  num2str(link_eleAngle));
        settings_3 = strcat('   The number of clusters： ',  num2str(app.CallingApp.noCluster_4.Value), ', the number of scatterers in a cluster： ', num2str(app.CallingApp.noRaysEachCluster_4.Value), ',  ', app.CallingApp.DropDown_7.Value);
        app.settings.Value = {'User settings in GUI： '; settings_1; settings_2; settings_3; settings_7;settings_16; settings_10; settings_15; settings_17;settings_11; settings_18;settings_12; settings_13; settings_14};

    else
        settings_1 = strcat('   Frequency band,  Scenario, Transmission link status：  ', app.CallingApp.scenarios);
        settings_2 = strcat('   The number of clusters： ',  num2str(app.CallingApp.noCluster_5.Value), ', the number of scatterers in a cluster： ', num2str(app.CallingApp.noRaysEachCluster_5.Value), ',  ', app.CallingApp.DropDown_7.Value);
        app.settings.Value = {'User settings in GUI： '; settings_1; settings_2; settings_7; settings_16; settings_10; settings_15; settings_17;settings_11; settings_18;settings_12; settings_13; settings_14};
    end
end
app.settings.FontSize = 16;
app.settings.FontColor = [0 0 1];
app.settings.FontName = 'Times New Roman';
end
