function flag_confs = get_lsfsState(app, appMain)
%GETLSFS_STATE 此处显示有关此函数的摘要
%   此处显示详细说明
    flag_confs.lsfs_pl = 0;
    flag_confs.lsfs_bl = 0;
    flag_confs.lsfs_al = 0;
    flag_confs.lsfs_ot = 0;
    flag_confs.o2i = 0;
    %获得经纬度，卫星场景专用
    [~,uePos] = tools.get_initialPos_table(appMain);
    flag_confs.Lo = uePos(1);
    flag_confs.La = uePos(2);
    
    if app.PLCheckBox.Value
        flag_confs.lsfs_pl = 1;
    end
    
    if app.BLCheckBox.Value
        flag_confs.lsfs_bl = 1;
    end
    
    if app.ALCheckBox.Value
        flag_confs.lsfs_al = 1;
    end
    
    if app.OTCheckBox.Value
        flag_confs.lsfs_ot = 1;
    end
    
    if contains(appMain.scenarios, 'O2I')
        flag_confs.o2i = 1;
    end
end

