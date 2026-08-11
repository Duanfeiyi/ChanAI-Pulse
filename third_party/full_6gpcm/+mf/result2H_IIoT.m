function [H, delay] = result2H_IIoT(result, delays,use_DMC)
%RESULT2H 此处显示有关此函数的摘要
%   result{i_snap, i_f} = H; 单频段
%   result{i_snap, i_f} = H;  H = no_txAntenna * no_rxAntenna *no_clusters+1 * no_rays_each_cluster
%   delay{i_snap, i_f} = delays; delays = no_txAntenna * no_rxAntenna *no_clusters+1 * no_rays_each_cluster

% Output: H: no_rxAntenna * no_txAntenna * snaps * no_paths
max_cluster = size(result{1,1,end,1},3)-1;
no_subpath = size(result{1,1,1,1},4);
no_snap = size(result, 3);
no_txAntenna = size(result{1,1,1,1},1);
no_rxAntenna = size(result{1,1,1,1},2);
if use_DMC
    no_paths = max_cluster*no_subpath;
else
    no_paths = max_cluster*no_subpath+1;
end
H = zeros(no_txAntenna,no_rxAntenna,no_snap,no_paths);
delay = H;

for i_snap = 1 : no_snap
     if use_DMC
        H_NLOS =  reshape(result{1,1,i_snap,1}, no_txAntenna, no_rxAntenna,[]);
        path_index = (size(result{1,1,i_snap,1},3))*no_subpath;
        H(:,:,i_snap,1:path_index) = H_NLOS;
        delay_NLOS =  reshape(delays{1,1,i_snap,1}, no_txAntenna, no_rxAntenna,[]);
        delay(:,:,i_snap,1:path_index) = delay_NLOS;
    else
        H_NLOS =  reshape(result{1,1,i_snap,1}(:,:,1:end-1,:), no_txAntenna, no_rxAntenna,[]);
        H_LOS = result{1,1,i_snap,1}(:,:,end,1);
        path_index = (size(result{1,1,i_snap,1},3)-1)*no_subpath + 1;
        H(:,:,i_snap,1:path_index) = cat(3,H_LOS,H_NLOS);
        delay_NLOS =  reshape(delays{1,1,i_snap,1}(:,:,1:end-1,:), no_txAntenna, no_rxAntenna,[]);
        delay_LOS = delays{1,1,i_snap,1}(:,:,end,1);
        delay(:,:,i_snap,1:path_index) = cat(3,delay_LOS,delay_NLOS);
    end
end



