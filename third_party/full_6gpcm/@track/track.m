classdef track < handle
    %TRACK 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        track_length = 60;
        move_speed = 0;                      
        move_accel = 0;  
        move_dir;
        positions;
        time_scale;
        name = 'static';
        move_direc_azimuth;
        move_direc_elevation;
        move_time;
        samp_rate;
        no_track_segment = 1;
    end
    
    methods
       function h_track = track(track_type, varargin)
          if exist('track_type','var') && ~isempty( track_type ) && nargin > 0
              h_track = track.generate( track_type, varargin{:} );
          end
        end
    end
    
    methods(Static)
        function types = supported_types
            types =  {'linear','static','circle','random','random_circle','satellite','shipStatic','shipLinear'};%%%%%这里做了修改2024.1.23徐凡
        end
        h_track = generate( track_type, move_time , move_speed , move_accel , ini_pos , move_dir , samp_rate, wind_speed);
        h_track = add_track(track_1, track_2);
    end
end