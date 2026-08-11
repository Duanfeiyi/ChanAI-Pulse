classdef clusters < handle
    %CLUSTERS 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties(Dependent)
        num_clusters                  % 簇的数量
        num_rays                      % 所有子径的数量
        num_rays_each_cluster
        num_dmcrays_each_cluster
        
        recombination_rate
        generation_rate
        
        corr_distance
        corr_distance_array  
        corr_distance_frequency
        
        weight                       % 功率的权重
        virtual_delays
        
        cluster_Infos
    end
    
    properties
        an_move_speed = 0;
        an_move_direc_azimuth = 0;
        an_move_direc_elevation = 0;
        
        zn_move_speed = 0;
        zn_move_direc_azimuth = 0;
        zn_move_direc_elevation = 0;
    end
    
    properties(Dependent, Access=protected)
        intial_phases = 0;                      % 簇的初始相位；
        power                              % 簇的功率；
    end
    
    properties(Access=private)
        Precombination_rate = 1;          % 天线到簇的距离；
        Pgeneration_rate = 20;            % 天线到簇的俯仰角；
        Pnum_rays = 100;
        Pwight = ones(1,20);
        
        Pcorr_distance = 40;
        Pcorr_distance_array = 200;
        Pcorr_distance_frequency = 1e8;
        
        Pnum_clusters = 20;
        Pnum_rays_each_cluster = 20;
        
        Pcluster_Infos = {}
    end
    
    methods
       function h_clusters = clusters()
            h_clusters.num_rays           = 100;  
       end
        
        % Get functions
        function out = get.recombination_rate(h_clusters)
            out = h_clusters.Precombination_rate;
        end
        function out = get.generation_rate(h_clusters)
            out = h_clusters.Pgeneration_rate; % Single
        end
        function out = get.num_clusters(h_clusters)
            out = h_clusters.Pnum_clusters;
        end
        function out = get.num_rays(h_clusters)
            out = h_clusters.Pnum_rays;
        end
        function out = get.weight(h_clusters)
            out = h_clusters.Pwight;
        end
        function out = get.num_rays_each_cluster(h_clusters)
            out = h_clusters.Pnum_rays_each_cluster;
        end
        function out = get.num_dmcrays_each_cluster(h_clusters)
            out = h_clusters.num_rays_each_cluster * 10;
        end

        function out = get.corr_distance(h_clusters)
            out = h_clusters.Pcorr_distance;
        end
        function out = get.corr_distance_array(h_clusters)
            out = h_clusters.Pcorr_distance_array;
        end
        
        function out = get.cluster_Infos(h_clusters)
            out = h_clusters.Pcluster_Infos;
        end
        function out = get.corr_distance_frequency(h_clusters)
            out = h_clusters.Pcorr_distance_frequency;
        end
        function out = get.an_move_speed(h_clusters)
            out = h_clusters.an_move_speed;
        end
        function out = get.zn_move_speed(h_clusters)
            out = h_clusters.zn_move_speed; % Single
        end
        function out = get.an_move_direc_azimuth(h_clusters)
            out = h_clusters.an_move_direc_azimuth;
        end
        function out = get.zn_move_direc_azimuth(h_clusters)
            out = h_clusters.zn_move_direc_azimuth;
        end
        function out = get.an_move_direc_elevation(h_clusters)
            out = h_clusters.an_move_direc_elevation;
        end
        function out = get.zn_move_direc_elevation(h_clusters)
            out = h_clusters.zn_move_direc_elevation; % Single
        end        
        
        % Set functions
        function set.num_rays(h_clusters, value)
            h_clusters.Pnum_rays = value;
        end
        function set.weight(h_clusters, value)
            if length(value) == length(h_clusters.Pwight)  
                h_clusters.Pwight = value;
            else
                error('length of wight is error')
            end 
        end
        function set.corr_distance_array(h_clusters,value)
            h_clusters.Pcorr_distance_array = value;
        end
        function set.corr_distance(h_clusters,value)
            h_clusters.Pcorr_distance = value;
        end
        function set.corr_distance_frequency(h_clusters,value)
            h_clusters.Pcorr_distance_frequency = value;
        end
        function set.num_clusters(h_clusters, value)
            h_clusters.Pnum_clusters = value;
        end
        function set.generation_rate(h_clusters,value)
            h_clusters.Pgeneration_rate = value;
        end
        function set.recombination_rate(h_clusters, value)
            h_clusters.Precombination_rate = value;
        end
        function set.num_rays_each_cluster(h_clusters, value)
            h_clusters.Pnum_rays_each_cluster = value;    
        end
        function set.an_move_speed(h_clusters,value)
            h_clusters.an_move_speed = value;
        end
        function set.zn_move_speed(h_clusters,value)
            h_clusters.zn_move_speed = value;
        end
        function set.an_move_direc_azimuth(h_clusters, value)
            h_clusters.an_move_direc_azimuth = value;
        end
        function set.zn_move_direc_azimuth(h_clusters,value)
            h_clusters.zn_move_direc_azimuth = value;
        end
        function set.an_move_direc_elevation(h_clusters, value)
            h_clusters.an_move_direc_elevation = value;
        end
        function set.zn_move_direc_elevation(h_clusters, value)
            h_clusters.zn_move_direc_elevation = value;    
        end
        function set.cluster_Infos(h_clusters, value)
            h_clusters.Pcluster_Infos = value;
        end
    end
    
    methods(Static)
        [ h_clusters ] = setClustersSpeed(clusters, pos_length, sim_params, scen_para, tx_track);
        p_sur = get_p_sur(clusters, tx_antenna_angle, rx_antenna_angle, delta_tx, delta_rx);
    end    
end

