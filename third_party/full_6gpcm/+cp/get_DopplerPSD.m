function [fd,PSD_sim] = get_DopplerPSD(delta_time,acf_sim,fd)
PSD_sim = zeros(1,length(fd));
for i = 1:length(fd)
    PSD_sim(i) = trapz(delta_time, acf_sim.*exp(1i*2*pi*fd(i)*delta_time));
end
PSD_sim = abs(PSD_sim) / max(abs(PSD_sim));
