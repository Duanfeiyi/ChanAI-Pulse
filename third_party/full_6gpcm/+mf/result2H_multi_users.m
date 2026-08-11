function [result_H, result_delay] = result2H_multi_users(result, delays)
%RESULT2H 此处显示有关此函数的摘要
%   result{i_user_tx, i_user_rx, i_snap} = H; 单频段
%   delay{i_user_tx, i_user_rx, i_snap} = delays;

% Output: H{i_user_tx, i_user_rx}: no_txAntenna * no_rxAntenna * snaps * no_rays
result_H = cell(size(result,1), size(result,2));
result_delay = cell(size(result,1), size(result,2));
for i_users_tx = 1 : size(result,1)
    for i_users_rx = 1 : size(result,2)
        max_cluster = size(result{i_users_tx, i_users_rx, end,1},3);
        no_subpath = size(result{i_users_tx, i_users_rx,1,1},4);
        no_snap = size(result, 3); 
        no_txAntenna = size(result{i_users_tx, i_users_rx,1,1},1);
        no_rxAntenna = size(result{i_users_tx, i_users_rx,1,1},2);
        no_paths = max_cluster * no_subpath;
        H = zeros(no_txAntenna, no_rxAntenna, no_snap, no_paths);
        delay = H;
        
        for i_snap = 1 : no_snap
            path_index = (size(result{i_users_tx, i_users_rx, i_snap, 1}, 3)) * no_subpath; 
            H(:, :, i_snap, 1: path_index) =  reshape(result{i_users_tx, i_users_rx,i_snap, 1}, no_txAntenna, no_rxAntenna, []);
            if isempty(delays)
            else
                delay(:, :, i_snap, 1: path_index) =  reshape(delays{i_users_tx, i_users_rx, i_snap, 1}, no_txAntenna, no_rxAntenna, []);
            end
        end
        result_H{i_users_tx, i_users_rx} = H;
        result_delay{i_users_tx, i_users_rx} = delay;
    end
end
end

