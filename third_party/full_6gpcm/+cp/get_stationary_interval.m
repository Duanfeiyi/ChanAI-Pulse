function SI = get_stationary_interval(pdp, window_size,TimeLine)
% pdp: Ms*Mf
H_PDP = squeeze(pdp);
[no_snaphots, no_carriers] = size(H_PDP);
% Averaging Power delay profiles using window size of window_size
H_bar_PDP = zeros(no_snaphots - window_size, no_carriers);
for drop = 1 : no_snaphots - window_size
    H_bar_PDP(drop,:) = sum(H_PDP(drop : drop + window_size - 1, :)) / window_size;
end

% Calculate the stationary interval
C_threshold = 0.8;
Delta_T_Num = ceil(no_snaphots/3);
SI = zeros(1,no_snaphots - window_size - Delta_T_Num);

for drop=1 : no_snaphots - window_size - Delta_T_Num
    C = zeros(1,Delta_T_Num);
    for t = 1 : Delta_T_Num
        C(t) = sum(H_bar_PDP(drop,:).*H_bar_PDP(t+drop,:))./max(sum(H_bar_PDP(drop,:).^2),sum(H_bar_PDP(t+drop,:).^2));
        if C(t) > C_threshold
        else
            SI(drop)=TimeLine(drop+t)-TimeLine(drop);
            break;
        end
    end
end