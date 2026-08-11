function check_display_freqTreeSelected(app)
%DISPLAY_SCENARIOTREESELECTED 此处显示有关此函数的摘要
%   此处显示详细说明
selectedNodes = app.Tree.SelectedNodes;
if isempty(selectedNodes.Children)

    tools.antenna2sonar(app);

    switch selectedNodes.Text
        case app.acousticNode.Text
            tempTree = app.Node_2.Children;
            tempTree.delete;

            % Create UWANode
            app.UWANode = uitreenode(app.Node_2);
            app.UWANode.Text = '水下通信(UWA)';

            % Create UWAShallowWaterNode
            app.UWAShallowWaterNode = uitreenode(app.UWANode);
            app.UWAShallowWaterNode.Tag = 'UWA-ShallowWater';
            app.UWAShallowWaterNode.Text = 'UWA-ShallowWater(浅海域)';

            app.Tree_2.SelectedNodes = app.UWAShallowWaterNode;

            app.NLoSO2IButton.Enable = 'off';
            app.LoSO2IButton.Enable = 'off';

            app.NLoSvButton.Enable = 'off';
            app.LoSButton.Enable = 'on';
            app.NLoSButton.Enable = 'off';
            app.LoSButton.Value = 1;

            app.EditField.Value = '1.5';
            app.bandwidth.Value = '1';
            app.freqSamples.Value = '1000';

            tools.display_RFOn(app);
            app.uwaPanel.Position = app.panelPos1.Position;

            if ~app.Button_Analysis.Enable
                app.guiAnalysisApp.DropDown_type.Items = {'时域/多普勒域信道统计特性 (Time domain)', '频域/时延域信道统计特性 (Frequency domain)', '空域/角度域信道统计特性 (Space domain)', '其他(Others)','大尺度衰落 (Large scale fadings)'};
                tools.show_guiAnalysis_dropdownType(app.guiAnalysisApp);
            end
        case app.VHFNode.Text
            tempTree = app.Node_2.Children;
            tempTree.delete;

            % Create TerrestrialcommuNode
            app.TerrestrialcommuNode = uitreenode(app.Node_2);
            app.TerrestrialcommuNode.Text = '地面通信 (Terrestrial commu.)';

            % Create RMaNode
            app.RMaNode = uitreenode(app.TerrestrialcommuNode);
            app.RMaNode.Tag = 'RMa';
            app.RMaNode.Text = 'RMa(郊区)';

            app.Tree_2.SelectedNodes = app.RMaNode;

            app.NLoSO2IButton.Enable = 'off';
            app.LoSO2IButton.Enable = 'off';

            app.NLoSvButton.Enable = 'off';
            app.LoSButton.Enable = 'off';
            app.NLoSButton.Enable = 'off';
            app.LoSButton.Value = 1;

            app.EditField.Value = '0.39';
            app.bandwidth.Value = '20';
            app.freqSamples.Value = '100';

        case app.ShortWaveNode.Text
            tempTree = app.Node_2.Children;
            tempTree.delete;
            % Create TerrestrialcommuNode
            app.TerrestrialcommuNode = uitreenode(app.Node_2);
            app.TerrestrialcommuNode.Text = '地面通信 (Terrestrial commu.)';

            % Create SkyWaveNodeNode
            app.SkyWaveNode = uitreenode(app.TerrestrialcommuNode);
            app.SkyWaveNode.Text = '天波(SkyWave)';
            app.SkyWaveNode.Tag = 'SkyWave';

            % Create GroundWaveNodeNode
            app.GroundWaveNode = uitreenode(app.TerrestrialcommuNode);
            app.GroundWaveNode.Text = '地波(GroundWave)';
            app.GroundWaveNode.Tag = 'GroundWave';

            app.NLoSO2IButton.Enable = 'off';
            app.LoSO2IButton.Enable = 'off';

            app.NLoSvButton.Enable = 'off';
            app.LoSButton.Enable = 'off';
            app.NLoSButton.Enable = 'on';
            app.NLoSButton.Value = 1;

            app.EditField.Value = '0.003';
            app.bandwidth.Value = '0.004';
            app.freqSamples.Value = '100';
            app.noCluster_5.Value = 10;
            app.Tree_2.SelectedNodes = app.SkyWaveNode;

            tools.display_RFOn(app);
            tools.display_systemUI(app);

            if ~app.Button_Analysis.Enable
                app.guiAnalysisApp.DropDown_type.Items = {'时域/多普勒域信道统计特性 (Time domain)', '频域/时延域信道统计特性 (Frequency domain)', '空域/角度域信道统计特性 (Space domain)', '其他(Others)', '大尺度衰落 (Large scale fadings)'};
                tools.show_guiAnalysis_dropdownType(app.guiAnalysisApp);
            end

        case app.sub6GHzNode.Text
            tempTree = app.Node_2.Children;
            tempTree.delete;
            % Create SatelliteNode
            app.SatelliteNode = uitreenode(app.Node_2);
            app.SatelliteNode.Text = '卫星(Satellite)';

            % Create SatelliteRuralNode
            app.SatelliteRuralNode = uitreenode(app.SatelliteNode);
            app.SatelliteRuralNode.Tag = 'Satellite-Rural';
            app.SatelliteRuralNode.Text = 'Satellite-Rural（乡村）';

            % Create SatelliteUrbanNode
            app.SatelliteUrbanNode = uitreenode(app.SatelliteNode);
            app.SatelliteUrbanNode.Tag = 'Satellite-Urban';
            app.SatelliteUrbanNode.Text = 'Satellite-Urban（城市）';

            % Create SatelliteSuburbanNode
            app.SatelliteSuburbanNode = uitreenode(app.SatelliteNode);
            app.SatelliteSuburbanNode.Tag = 'Satellite-Suburban';
            app.SatelliteSuburbanNode.Text = 'Satellite-Suburban（郊区）';

            % Create SatelliteDenseUrbanNode
            app.SatelliteDenseUrbanNode = uitreenode(app.SatelliteNode);
            app.SatelliteDenseUrbanNode.Tag = 'Satellite-DenseUrban';
            app.SatelliteDenseUrbanNode.Text = 'Satellite-DenseUrban（密集城市）';

            % Create UAVNode
            app.UAVNode = uitreenode(app.Node_2);
            app.UAVNode.Text = '无人机 (UAV)';

            % Create UAVUMiNode
            app.UAVUMiNode = uitreenode(app.UAVNode);
            app.UAVUMiNode.Tag = 'UAV-UMi';
            app.UAVUMiNode.Text = 'UAV-UMi(城市微小区)';

            % Create UAVUMaNode
            app.UAVUMaNode = uitreenode(app.UAVNode);
            app.UAVUMaNode.Tag = 'UAV-UMa';
            app.UAVUMaNode.Text = 'UAV-UMa(城市宏小区)';

            % Create UAVRMaNode
            app.UAVRMaNode = uitreenode(app.UAVNode);
            app.UAVRMaNode.Tag = 'UAV-RMa';
            app.UAVRMaNode.Text = 'UAV-RMa(郊区)';

            % Create TerrestrialcommuNode
            app.TerrestrialcommuNode = uitreenode(app.Node_2);
            app.TerrestrialcommuNode.Text = '地面通信 (Terrestrial commu.)';

            % Create UMiNode
            app.UMiNode = uitreenode(app.TerrestrialcommuNode);
            app.UMiNode.NodeData = '城市微小区场景';
            app.UMiNode.Tag = 'UMi';
            app.UMiNode.Text = 'UMi(城市微小区)';

            % Create UMaNode
            app.UMaNode = uitreenode(app.TerrestrialcommuNode);
            app.UMaNode.Tag = 'UMa';
            app.UMaNode.Text = 'UMa(城市宏小区)';

            % Create RMaNode
            app.RMaNode = uitreenode(app.TerrestrialcommuNode);
            app.RMaNode.Tag = 'RMa';
            app.RMaNode.Text = 'RMa(郊区)';

            % Create V2I_expressway_mainroadNode
            app.ExpresswaymainroadNode = uitreenode(app.TerrestrialcommuNode);
            app.ExpresswaymainroadNode.Tag = 'Expressway-main road';
            app.ExpresswaymainroadNode.Text = 'Expressway-main road (公路-主干道)';

            % Create V2I_expressway_mainroadNode
            app.ExpresswaysideroadNode = uitreenode(app.TerrestrialcommuNode);
            app.ExpresswaysideroadNode.Tag = 'Expressway-side road';
            app.ExpresswaysideroadNode.Text = 'Expressway-side road (公路-支路)';

            % Create Officeoutdoor
            app.OfficeOutdoorNode = uitreenode(app.TerrestrialcommuNode);
            app.OfficeOutdoorNode.Tag = 'OfficeOutdoor';
            app.OfficeOutdoorNode.Text = 'OfficeOutdoor(办公楼室外)';

            % Create InterofficeNode
            app.InterOfficeNode = uitreenode(app.TerrestrialcommuNode);
            app.InterOfficeNode.Tag = 'InterOffice';
            app.InterOfficeNode.Text = 'InterOffice(办公楼宇间)';

            % Create IndoorNode
            app.IndoorNode = uitreenode(app.TerrestrialcommuNode);
            app.IndoorNode.Tag = 'Indoor';
            app.IndoorNode.Text = 'Indoor(室内)';

            % Create IndoorCorridorNode
            app.IndoorCorridorNode = uitreenode(app.TerrestrialcommuNode);
            app.IndoorCorridorNode.Tag = 'Indoor-Corridor';
            app.IndoorCorridorNode.Text = 'Indoor-Corridor(室内-走廊)';

            % Create MaritimeNode
            app.MaritimeNode = uitreenode(app.Node_2);
            app.MaritimeNode.Text = '海洋 (Maritime)';

            % Create MaritimeShiptoshipNode
            app.MaritimeShiptoshipNode = uitreenode(app.MaritimeNode);
            app.MaritimeShiptoshipNode.Tag = 'Maritime-Ship to ship';
            app.MaritimeShiptoshipNode.Text = 'Maritime-Ship to ship（船对船）';

            % Create MaritimeShiptolandNode
            app.MaritimeShiptolandNode = uitreenode(app.MaritimeNode);
            app.MaritimeShiptolandNode.Tag = 'Maritime-Ship to land';
            app.MaritimeShiptolandNode.Text = 'Maritime-Ship to land（船对岸）';

            % Create V2VNode
            app.V2VNode = uitreenode(app.Node_2);
            app.V2VNode.Text = '车对车通信 (V2V)';

            % Create V2VHighwayNode
            app.V2VHighwayNode = uitreenode(app.V2VNode);
            app.V2VHighwayNode.Tag = 'V2V-Highway';
            app.V2VHighwayNode.Text = 'V2V-Highway(高速公路)';

            % Create V2VUrbanNode
            app.V2VUrbanNode = uitreenode(app.V2VNode);
            app.V2VUrbanNode.Tag = 'V2V-Urban';
            app.V2VUrbanNode.Text = 'V2V-Urban(城市)';

            % Create RISNode
            app.RISNode = uitreenode(app.Node_2);
            app.RISNode.Text = '智能反射面 (RIS)';

            % Create RISIndoorNode
            app.RISIndoorNode = uitreenode(app.RISNode);
            app.RISIndoorNode.Tag = 'RIS-Indoor';
            app.RISIndoorNode.Text = 'RIS-Indoor(室内)';

            % Create RISUMiNode
            app.RISUMiNode = uitreenode(app.RISNode);
            app.RISUMiNode.Tag = 'RIS-UMi';
            app.RISUMiNode.Text = 'RIS-UMi(城市微小区)';

            % Create RISUMaNode
            app.RISUMaNode = uitreenode(app.RISNode);
            app.RISUMaNode.Tag = 'RIS-UMa';
            app.RISUMaNode.Text = 'RIS-UMa(城市宏小区)';

            % Create RISRMaNode
            app.RISRMaNode = uitreenode(app.RISNode);
            app.RISRMaNode.Tag = 'RIS-RMa';
            app.RISRMaNode.Text = 'RIS-RMa(郊区)';

            % Create IIoTNode_2
            app.IIoTNode_2 = uitreenode(app.Node_2);
            app.IIoTNode_2.Text = '工业物联网 (IIoT)';

            % Create IIoT_LoSNode
            app.IIoT_LoSNode = uitreenode(app.IIoTNode_2);
            app.IIoT_LoSNode.Tag = 'IIoT_LoS';
            app.IIoT_LoSNode.Text = 'IIoT_LoS';

            % Create IIoTDH_NLoSNode
            app.IIoTDH_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTDH_NLoSNode.Tag = 'IIoT-DH_NLoS';
            app.IIoTDH_NLoSNode.Text = 'IIoT-DH_NLoS(障碍物密集_高天线)';

            % Create IIoTDL_NLoSNode
            app.IIoTDL_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTDL_NLoSNode.Tag = 'IIoT-DL_NLoS';
            app.IIoTDL_NLoSNode.Text = 'IIoT-DL_NLoS(障碍物密集_低天线)';

            % Create IIoTSH_NLoSNode
            app.IIoTSH_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTSH_NLoSNode.Tag = 'IIoT-SH_NLoS';
            app.IIoTSH_NLoSNode.Text = 'IIoT-SH_NLoS(障碍物稀少_高天线)';

            % Create IIoTSL_NLoSNode
            app.IIoTSL_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTSL_NLoSNode.Tag = 'IIoT-SL_NLoS';
            app.IIoTSL_NLoSNode.Text = 'IIoT-SL_NLoS(障碍物稀少_低天线)';

            % Create ISACNode
            app.ISACNode = uitreenode(app.Node_2);
            app.ISACNode.Text = '通感一体化 (ISAC)';

            % Create ISACUMaNode
            app.ISACUMaNode = uitreenode(app.ISACNode);
            app.ISACUMaNode.Tag = 'ISAC-UMa';
            app.ISACUMaNode.Text = 'ISAC-UMa(城市宏小区)';

            % Create ISACUMiNode
            app.ISACUMiNode = uitreenode(app.ISACNode);
            app.ISACUMiNode.Tag = 'ISAC-UMi';
            app.ISACUMiNode.Text = 'ISAC-UMi(城市微小区)';

            % Create ISACRMaNode
            app.ISACRMaNode = uitreenode(app.ISACNode);
            app.ISACRMaNode.Tag = 'ISAC-RMa';
            app.ISACRMaNode.Text = 'ISAC-RMa(郊区)';

            % Create ISACIndoorNode
            app.ISACIndoorNode = uitreenode(app.ISACNode);
            app.ISACIndoorNode.Tag = 'ISAC-Indoor';
            app.ISACIndoorNode.Text = 'ISAC-Indoor(室内)';

            % Create UHSTNode
            app.UHSTNode = uitreenode(app.Node_2);
            app.UHSTNode.Tag = 'UHST';
            app.UHSTNode.Text = '超高铁 (UHST)';

            % Create USNode
            app.USNode = uitreenode(app.Node_2);
            app.USNode.Text = '地下空间(US)';

            app.UStunnelNode = uitreenode(app.USNode);
            app.UStunnelNode.Tag = 'US-tunnel';
            app.UStunnelNode.Text = 'US-tunnel(地下隧道)';

            app.USgarageNode = uitreenode(app.USNode);
            app.USgarageNode.Tag = 'US-garage';
            app.USgarageNode.Text = 'US-garage(地下停车场)';

            app.Tree_2.SelectedNodes = app.IndoorNode;

            tools.display_RFOn(app);
            tools.display_systemUI(app);
            % set_freq_sub6Ghz_value
            app.Tree.SelectedNodes = app.sub6GHzNode;
            app.EditField.Value = '2.6';
            app.bandwidth.Value = '50';
            app.freqSamples.Value = '100';

            app.noCluster_5.Value = 15;

            if ~app.Button_Analysis.Enable
                app.guiAnalysisApp.DropDown_type.Items = {'时域/多普勒域信道统计特性 (Time domain)', '频域/时延域信道统计特性 (Frequency domain)', '空域/角度域信道统计特性 (Space domain)', '其他(Others)', '大尺度衰落 (Large scale fadings)'};
                tools.show_guiAnalysis_dropdownType(app.guiAnalysisApp);
            end

        case app.cmWaveNode.Text
            tempTree = app.Node_2.Children;
            tempTree.delete;
            % Create SatelliteNode
            app.SatelliteNode = uitreenode(app.Node_2);
            app.SatelliteNode.Text = '卫星(Satellite)';

            % Create SatelliteRuralNode
            app.SatelliteRuralNode = uitreenode(app.SatelliteNode);
            app.SatelliteRuralNode.Tag = 'Satellite-Rural';
            app.SatelliteRuralNode.Text = 'Satellite-Rural（乡村）';

            % Create SatelliteUrbanNode
            app.SatelliteUrbanNode = uitreenode(app.SatelliteNode);
            app.SatelliteUrbanNode.Tag = 'Satellite-Urban';
            app.SatelliteUrbanNode.Text = 'Satellite-Urban（城市）';

            % Create SatelliteSuburbanNode
            app.SatelliteSuburbanNode = uitreenode(app.SatelliteNode);
            app.SatelliteSuburbanNode.Tag = 'Satellite-Suburban';
            app.SatelliteSuburbanNode.Text = 'Satellite-Suburban（郊区）';

            % Create SatelliteDenseUrbanNode
            app.SatelliteDenseUrbanNode = uitreenode(app.SatelliteNode);
            app.SatelliteDenseUrbanNode.Tag = 'Satellite-DenseUrban';
            app.SatelliteDenseUrbanNode.Text = 'Satellite-DenseUrban（密集城市）';

            % Create UAVNode
            app.UAVNode = uitreenode(app.Node_2);
            app.UAVNode.Text = '无人机 (UAV)';

            % Create UAVUMiNode
            app.UAVUMiNode = uitreenode(app.UAVNode);
            app.UAVUMiNode.Tag = 'UAV-UMi';
            app.UAVUMiNode.Text = 'UAV-UMi(城市微小区)';

            % Create UAVUMaNode
            app.UAVUMaNode = uitreenode(app.UAVNode);
            app.UAVUMaNode.Tag = 'UAV-UMa';
            app.UAVUMaNode.Text = 'UAV-UMa(城市宏小区)';

            % Create UAVRMaNode
            app.UAVRMaNode = uitreenode(app.UAVNode);
            app.UAVRMaNode.Tag = 'UAV-RMa';
            app.UAVRMaNode.Text = 'UAV-RMa(郊区)';

            % Create TerrestrialcommuNode
            app.TerrestrialcommuNode = uitreenode(app.Node_2);
            app.TerrestrialcommuNode.Text = '地面通信 (Terrestrial commu.)';

            % Create UMiNode
            app.UMiNode = uitreenode(app.TerrestrialcommuNode);
            app.UMiNode.NodeData = '城市微小区场景';
            app.UMiNode.Tag = 'UMi';
            app.UMiNode.Text = 'UMi(城市微小区)';

            % Create UMaNode
            app.UMaNode = uitreenode(app.TerrestrialcommuNode);
            app.UMaNode.Tag = 'UMa';
            app.UMaNode.Text = 'UMa(城市宏小区)';

            % Create RMaNode
            app.RMaNode = uitreenode(app.TerrestrialcommuNode);
            app.RMaNode.Tag = 'RMa';
            app.RMaNode.Text = 'RMa(郊区)';

            % Create RMiNode
            app.RMiNode = uitreenode(app.TerrestrialcommuNode);
            app.RMiNode.NodeData = '郊区微小区场景';
            app.RMiNode.Tag = 'RMi';
            app.RMiNode.Text = 'RMi(郊区微小区)';

            % Create IndoorNode
            app.IndoorNode = uitreenode(app.TerrestrialcommuNode);
            app.IndoorNode.Tag = 'Indoor';
            app.IndoorNode.Text = 'Indoor(室内)';

            % Create IndoorCorridorNode
            app.IndoorCorridorNode = uitreenode(app.TerrestrialcommuNode);
            app.IndoorCorridorNode.Tag = 'Indoor-Corridor';
            app.IndoorCorridorNode.Text = 'Indoor-Corridor(室内-走廊)';

            % Create MaritimeNode
            app.MaritimeNode = uitreenode(app.Node_2);
            app.MaritimeNode.Text = '海洋 (Maritime)';

            % Create MaritimeShiptoshipNode
            app.MaritimeShiptoshipNode = uitreenode(app.MaritimeNode);
            app.MaritimeShiptoshipNode.Tag = 'Maritime-Ship to ship';
            app.MaritimeShiptoshipNode.Text = 'Maritime-Ship to ship（船对船）';

            % Create MaritimeShiptolandNode
            app.MaritimeShiptolandNode = uitreenode(app.MaritimeNode);
            app.MaritimeShiptolandNode.Tag = 'Maritime-Ship to land';
            app.MaritimeShiptolandNode.Text = 'Maritime-Ship to land（船对岸）';

            % Create V2VNode
            app.V2VNode = uitreenode(app.Node_2);
            app.V2VNode.Text = '车对车通信 (V2V)';

            % Create V2VHighwayNode
            app.V2VHighwayNode = uitreenode(app.V2VNode);
            app.V2VHighwayNode.Tag = 'V2V-Highway';
            app.V2VHighwayNode.Text = 'V2V-Highway(高速公路)';

            % Create V2VUrbanNode
            app.V2VUrbanNode = uitreenode(app.V2VNode);
            app.V2VUrbanNode.Tag = 'V2V-Urban';
            app.V2VUrbanNode.Text = 'V2V-Urban(城市)';

            % Create RISNode
            app.RISNode = uitreenode(app.Node_2);
            app.RISNode.Text = '智能反射面 (RIS)';

            % Create RISIndoorNode
            app.RISIndoorNode = uitreenode(app.RISNode);
            app.RISIndoorNode.Tag = 'RIS-Indoor';
            app.RISIndoorNode.Text = 'RIS-Indoor(室内)';

            % Create RISUMiNode
            app.RISUMiNode = uitreenode(app.RISNode);
            app.RISUMiNode.Tag = 'RIS-UMi';
            app.RISUMiNode.Text = 'RIS-UMi(城市微小区)';

            % Create RISUMaNode
            app.RISUMaNode = uitreenode(app.RISNode);
            app.RISUMaNode.Tag = 'RIS-UMa';
            app.RISUMaNode.Text = 'RIS-UMa(城市宏小区)';

            % Create RISRMaNode
            app.RISRMaNode = uitreenode(app.RISNode);
            app.RISRMaNode.Tag = 'RIS-RMa';
            app.RISRMaNode.Text = 'RIS-RMa(郊区)';

            % Create IIoTNode_2
            app.IIoTNode_2 = uitreenode(app.Node_2);
            app.IIoTNode_2.Text = '工业物联网 (IIoT)';

            % Create IIoT_LoSNode
            app.IIoT_LoSNode = uitreenode(app.IIoTNode_2);
            app.IIoT_LoSNode.Tag = 'IIoT_LoS';
            app.IIoT_LoSNode.Text = 'IIoT_LoS';

            % Create IIoTDH_NLoSNode
            app.IIoTDH_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTDH_NLoSNode.Tag = 'IIoT-DH_NLoS';
            app.IIoTDH_NLoSNode.Text = 'IIoT-DH_NLoS(障碍物密集_高天线)';

            % Create IIoTDL_NLoSNode
            app.IIoTDL_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTDL_NLoSNode.Tag = 'IIoT-DL_NLoS';
            app.IIoTDL_NLoSNode.Text = 'IIoT-DL_NLoS(障碍物密集_低天线)';

            % Create IIoTSH_NLoSNode
            app.IIoTSH_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTSH_NLoSNode.Tag = 'IIoT-SH_NLoS';
            app.IIoTSH_NLoSNode.Text = 'IIoT-SH_NLoS(障碍物稀少_高天线)';

            % Create IIoTSL_NLoSNode
            app.IIoTSL_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTSL_NLoSNode.Tag = 'IIoT-SL_NLoS';
            app.IIoTSL_NLoSNode.Text = 'IIoT-SL_NLoS(障碍物稀少_低天线)';

            % Create ISACNode
            app.ISACNode = uitreenode(app.Node_2);
            app.ISACNode.Text = '通感一体化 (ISAC)';

            % Create ISACUMaNode
            app.ISACUMaNode = uitreenode(app.ISACNode);
            app.ISACUMaNode.Tag = 'ISAC-UMa';
            app.ISACUMaNode.Text = 'ISAC-UMa(城市宏小区)';

            % Create ISACUMiNode
            app.ISACUMiNode = uitreenode(app.ISACNode);
            app.ISACUMiNode.Tag = 'ISAC-UMi';
            app.ISACUMiNode.Text = 'ISAC-UMi(城市微小区)';

            % Create ISACRMaNode
            app.ISACRMaNode = uitreenode(app.ISACNode);
            app.ISACRMaNode.Tag = 'ISAC-RMa';
            app.ISACRMaNode.Text = 'ISAC-RMa(郊区)';

            % Create ISACIndoorNode
            app.ISACIndoorNode = uitreenode(app.ISACNode);
            app.ISACIndoorNode.Tag = 'ISAC-Indoor';
            app.ISACIndoorNode.Text = 'ISAC-Indoor(室内)';

            % Create UHSTNode
            app.UHSTNode = uitreenode(app.Node_2);
            app.UHSTNode.Tag = 'UHST';
            app.UHSTNode.Text = '超高铁 (UHST)';

            app.Tree_2.SelectedNodes = app.IndoorNode;
            tools.display_RFOn(app);
            tools.display_systemUI(app);
            app.EditField.Value = '10';
            app.bandwidth.Value = '200';
            app.freqSamples.Value = '100';
            app.noCluster_5.Value = 10;

            if ~app.Button_Analysis.Enable
                app.guiAnalysisApp.DropDown_type.Items = {'时域/多普勒域信道统计特性 (Time domain)', '频域/时延域信道统计特性 (Frequency domain)', '空域/角度域信道统计特性 (Space domain)', '其他(Others)', '大尺度衰落 (Large scale fadings)'};
                tools.show_guiAnalysis_dropdownType(app.guiAnalysisApp);
            end

        case app.mmWaveNode.Text
            tempTree = app.Node_2.Children;
            tempTree.delete;
            % Create SatelliteNode
            app.SatelliteNode = uitreenode(app.Node_2);
            app.SatelliteNode.Text = '卫星(Satellite)';

            % Create SatelliteRuralNode
            app.SatelliteRuralNode = uitreenode(app.SatelliteNode);
            app.SatelliteRuralNode.Tag = 'Satellite-Rural';
            app.SatelliteRuralNode.Text = 'Satellite-Rural（乡村）';

            % Create SatelliteUrbanNode
            app.SatelliteUrbanNode = uitreenode(app.SatelliteNode);
            app.SatelliteUrbanNode.Tag = 'Satellite-Urban';
            app.SatelliteUrbanNode.Text = 'Satellite-Urban（城市）';

            % Create SatelliteSuburbanNode
            app.SatelliteSuburbanNode = uitreenode(app.SatelliteNode);
            app.SatelliteSuburbanNode.Tag = 'Satellite-Suburban';
            app.SatelliteSuburbanNode.Text = 'Satellite-Suburban（郊区）';

            % Create SatelliteDenseUrbanNode
            app.SatelliteDenseUrbanNode = uitreenode(app.SatelliteNode);
            app.SatelliteDenseUrbanNode.Tag = 'Satellite-DenseUrban';
            app.SatelliteDenseUrbanNode.Text = 'Satellite-DenseUrban（密集城市）';

            % Create UAVNode
            app.UAVNode = uitreenode(app.Node_2);
            app.UAVNode.Text = '无人机 (UAV)';

            % Create UAVUMiNode
            app.UAVUMiNode = uitreenode(app.UAVNode);
            app.UAVUMiNode.Tag = 'UAV-UMi';
            app.UAVUMiNode.Text = 'UAV-UMi(城市微小区)';

            % Create UAVUMaNode
            app.UAVUMaNode = uitreenode(app.UAVNode);
            app.UAVUMaNode.Tag = 'UAV-UMa';
            app.UAVUMaNode.Text = 'UAV-UMa(城市宏小区)';

            % Create UAVRMaNode
            app.UAVRMaNode = uitreenode(app.UAVNode);
            app.UAVRMaNode.Tag = 'UAV-RMa';
            app.UAVRMaNode.Text = 'UAV-RMa(郊区)';

            % Create TerrestrialcommuNode
            app.TerrestrialcommuNode = uitreenode(app.Node_2);
            app.TerrestrialcommuNode.Text = '地面通信 (Terrestrial commu.)';

            % Create UMiNode
            app.UMiNode = uitreenode(app.TerrestrialcommuNode);
            app.UMiNode.NodeData = '城市微小区场景';
            app.UMiNode.Tag = 'UMi';
            app.UMiNode.Text = 'UMi(城市微小区)';

            % Create UMaNode
            app.UMaNode = uitreenode(app.TerrestrialcommuNode);
            app.UMaNode.Tag = 'UMa';
            app.UMaNode.Text = 'UMa(城市宏小区)';

            % Create RMaNode
            app.RMaNode = uitreenode(app.TerrestrialcommuNode);
            app.RMaNode.Tag = 'RMa';
            app.RMaNode.Text = 'RMa(郊区)';

            % Create RMiNode
            app.RMiNode = uitreenode(app.TerrestrialcommuNode);
            app.RMiNode.NodeData = '郊区微小区场景';
            app.RMiNode.Tag = 'RMi';
            app.RMiNode.Text = 'RMi(郊区微小区)';

            % Create IndoorNode
            app.IndoorNode = uitreenode(app.TerrestrialcommuNode);
            app.IndoorNode.Tag = 'Indoor';
            app.IndoorNode.Text = 'Indoor(室内)';

            % Create IndoorCorridorNode
            app.IndoorCorridorNode = uitreenode(app.TerrestrialcommuNode);
            app.IndoorCorridorNode.Tag = 'Indoor-Corridor';
            app.IndoorCorridorNode.Text = 'Indoor-Corridor(室内-走廊)';

            % Create MaritimeNode
            app.MaritimeNode = uitreenode(app.Node_2);
            app.MaritimeNode.Text = '海洋 (Maritime)';

            % Create MaritimeShiptoshipNode
            app.MaritimeShiptoshipNode = uitreenode(app.MaritimeNode);
            app.MaritimeShiptoshipNode.Tag = 'Maritime-Ship to ship';
            app.MaritimeShiptoshipNode.Text = 'Maritime-Ship to ship（船对船）';

            % Create MaritimeShiptolandNode
            app.MaritimeShiptolandNode = uitreenode(app.MaritimeNode);
            app.MaritimeShiptolandNode.Tag = 'Maritime-Ship to land';
            app.MaritimeShiptolandNode.Text = 'Maritime-Ship to land（船对岸）';

            % Create V2VNode
            app.V2VNode = uitreenode(app.Node_2);
            app.V2VNode.Text = '车对车通信 (V2V)';

            % Create V2VHighwayNode
            app.V2VHighwayNode = uitreenode(app.V2VNode);
            app.V2VHighwayNode.Tag = 'V2V-Highway';
            app.V2VHighwayNode.Text = 'V2V-Highway(高速公路)';

            % Create V2VUrbanNode
            app.V2VUrbanNode = uitreenode(app.V2VNode);
            app.V2VUrbanNode.Tag = 'V2V-Urban';
            app.V2VUrbanNode.Text = 'V2V-Urban(城市)';

            % Create RISNode
            app.RISNode = uitreenode(app.Node_2);
            app.RISNode.Text = '智能反射面 (RIS)';

            % Create RISIndoorNode
            app.RISIndoorNode = uitreenode(app.RISNode);
            app.RISIndoorNode.Tag = 'RIS-Indoor';
            app.RISIndoorNode.Text = 'RIS-Indoor(室内)';

            % Create RISUMiNode
            app.RISUMiNode = uitreenode(app.RISNode);
            app.RISUMiNode.Tag = 'RIS-UMi';
            app.RISUMiNode.Text = 'RIS-UMi(城市微小区)';

            % Create RISUMaNode
            app.RISUMaNode = uitreenode(app.RISNode);
            app.RISUMaNode.Tag = 'RIS-UMa';
            app.RISUMaNode.Text = 'RIS-UMa(城市宏小区)';

            % Create RISRMaNode
            app.RISRMaNode = uitreenode(app.RISNode);
            app.RISRMaNode.Tag = 'RIS-RMa';
            app.RISRMaNode.Text = 'RIS-RMa(郊区)';

            % Create IIoTNode_2
            app.IIoTNode_2 = uitreenode(app.Node_2);
            app.IIoTNode_2.Text = '工业物联网 (IIoT)';

            % Create IIoT_LoSNode
            app.IIoT_LoSNode = uitreenode(app.IIoTNode_2);
            app.IIoT_LoSNode.Tag = 'IIoT_LoS';
            app.IIoT_LoSNode.Text = 'IIoT_LoS';

            % Create IIoTDH_NLoSNode
            app.IIoTDH_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTDH_NLoSNode.Tag = 'IIoT-DH_NLoS';
            app.IIoTDH_NLoSNode.Text = 'IIoT-DH_NLoS(障碍物密集_高天线)';

            % Create IIoTDL_NLoSNode
            app.IIoTDL_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTDL_NLoSNode.Tag = 'IIoT-DL_NLoS';
            app.IIoTDL_NLoSNode.Text = 'IIoT-DL_NLoS(障碍物密集_低天线)';

            % Create IIoTSH_NLoSNode
            app.IIoTSH_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTSH_NLoSNode.Tag = 'IIoT-SH_NLoS';
            app.IIoTSH_NLoSNode.Text = 'IIoT-SH_NLoS(障碍物稀少_高天线)';

            % Create IIoTSL_NLoSNode
            app.IIoTSL_NLoSNode = uitreenode(app.IIoTNode_2);
            app.IIoTSL_NLoSNode.Tag = 'IIoT-SL_NLoS';
            app.IIoTSL_NLoSNode.Text = 'IIoT-SL_NLoS(障碍物稀少_低天线)';

            % Create ISACNode
            app.ISACNode = uitreenode(app.Node_2);
            app.ISACNode.Text = '通感一体化 (ISAC)';

            % Create ISACUMaNode
            app.ISACUMaNode = uitreenode(app.ISACNode);
            app.ISACUMaNode.Tag = 'ISAC-UMa';
            app.ISACUMaNode.Text = 'ISAC-UMa(城市宏小区)';

            % Create ISACUMiNode
            app.ISACUMiNode = uitreenode(app.ISACNode);
            app.ISACUMiNode.Tag = 'ISAC-UMi';
            app.ISACUMiNode.Text = 'ISAC-UMi(城市微小区)';

            % Create ISACRMaNode
            app.ISACRMaNode = uitreenode(app.ISACNode);
            app.ISACRMaNode.Tag = 'ISAC-RMa';
            app.ISACRMaNode.Text = 'ISAC-RMa(郊区)';

            % Create ISACIndoorNode
            app.ISACIndoorNode = uitreenode(app.ISACNode);
            app.ISACIndoorNode.Tag = 'ISAC-Indoor';
            app.ISACIndoorNode.Text = 'ISAC-Indoor(室内)';

            % Create UHSTNode
            app.UHSTNode = uitreenode(app.Node_2);
            app.UHSTNode.Tag = 'UHST';
            app.UHSTNode.Text = '超高铁 (UHST)';

            app.Tree_2.SelectedNodes = app.IndoorNode;
            tools.display_RFOn(app);
            tools.display_systemUI(app);
            app.EditField.Value = '50';
            app.bandwidth.Value = '500';
            app.freqSamples.Value = '100';
            app.noCluster_5.Value = 10;

            if ~app.Button_Analysis.Enable
                app.guiAnalysisApp.DropDown_type.Items = {'时域/多普勒域信道统计特性 (Time domain)', '频域/时延域信道统计特性 (Frequency domain)', '空域/角度域信道统计特性 (Space domain)', '其他(Others)', '大尺度衰落 (Large scale fadings)'};
                tools.show_guiAnalysis_dropdownType(app.guiAnalysisApp);
            end

        case app.THzNode.Text
            tempTree = app.Node_2.Children;
            tempTree.delete;
            % Create TerrestrialcommuNode
            app.TerrestrialcommuNode = uitreenode(app.Node_2);
            app.TerrestrialcommuNode.Text = '地面通信 (Terrestrial commu.)';

            % Create IndoorNode
            app.IndoorNode = uitreenode(app.TerrestrialcommuNode);
            app.IndoorNode.Tag = 'Indoor';
            app.IndoorNode.Text = 'Indoor(室内)';

            app.Tree_2.SelectedNodes = app.IndoorNode;

            app.NLoSO2IButton.Enable = 'off';
            app.LoSO2IButton.Enable = 'off';

            app.NLoSvButton.Enable = 'off';
            app.LoSButton.Enable = 'on';
            app.NLoSButton.Enable = 'on';
            app.NLoSButton.Value = 1;

            tools.display_RFOn(app);
            tools.display_systemUI(app);
            app.EditField.Value = '300';
            app.bandwidth.Value = '2000';
            app.freqSamples.Value = '100';
            app.noCluster_5.Value = 5;

            if ~app.Button_Analysis.Enable
                app.guiAnalysisApp.DropDown_type.Items = {'时域/多普勒域信道统计特性 (Time domain)', '频域/时延域信道统计特性 (Frequency domain)', '空域/角度域信道统计特性 (Space domain)', '其他(Others)','大尺度衰落 (Large scale fadings)'};
                tools.show_guiAnalysis_dropdownType(app.guiAnalysisApp);
            end
        case app.IRNode.Text
            tempTree = app.Node_2.Children;
            tempTree.delete;
            % Create TerrestrialcommuNode
            app.TerrestrialcommuNode = uitreenode(app.Node_2);
            app.TerrestrialcommuNode.Text = '地面通信 (Terrestrial commu.)';

            % Create IndoorNode
            app.IndoorNode = uitreenode(app.TerrestrialcommuNode);
            app.IndoorNode.Tag = 'Indoor';
            app.IndoorNode.Text = 'Indoor(室内)';

            app.Tree_2.SelectedNodes = app.IndoorNode;

            app.EditField.Value = '10000';
            app.freqSamples.Value = '100';
            tools.display_RFOff(app);
            app.OWCPanel.Position = app.panelPos1.Position;

            if ~app.Button_Analysis.Enable
                app.guiAnalysisApp.DropDown_type.Items = {'时域/多普勒域信道统计特性 (Time domain)', '频域/时延域信道统计特性 (Frequency domain)', '空域/角度域信道统计特性 (Space domain)'};
                tools.show_guiAnalysis_dropdownType(app.guiAnalysisApp);
            end
            app.DropDown_tx.Items = {'点(point)'};
            app.DropDown_rx.Items = {'点(point)'};
        case app.VLNode.Text
            tempTree = app.Node_2.Children;
            tempTree.delete;
            % Create TerrestrialcommuNode
            app.TerrestrialcommuNode = uitreenode(app.Node_2);
            app.TerrestrialcommuNode.Text = '地面通信 (Terrestrial commu.)';

            % Create IndoorNode
            app.IndoorNode = uitreenode(app.TerrestrialcommuNode);
            app.IndoorNode.Tag = 'Indoor';
            app.IndoorNode.Text = 'Indoor(室内)';

            app.Tree_2.SelectedNodes = app.IndoorNode;

            app.EditField.Value = '395000';
            app.freqSamples.Value = '100';
            tools.display_RFOff(app);
            app.OWCPanel.Position = app.panelPos1.Position;

            if ~app.Button_Analysis.Enable
                app.guiAnalysisApp.DropDown_type.Items = {'时域/多普勒域信道统计特性 (Time domain)', '频域/时延域信道统计特性 (Frequency domain)', '空域/角度域信道统计特性 (Space domain)'};
                tools.show_guiAnalysis_dropdownType(app.guiAnalysisApp);
            end
        case app.UVNode.Text
            tempTree = app.Node_2.Children;
            tempTree.delete;
            % Create TerrestrialcommuNode
            app.TerrestrialcommuNode = uitreenode(app.Node_2);
            app.TerrestrialcommuNode.Text = '地面通信 (Terrestrial commu.)';

            % Create IndoorNode
            app.IndoorNode = uitreenode(app.TerrestrialcommuNode);
            app.IndoorNode.Tag = 'Indoor';
            app.IndoorNode.Text = 'Indoor(室内)';
            app.Tree_2.SelectedNodes = app.IndoorNode;
            app.EditField.Value = '750000';
            app.freqSamples.Value = '100';
            tools.display_RFOff(app);
            app.OWCPanel.Position = app.panelPos1.Position;

            if ~app.Button_Analysis.Enable
                app.guiAnalysisApp.DropDown_type.Items = {'时域/多普勒域信道统计特性 (Time domain)', '频域/时延域信道统计特性 (Frequency domain)', '空域/角度域信道统计特性 (Space domain)'};
                tools.show_guiAnalysis_dropdownType(app.guiAnalysisApp);
            end
    end
    %     if (strcmp(app.Tree.SelectedNodes.Text, app.sub6GHzNode.Text) || strcmp(app.Tree.SelectedNodes.Text, app.mmWaveNode.Text)) && (strcmp(app.Tree_2.SelectedNodes.Text, app.UMiNode.Text)...
    %             || strcmp(app.Tree_2.SelectedNodes.Text, app.UMaNode.Text) || strcmp(app.Tree_2.SelectedNodes.Text, app.RMaNode.Text))
    %         app.NLoSO2IButton.Enable = 'on';
    %         app.LoSO2IButton.Enable = 'on';
    %     else
    app.NLoSO2IButton.Enable = 'off';
    app.LoSO2IButton.Enable = 'off';
    app.LoSO2IButton.Value = 0;
    app.NLoSO2IButton.Value = 0;
    %     end
end
end