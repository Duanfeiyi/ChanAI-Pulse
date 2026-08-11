function [xT, yT, zT, xR, yR, zR, SSP] = get_clusters_new_satellite(channel_model, aoa, eoa, r, SSP, rx_pos_t)
%GET_CLUSTERS_NEW_SATELLITE % 卫星场景为单簇
    [ ahat_x, ahat_y, ahat_z ] = sph2cart(aoa, eoa, 1);
    ahat(1,:,:) = ahat_x;
    ahat(2,:,:) = ahat_y;
    ahat(3,:,:) = ahat_z;
    dist = SSP.taus*channel_model.sim_params.speed_of_light';
    [ ~, ~, norm_a ]  = solve_cos_theorem( ahat , r' , dist  );
    % 计算单簇的位置，并替换
    [xR_ind, yR_ind, zR_ind ] = sph2cart(aoa, eoa, squeeze(norm_a));
    xR = xR_ind + rx_pos_t(1);
    yR = yR_ind + rx_pos_t(2);
    zR = zR_ind + rx_pos_t(3);
    xT = xR;
    yT = yR;
    zT = zR;
    SSP.virtual_delays = zeros(size(xR, 1), size(xR, 2));
end

