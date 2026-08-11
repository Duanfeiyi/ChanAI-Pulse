function checkResult = check_propertiesSupport(app,propertyName)
    checkResult = 0;
% 检查该场景和频段是否支持仿真该统计特性
    if strfind(app.scenarios, app.sps.scenario_MARITIME) 
        % 海洋通信场景当前只支持仿真Doppler PSD
        if strfind(app.DropDown_statisticalpros.Value, '(Doppler PSD')
        else
            checkResult = 1;
            msgbox(strcat(app.scenarios, 'Simulation is currently not supported', propertyName, ',please select other statistical properties for simulation'), "modal");
        end
        
    elseif strfind(app.scenarios, app.sps.scenario_RIS) 
        % RIS场景当前只支持仿真ACF
        if strfind(app.DropDown_statisticalpros.Value, 'ACF')
        else
            checkResult = 1;
            msgbox(strcat(app.scenarios, 'Simulation is currently not supported', propertyName, ',please select other statistical properties for simulation'), "modal");
        end
        
    elseif tools.is_owc_band(app.scenarios, app) 
        % OWC 场景当前只支持仿真FCF和rmsDS
        if ~isempty(strcat(strfind(app.DropDown_statisticalpros.Value, 'Delay Spread'), ...
                strfind(app.DropDown_statisticalpros.Value, 'FCF')))  % strfind(app.DropDown_statisticalpros.Value, 'ACF'), 
        else
            msgbox(strcat(app.scenarios, 'Simulation is currently not supported', app.DropDown_statisticalpros.Value, ',please select other statistical properties for simulation'), "modal");
            return;
        end
    elseif strfind(scenario, app.sps.scenario_SATELLITE)     
        % 卫星场景当前只支持仿真ACF,FCF和rmsDS
        if ~isempty(strcat(strfind(app.DropDown_statisticalpros.Value, 'ACF'), strfind(app.DropDown_statisticalpros.Value, 'delay spread'), ...
                strfind(app.DropDown_statisticalpros.Value, 'FCF')))
        else
            msgbox(strcat(app.scenarios, 'Simulation is currently not supported', app.DropDown_statisticalpros.Value, ',please select other statistical properties for simulation'), "modal");
            return;
        end        
end