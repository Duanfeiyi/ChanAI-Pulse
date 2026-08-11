function [xT, yT, zT, xR, yR, zR, SSP] = get_clusters_new(channel_model, SSP, scen_para, rx_pos_t, tx_pos_t, num_rays_each_cluster)
% Get the angles of the subpaths and perform random coupling.
n_freq    = numel( channel_model.sim_params.carrier_frequency );
r       = rx_pos_t - tx_pos_t;
norm_r  = sqrt(sum(r.^2)).';
delay   = norm_r / channel_model.sim_params.speed_of_light + SSP.taus;
SSP.taus(1,:) = delay;

[ aod, eod, aoa, eoa, SSP ] = get_subpath_angles( channel_model, SSP, 1, false );

if contains(channel_model.sim_params.scenarioName, channel_model.sim_params.scenario_SKYWAVE)
    [xT, yT, zT, xR, yR, zR, SSP] = get_clusters_new_skywave(channel_model, SSP, eoa, aod, eod, aoa, norm_r, num_rays_each_cluster, tx_pos_t);
else
    % 构造簇内子径都相同的时延和簇内子径平分的功率
    num_clusters = length(SSP.taus); % 包含los径的1个
    delays_ray(1,:) = SSP.taus(1).*ones(1, num_rays_each_cluster);
    
    if isfield(SSP, 'use_DMC')
        use_DMC = SSP.use_DMC;
    else
        use_DMC = false;
    end
    
    if n_freq == 1
        powers_ray(1,:) = SSP.pow(1).*ones(1, num_rays_each_cluster);
        pin_ray = zeros(num_clusters, num_rays_each_cluster);
        if use_DMC
            pin_ray(1,:) = SSP.pin_dmc(1).*ones(1, num_rays_each_cluster);
            pin_ray(2:end,:) = reshape(SSP.pin_dmc(2:end), num_clusters-1, num_rays_each_cluster);
            SSP.pin_dmc = pin_ray;
        else
            pin_ray(1,:) = SSP.pin(1).*ones(1, num_rays_each_cluster);
            pin_ray(2:end,:) = reshape(SSP.pin(2:end), num_clusters-1, num_rays_each_cluster);
        end
    else
        pin_ray = zeros(num_clusters, num_rays_each_cluster,n_freq);
        powers_ray(1,:,:) = SSP.pow(1,1,:).*ones(1, num_rays_each_cluster);
        pin_ray(1,:,:) = SSP.pin(1,1,:).*ones(1, num_rays_each_cluster);
        pin_ray(2:end,:,:) = reshape(SSP.pin(:,2:end,:), num_clusters-1, num_rays_each_cluster,n_freq);
    end
    
    if n_freq == 1
        % 构造簇内子径的时延和功率
        if channel_model.sim_params.use_large_bandwidth_3GPP
            for i_clusters = 2: length(SSP.taus)
                [delays_ray, powers_ray] = get_delays_powers_large_bandwidth(channel_model, SSP, delays_ray, powers_ray, i_clusters);
            end
        else
            for i_clusters = 2: length(SSP.taus)
                delays_ray = [delays_ray; clst_expand(SSP.taus(i_clusters), num_rays_each_cluster)];
                powers_ray = [powers_ray; clst_expand(SSP.pow(i_clusters), num_rays_each_cluster)/num_rays_each_cluster];
            end
        end
    else
        for i_clusters = 2: length(SSP.taus)
            delays_ray = [delays_ray; clst_expand(SSP.taus(i_clusters), num_rays_each_cluster)];
        end
        for i_freq = 1:n_freq
            temp_powers = powers_ray(1,:,i_freq);
            for i_clusters = 2: length(SSP.taus)
                temp_powers = [temp_powers; clst_expand(SSP.pow(:,i_clusters,i_freq), num_rays_each_cluster)/num_rays_each_cluster];
            end
            powers_ray(1:size(temp_powers,1),:,i_freq) = temp_powers;
        end
        SSP.pow_old = SSP.pow;
    end
    SSP.taus = delays_ray;
    SSP.pow = powers_ray;
    if ~use_DMC
        SSP.pin = pin_ray;
    end
    
    if contains(channel_model.sim_params.scenarioName, channel_model.sim_params.scenario_SATELLITE)
        [xT, yT, zT, xR, yR, zR, SSP] = get_clusters_new_satellite(channel_model, aoa, eoa, r, SSP, rx_pos_t);
    elseif contains(channel_model.sim_params.scenarioName, channel_model.sim_params.scenario_UHST)
        [xT, yT, zT, xR, yR, zR, SSP] = get_clusters_new_uhst(channel_model, scen_para, aod, eod, aoa, eoa, SSP, rx_pos_t, tx_pos_t);
    elseif contains(channel_model.sim_params.scenarioName, channel_model.sim_params.scenario_US_garage)
        [xT, yT, zT, xR, yR, zR, SSP] = get_clusters_new_garage(channel_model,num_clusters,num_rays_each_cluster,tx_pos_t,rx_pos_t,SSP,aoa,eoa,r);
    else
        % 发射端与首跳簇间距d1和接收端与末跳簇间距d2，都是非复指数分布随机数
        %% 法一，簇内子径的d随机生成, 簇分布不明显
        %     dnm_Tx = zeros(num_clusters, num_rays_each_cluster);
        %     dnm_Rx = zeros(num_clusters, num_rays_each_cluster);
        %     for i_clusters = 2: num_clusters
        %         dnm_Tx(i_clusters, :) = exprnd(scen_para.d_Tx_mean, 1, num_rays_each_cluster)+ scen_para.d_Tx_min;
        %         dnm_Rx(i_clusters, :) = exprnd(scen_para.d_Rx_mean, 1, num_rays_each_cluster)+ scen_para.d_Rx_min;
        %     end
        %
        % 法二，同一个簇内子径的d相同
        dn_Tx = exprnd(scen_para.d_Tx_mean, num_clusters, 1)*0.5+ scen_para.d_Tx_min;
        dn_Tx(1) = 0;
        dn_Rx = exprnd(scen_para.d_Rx_mean, num_clusters, 1)*0.5+ scen_para.d_Rx_min;
        dn_Rx(1) = 0;
        
        dnm_Tx = repmat(dn_Tx,1,num_rays_each_cluster);
        dnm_Rx = repmat(dn_Rx,1,num_rays_each_cluster);

        [xT, yT, zT] = sph2cart(aod, eod, dnm_Tx);
        [xR, yR, zR] = sph2cart(aoa, eoa, dnm_Rx);
        xT = xT + tx_pos_t(1);  % 局部坐标转为全局坐标
        yT = yT + tx_pos_t(2);
        zT = zT + tx_pos_t(3);

        xR = xR + rx_pos_t(1);
        yR = yR + rx_pos_t(2);
        zR = zR + rx_pos_t(3);
        
        % 对d的限制(d1+d2+首跳簇和末跳簇间距离)/光速+虚拟时延=SSP.taus
        Dlink = channel_model.get_distance_ca2cz(xT, yT, zT, 1, 1, 1, xR, yR, zR, 1, 1, 1, 0);
        delays_total = (dnm_Tx + Dlink + dnm_Rx)/channel_model.sim_params.speed_of_light;
        SSP.taus = sort(SSP.taus);
        [delays_total, index] = sort(delays_total, 1);
        SSP.virtual_delays = SSP.taus-delays_total;
        
        xT = xT(index(:,1), :);  % 局部坐标转为全局坐标
        yT = yT(index(:,1), :);
        zT = zT(index(:,1), :);
        
        xR = xR(index(:,1), :);
        yR = yR(index(:,1), :);
        zR = zR(index(:,1), :);
        
        ind = SSP.virtual_delays < 0;
        
        if sum(ind, 'all') >= 1
            % 退化为单簇，解三角形
            phi_a = aoa(ind);
            theta_a = eoa(ind);
            [ ahat_x, ahat_y, ahat_z ] = sph2cart(phi_a, theta_a, 1);
            ahat = [ ahat_x'; ahat_y'; ahat_z'];
            dist = SSP.taus(ind)*channel_model.sim_params.speed_of_light';
            [ ~, ~, norm_a ]  = solve_cos_theorem( ahat , r' , dist  );
            
            % 计算单簇的位置，并替换
            [xR_ind, yR_ind, zR_ind ] = sph2cart(phi_a, theta_a, norm_a');
            xR(ind) = xR_ind + rx_pos_t(1);
            yR(ind) = yR_ind + rx_pos_t(2);
            zR(ind) = zR_ind + rx_pos_t(3);
            xT(ind) = xR(ind);
            yT(ind) = yR(ind);
            zT(ind) = zR(ind);
            SSP.virtual_delays(ind) = 0;
        end
        
        if use_DMC
            c_ds_dmc = scen_para.PerClusterDS_D / 1e9; % ns
            power_decay_rate = scen_para.power_decay_rate;
            SSP.virtual_delays = c_ds_dmc*6*rand(num_clusters, num_rays_each_cluster);
            SSP.taus = SSP.taus(:,1) + SSP.virtual_delays;
            powers_ray = exp(-SSP.taus/power_decay_rate);
            powers_ray = powers_ray ./repmat((sum(powers_ray,2) ./ sum(SSP.pow,2)),1,num_rays_each_cluster);
            SSP.pow = powers_ray;
        end
        
        %         %% plot
        %         figure
        %     for i_cluster = 2: size(xT, 1)
        %         scatter3(xT(i_cluster, :), yT(i_cluster, :), zT(i_cluster, :), 'MarkerEdgeColor','r');
        %         hold on;
        % %         scatter3(xR(i_cluster, :), yR(i_cluster, :), zR(i_cluster, :),  'MarkerFaceColor','b');
        %     end
    end
end
