function setAppScenarios(app)
%SETAPPSCENARIOS 设置场景名称，拼接而成
    if contains(app.Tree_2.SelectedNodes.Tag, {app.sps.scenario_MARITIME, app.sps.scenario_IIOT, app.sps.scenario_UHST})...
            || tools.is_owc_band(app.Tree.SelectedNodes.Tag, app)
            app.scenarios = strcat(app.Tree.SelectedNodes.Tag,'_',app.Tree_2.SelectedNodes.Tag);
    elseif strfind(app.Tree_2.SelectedNodes.Tag, app.sps.scenario_RIS)
            app.scenarios = strcat(app.Tree.SelectedNodes.Tag,'_',app.Tree_2.SelectedNodes.Tag,'_', app.ButtonGroup_RIS.SelectedObject.Text);
    elseif strfind(app.Tree_2.SelectedNodes.Tag, app.sps.scenario_ISAC)
        switch app.ButtonGroup_2.SelectedObject.Text
            case 'LoS-LoS'
                app.scenarios = strcat(app.Tree.SelectedNodes.Tag,'_',app.Tree_2.SelectedNodes.Tag,'_', 'LoS');
            case 'NLoS-NLoS'
                app.scenarios = strcat(app.Tree.SelectedNodes.Tag,'_',app.Tree_2.SelectedNodes.Tag,'_', 'NLoS');
        end
    else
            app.scenarios = strcat(app.Tree.SelectedNodes.Tag,'_',app.Tree_2.SelectedNodes.Tag,'_', app.ButtonGroup.SelectedObject.Text);
    end
end

