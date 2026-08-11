function h_track = generate( track_type, move_time , move_speed , move_accel , ini_pos , move_dir , samp_rate, wind_speed)
%GENERATE 此处显示有关此函数的摘要
%   此处显示详细说明
    supported_types = track.supported_types;
    if ~exist( 'track_type' , 'var' )
        error('"track_type" is not given.')
    elseif ~( ischar(track_type) && any( strcmpi(track_type,supported_types)) )
        str = 'Track type not found. Supported types are: ';
        no = numel(supported_types);
        for n = 1:no
            str = [str,supported_types{n}];
            if n<no
                str = [str,', '];
            end
        end
        error(str);
    end

    if ~exist( 'wind_speed' , 'var' )
        wind_speed = 5; % 海洋通信场景，默认的风速是5 m/s。
    end
    
    if sum(move_dir) == 0
        
    else
        move_dir = move_dir./norm(move_dir);
    end
    time_scale = 0:1/samp_rate:move_time;
    positions = zeros(length(time_scale),3);
    speed = zeros(length(time_scale),1);
    
    switch track_type
        case 'static'
            track_length = 0;
            for t=1:length(time_scale)
                positions(t,:) = ini_pos;
            end
        case 'linear'
           track_length = move_time*(2*move_speed + move_accel*move_time)/2;
           positions(1,:) = ini_pos;
           speed(1,:) = move_speed;
           for t=2:length(time_scale)
                positions(t,:) = positions(t-1,:) + 1/samp_rate.*(move_speed + move_accel*(t/samp_rate)).*move_dir;  %%%%%%%%%%%%% 这是个末速度*T
                speed(t) = speed(t-1) + move_accel*1/samp_rate;
           end

        case 'circle'
            r_vect = [move_dir(2) -move_dir(1) 0];
            track_length = move_time*(2*move_speed+move_accel*move_time)/2;
            radius = track_length/2/pi.*r_vect;
            center = ini_pos + radius;
            rad(1) = 0;
            speed(1,:) = move_speed;
            for t = 2:length(time_scale)
                rad(t) = rad(t-1) + (move_speed+move_accel*(t/samp_rate))/samp_rate/norm(radius);
                speed(t) = speed(t-1) + move_accel * 1/samp_rate;
            end
            rad=rad.*1.6;
            for t=1:length(time_scale)
                positions(t,:) = center + [-cos(rad(t))*radius(1)-sin(rad(t))*radius(2) sin(rad(t))*radius(1)-cos(rad(t))*radius(2) t*move_dir(3)];
            end

        case 'random'
           track_length = move_time*(2*move_speed + move_accel*move_time)/2;
           positions(1,:) = ini_pos;
           speed(1,:) = move_speed;
           for t=2:length(time_scale)
                move_dir=(0.7.*ones(1,3)+0.6.*rand(1,3)).*move_dir;
                move_dir = move_dir./norm(move_dir);
                positions(t,:) = positions(t-1,:) + 1/samp_rate.*(move_speed + move_accel*(t/samp_rate)).*move_dir;  %%%%%%%%%%%%% 这是个末速度*T
                speed(t) = speed(t-1) + move_accel*1/samp_rate;
           end
       
        case 'random_circle'
            track_length = move_time*(2*move_speed + move_accel*move_time)/2;
            %初始化
            t=1;
            p(1,:)= ini_pos;
            r(1)=0.05+0.1*rand(1);
            center(1,:) = p(1,:)-[r(1),0,0];
            radius(1,:)=[r(1),0,0];
            i=1;
            speed(1,:) = move_speed;
            while (t<=length(time_scale))
                % TODO
                % speed(t+1) = speed(t) + move_accel * 1/samp_rate;
                
                r(i+1)=0.05+0.1*rand(1); %半径随机取值
                tou(i) = 0.05+0.1*rand(1); %运动周期随机取值
                T(i) = floor(tou(i)*samp_rate)+1; %运动周期取整数
                rad(t) = atan2d(-radius(i,2),-radius(i,1)); %确定每个周期的初始辐角
                rad(t) = mod(rad(t),360)/360*2*pi;
                for k=(t+1):(T(i)+t-1)
                    rad(k)=rad(k-1) +((-1)^i)*((move_speed +1/2*move_accel)/samp_rate/r(i));%%如果r(i)>0,转弯方向应该改变
                end
                for k=t:(T(i)+t-1)
                    p(k,:) = center(i,:) + [cos(rad(k))*r(i),  sin(rad(k))*r(i), move_dir(3)*(k-t+1)/samp_rate];
                end
                t=t+T(i);
                radius(i+1,:)=[(p(t-1,1)-center(i,1)),(p(t-1,2)-center(i,2)),0];
                radius(i+1,:)=radius(i+1,:)/norm(radius(i+1,:));
                radius(i+1,:)=radius(i+1,:).*r(i+1);
                center(i+1,:)= p(t-1,:)+radius(i+1,:);
                i=i+1;
            end
            positions=p(1:length(time_scale),:);
            
        case 'shipStatic' 
            track_length = 0;
            [Z] = getZ_paras(time_scale, samp_rate, wind_speed);
            for t = 1:length(time_scale)
                positions(t,:) = ini_pos + [0 0 Z(t)];
            end
            
        case 'shipLinear'
            track_length = move_time*(2* move_speed+move_accel*move_time)/2;
            [Z] = getZ_paras(time_scale, samp_rate, wind_speed);
            
            positions(1,:) = ini_pos+[0 0 Z(1)];
            speed(1,:) = move_speed;
            for t=2:length(time_scale)
                positions(t,:) = positions(t-1,:) + 1/samp_rate.*(move_speed + move_accel*(t-1-0.5)/samp_rate).*move_dir+[0 0 Z(t)-Z(t-1)];
                speed(t) = speed(t-1) + move_accel*1/samp_rate;
            end
            
        otherwise
            error('track:generate',['Track type "',track_type,'" is not supported.']);
    end
    
    h_track = track([]);
    h_track.move_time = move_time;
    h_track.name = track_type;
    h_track.positions = positions;
    h_track.time_scale = time_scale';
    h_track.track_length = track_length;
    h_track.move_speed = speed;
    h_track.move_accel = move_accel;
    h_track.samp_rate = samp_rate;
    h_track.move_dir = move_dir;
    h_track.move_direc_azimuth = atan2(move_dir(2), move_dir(1)) .* ones(length(time_scale),1);
    h_track.move_direc_elevation = atan2(move_dir(3), move_dir(1)) .* ones(length(time_scale),1);
end

function [Z] = getZ_paras(time_scale, samp_rate, wind_speed)
    N = 25; % N is the number of composite waves in equation (8)
    delta_w = 0.2;
    belta=0.74;
    g=9.8;
    b=0.0081;
    
    c = unifrnd(0, 2 * pi,N,1);
    Z = zeros(length(time_scale),1);
    z = zeros(length(time_scale),N);
    a = zeros(1,N);
    w = zeros(1,N);
    s = zeros(1,N);
    
    for tz=1:length(time_scale)
        for n=1:1:N
            w(n)=0.2+delta_w*(n-1);
            s(n)=b*g^2/w(n)^5*exp(-belta*(g/(wind_speed*w(n)))^4);
            a(n)=sqrt(2*s(n)*delta_w);
            z(tz,n)=a(n)*cos(w(n)*(tz-1)*1/samp_rate+c(n));
        end
        Z(tz)=sum(z(tz,:));
    end
end

