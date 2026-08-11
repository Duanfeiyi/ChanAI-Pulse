function setFreqAndScensTree(app, inportStr)
% 将载入的频段和场景配置显示在界面上，例如载入 sub-6 GHz_UMi_LoS, 那么在界面上 设置频段Tree上选择
% sub-6 GHz，在设置场景Tree界面上 选择UMi， 传播条件选中为LoS
    
    freqAndScens = strsplit(inportStr, '_');
    freq = freqAndScens{1};
    scen = freqAndScens{2};
    if length(freqAndScens) == 3
        propag = freqAndScens{3};
        % 设置传播条件界面
        if ~isempty(strfind(propag, app.NLoSButton_RIS.Text)) && ~isempty(strfind(scen, app.sps.scenario_RIS))
            app.ButtonGroup_RIS.SelectedObject = app.NLoSButton_RIS;
        elseif ~isempty(strfind(propag, app.LoSButton_RIS.Text)) && ~isempty(strfind(scen, app.sps.scenario_RIS))
            app.ButtonGroup_RIS.SelectedObject = app.LoSButton_RIS;
        elseif strfind(propag, app.NLoSButton.Text) 
            app.ButtonGroup.SelectedObject = app.NLoSButton;
        elseif strfind(propag, app.NLoSO2IButton.Text) 
            app.ButtonGroup.SelectedObject = app.NLoSO2IButton;
        elseif strfind(propag, app.LoSO2IButton.Text) 
            app.ButtonGroup.SelectedObject = app.LoSO2IButton;
        else
            app.ButtonGroup.SelectedObject = app.LoSButton;
        end
    end

    if strfind(scen, app.sps.scenario_IIOT)
        scen = strcat(scen, '_', propag);
    end
    
    % 设置频段Tree界面
    setFreqTreeNode(app, freq);
    
    % 设置场景Tree界面
    setScenTreeNode(app, scen);
    
end

function setFreqTreeNode(app, inportFreq)
    switch inportFreq
        case app.acousticNode.Tag
            app.Tree.SelectedNodes = app.acousticNode;
        case app.ShortWaveNode.Tag
            app.Tree.SelectedNodes = app.ShortWaveNode;
        case app.VHFNode.Tag
            app.Tree.SelectedNodes = app.VHFNode;
        case app.sub6GHzNode.Tag
            app.Tree.SelectedNodes = app.sub6GHzNode;
        case app.cmWaveNode.Tag
            app.Tree.SelectedNodes = app.cmWaveNode;         
        case app.mmWaveNode.Tag
            app.Tree.SelectedNodes = app.mmWaveNode;
        case app.THzNode.Tag
            app.Tree.SelectedNodes = app.THzNode;
        case app.IRNode.Tag
            app.Tree.SelectedNodes = app.IRNode;
        case app.VLNode.Tag
            app.Tree.SelectedNodes = app.VLNode;
        case app.UVNode.Tag
            app.Tree.SelectedNodes = app.UVNode;
        otherwise
            app.Tree.SelectedNodes = app.sub6GHzNode;
    end
end

