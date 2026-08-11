function [tx_track, rx_track] = get_x_snap_track(i_snap, tx_track, rx_track)
%GET_X_SNAP_TRACK 计算CCF和FCF等统计特性时，只需要某一个时间点的轨迹相关量
    %   此处显示详细说明
    for i_users_tx = 1:size(tx_track, 2)
        for i_users_rx = 1:size(rx_track, 2)
            tx_track(i_users_tx).move_speed = tx_track(i_users_tx).move_speed(i_snap);
            tx_track(i_users_tx).positions = tx_track(i_users_tx).positions(1,:,:);
            tx_track(i_users_tx).time_scale = tx_track(i_users_tx).time_scale(i_snap);
            tx_track(i_users_tx).move_direc_azimuth = tx_track(i_users_tx).move_direc_azimuth(i_snap);
            tx_track(i_users_tx).move_direc_elevation = tx_track(i_users_tx).move_direc_elevation(i_snap);

            rx_track(i_users_rx).move_speed = rx_track(i_users_rx).move_speed(i_snap);
            rx_track(i_users_rx).positions = rx_track(i_users_rx).positions(1,:,:);
            rx_track(i_users_rx).time_scale = rx_track(i_users_rx).time_scale(i_snap);
            rx_track(i_users_rx).move_direc_azimuth = rx_track(i_users_rx).move_direc_azimuth(i_snap);
            rx_track(i_users_rx).move_direc_elevation = rx_track(i_users_rx).move_direc_elevation(i_snap);
        end
    end
end