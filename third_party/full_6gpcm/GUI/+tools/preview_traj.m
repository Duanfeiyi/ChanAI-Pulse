function preview_traj(app)
if isempty(app.selection_rx) || isempty(app.selection_tx)
    % 弹出提示框
    uialert(app.UIFigure, '请先选择单元格', '选择错误');
    return; % 直接返回，不执行后面的代码
else
    selected_tx_rows = app.UITable_tx.Selection(:,1);
    selected_rx_rows = app.UITable_rx.Selection(:,1);
    % 使用行索引从表格数据中提取相应的行数据
    selected_tx_data = app.UITable_tx.Data(selected_tx_rows,:);
    selected_rx_data = app.UITable_rx.Data(selected_rx_rows,:);
    
    rxTrackType = selected_rx_data.team5{1};
    txTrackType = selected_tx_data.team5{1};
    if isempty(txTrackType) || isempty(rxTrackType)
        % 弹出提示框
        uialert(app.UIFigure, '您选择的单元格未设置运动轨迹，请先设置运动轨迹后预览', '选择错误');
        return; % 直接返回，不执行后面的代码
    end
    
    mf.add_logs('TxPosVisualizeButtonPushed', 'Preview the motion trajectories of the Tx and Rx');
    initialPosRx = str2num(selected_rx_data.team3{1});
    initialPosTx = str2num(selected_tx_data.team3{1});
    
    trackOriRx = str2num(selected_rx_data.team8{1});
    trackOriTx = str2num(selected_tx_data.team8{1});
    
    rxSpeed = str2num(selected_rx_data.team6{1});
    txSpeed = str2num(selected_tx_data.team6{1});
    
    rxAcceleration = str2num(selected_rx_data.team7{1});
    txAcceleration = str2num(selected_tx_data.team7{1});
    
    rx_track = track(rxTrackType, app.trackLength.Value, rxSpeed, rxAcceleration, initialPosRx, trackOriRx, app.sampleRate.Value);
    
    move_time = app.trackLength.Value;
    samp_rate = app.sampleRate.Value;
    
    if contains(txTrackType, 'satellite')
        tx_track = tools.get_track_satellite(app, move_time, samp_rate, initialPosTx);
        app.h_satellite.visualize_earth(tx_track.time_scale');
    else
        tx_track = track(txTrackType, move_time, txSpeed, txAcceleration, initialPosTx, trackOriTx, samp_rate);
    end
    %% 轨迹图示
    switch app.ButtonGroup_preview.SelectedObject.Text
        case 'Both'
            figure();
            %                             scatter3(0,0,0);
            %                             hold on;
            scatter3(tx_track.positions(:,1,:), tx_track.positions(:,2,:), tx_track.positions(:,3,:), 'MarkerEdgeColor','b', 'MarkerFaceColor','b');
            hold on;
            scatter3(rx_track.positions(:,1,:), rx_track.positions(:,2,:), rx_track.positions(:,3,:), 'MarkerEdgeColor','r', 'MarkerFaceColor','r');
            
            xlabel('x-axis (m)')
            ylabel('y-axis (m)')
            zlabel('z-axis (m)')
            title('\fontsize{16}The trajectory of the satellite relative to the Tx and Rx (m)');
            legend({'Tx','Rx'}) % ,'阻挡物'
        case 'Tx'
            figure();
            scatter3(tx_track.positions(:,1,:), tx_track.positions(:,2,:), tx_track.positions(:,3,:));
            
            title('\fontsize{16}The motion trajectory diagram of the Tx (m)');
            xlabel('x-axis (m)')
            ylabel('y-axis (m)')
            zlabel('z-axis (m)')
            legend({'Tx'}) % ,'阻挡物'
        case 'Rx'
            figure();
            scatter3(rx_track.positions(:,1,:), rx_track.positions(:,2,:), rx_track.positions(:,3,:), 'MarkerEdgeColor','r', 'MarkerFaceColor','r');
            
            title('\fontsize{16}The motion trajectory diagram of the Rx (m)');
            xlabel('x-axis (m)')
            ylabel('y-axis (m)')
            zlabel('z-axis (m)')
            legend({'Rx'}) % ,'阻挡物'
    end
end
mf.add_logs('TxPosVisualizeButtonPushed', 'The Tx trajectory preview is complete');
end

