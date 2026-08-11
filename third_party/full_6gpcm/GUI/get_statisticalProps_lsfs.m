function get_statisticalProps_lsfs(app, cm, tx_track, rx_track, savePath, ssps)
    flag_confs = tools.get_lsfsState(app, app.CallingApp);
    d_waitbar = uiprogressdlg(app.UIFigure, 'Title', 'Simulation of large-scale fading', 'Message', 'Simulating... ...', 'Indeterminate','on');
    fc_GHz = cm.sim_params.carrier_frequency' / 1e9;  
    no_F = numel(fc_GHz);
    oF = ones( no_F,1 );
    bl_not_supported_scens = {cm.sim_params.scenario_RIS, cm.sim_params.scenario_UHST, cm.sim_params.scenario_MARITIME, cm.sim_params.scenario_IIOT,cm.sim_params.scenario_ISAC};
    flag_lsfs.lsfs_pl = flag_confs.lsfs_pl * oF;
    flag_lsfs.lsfs_bl = (flag_confs.lsfs_bl && contains(cm.sim_params.scenarioName, cm.sim_params.freqband_MMWAVE) &&...
        ~contains(cm.sim_params.scenarioName, bl_not_supported_scens) ) * oF;
    flag_lsfs.lsfs_al = flag_confs.lsfs_al * (fc_GHz <= 1000 & fc_GHz >= 1);
    flag_lsfs.lsfs_ot = flag_confs.lsfs_ot * oF;
    flag_lsfs.o2i = flag_confs.o2i * oF;
	flag_lsfs.Lo = flag_confs.Lo;
	flag_lsfs.La = flag_confs.La;

    i_txUser = str2num(app.DropDown_txUserIndex_lsfs.Value);
    i_rxUser = str2num(app.DropDown_rxUserIndex_lsfs.Value);
    tx_track = tx_track(i_txUser);
    rx_track = rx_track(i_rxUser);
    
    get_lsfs(cm, flag_lsfs, tx_track, rx_track, savePath, app.CallingApp.lsf_confs, ssps);
    
    for i_freq = 1:length(fc_GHz)
        legend_name{i_freq} = [num2str(fc_GHz(i_freq)),' GHz'];
    end
    
    get_lsfs(cm, flag_lsfs, tx_track, rx_track, savePath, app.CallingApp.lsf_confs, ssps);
    
    % 路径损耗
    if flag_lsfs.lsfs_pl
        app.Label_PLConcerned.Visible = false;
        strName = strcat(savePath, filesep, 'pathloss', '.mat');
        load(strName, 'pathloss' );
        PL_x = (1:length(pathloss)) / app.CallingApp.sampleRate.Value;
        PL_y = pathloss;
        plot(app.UIAxes_PL,PL_x,PL_y);
        legend(app.UIAxes_PL,legend_name);
    else
        app.Label_PLConcerned.Visible = true;
        legend(app.UIAxes_PL, 'off');
        cla(app.UIAxes_PL);
    end
    
    % 阻挡损耗
    if flag_lsfs.lsfs_bl
        app.Label_BLConcerned.Visible = false;
        strName = strcat(savePath, filesep, 'blockloss', '.mat');
        load(strName, 'blockloss' );
        BL_x = (1:length(blockloss)) / app.CallingApp.sampleRate.Value;
        BL_y = blockloss;
        plot(app.UIAxes_BL,BL_x,BL_y);
        legend(app.UIAxes_BL,legend_name);
    else
        app.Label_BLConcerned.Visible = true;
        legend(app.UIAxes_BL, 'off');
        cla(app.UIAxes_BL);
    end
    
    % 大气吸收损耗
    if flag_lsfs.lsfs_al
        app.Label_ALConcerned.Visible = false;
        strName = strcat(savePath, filesep, 'atmospheric attenuation', '.mat');
        load(strName, 'pl_t' );
        AL_x = (1:length(pl_t)) / app.CallingApp.sampleRate.Value;
        AL_y = pl_t;
        plot(app.UIAxes_AL,AL_x,AL_y);
        legend(app.UIAxes_AL,legend_name);
    else
        app.Label_ALConcerned.Visible = true;
        legend(app.UIAxes_AL, 'off');
        cla(app.UIAxes_AL);
    end
    
    % 其他损耗
    if flag_lsfs.lsfs_ot(1) && (contains(app.CallingApp.scenarios,'UMi') || contains(app.CallingApp.scenarios,'UMa') || contains(app.CallingApp.scenarios,'RMa')) && ~contains(app.CallingApp.scenarios,'VHF')
        app.Label_OTConcerned.Visible = false;
        strName = strcat(savePath, filesep, 'rain attenuation', '.mat');
        load(strName, 'pl_r' );
        RA_x = (1:length(pl_r)) / app.CallingApp.sampleRate.Value;
        RA_y = pl_r;
        plot(app.UIAxes_OT,RA_x,RA_y);
        hold(app.UIAxes_OT,'off')
        legend(app.UIAxes_OT,{'Rain attenuation'});

    elseif flag_lsfs.lsfs_ot(1) && ~isempty(strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_SATELLITE))
        app.Label_OTConcerned.Visible = false;
        strName = strcat(savePath, filesep, 'rain attenuation', '.mat');
        load(strName, 'pl_r' );
        RA_x = (1:length(pl_r)) / app.CallingApp.sampleRate.Value;
        RA_y = pl_r;
        plot(app.UIAxes_OT,RA_x,RA_y);
        hold(app.UIAxes_OT,'on')

        strName = strcat(savePath, filesep, 'tropospheric attenuation', '.mat');
        load(strName, 'pl_s' );
        plot(app.UIAxes_OT, RA_x, pl_s);
        hold(app.UIAxes_OT,'on')

        strName = strcat(savePath, filesep, 'gaseous attenuation', '.mat');
        load(strName, 'pl_g' );
        plot(app.UIAxes_OT,RA_x,pl_g);
        hold(app.UIAxes_OT,'on')

        strName = strcat(savePath, filesep, 'cloud and fog attenuation', '.mat');
        load(strName, 'pl_c' );
        plot(app.UIAxes_OT,RA_x,pl_c);
        hold(app.UIAxes_OT,'off')

        legend(app.UIAxes_OT,{'Rain attenuation','Tropospheric attenuation','Gaseous attenuation', 'Cloud and fog attenuation'});
    else
        app.Label_OTConcerned.Visible = true;
        legend(app.UIAxes_OT, 'off');
        cla(app.UIAxes_OT);
    end

    %% 收发机轨迹以及障碍物位置 & 收发机2d、3d距离
    txPos = tx_track.positions'; rxPos = rx_track.positions';
    % 收发机轨迹以及障碍物位置
    cla(app.UIAxes_RxTx);
    cla(app.UIAxes_DisRxTx);
    if strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_SATELLITE)
        txPos = txPos / 1000;
        rxPos = rxPos / 1000;
    end
    if app.CheckBox_3dRxTx.Value
        plot3(app.UIAxes_RxTx, txPos(1,:), txPos(2,:), txPos(3,:), 'ro');%['o','r']);
        hold(app.UIAxes_RxTx,'on')
        plot3(app.UIAxes_RxTx, rxPos(1,:), rxPos(2,:), rxPos(3,:), 'bo');
        %                        plot3(app.UIAxes_RxTx, app.CallingApp.lsf_confs.X, app.CallingApp.lsf_confs.Y, app.CallingApp.lsf_confs.Z, 'k');

    else
        plot(app.UIAxes_RxTx, txPos(1,:), txPos(2,:),'ro')
        hold(app.UIAxes_RxTx,'on')
        plot(app.UIAxes_RxTx, rxPos(1,:), rxPos(2,:),'bo')
        %                        plot(app.UIAxes_RxTx, app.CallingApp.lsf_confs.X, app.CallingApp.lsf_confs.Y,'kx')
        hold(app.UIAxes_RxTx,'off')
        view(app.UIAxes_RxTx, 0, 90);
    end
    
    if strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_SATELLITE)
        legend(app.UIAxes_RxTx,{'Satelite','Receiver'});
        title(app.UIAxes_RxTx, 'Motion trajectory of the satelite and receiver');
        xlabel(app.UIAxes_RxTx,'x-axis (km)');
        ylabel(app.UIAxes_RxTx,'y-axis (km)');
        zlabel(app.UIAxes_RxTx,'z-axis (km)');
        app.CallingApp.h_satellite.visualize_earth(tx_track.time_scale');
    else
        legend(app.UIAxes_RxTx,{'Transmitter','Receiver'}) % ,'阻挡物'
        title(app.UIAxes_RxTx,'Motion trajectory of the transmitter and receiver');
        xlabel(app.UIAxes_RxTx,'x-axis (m)');
        ylabel(app.UIAxes_RxTx,'y-axis (m)');
        zlabel(app.UIAxes_RxTx,'z-axis (m)');
    end

    % 收发机2d、3d距离
    d_2d = sqrt( sum( (txPos([1,2],:) - rxPos([1,2],:)).^2 , 1 ) );
    d_3d = sqrt( sum( (txPos - rxPos).^2 , 1 ) );
    t = (1:numel(d_2d)) / app.CallingApp.sampleRate.Value;
    plot(app.UIAxes_DisRxTx, t, d_2d);
    hold(app.UIAxes_DisRxTx,'on')
    plot(app.UIAxes_DisRxTx, t, d_3d);
    hold(app.UIAxes_DisRxTx,'off')
    legend(app.UIAxes_DisRxTx,{'2D distance','3D distance'})
    if strfind(app.CallingApp.scenarios, app.CallingApp.sps.scenario_SATELLITE)
        ylabel(app.UIAxes_DisRxTx,'distance (km)');
    else
        ylabel(app.UIAxes_DisRxTx,'distance (m)');
    end
    close(d_waitbar);
end