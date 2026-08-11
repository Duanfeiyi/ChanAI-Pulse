function [xT, yT, zT, xR, yR, zR, SSP] = get_clusters_new_skywave(channel_model, SSP, eoa, aod, eod, aoa, norm_r, num_rays_each_cluster, tx_pos_t)
    %GET_CLUSTERS_NEW_SKYWAVE 此处显示有关此函数的摘要
    pin_ray = zeros(size(eoa));
    delays_ray(1,:) = SSP.taus(1).*ones(1, size(eoa, 2));
    powers_ray(1,:) = SSP.pow(1).*ones(1, size(eoa, 2));
    pin_ray(1:end,:) = reshape(SSP.pin, size(eoa, 1), size(eoa, 2));
    for i_clusters = 1: length(SSP.taus)
        delays_ray = [delays_ray; clst_expand(SSP.taus(i_clusters), num_rays_each_cluster)];
        powers_ray = [powers_ray; clst_expand(SSP.pow(i_clusters), num_rays_each_cluster)/num_rays_each_cluster];
    end
    SSP.taus = delays_ray;
    SSP.pow = powers_ray;
    SSP.pin = pin_ray;
    dn_Tx = exprnd(20000, size(aod, 1),1)+ repmat(norm_r./SSP.n'/2,[size(aod, 1)/size(SSP.n',1) 1]);
    dn_Rx = norm_r-exprnd(20000, size(aod, 1),1)- repmat(norm_r./SSP.n'/2,[size(aod, 1)/size(SSP.n',1) 1]);
    dmn_Tx = repmat(dn_Tx,1,size(aod, 2));
    dmn_Rx = repmat(dn_Rx,1,size(aod, 2));

    [xT, yT, zT] = sph2cart(aod, eod, dmn_Tx);
    [xR, yR, zR] = sph2cart(aoa, eoa, dmn_Rx);

    SSP.virtual_delays = zeros(size(SSP.taus));

    xT = xT + tx_pos_t(1);  % 局部坐标转为全局坐标
    yT = yT + tx_pos_t(2);
    zT = zT + tx_pos_t(3);
    xR = xR + tx_pos_t(1);  % 单簇
    yR = yR + tx_pos_t(2);
    zR = zR + tx_pos_t(3);
end

