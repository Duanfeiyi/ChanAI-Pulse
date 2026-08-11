function display_systemUI(app)
    app.satellitePanel.Position = [-343,-509,586,476];
    app.RISPanel.Position = [255,-509,580,476];
    app.maritimePanel.Position = [853,-512,577,479];
    app.OWCPanel.Position = [183,-1206,656,541];
    app.uwaPanel.Position = [875,-1182,658,443];
    if strfind(app.Tree_2.SelectedNodes.Text, app.sps.scenario_MARITIME)
        app.maritimePanel.Position = app.panelPos1.Position;
    elseif strfind(app.Tree_2.SelectedNodes.Text, app.sps.scenario_RIS)
        app.RISPanel.Position = app.panelPos1.Position;
    elseif strfind(app.Tree_2.SelectedNodes.Text, app.sps.scenario_SATELLITE)
        app.satellitePanel.Position = app.panelPos2.Position;
    elseif strfind(app.Tree_2.SelectedNodes.Text, app.sps.scenario_UWA)
        app.uwaPanel.Position = app.panelPos2.Position;
    else
    end
end