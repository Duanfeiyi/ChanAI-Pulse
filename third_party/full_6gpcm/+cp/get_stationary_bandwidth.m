function SB = get_stationary_bandwidth(h,window_size,FrequencyLine)
% pdp: 1*Mf
ctf = fft(h);
no_carriers = length(ctf);
dif_carriers = 3;
i_fc_num = round(no_carriers/5) - 1;
i_num = round(no_carriers/dif_carriers);
h_PDP = zeros(i_fc_num,i_num+1);
for i_fc = 1:i_fc_num
    i_start = (i_fc-1)*dif_carriers+1;
    h_PDP (:,i_fc) = abs(ifft(ctf(i_start:(i_start+i_fc_num-1)))).^2;
end

[no_freqsample,no_seg] = size(h_PDP);
% Averaging Power delay profiles using window size of window_size
H_bar_PDP=zeros(no_freqsample,no_seg-window_size);
for drop = 1 : no_seg - window_size
    H_bar_PDP(:,drop) = sum(h_PDP(:,drop : drop + window_size - 1),2) / window_size;
end
H_bar_PDP = H_bar_PDP.';
% Calculate the stationary interval
C_threshold = 0.9;
Delta_T_Num = 30;
SB = zeros(1,no_seg - window_size - Delta_T_Num);
for drop=1 : no_seg - window_size - Delta_T_Num
    C = zeros(1,Delta_T_Num);
    for t = 1 : Delta_T_Num
        C(t) = sum(H_bar_PDP(drop,:).*H_bar_PDP(t+drop,:))./max(sum(H_bar_PDP(drop,:).^2),sum(H_bar_PDP(t+drop,:).^2));
        if C(t)>C_threshold
        else
            SB(drop) = FrequencyLine(drop+t)-FrequencyLine(drop);
            break;
        end
    end
end
SB(SB==0) = FrequencyLine(1+Delta_T_Num)-FrequencyLine(1);