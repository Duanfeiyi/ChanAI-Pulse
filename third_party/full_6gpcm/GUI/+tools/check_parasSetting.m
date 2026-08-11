function check_parasSetting(app)
% 信道矩阵和统计特性仿真按钮，执行后首先校验前面用户所设置的参数是否合理
txInitialPos = mf.str2positions(cell2mat(app.UITable_tx.Data{1,3}));
rxInitialPos = mf.str2positions(cell2mat(app.UITable_rx.Data{1,3}));

if app.sampleRate.Value * app.trackLength.Value < 1
    error("Motion trajectory module, move duration * sampling rate per second < 1. Please reset.");
end

if strfind(app.scenarios, 'Satellite') % 若此时设置场景为卫星场景，接收端经度纬度需要限制
    if (rxInitialPos(1) > 180 || rxInitialPos(1) < -180) || (rxInitialPos(2) > 90 || rxInitialPos(2) < -90)
        error("The longitude or latitude of Rx is incorrectly set. Please reset");
    end
else
    % 若前一场景为卫星通信，高度会很高，提示用户修改高度
    if txInitialPos(3) > 1000 || txInitialPos(3) < -1000
        error("The initial position height is abnormal. Please reset");
    end
end
if strfind(app.scenarios, app.sps.scenario_UHST)
    if str2num(cell2mat(app.UITable_rx.Data{1, 6})) < 100
        error("The UHST speed is incorrectly set, which should be greater than 100 m/s. Please reset");
    end
    if str2num(cell2mat(app.UITable_tx.Data{1, 6})) ~= 0
        error("The AP in the tube in UHST scenario should be static. Please reset");
    end
    if norm(txInitialPos - rxInitialPos) < 1000
        error("The initial positions of the UHST and AP are incorrectly set, which should be larger than 1000 m. Please reset");
    end
end

if strfind(app.scenarios, app.sps.scenario_UWA)
    if app.txDepth.Value > app.height_water_uwa.Value
        app.txDepth.Value = app.height_water_uwa.Value;
        error("The depth of Tx must not exceed the water depth");
    elseif app.rxDepth.Value > app.height_water_uwa.Value
        app.rxDepth.Value = app.height_water_uwa.Value;
        error("The depth of Rx must not exceed the water depth");
    end

    if ~isequal(txInitialPos(3), app.txDepth.Value)
        error("The Z position of Tx must be equal to the depth of Tx");
    elseif ~isequal(rxInitialPos(3), app.rxDepth.Value)
        error("The Z position of Rx must be equal to the depth of Rx");
    end
    if ~isequal( sqrt( (txInitialPos(1)-rxInitialPos(1)).^2 + (txInitialPos(2)-rxInitialPos(2)).^2 ), app.Distance_tx_rx.Value)
        error('The horizontal distance between the Tx and Rx should be %d m. Please reset', app.Distance_tx_rx.Value)
    end
    trackOriTx = str2num(cell2mat(app.UITable_tx.Data{1,8}));
    trackOriRx = str2num(cell2mat(app.UITable_rx.Data{1,8}));
    if trackOriTx(3)~=0 
        error('The Tx can only move in the XY plane. Please reset')
    elseif trackOriRx(3)~=0
        error('The Rx can only move in the XY plane. Please reset')
    end

end


if isempty(app.EditField.Value) || isempty(app.bandwidth.Value)
    error("The carrier frequency or bandwidth can not be empty. Please reset");
end

%频段限制
if strfind(app.scenarios, app.sps.freqband_SHORTWAVE)
    if str2double(app.EditField.Value) < 0.0015 || str2double(app.EditField.Value) > 0.03
        error("The shortwave frequency should be set to 0.015-0.03 GHz. Please reset");
    elseif app.LoSO2IButton.Value || app.NLoSO2IButton.Value
        error("The shortwave frequency band currently does not support outdoor to indoor (O2I) scenarios. Please reset the propagation conditions");
    end
    if norm(txInitialPos - rxInitialPos) < 700000||norm(txInitialPos - rxInitialPos) > 12000000
        error("The initial positions are incorrect, which should be larger than 700 km and smaller than 12000km. Please reset");
    end
