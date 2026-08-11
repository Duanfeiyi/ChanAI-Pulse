function sat_track = get_track_satellite(app, move_time, samp_rate, initialPosTx)
    Ain = 6378.137 + app.satHeight.Value;  %Semimajor axis in [km]; Default: 42164 km, GEO orbit
    Bin = app.BinEditField.Value;  %Orbital eccentricity [0-1]; Default: 0
    Cin = app.CinEditField.Value;  %Orbital inclination in [degree]; Default: 0 旋转平面的倾斜角度
    Din = app.DinEditField.Value;  %Longitude of the ascending node in [degree]; Default: 0 升交点的经度
    Ein = app.EinEditField.Value;  %Argument of periapsis in [degree]; Default: 0
    Fin = app.FinEditField.Value;  %True anomaly in [degree]; Default: 0 %初始角度

    %%600km
    %0       90
    %0.8675  80
    %2.8     60
    %5.55    40
    %10.8    20
    %%sim10km
    %20    0.24
    %40   0.106

    app.h_satellite = satellite('custom',Ain, Bin, Cin, Din, Ein, Fin);

    if app.satHeight == 35786  % 地球静止卫星
        sat_track = track('static', move_time, 0, 0, initialPosTx, [0 0 0], samp_rate); % 发射端在天上, 速度为0
    else
        % 选接收端第一个坐标来确定卫星的位置
        [~, ue_pos] = tools.get_initialPos_table(app); % 南京的经纬度 经纬度用南纬是负，北纬是正，东经是正，西经是负
        sat_track = app.h_satellite.get_satellite_track(move_time, samp_rate, [ue_pos(1,1), ue_pos(1,2)]);
        % 更新表格上的信息
        txInitialPos = ['[',num2str(sat_track.positions(1,1,:)),' ',num2str(sat_track.positions(1,2,:)),' ',num2str(sat_track.positions(1,3,:)),']'];
        txSpeed = num2str(sat_track.move_speed(1));
        txAcceleration = num2str(sat_track.move_accel);
        txTrackOri = '[1 0 0]';
        % 创建新行数据
        team = table2array(app.UITable_tx.Data);
        team{1,3} = txInitialPos;
        team{1,6} = txSpeed;
        team{1,7} = txAcceleration;
        team{1,8} = txTrackOri;
        app.UITable_tx.Data = cell2table(team);

    end
end