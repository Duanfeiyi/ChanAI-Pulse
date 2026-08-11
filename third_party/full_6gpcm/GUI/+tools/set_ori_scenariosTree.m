function set_ori_scenariosTree(app)
%SET_ORI_SCENARIOSTREE 此处显示有关此函数的摘要
%   此处显示详细说明
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

    % Create SkyWaveNodeNode
    app.SkyWaveNode = uitreenode(app.TerrestrialcommuNode);
    app.SkyWaveNode.Text = '天波(SkyWave)';
    app.SkyWaveNode.Tag = 'SkyWave';

    % Create GroundWaveNodeNode
    app.GroundWaveNode = uitreenode(app.TerrestrialcommuNode);
    app.GroundWaveNode.Text = '地波(GroundWave)';
    app.GroundWaveNode.Tag = 'GroundWave';

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

    % Create UWANode
    app.UWANode = uitreenode(app.Node_2);
    app.UWANode.Text = '水下通信(UWA)';

    % Create UWANode
    app.UWAShallowWaterNode = uitreenode(app.UWANode);
    app.UWAShallowWaterNode.Text = 'UWA-ShallowWater(浅海域)';
    app.UWAShallowWaterNode.Tag = 'UWA-ShallowWater';

end

