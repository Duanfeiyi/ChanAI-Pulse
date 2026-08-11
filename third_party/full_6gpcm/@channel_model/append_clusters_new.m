function [xT, yT, zT, xR, yR, zR, SSP] = append_clusters_new( channel_model, num_new_clusters, clusters, SSP, LSP, xT, yT, zT, xR, yR, zR,tx_pos, rx_pos, condition)
% 生成新的簇的相关信息，并且append到原有簇信息中
if ~exist('condition', 'var')
    condition = 'others';
end
% 初始化簇级别的时延、功率、角度等，使用3GPP TR 38901的方法
if ~contains(condition, 'UWA_boundary')
    SSP_new = get_ssf_parameters( channel_model, LSP ,tx_pos, rx_pos, num_new_clusters, clusters);
end
if contains(condition, 'UWA_boundary')
    n_mobiles       = 1;
    n_clusters = num_new_clusters;
    n_subpaths      = clusters.num_rays_each_cluster;
    n_nlos_clusters = n_clusters;
    n_paths = n_nlos_clusters*n_subpaths;
    n_freq          = numel( channel_model.sim_params.carrier_frequency);
    n_nlos_paths = n_nlos_clusters * clusters.num_rays_each_cluster;
    SSP_new.pin = zeros( n_mobiles,n_paths,n_freq );
    % Generate random variables for the NLOS phases
    randC = rand( n_mobiles,n_nlos_paths );
    % Set phases
    SSP_new.pin(:,1:end) = 2*pi*randC-pi;
    SSP_new.NumClusters = num_new_clusters+1;
    SSP_new.NumSubPaths = [ones(1,n_nlos_clusters) * n_subpaths];
end

switch condition
    case 'Maritime_h'
        [ new_xT, new_yT, new_zT, new_xR, new_yR, new_zR, SSP_new] = get_clusters_evaporation_3GPP( LSP, channel_model, SSP_new, channel_model.sim_params.scen_para, rx_pos, tx_pos, clusters.num_rays_each_cluster);
    case 'Maritime_l'
        [ new_xT, new_yT, new_zT, new_xR, new_yR, new_zR, SSP_new] = get_clusters_sea_3GPP( LSP, channel_model, SSP_new, channel_model.sim_params.scen_para, rx_pos, tx_pos, clusters.num_rays_each_cluster, SSP.tx_antenna_angle, SSP.rx_antenna_angle );
    case 'IIoT'
        % 初始化簇级别的时延、功率、角度等，使用3GPP TR 38901的方法
        % SSP_new = get_ssf_parameters( channel_model,LSP ,tx_pos, rx_pos, num_new_clusters, clusters);
        % 假设d，得到簇内散射体具体位置
        SSP_new.use_DMC = SSP.use_DMC;
        if SSP.use_DMC
            pin_dmc = get_random_phases(channel_model, SSP_new,clusters.num_dmcrays_each_cluster);
            SSP_new.pin_dmc = pin_dmc;
            [new_xT, new_yT, new_zT, new_xR, new_yR, new_zR, SSP_new] = channel_model.get_clusters_new(SSP_new, channel_model.sim_params.scen_para, rx_pos, tx_pos, clusters.num_dmcrays_each_cluster);
        else
            pin = get_random_phases(channel_model, SSP_new,clusters.num_rays_each_cluster);
            SSP_new.pin = pin;
            [new_xT, new_yT, new_zT, new_xR, new_yR, new_zR, SSP_new] = channel_model.get_clusters_new(SSP_new, channel_model.sim_params.scen_para, rx_pos, tx_pos, clusters.num_rays_each_cluster);
        end
    case 'evaporation_duct'
        [ new_xT, new_yT, new_zT, new_xR, new_yR, new_zR, SSP_new] = get_clusters_evaporation_3GPP( LSP, channel_model, SSP_new, channel_model.sim_params.scen_para, rx_pos, tx_pos, clusters.num_rays_each_cluster);
    case {'troposcatter','troposcatter_RMa'}
        [ new_xT, new_yT, new_zT, new_xR, new_yR, new_zR, SSP_new] = get_clusters_trop( LSP, channel_model, SSP_new, channel_model.sim_params.scen_para, rx_pos, tx_pos, clusters.num_rays_each_cluster,condition);
    case 'UWA_boundary'
        [ new_xT, new_yT, new_zT, new_xR, new_yR, new_zR, SSP_new] = get_clusters_UWAb( channel_model, SSP_new, channel_model.sim_params.scen_para, rx_pos, tx_pos, clusters.num_rays_each_cluster);
        %     case 'UWA_in-water'
        %         [ xT, yT, zT, xR, yR, zR, SSP] = get_clusters_UWAi( LSP, channel_model, SSP, scen_para, rx_pos, tx_pos, clusters.num_rays_each_cluster);
    otherwise
        % 假设d，得到簇内散射体具体位置
        [new_xT, new_yT, new_zT, new_xR, new_yR, new_zR, SSP_new] = channel_model.get_clusters_new(SSP_new, channel_model.sim_params.scen_para, rx_pos, tx_pos, clusters.num_rays_each_cluster);
end

xT = cat(1, xT, new_xT(2:end,:));
yT = cat(1, yT, new_yT(2:end,:));
zT = cat(1, zT, new_zT(2:end,:));

xR = cat(1, xR, new_xR(2:end,:));
yR = cat(1, yR, new_yR(2:end,:));
zR = cat(1, zR, new_zR(2:end,:));

%SSP.pow = cat(1,SSP.pow, SSP_new.pow(2:end,:,:)); % 不区分频段
if strcmp(condition,'UWA_boundary')
    SSP.record_nlos_case = [SSP.record_nlos_case';SSP_new.record_nlos_case(1:end,:)']';
else
    SSP.pow = cat(1,SSP.pow, SSP_new.pow(2:end,:,:)); % 不区分频段
end

SSP.virtual_delays = [SSP.virtual_delays; SSP_new.virtual_delays(2:end,:)];
if isfield(SSP, 'use_DMC') && SSP.use_DMC
    SSP.pin_dmc = [SSP.pin_dmc; SSP_new.pin_dmc(2:end,:)]; % 不区分频段
    SSP.NumSubPaths_dmc = [SSP.NumSubPaths_dmc'; SSP_new.NumSubPaths_dmc(2:end)']'; % 不区分频段
else
    SSP.pin = cat(1,SSP.pin,SSP_new.pin(2:end,:,:)); % 不区分频段
    SSP.NumSubPaths = [SSP.NumSubPaths'; SSP_new.NumSubPaths(2:end)']'; % 不区分频段
end
SSP.NumClusters = SSP.NumClusters + size(new_zR, 1)-1; % 不区分频段
SSP.taus = [SSP.taus; SSP_new.taus(2:end,:)]; % 不区分频段
if isfield(SSP, 'alpha_n_m' )
    SSP.alpha_n_m = [SSP.alpha_n_m; SSP_new.alpha_n_m(2:end,:,:)];
end

if size(SSP.pin,3) > 1
    SSP.pow_old = cat(2,SSP.pow_old,SSP_new.pow_old(:,2:end,:));
end
end