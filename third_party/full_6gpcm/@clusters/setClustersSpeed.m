function [clusters] = setClustersSpeed(clusters, pos_length, sim_params, scen_para, tx_track)
%SETCLUSTERSSPEED 此处显示有关此函数的摘要
%   此处显示详细说明
if ~exist('sim_params', 'var')
    sim_params = [];
end

if ~exist('scen_para', 'var')
    scen_para = [];
end

% scen_para.wind_speed;
if ~isempty(sim_params) && contains(sim_params.scenarioName, sim_params.scenario_UWA)
  
    [vcluster_zn, ~] = UWACM_spectrum_U(tx_track.time_scale, scen_para.wind_speed);
clusters.zn_move_speed = abs(vcluster_zn);
for i = 1:length(vcluster_zn)
    if vcluster_zn(i) > 0
       clusters.zn_move_direc_elevation(i) = pi/2;  
    elseif vcluster_zn(i) < 0
        clusters.zn_move_direc_elevation(i) = -pi/2; 
    end
end
    clusters.zn_move_speed = ones(pos_length, 1) .* clusters.zn_move_speed;
    clusters.zn_move_direc_azimuth = ones(pos_length, 1) .* clusters.zn_move_speed;
    clusters.zn_move_direc_elevation = ones(pos_length, 1) .* clusters.zn_move_speed;
end
if length(clusters.an_move_speed) == 1
    clusters.an_move_speed = ones(pos_length, 1) .* clusters.an_move_speed;
    clusters.an_move_direc_azimuth = ones(pos_length, 1) .* clusters.an_move_direc_azimuth;
    clusters.an_move_direc_elevation = ones(pos_length, 1) .* clusters.an_move_direc_elevation;
elseif length(clusters.an_move_speed) ~= pos_length
    error('The speed of the cluster at different time points is unclear. Please keep the length of the velocity matrix the same as the track length of Tx');
end

if length(clusters.zn_move_speed) == 1
    clusters.zn_move_speed = ones(pos_length, 1) .* clusters.zn_move_speed;
    clusters.zn_move_direc_azimuth = ones(pos_length, 1) .* clusters.zn_move_speed;
    clusters.zn_move_direc_elevation = ones(pos_length, 1) .* clusters.zn_move_speed;
elseif length(clusters.zn_move_speed) ~= pos_length
    error('The speed of the cluster at different time points is unclear. Please keep the length of the velocity matrix the same as the track length of Rx');
end
end

