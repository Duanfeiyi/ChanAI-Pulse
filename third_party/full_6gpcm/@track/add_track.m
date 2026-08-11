function [track_total] = add_track(track_1,track_2)
%ADD_TRACK 此处显示有关此函数的摘要
%   此处显示详细说明
    track_total = track([]);
    track_total.move_time = cat(1, track_1.move_time, track_2.move_time);
    track_total.name = 'mix';
    track_total.positions = cat(1, track_1.positions, track_2.positions);
    track_total.time_scale = cat(1, track_1.time_scale, track_2.time_scale);
    track_total.track_length = cat(1, track_1.track_length, track_2.track_length);
    track_total.move_speed = cat(1, track_1.move_speed, track_2.move_speed);
    track_total.move_accel = cat(1, track_1.move_accel, track_2.move_accel);
    track_total.move_direc_azimuth = cat(1, track_1.move_direc_azimuth, track_2.move_direc_azimuth);
    track_total.no_track_segment = track_1.no_track_segment + track_2.no_track_segment;
end