elseif strfind(app.scenarios, app.sps.scenario_UWA)
    if str2double(app.EditField.Value) < 0.2 || str2double(app.EditField.Value) > 50
        error("The acoustic frequency should be set to 0.2-50 KHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.scenario_VHF)
    if str2double(app.EditField.Value) < 0.03 || str2double(app.EditField.Value) > 0.45
        error("The VHF frequency should be set to 0.03-0.45 GHz. Please reset");
    end

elseif strfind(app.scenarios, app.sps.freqband_SUB6GHZ)
    if sum(mf.str2frequencys(app.EditField.Value,app.bandwidth.Value,app.freqSamples.Value) < 0.45)>0 || sum(mf.str2frequencys(app.EditField.Value,app.bandwidth.Value,app.freqSamples.Value) > 6)>0
        error("The sub-6 GHz frequency should be set to 0.45-6 GHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.freqband_CMWAVE)
    if sum(mf.str2frequencys(app.EditField.Value,app.bandwidth.Value,app.freqSamples.Value) < 6)>0 || sum(mf.str2frequencys(app.EditField.Value,app.bandwidth.Value,app.freqSamples.Value) > 24)>0
        error("The cmWave frequency should be set to 7-24 MHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.freqband_MMWAVE)
    if sum(mf.str2frequencys(app.EditField.Value,app.bandwidth.Value,app.freqSamples.Value) < 24)>0 || sum(mf.str2frequencys(app.EditField.Value,app.bandwidth.Value,app.freqSamples.Value) > 300)>0
        error("The mmWave frequency should be set to 24-300 GHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.freqband_THZ)
    if str2double(app.EditField.Value) < 300 || str2double(app.EditField.Value) > 10000
        error("The THz frequency should be set to 100-10000 GHz. Please reset");
    end
    % 加入对OWC频段的限制
elseif strfind(app.scenarios, app.sps.freqband_IR)
    if str2double(app.EditField.Value) < 10000 || str2double(app.EditField.Value) > 395000
        error("The infrared band frequency should be set to 10000-395000 GHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.freqband_VL)
    if str2double(app.EditField.Value) < 395000 || str2double(app.EditField.Value) > 750000
        error("The visible frequency should be set between 395000-750000GHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.freqband_UV)
    if str2double(app.EditField.Value) < 750000 || str2double(app.EditField.Value) > 30000000
        error("The UV frequency should be set between 750000 and 30000000 GHz. Please reset");
    end
end

%带宽限制
if strfind(app.scenarios, app.sps.freqband_SHORTWAVE)
    if str2double(app.bandwidth.Value) < 0.003 || str2double(app.bandwidth.Value) > 0.004
        error("The shortwave bandwidth should be set to 0.003-0.004 MHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.scenario_UWA)
    if str2double(app.bandwidth.Value) < 0.1 || str2double(app.bandwidth.Value) > 10
        error("The acoustic bandwidth should be set to 0.1-10 KHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.scenario_VHF)
    if str2double(app.bandwidth.Value) < 3 || str2double(app.bandwidth.Value) > 30
        error("The VHF bandwidth should be set to 3-30 MHz. Please reset");
    end

elseif strfind(app.scenarios, app.sps.freqband_SUB6GHZ)
    [~,bandwidth]=mf.str2frequencys(app.EditField.Value,app.bandwidth.Value,app.freqSamples.Value);
    if sum( bandwidth < 30)>0 || sum( bandwidth > 1000)>0
        error("The sub-6 GHz bandwidth should be set to 30-1000 MHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.freqband_CMWAVE)
    [~,bandwidth]=mf.str2frequencys(app.EditField.Value,app.bandwidth.Value,app.freqSamples.Value);
    if sum( bandwidth < 100)>0 || sum( bandwidth > 2000)>0
        error("The cmWave bandwidth should be set to 100-2000 MHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.freqband_MMWAVE)
    [~,bandwidth]=mf.str2frequencys(app.EditField.Value,app.bandwidth.Value,app.freqSamples.Value);
    if sum( bandwidth < 100)>0 || sum( bandwidth > 2000)>0
        error("The mmWave bandwidth should be set to 100-2000 MHz. Please reset");
    end
elseif strfind(app.scenarios, app.sps.freqband_THZ)
    if str2double(app.bandwidth.Value) < 500 || str2double(app.bandwidth.Value) > 5000
        error("The THz frequency should be set to 500-5000 MHz. Please reset");
    end
end

% 对是否支持多用户进行检查
% 光无线、卫星、海洋船对船、IIOT、RIS、水声收发端都不支持多用户，UAV发射端不支持多用户，接收端支持，其他都支持
scenarios =  {app.sps.scenario_SATELLITE, app.sps.scenario_ISAC, app.sps.scenario_UHST, app.sps.scenario_RIS, ...
    app.sps.scenario_MARITIME,app.sps.freqband_VL,app.sps.freqband_UV,app.sps.freqband_IR,app.sps.freqband_SHORTWAVE, app.sps.scenario_UWA};

% scenarios =  {app.sps.scenario_SATELLITE, app.sps.scenario_IIOT, app.sps.scenario_ISAC, app.sps.scenario_UHST, app.sps.scenario_RIS, ...
%               app.sps.scenario_MARITIME,app.sps.freqband_VL,app.sps.freqband_UV,app.sps.freqband_IR,app.sps.freqband_SHORTWAVE};
if contains(app.scenarios, scenarios)
    if size(app.UITable_tx.Data, 1) >1 || size(app.UITable_rx.Data, 1) >1
        error([app.scenarios, ' channels do not support multi-users. Please reset.']);
    end
elseif contains(app.scenarios, app.sps.scenario_UAV)
    if size(app.UITable_tx.Data, 1) >1
        error(['Tx side of ', app.scenarios, ' channels do not support multi-users. Please reset.']);
    end
end
% 确保设置的运动轨迹与设置的场景相对应
if strfind(app.scenarios, app.sps.scenario_SATELLITE)
    if ~strcmp(cell2mat(app.UITable_tx.Data{1,5}), 'satellite')
        error("In the satellite communication scenario, the trajectory type of the transmitter should be set to 'satellite'. Please reset");
    end
elseif strfind(app.scenarios, app.sps.scenario_MARITIME_ship2ship)
    if ~((strcmp(cell2mat(app.UITable_tx.Data{1,5}),'shipStatic') || strcmp(cell2mat(app.UITable_tx.Data{1,5}),'shipLinear')) && ...
            (strcmp(cell2mat(app.UITable_rx.Data{1,5}),'shipStatic') || strcmp(cell2mat(app.UITable_rx.Data{1,5}),'shipLinear')))
        error("In the maritime ship to ship communication scenario, the trajectory types of the transmitter and receiver should be set to 'shipStatic' or 'shipLinear'. Please reset");
    end
elseif strfind(app.scenarios, app.sps.scenario_MARITIME_ship2land)
    if ~((strcmp(cell2mat(app.UITable_tx.Data{1,5}),'shipStatic') || strcmp(cell2mat(app.UITable_tx.Data{1,5}),'shipLinear')))
        error("In the maritime ship to land communication scenario, the trajectory types of the transmitter should be set to 'shipStatic' or 'shipLinear'. Please reset");
    end
    if contains(cell2mat(app.UITable_rx.Data{1,5}),'ship')
        error("In the maritime ship to land communication scenario, the trajectory types of the receiver should not be set to 'shipStatic' or 'shipLinear'. Please reset");
    end
elseif strfind(app.scenarios, app.sps.scenario_UWA)
    if ~(contains(cell2mat(app.UITable_tx.Data{1,5}),{'shipStatic','static','linear','shipLinear'})) || ~(contains(cell2mat(app.UITable_rx.Data{1,5}),{'shipStatic','static','linear','shipLinear'}))
        error("In the UWA scenario, the trajectory types of the transmitter and receiver should be set to 'static', 'shipStatic', 'linear' or 'shipLinear'. Please reset");
    end
end

if strcmp(cell2mat(app.UITable_tx.Data{1,5}),'satellite')
    if ~contains(app.scenarios, app.sps.scenario_SATELLITE)
        error("The trajectory type of Tx applies only to the satellite communication scenario. Please reset")
    end
end
if contains(cell2mat(app.UITable_tx.Data{1,5}),'ship') || contains(cell2mat(app.UITable_rx.Data{1,5}),'ship')
    if ~contains(app.scenarios, {app.sps.scenario_MARITIME, app.sps.scenario_UWA})
        error("The current trajectory type applies only to the maritime communication scenario. Please reset")
    end
end

if ~tools.is_owc_band(app.scenarios, app) && isempty(strfind(app.switchSampleRate.Value, 'Close'))
    for i_tx = 1: size(app.UITable_tx.Data, 1)
        for i_rx = 1: size(app.UITable_rx.Data, 1)
            fDmax = (str2num(cell2mat(app.UITable_tx.Data{i_tx, 6})) + str2num(cell2mat(app.UITable_rx.Data{i_rx, 6})))/app.sps.wavelength;
            % 运动轨迹界面提示用户采样频率不能低于两倍多普勒频移带宽
            if app.sampleRate.Value < 4*fDmax
                error(strcat("The sampling frequency needs to satisfy the sampling theorem, please increase to twice the Doppler shift bandwidth, the number of samples per second needs to be greater than ", num2str(4 * fDmax)));
            end
        end
    end
end

%对多频段信道模型的输入限制
scenarios =  {app.sps.scenario_ISAC, app.sps.scenario_SATELLITE, app.sps.scenario_UHST,...
    app.sps.scenario_UAV, app.sps.scenario_IIOT, app.sps.scenario_RIS, app.sps.scenario_MARITIME, app.sps.scenario_V2V, app.sps.scenario_US, app.sps.scenario_UWA};
if length(app.sps.carrier_frequency) > 1
    freq_check = contains(app.scenarios, app.sps.freqband_SUB6GHZ) || contains(app.scenarios, app.sps.freqband_CMWAVE) || contains(app.scenarios, app.sps.freqband_MMWAVE);
    if contains(app.scenarios,scenarios) && freq_check
        error('The multi-frequency channel model only supports the sub-6 GHz, cmWave and mmWave bands and Terrestrial Communication scenarios ')
    end
end
end