function setScenTreeNode(app, inportScen)
    if(contains(inportScen,app.sps.scenario_SATELLITE))
        switch inportScen
            case app.SatelliteDenseUrbanNode.Tag
                app.Tree_2.SelectedNodes = app.SatelliteDenseUrbanNode;
            case app.SatelliteRuralNode.Tag
                app.Tree_2.SelectedNodes = app.SatelliteRuralNode;
            case app.SatelliteSuburbanNode.Tag
                app.Tree_2.SelectedNodes = app.SatelliteSuburbanNode;
            case app.SatelliteUrbanNode.Tag
                app.Tree_2.SelectedNodes = app.SatelliteUrbanNode;
        end
    elseif(contains(inportScen,app.sps.scenario_UAV))
        switch inportScen
            case app.UAVUMiNode.Tag
                app.Tree_2.SelectedNodes = app.UAVUMiNode;
            case app.UAVUMaNode.Tag
                app.Tree_2.SelectedNodes = app.UAVUMaNode;
            case app.UAVRMaNode.Tag
                app.Tree_2.SelectedNodes = app.UAVRMaNode;
        end

    elseif(contains(inportScen,app.sps.scenario_MARITIME))
        switch inportScen
            case app.MaritimeShiptoshipNode.Tag
                app.Tree_2.SelectedNodes = app.MaritimeShiptoshipNode;
            case app.MaritimeShiptolandNode.Tag
                app.Tree_2.SelectedNodes = app.MaritimeShiptolandNode;
        end

    elseif(contains(inportScen,app.sps.scenario_RIS))
        switch inportScen
            case app.RISIndoorNode.Tag
                app.Tree_2.SelectedNodes = app.RISIndoorNode;
            case app.RISUMiNode.Tag
                app.Tree_2.SelectedNodes = app.RISUMiNode;
            case app.RISUMaNode.Tag
                app.Tree_2.SelectedNodes = app.RISUMaNode;
            case app.RISRMaNode.Tag
                app.Tree_2.SelectedNodes = app.RISRMaNode;
        end

    elseif(contains(inportScen,app.sps.scenario_V2V))
        switch inportScen
            case app.V2VHighwayNode.Tag
                app.Tree_2.SelectedNodes = app.V2VHighwayNode;
            case app.V2VUrbanNode.Tag
                app.Tree_2.SelectedNodes = app.V2VUrbanNode;
        end

    elseif(contains(inportScen,app.sps.scenario_IIOT))
        switch inportScen
            case app.IIoTDH_NLoSNode.Tag
                app.Tree_2.SelectedNodes = app.IIoTDH_NLoSNode;
            case app.IIoTDL_NLoSNode.Tag
                app.Tree_2.SelectedNodes = app.IIoTDL_NLoSNode;
            case app.IIoTSH_NLoSNode.Tag
                app.Tree_2.SelectedNodes = app.IIoTSH_NLoSNode;
            case app.IIoTSL_NLoSNode.Tag
                app.Tree_2.SelectedNodes = app.IIoTSL_NLoSNode;
            otherwise
                app.Tree_2.SelectedNodes = app.IIoT_LoSNode;
        end

    elseif(contains(inportScen,app.sps.scenario_ISAC))
        switch inportScen
            case app.ISACUMaNode.Tag
                app.Tree_2.SelectedNodes = app.ISACUMaNode;
            case app.ISACUMiNode.Tag
                app.Tree_2.SelectedNodes = app.ISACUMiNode;
            case app.ISACRMaNode.Tag
                app.Tree_2.SelectedNodes = app.ISACRMaNode;
            case app.ISACIndoorNode.Tag
                app.Tree_2.SelectedNodes = app.ISACIndoorNode;
        end

    elseif(contains(inportScen,app.sps.scenario_UHST))
        app.Tree_2.SelectedNodes = app.UHSTNode;

    elseif (contains(inportScen,app.sps.scenario_UWA))
        app.Tree_2.SelectedNodes = app.UWAShallowWaterNode;

    else
        if(app.Tree.SelectedNodes == app.ShortWaveNode)
            switch inportScen
                case app.SkyWaveNode.Tag
                    app.Tree_2.SelectedNodes = app.SkyWaveNode;
                case app.GroundWaveNode.Tag
                    app.Tree_2.SelectedNodes = app.GroundWaveNode;
            end
        elseif(app.Tree.SelectedNodes == app.THzNode)
            app.Tree_2.SelectedNodes = app.IndoorNode;
        elseif(app.Tree.SelectedNodes == app.VHFNode)
            app.Tree_2.SelectedNodes = app.RMaNode;
        else
            switch inportScen
                case app.UMiNode.Tag
                    app.Tree_2.SelectedNodes = app.UMiNode;
                case app.UMaNode.Tag
                    app.Tree_2.SelectedNodes = app.UMaNode;
                case app.RMaNode.Tag
                    app.Tree_2.SelectedNodes = app.RMaNode;
                case app.IndoorNode.Tag
                    app.Tree_2.SelectedNodes = app.IndoorNode;
                case app.IndoorCorridorNode.Tag
                    app.Tree_2.SelectedNodes = app.IndoorCorridorNode;
            end
        end

    end
                 
end

