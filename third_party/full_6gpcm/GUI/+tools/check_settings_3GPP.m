function check_settings_3GPP(app, model_selection)
% 信道矩阵和统计特性仿真按钮，执行后首先校验前面用户所设置的参数是否合理
if strfind(app.scenarios, app.sps.freqband_SHORTWAVE)
    error("%s: The shortwave band is not supported. Please reset.",model_selection);
elseif strfind(app.scenarios, app.sps.freqband_SUB6GHZ)
    if str2double(app.EditField.Value) < 0.5 || str2double(app.EditField.Value) > 6
        error("%s: The frequency of sub-6 GHz frequency band should be set between 0.5 and 6 GHz. Please reset.",model_selection);
    end
elseif strfind(app.scenarios, app.sps.freqband_MMWAVE)
    if str2double(app.EditField.Value) < 6 || str2double(app.EditField.Value) > 100
        error("%s: The frequency of the millimeter wave band should be set between 6 and 100 GHz. Please reset.",model_selection);
    end
elseif strfind(app.scenarios, app.sps.freqband_THZ)
    error("%s: THz is not supported. Please reset",model_selection);
    % 加入对OWC频段的限制
elseif strfind(app.scenarios, app.sps.freqband_IR)
    error("%s: The infrared band is not supported. Please reset.",model_selection);
elseif strfind(app.scenarios, app.sps.freqband_VL)
    error("%s: The visible band is not supported. Please reset.",model_selection);
elseif strfind(app.scenarios, app.sps.freqband_UV)
    error("%s: UV is not supported. Please reset",model_selection);
end

% 检查场景
switch model_selection
    case {'3GPP TR 38.901', 'IMT2020'}  % 仅支持IIOT场景+地面通信场景，除室内走廊
        % 若频段_场景包含光无线、太赫兹、短波、通感、RIS、UHST、海洋、卫星、无人机，则报错
        if contains(app.scenarios, {app.sps.scenario_ISAC, app.sps.scenario_RIS, app.sps.scenario_UHST, 'Corridor', 'Expressway', 'Office',...
                app.sps.scenario_MARITIME, app.sps.scenario_UAV, app.sps.scenario_SATELLITE, app.sps.freqband_UV, app.sps.freqband_SHORTWAVE, ...
                app.sps.freqband_IR, app.sps.freqband_VL, app.sps.freqband_THZ})
            error('%s: The %s scenario is not supported. Please reset.', model_selection, app.scenarios);
        end
        % IMT-2020除不支持上述3GPP TR 38.901模型不支持的之外还不支持IIoT
        if contains(model_selection, 'IMT2020') && contains(app.scenarios, app.sps.scenario_IIOT)
             error('%s: The %s scenario is not supported. Please reset.', model_selection, app.scenarios);
        end
    case '3GPP TR 38.811' % 仅支持卫星场景
        if ~contains(app.scenarios, app.sps.scenario_SATELLITE)
            error('%s: The %s scenario is not supported. Please reset.', model_selection, app.scenarios);
        end
    case '3GPP TR 36.777' % 仅支持无人机场景
        if ~contains(app.scenarios, app.sps.scenario_UAV)
            error('%s: The %s scenario is not supported. Please reset.', model_selection, app.scenarios);
        end
    case '3GPP TR 37.885' % 仅支持车对车场景
        if ~contains(app.scenarios, app.sps.scenario_V2V)
            error('%s: The %s scenario is not supported. Please reset.', model_selection, app.scenarios);
        end
end
end