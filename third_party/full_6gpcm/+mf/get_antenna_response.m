function [antenna_responseLOS, antenna_responseNLOS] = get_antenna_response(tx_antenna, rx_antenna, tx_pos, rx_pos, clusters, i_clusterPos, xppr)
global antennaSwitch;

if antennaSwitch == 1
    % LOS响应
    if size(i_clusterPos.xR,2)==clusters.num_rays_each_cluster && size(i_clusterPos.xR,1)>1
        num_clusters = size(i_clusterPos.xR,1)-1;
        pT = reshape([i_clusterPos.xT(2:end,1), i_clusterPos.yT(2:end,1), i_clusterPos.zT(2:end,1)],3,num_clusters);
        pR = reshape([i_clusterPos.xR(2:end,1), i_clusterPos.yR(2:end,1), i_clusterPos.zR(2:end,1)],3,num_clusters);
    else
        num_clusters = size(i_clusterPos.xR,1);
        pT = reshape([i_clusterPos.xT(:,1), i_clusterPos.yT(:,1), i_clusterPos.zT(:,1)],3,num_clusters);
        pR = reshape([i_clusterPos.xR(:,1), i_clusterPos.yR(:,1), i_clusterPos.zR(:,1)],3,num_clusters);
    end
    co_polar_imbalance = 1;

    % faraday rotation 有天线方向图时再考虑
    % far_rot_phi = 108/((fc(i_f)/1e9)^2);
    far_rot_phi = 0;
    far_rot = [cos(far_rot_phi),-sin(far_rot_phi);sin(far_rot_phi),cos(far_rot_phi)];

    tx_antenna_nums = tx_antenna.no_elements;
    rx_antenna_nums = rx_antenna.no_elements;

    tx_pattern_responseLOSFV = zeros(tx_antenna_nums,rx_antenna_nums);
    tx_pattern_responseLOSFH = zeros(tx_antenna_nums,rx_antenna_nums);
    rx_pattern_responseLOSFV = zeros(rx_antenna_nums,tx_antenna_nums);
    rx_pattern_responseLOSFH = zeros(rx_antenna_nums,tx_antenna_nums);
    % antenna_responseLOS = ones(rx_antenna_nums,tx_antenna_nums);
    rx2txLCS = gcs2lcs(rx_antenna.element_position, ...
        tx_antenna, tx_pos'*ones(1,rx_antenna_nums));
    relativePosRx2Tx = (repmat(rx2txLCS,1,tx_antenna_nums)- ...
        reshape(repmat(tx_antenna.element_position, ...
        rx_antenna_nums,1),3,tx_antenna_nums*rx_antenna_nums));
    [betaATxLOS, betaETxLOS,~] = cart2sph(relativePosRx2Tx(1,:),relativePosRx2Tx(2,:),relativePosRx2Tx(3,:));
    for i_no_tx = 1:tx_antenna_nums
        [tx_pattern_responseLOSFV(i_no_tx,:), tx_pattern_responseLOSFH(i_no_tx,:)] = efield2FVFH(tx_antenna, ...
            betaETxLOS(1:rx_antenna_nums+rx_antenna_nums*(i_no_tx-1))/pi*180, ...
            betaATxLOS(1:rx_antenna_nums+rx_antenna_nums*(i_no_tx-1))/pi*180,i_no_tx);
    end

    tx2rxLCS = gcs2lcs(tx_antenna.element_position, ...
        rx_antenna,rx_pos'*ones(1,tx_antenna_nums));
    relativePosTx2Rx = (repmat(tx2rxLCS,1,rx_antenna_nums)- ...
        reshape(repmat(rx_antenna.element_position, ...
        tx_antenna_nums,1),3,rx_antenna_nums*tx_antenna_nums));
    [betaARxLOS,betaERxLOS,~] = cart2sph(relativePosTx2Rx(1,:),relativePosTx2Rx(2,:),relativePosTx2Rx(3,:));
    for i_no_rx = 1:rx_antenna_nums
        [rx_pattern_responseLOSFV(i_no_rx,:),rx_pattern_responseLOSFH(i_no_rx,:)] = efield2FVFH(rx_antenna, ...
            betaERxLOS(1:tx_antenna_nums+tx_antenna_nums*(i_no_rx-1))/pi*180, ...
            betaARxLOS(1:tx_antenna_nums+tx_antenna_nums*(i_no_rx-1))/pi*180,i_no_rx);
    end

    tx_pattern_responseLOSFV = reshape(tx_pattern_responseLOSFV.',rx_antenna_nums*tx_antenna_nums,1);
    tx_pattern_responseLOSFH = reshape(tx_pattern_responseLOSFH.',rx_antenna_nums*tx_antenna_nums,1);
    rx_pattern_responseLOSFV = reshape(rx_pattern_responseLOSFV,rx_antenna_nums*tx_antenna_nums,1);
    rx_pattern_responseLOSFH = reshape(rx_pattern_responseLOSFH,rx_antenna_nums*tx_antenna_nums,1);

    antenna_responseLOS = [rx_pattern_responseLOSFV,rx_pattern_responseLOSFH]...
        *[exp(1j*2*pi*rand(1)),0;0,exp(1j*2*pi*rand(1))]*[tx_pattern_responseLOSFV,tx_pattern_responseLOSFH].';
    antenna_responseLOS = reshape(diag(antenna_responseLOS),rx_antenna_nums,tx_antenna_nums);
    antenna_responseLOS = permute(antenna_responseLOS,[2,1,3,4]);
    %%

    % NLOS计算每条子径对于天线单元的方向图响应
    tx_pattern_responseFVNLOS = zeros(tx_antenna_nums,num_clusters);
    tx_pattern_responseFHNLOS = zeros(tx_antenna_nums,num_clusters);
    rx_pattern_responseFVNLOS = zeros(rx_antenna_nums,num_clusters);
    rx_pattern_responseFHNLOS = zeros(rx_antenna_nums,num_clusters);
    theta_VV = 2*pi*rand(1,1,num_clusters);
    theta_VH = 2*pi*rand(1,1,num_clusters);
    theta_HV = 2*pi*rand(1,1,num_clusters);
    theta_HH = 2*pi*rand(1,1,num_clusters);
    % 总的天线响应，包括方向图，极化旋转等
    antenna_responseNLOS = zeros(rx_antenna_nums,tx_antenna_nums,num_clusters);

    
    % 每个簇相对于参考天线的位置
    tx_clusterPosLCS = gcs2lcs(pT,tx_antenna,tx_pos'*ones(1,num_clusters));
    relativePosTx2cluster = (repmat(tx_clusterPosLCS,1,tx_antenna_nums...
        )-reshape(repmat(tx_antenna.element_position,num_clusters,1),3,tx_antenna_nums*num_clusters));
    [betaATx,betaETx,~] = cart2sph(relativePosTx2cluster(1,:),relativePosTx2cluster(2,:),relativePosTx2cluster(3,:));
    for i_no_tx = 1:tx_antenna_nums
        [tx_pattern_responseFVNLOS(i_no_tx,:),tx_pattern_responseFHNLOS(i_no_tx,:)] = efield2FVFH(tx_antenna, ...
            betaETx(1:num_clusters+num_clusters*(i_no_tx-1))/pi*180, ...
            betaATx(1:num_clusters+num_clusters*(i_no_tx-1))/pi*180,i_no_tx);
    end

    
    % 每个簇相对于参考天线的位置
    rx_clusterPosLCS = gcs2lcs(pR,rx_antenna,rx_pos'*ones(1,num_clusters));
    relativePosRx2cluster = (repmat(rx_clusterPosLCS,1,rx_antenna_nums...
        )-reshape(repmat(rx_antenna.element_position,num_clusters,1),3,rx_antenna_nums*num_clusters));
    [betaARx,betaERx,~] = cart2sph(relativePosRx2cluster(1,:),relativePosRx2cluster(2,:),relativePosRx2cluster(3,:));
    for i_no_rx = 1:rx_antenna_nums
        [rx_pattern_responseFVNLOS(i_no_rx,:),rx_pattern_responseFHNLOS(i_no_rx,:)] = efield2FVFH(rx_antenna, ...
            betaERx(1:num_clusters+num_clusters*(i_no_rx-1))/pi*180, ...
            betaARx(1:num_clusters+num_clusters*(i_no_rx-1))/pi*180,i_no_rx);
    end
    polarResponse = [exp(1j*theta_VV(1,1,:)),...
        sqrt(co_polar_imbalance./xppr).*exp(1j*theta_VH(1,1,:));...
        sqrt(1./xppr).*exp(1j*theta_HV(1,1,:)),...
        exp(1j*theta_HH(1,1,:))];

    for i_m = 1:num_clusters
        antenna_responseNLOS(:,:,i_m) = [rx_pattern_responseFVNLOS(:, ...
            i_m),rx_pattern_responseFHNLOS(:,i_m)]*polarResponse(:,:,i_m)*far_rot*...
            [tx_pattern_responseFVNLOS(:,i_m),tx_pattern_responseFHNLOS(:,i_m)].';
    end
    % size(antenna_responseNLOS)
    antenna_responseNLOS = repmat(antenna_responseNLOS,1,1,1,size(i_clusterPos.xR,2));
    antenna_responseNLOS = permute(antenna_responseNLOS,[2,1,3,4]);
else
    antenna_responseNLOS = 1;
    antenna_responseLOS = 1;
end
end

