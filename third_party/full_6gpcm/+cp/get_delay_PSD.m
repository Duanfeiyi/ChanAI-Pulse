function [tau,PSD_sim] = get_delay_PSD(fDelta,fcf_sim,tau)
PSD_sim = zeros(1,length(tau));
for i = 1:length(tau)
    PSD_sim(i) = trapz(fDelta, fcf_sim.*exp(1i*2*pi*tau(i)*fDelta)); %…æ¡À∏∫∫≈
end
PSD_sim = real(PSD_sim) / max(real(PSD_sim));



