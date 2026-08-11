function [H, delay] = result2H(result, delays)
%RESULT2H 此处显示有关此函数的摘要
%   result{i_snap, i_f} = H; 单频段
%   result{i_snap, i_f} = H;  H = no_txAntenna * no_rxAntenna * no_clusters * no_rays_each_cluster

% Output: H: no_rxAntenna * no_txAntenna * snaps * no_clusters
if numel([size(result, 1),size(result, 1)]) > 2
    [H, delay] = mf.result2H_multi_users(result, delays);
else
    max_cluster = size(result{end,1},3);
    no_subpath = size(result{1,1},4);
    no_snap = size(result, 3);
    no_txAntenna = size(result{1,1},1);
    no_rxAntenna = size(result{1,1},2);
    no_paths = max_cluster * no_subpath;
    H = zeros(no_txAntenna, no_rxAntenna, no_snap, no_paths);
    delay = H;

    for i_snap = 1 : no_snap
        path_index = (size(result{1,1,i_snap},3))*no_subpath; % TODO result{1,1,i_snap,1}
        H(:, :, i_snap, 1: path_index) =  reshape(result{1,1,i_snap}, no_txAntenna, no_rxAntenna, []);
        if isempty(delays)
        else
            delay(:, :, i_snap, 1: path_index) =  reshape(delays{1,1,i_snap}, no_txAntenna, no_rxAntenna, []);
        end
    end
end
end

