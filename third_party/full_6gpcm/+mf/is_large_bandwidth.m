function [LargeBandwidth] = is_large_bandwidth(cm,B)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
LargeBandwidth = 0;
if cm.sim_params.speed_of_light/mf.findMaxDistance(cm.rx_array(1,1).element_position_gcs) < B(1) || ...
        cm.sim_params.speed_of_light/mf.findMaxDistance(cm.tx_array(1,1).element_position_gcs) < B(1)||...
        B(1) >= 1e9  || B(1) >= max(cm.sim_params.carrier_frequency)*0.1
    LargeBandwidth = 1;
end