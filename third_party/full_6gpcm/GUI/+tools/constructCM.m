function cm = constructCM(app, scenario)
global antennaSwitch;
antennaSwitch = 1;
dualPolFlagTx = 0;
dualPolFlagRx = 0;
if tools.is_owc_band(scenario, app)
    app.sps.color_VLC = app.LEDColor.Value;
    app.sps.radiant_type_VLC = app.LEDType.Value;
    cm = channel_model(app.sps);
    cm.clusters.num_clusters = app.noCluster_6.Value;
    cm.clusters.num_rays_each_cluster = app.noRaysEachCluster_6.Value;
else
    if strfind(scenario, app.sps.freqband_SHORTWAVE)
        cm = channel_model(app.sps);
        cm.clusters.num_rays_each_cluster = app.noRaysEachCluster_7.Value;
    else
        cm = channel_model(app.sps);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 240202 sgxy 
    % 从界面上的表格获取到信息
    array_list = table2array(app.UITable_antenna.Data);
    array_index = array_list(:,1);
    tx_track_list = table2array(app.UITable_tx.Data);
    rx_track_list = table2array(app.UITable_rx.Data);
    % 获取天线列信息
    tx_array_pos = ones(length(tx_track_list(:,4)),1);
    rx_array_pos = ones(length(rx_track_list(:,4)),1);
    % 二者做匹配
    array_index = str2double(array_index);
    for i = 1 : numel(tx_array_pos)
        tx_track_list{i,4} = str2double(tx_track_list{i,4});
        logical_indices = ismember(array_index,tx_track_list{i,4});
        positions = find(logical_indices);
        %发射端运动轨迹天线编号不能为空, 请在运动轨迹页面进行设置
        if isempty(positions)
            error('The antenna id of the user in the Tx side can not be empty, please set these parameters on the Track page');
        end
        tx_array_pos(i) = positions;
    end
    for i = 1 : numel(rx_array_pos)
        rx_track_list{i,4} = str2double(rx_track_list{i,4});
        logical_indices = ismember(array_index,rx_track_list{i,4});
        positions = find(logical_indices);
        %接收端运动轨迹天线编号不能为空, 请在运动轨迹页面进行设置
        if isempty(positions)
            error('The antenna id of the user in the Rx side can not be empty, please set these parameters on the Track page');
        end
        rx_array_pos(i) = positions;
    end

    if length(app.sps.carrier_frequency)>1
        cm.nSPL = 4;
        cm.lambda_s = 0.2;
        cm.pstable = 0.1;
    end

    % 初始化Tx天线信息
    for i = 1 : numel(tx_array_pos)
        if iscell(array_list(tx_array_pos(i),10))   
                 array1 = string(array_list(tx_array_pos(i),10)); 
        else
                 array1 = array_list(tx_array_pos(i),10);
        end
        if iscell(array_list(tx_array_pos(i),12))   
                 array2 = string(array_list(tx_array_pos(i),12)); 
        else
                 array2 = array_list(tx_array_pos(i),12);
        end  
        switch array1
            case '理想点源(Ideal point source)'
                antennaSwitch = 0;
                EfieldThetaTx = [];
                EfieldPhiTx = [];
            case '全向单极化(垂直)(Omnidirectional single polarization (vertical))'
                EfieldThetaTx = ones(181,360);
                EfieldPhiTx = zeros(181,360);
            case '全向单极化(水平)(Omnidirectional unipolarization (horizontal))'
                EfieldThetaTx = zeros(181,360);
                EfieldPhiTx = ones(181,360);
            case '全向±45°双极化(Omnidirectional ±45° dual polarization)'
                dualPolFlagTx = 1;
                EfieldThetaTx = ones(181,360);
                EfieldPhiTx = ones(181,360);                
            case '自定义(user-defined)'
                patternTx = importdata(array_list(tx_array_pos(i),11));
                patternTx = patternTx.data;
                EfieldThetaTx = reshape(patternTx(:,4).*exp(1j*patternTx(:,5)/180*pi),181,360);
                EfieldPhiTx = reshape(patternTx(:,6).*exp(1j*patternTx(:,7)/180*pi),181,360);
        end
        
        switch array2
            case '均匀线阵(ULA)'
                for i_freq = 1:length(app.sps.carrier_frequency)
                    cm.tx_array(i,i_freq) = antenna_array('linear',str2double(array_list(tx_array_pos(i),3)),app.sps.carrier_frequency(i_freq) ...
                        ,str2double(array_list(tx_array_pos(i),5)),EfieldThetaTx,EfieldPhiTx,str2double(array_list(tx_array_pos(i),7))*pi/180 ...
                        ,str2double(array_list(tx_array_pos(i),8))*pi/180,str2double(array_list(tx_array_pos(i),9))*pi/180);
                    
                    cm.tx_array(i,i_freq).dual_pol_flag = dualPolFlagTx;
                end
            case '均匀面阵(UPA)'
                for i_freq = 1:length(app.sps.carrier_frequency)
                    cm.tx_array(i,i_freq) = antenna_array('planar',str2double(array_list(tx_array_pos(i),3)),str2double(array_list(tx_array_pos(i),4)), ...
                        app.sps.carrier_frequency(i_freq),str2double(array_list(tx_array_pos(i),5)),str2double(array_list(tx_array_pos(i),6)), ...
                        EfieldThetaTx,EfieldPhiTx,[str2double(array_list(tx_array_pos(i),7))*pi/180, ...
                        str2double(array_list(tx_array_pos(i),8))*pi/180,str2double(array_list(tx_array_pos(i),9))*pi/180]);
                    
                    cm.tx_array(i,i_freq).dual_pol_flag = dualPolFlagTx;
                end
            case '圆柱阵列(Cylindrical)'
                for i_freq = 1:length(app.sps.carrier_frequency)
                    cm.tx_array(i,i_freq) = antenna_array('cylindrical',str2double(array_list(tx_array_pos(i),3)),str2double(array_list(tx_array_pos(i),4)), ...
                        app.sps.carrier_frequency(i_freq),str2double(array_list(tx_array_pos(i),5)),str2double(array_list(tx_array_pos(i),6)), ...
                        EfieldThetaTx,EfieldPhiTx,[str2double(array_list(tx_array_pos(i),7))*pi/180, ...
                        str2double(array_list(tx_array_pos(i),8))*pi/180,str2double(array_list(tx_array_pos(i),9))*pi/180]);
                    
                    cm.tx_array(i,i_freq).dual_pol_flag = dualPolFlagTx;
                end
        end
    end
    
    % 初始化Rx天线信息
    for i = 1 : numel(rx_array_pos)
        if iscell(array_list(rx_array_pos(i),10))   
                 array3 = string(array_list(rx_array_pos(i),10)); 
        else
                 array3 = array_list(rx_array_pos(i),10);
        end
        if iscell(array_list(rx_array_pos(i),12))   
                 array4 = string(array_list(rx_array_pos(i),12)); 
        else
                 array4 = array_list(rx_array_pos(i),12);
        end  
        switch array3
            case '理想点源(Ideal point source)'
                antennaSwitch = 0;
                EfieldThetaRx = [];
                EfieldPhiRx = [];
            case '全向单极化(垂直)(Omnidirectional single polarization (vertical))'
                EfieldThetaRx = ones(181,360);
                EfieldPhiRx = zeros(181,360);
            case '全向单极化(水平)(Omnidirectional unipolarization (horizontal))'
                EfieldThetaRx = zeros(181,360);
                EfieldPhiRx = ones(181,360);
            case '全向±45°双极化(Omnidirectional ±45° dual polarization)'
                dualPolFlagRx = 1;
                EfieldThetaRx = ones(181,360);
                EfieldPhiRx = ones(181,360);                
            case '自定义(user-defined)'
                patternRx = importdata(array_list(rx_array_pos(i),11));
                patternRx = patternRx.data;
                EfieldThetaRx = reshape(patternRx(:,4).*exp(1j*patternRx(:,5)/180*pi),181,360);
                EfieldPhiRx = reshape(patternRx(:,6).*exp(1j*patternRx(:,7)/180*pi),181,360);
        end
        
        switch array4
            case '均匀线阵(ULA)'
                for i_freq = 1:length(app.sps.carrier_frequency)
                    cm.rx_array(i,i_freq) = antenna_array('linear',str2double(array_list(rx_array_pos(i),3)),app.sps.carrier_frequency(i_freq) ...
                        ,str2double(array_list(rx_array_pos(i),5)),EfieldThetaRx,EfieldPhiRx,str2double(array_list(rx_array_pos(i),7))*pi/180 ...
                        ,str2double(array_list(rx_array_pos(i),8))*pi/180,str2double(array_list(rx_array_pos(i),9))*pi/180);
                    
                    cm.rx_array(i,i_freq).dual_pol_flag = dualPolFlagRx;
                end
            case '均匀面阵(UPA)'
                for i_freq = 1:length(app.sps.carrier_frequency)
                    cm.rx_array(i,i_freq) = antenna_array('planar',str2double(array_list(rx_array_pos(i),3)),str2double(array_list(rx_array_pos(i),4)), ...
                        app.sps.carrier_frequency(i_freq),str2double(array_list(rx_array_pos(i),5)),str2double(array_list(rx_array_pos(i),6)), ...
                        EfieldThetaRx, EfieldPhiRx, [str2double(array_list(rx_array_pos(i),7))*pi/180, ...
                        str2double(array_list(rx_array_pos(i),8))*pi/180,str2double(array_list(rx_array_pos(i),9))*pi/180]);
                    
                    cm.rx_array(i,i_freq).dual_pol_flag = dualPolFlagRx;
                end
            case '圆柱阵列(Cylindrical)'
                for i_freq = 1:length(app.sps.carrier_frequency)
                    cm.rx_array(i,i_freq) = antenna_array('cylindrical',str2double(array_list(rx_array_pos(i),3)),str2double(array_list(rx_array_pos(i),4)), ...
                        app.sps.carrier_frequency(i_freq),str2double(array_list(rx_array_pos(i),5)),str2double(array_list(rx_array_pos(i),6)), ...
                        EfieldThetaRx, EfieldPhiRx, [str2double(array_list(rx_array_pos(i),7))*pi/180, ...
                        str2double(array_list(rx_array_pos(i),8))*pi/180,str2double(array_list(rx_array_pos(i),9))*pi/180]);
                    
                    cm.rx_array(i,i_freq).dual_pol_flag = dualPolFlagRx;
                end
        end
    end
    anOri1 = mf.str2positions(app.anOri.Value);
    [an_azimuth, an_elevation, ~] = cart2sph(anOri1(1), anOri1(2), anOri1(3));
    znOri1 = mf.str2positions(app.znOri.Value);
    [zn_azimuth, zn_elevation, ~] = cart2sph(znOri1(1), znOri1(2), znOri1(3));
    % 240202 sgxy
    for i = 1 : numel(tx_array_pos)
        for j = 1 : numel(rx_array_pos)
            cm.clusters(i,j).an_move_speed = app.anSpeed.Value;
            cm.clusters(i,j).an_move_direc_azimuth = an_azimuth;
            cm.clusters(i,j).an_move_direc_elevation = an_elevation;
            
            cm.clusters(i,j).zn_move_speed = app.znSpeed.Value;
            cm.clusters(i,j).zn_move_direc_azimuth = zn_azimuth;
            cm.clusters(i,j).zn_move_direc_elevation = zn_elevation;
        end
    end
       
    if strfind(scenario, app.sps.scenario_SATELLITE)
        cm.sim_params.scen_para.rain_rate = app.rainRate.Value;
        for i = 1 : numel(tx_array_pos)
            for j = 1 : numel(rx_array_pos)
                cm.clusters(i,j).num_clusters = app.noCluster_4.Value;
                cm.clusters(i,j).num_rays_each_cluster = app.noRaysEachCluster_4.Value;
            end
        end
    elseif strfind(scenario,  app.sps.scenario_RIS)
        cm.sim_params.scen_para.Nc0_B2RIS = app.noCluster_RIS1.Value;
        cm.sim_params.scen_para.Nc0_B2U = app.noCluster_RIS3.Value;
        cm.sim_params.scen_para.NumRay_B2RIS = app.noRaysEachCluster_RIS1.Value;
        cm.sim_params.scen_para.NumRay_B2U = app.noRaysEachCluster_RIS3.Value;
        cm.ris = tools.gen_ris_gui(app);
    elseif strfind(scenario, app.sps.scenario_MARITIME)
        for i = 1 : numel(tx_array_pos)
            for j = 1 : numel(rx_array_pos)
                cm.clusters(i,j).num_clusters = app.noCluster_2.Value;
                cm.clusters(i,j).num_rays_each_cluster = app.noRaysEachCluster_2.Value;
            end
        end
    else        
        % 240202 sgxy
        for i = 1 : numel(tx_array_pos)
            for j = 1 : numel(rx_array_pos)
                cm.clusters(i,j).num_clusters = app.noCluster_5.Value;
                cm.clusters(i,j).num_rays_each_cluster = app.noRaysEachCluster_5.Value;
            end
        end
    end
end
