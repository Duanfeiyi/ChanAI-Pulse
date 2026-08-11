function SD = get_stationary_distance(pdp, window_size,SpaceLine)
% pdp: Mt*Mf
H_PDP = squeeze(pdp);
[no_antennas, no_carriers] = size(H_PDP);
% Averaging Power delay profiles using window size of window_size
H_bar_PDP = zeros(no_antennas-window_size, no_carriers);
for drop = 1 : no_antennas - window_size
    H_bar_PDP(drop,:) = sum(H_PDP(drop : drop + window_size - 1, :)) / window_size;
end

% Calculate the stationary interval
C_threshold = 0.8;
Delta_T_Num = 10;
SD = zeros(1, no_antennas - window_size - Delta_T_Num);
for drop = 1 : no_antennas - window_size - Delta_T_Num
    C = zeros(1, Delta_T_Num);
    for t = 1 : Delta_T_Num
        C(t) = sum(H_bar_PDP(drop,:) .* H_bar_PDP(t+drop,:))./max(sum(H_bar_PDP(drop,:).^2),sum(H_bar_PDP(t+drop,:).^2));
        if C(t) > C_threshold
            
        else
            SD(drop) = SpaceLine(drop+t) - SpaceLine(drop);
            break;
        end
    end
end