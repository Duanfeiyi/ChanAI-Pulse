function check_display_scenarioTreeSelected(app)
%check_display_scenarioTreeSelected 此处显示有关此函数的摘要
    selectedNodes = app.Tree_2.SelectedNodes;
    if isempty(selectedNodes.Children)
        if strfind (selectedNodes.Text, app.sps.scenario_SATELLITE)
            app.satellitePanel.Position = app.panelPos2.Position;
            app.RISPanel.Position = [255,-509,580,476];
            app.maritimePanel.Position = [853,-512,577,479]; 
            app.OWCPanel.Position = [181,-1021,584,468];
            app.skywavePanel.Position = [-571,-1036,646,443];
            app.ISACPanel.Position=[-571,-1614,658,525];
            app.DropDown_7.Value = 'single-bounce model';
        elseif strfind (selectedNodes.Text, app.sps.scenario_UAV) 
            app.satellitePanel.Position = [-343,-509,586,476];
            app.RISPanel.Position = [255,-509,580,476];
            app.maritimePanel.Position = [853,-512,577,479];  
            app.OWCPanel.Position = [181,-1021,584,468];
            app.skywavePanel.Position = [-571,-1036,646,443];
            app.ISACPanel.Position=[-571,-1614,658,525];
            app.DropDown_7.Value = 'multi-bounce model';
        elseif strfind (selectedNodes.Text, app.sps.scenario_MARITIME)
            app.DropDown_7.Value = 'multi-bounce model';
            app.satellitePanel.Position = [-343,-509,586,476];
            app.RISPanel.Position = [255,-509,580,476];
            app.skywavePanel.Position = [-571,-1036,646,443];
            app.maritimePanel.Position = app.panelPos1.Position;
            app.OWCPanel.Position = [181,-1021,584,468];
        elseif strfind(selectedNodes.Text, app.sps.scenario_RIS)
            app.RISPanel.Position = app.panelPos1.Position;
            app.satellitePanel.Position = [-343,-509,586,476];
            app.maritimePanel.Position = [853,-512,577,479];
            app.skywavePanel.Position = [-571,-1036,646,443];
            app.OWCPanel.Position = [181,-1021,584,468];
            app.ISACPanel.Position=[-571,-1614,658,525];
            app.DropDown_7.Value = 'multi-bounce model';
        elseif strfind(selectedNodes.Text, app.sps.scenario_ISAC)
            app.ISACPanel.Position=app.panelPos1.Position;
            app.satellitePanel.Position = [-343,-509,586,476];
            app.RISPanel.Position = [255,-509,580,476];
            app.maritimePanel.Position = [853,-512,577,479];
            app.skywavePanel.Position = [-571,-1036,646,443];
            app.OWCPanel.Position = [181,-1021,584,468];
            app.DropDown_7.Value = 'multi-bounce model';
        elseif strfind(selectedNodes.Text, app.sps.scenario_SKYWAVE)
            app.skywavePanel.Position = app.panelPos2.Position;
            app.satellitePanel.Position = [-343,-509,586,476];
            app.RISPanel.Position = [255,-509,580,476];
            app.maritimePanel.Position = [853,-512,577,479];
            app.OWCPanel.Position = [181,-1021,584,468];
            app.ISACPanel.Position=[-571,-1614,658,525];
            app.DropDown_7.Value = 'multi-bounce model';
        elseif contains(app.Tree.SelectedNodes.Text,{app.IRNode.Text,app.VLNode.Text,app.UVNode.Text})
        else
            app.satellitePanel.Position = [-343,-509,586,476];
            app.RISPanel.Position = [255,-509,580,476];
            app.maritimePanel.Position = [853,-512,577,479];
            app.skywavePanel.Position = [-571,-1036,646,443];
            app.OWCPanel.Position = [181,-1021,584,468];
            app.ISACPanel.Position=[-571,-1614,658,525];
            app.DropDown_7.Value = 'multi-bounce model';
            if isvalid(app.IndoorNode)
                if strcmp(app.Tree_2.SelectedNodes.Text, app.IndoorNode.Text) && tools.is_owc_band(app.Tree.SelectedNodes, app)
                    app.OWCPanel.Position = app.panelPos1.Position;
                end
            end
        end
        if (strcmp(app.Tree.SelectedNodes.Text, app.sub6GHzNode.Text) || strcmp(app.Tree.SelectedNodes.Text, app.mmWaveNode.Text)) && (strcmp(app.Tree_2.SelectedNodes.Text, app.UMiNode.Text)...
                || strcmp(app.Tree_2.SelectedNodes.Text, app.UMaNode.Text) || strcmp(app.Tree_2.SelectedNodes.Text, app.RMaNode.Text))
            app.NLoSO2IButton.Enable = 'on';
            app.LoSO2IButton.Enable = 'on';
        else
            app.NLoSO2IButton.Enable = 'off';
            app.LoSO2IButton.Enable = 'off';
            app.LoSO2IButton.Value = 0;
            app.NLoSO2IButton.Value = 0;
        end 
        

    end
    %IIOT场景不需要选择传播条件
    if(strcmp(app.Tree.SelectedNodes.Tag , app.sps.freqband_SUB6GHZ) || strcmp(app.Tree.SelectedNodes.Tag , app.sps.freqband_MMWAVE) || strcmp(app.Tree.SelectedNodes.Tag , app.sps.freqband_CMWAVE))
        if(strcmp(app.Tree_2.SelectedNodes.Text,app.IIoT_LoSNode.Text) || strcmp(app.Tree_2.SelectedNodes.Text,app. IIoTDH_NLoSNode.Text) || strcmp(app.Tree_2.SelectedNodes.Text,app. IIoTDL_NLoSNode.Text) ...
                || strcmp(app.Tree_2.SelectedNodes.Text,app.IIoTSH_NLoSNode.Text) || strcmp(app.Tree_2.SelectedNodes.Text,app.IIoTSL_NLoSNode.Text))
            app.LoSButton.Enable = 'off';
            app.NLoSButton.Enable = 'off';
            app.LoSButton.Value = 0;
            app.NLoSButton.Value = 0;
        % UHST 场景不需要选择传播条件
        elseif((strcmp(app.Tree.SelectedNodes.Tag , app.sps.freqband_SUB6GHZ) || strcmp(app.Tree.SelectedNodes.Tag , app.sps.freqband_CMWAVE) || strcmp(app.Tree.SelectedNodes.Tag , app.sps.freqband_CMWAVE) || strcmp(app.Tree.SelectedNodes.Tag , app.sps.freqband_MMWAVE)) && strcmp(app.Tree_2.SelectedNodes.Text,app.UHSTNode.Text))
            app.LoSButton.Enable = 'off';
            app.NLoSButton.Enable = 'off';
            app.LoSButton.Value = 0;
            app.NLoSButton.Value = 0;
            %V2VHighway不能选择NLoS条件
        elseif ((strcmp(app.Tree.SelectedNodes.Tag , app.sps.freqband_SUB6GHZ) || strcmp(app.Tree.SelectedNodes.Tag , app.sps.freqband_MMWAVE)) && strcmp(app.Tree_2.SelectedNodes.Text, app.V2VHighwayNode.Text))
            app.LoSButton.Enable = 'on';
            app.NLoSButton.Enable = 'off';
            app.NLoSButton.Value = 0;
        else
            app.LoSButton.Enable = 'on';
            app.NLoSButton.Enable = 'on';
        end
        if (strcmp(app.Tree_2.SelectedNodes.Text, app.V2VHighwayNode.Text) || strcmp(app.Tree_2.SelectedNodes.Text, app.V2VUrbanNode.Text))
            app.NLoSvButton.Enable = 'on';
        else
            app.NLoSvButton.Enable = 'off';
            app.NLoSvButton.Value = 0;
        end
    elseif strcmp(app.Tree.SelectedNodes.Tag , 'ShortWave')
        app.NLoSvButton.Enable = 'off';
        app.LoSButton.Enable = 'off';
        app.NLoSButton.Value = 1;
    else
        app.NLoSvButton.Enable = 'off';
        app.LoSButton.Enable = 'on';
        app.NLoSButton.Enable = 'on';
    end

    if (strcmp(app.Tree.SelectedNodes.Text, app.sub6GHzNode.Text)) && (strcmp(app.Tree_2.SelectedNodes.Text, app.ExpresswaymainroadNode.Text))

        app.NLoSO2IButton.Enable = 'off';
        app.LoSO2IButton.Enable = 'off';
        app.LoSO2IButton.Value = 0;
        app.NLoSO2IButton.Value = 0;
        app.NLoSButton.Enable = 'off';
        app.NLoSButton.Value = 0;
    end
    if (strcmp(app.Tree.SelectedNodes.Text, app.sub6GHzNode.Text)) && (strcmp(app.Tree_2.SelectedNodes.Text, app.ExpresswaysideroadNode.Text))
        app.NLoSO2IButton.Enable = 'off';
        app.LoSO2IButton.Enable = 'off';
        app.LoSO2IButton.Value = 0;
        app.NLoSO2IButton.Value = 0;
        app.LoSButton.Enable = 'off';
        app.LoSButton.Value = 0;
    end
    if (strcmp(app.Tree.SelectedNodes.Text, app.sub6GHzNode.Text)) && (strcmp(app.Tree_2.SelectedNodes.Text, app.InterOfficeNode.Text))
        app.NLoSO2IButton.Enable = 'off';
        app.LoSO2IButton.Enable = 'off';
        app.LoSO2IButton.Value = 0;
        app.NLoSO2IButton.Value = 0;
        app.NLoSButton.Enable = 'off';
        app.NLoSButton.Value = 0;
    end
    if (strcmp(app.Tree.SelectedNodes.Text, app.sub6GHzNode.Text)) && (contains(app.Tree_2.SelectedNodes.Text, {app.OfficeOutdoorNode.Text, app.UStunnelNode.Text,app.USgarageNode.Text}))
        app.NLoSO2IButton.Enable = 'off';
        app.LoSO2IButton.Enable = 'off';
        app.LoSO2IButton.Value = 0;
        app.NLoSO2IButton.Value = 0;
        app.NLoSButton.Enable = 'off';
        app.NLoSButton.Value = 0;
    end
    if (strcmp(app.Tree.SelectedNodes.Text, app.VHFNode.Text)) && (strcmp(app.Tree_2.SelectedNodes.Text, app.RMaNode.Text))
        app.NLoSO2IButton.Enable = 'off';
        app.LoSO2IButton.Enable = 'off';
        app.NLoSButton.Enable = 'off';
        app.LoSButton.Value = 1;
    end
end