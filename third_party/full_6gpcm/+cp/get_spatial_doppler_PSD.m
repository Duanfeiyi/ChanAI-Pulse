function PSD_sim = get_spatial_doppler_PSD(delta_ant,ccf_sim,costheta,lambda)
PSD_sim = zeros(1,length(costheta));
for i = 1:length(costheta)
    PSD_sim(i) = trapz(delta_ant, ccf_sim.*exp(-1i*2*pi*costheta(i)/lambda*delta_ant));
end
PSD_sim = PSD_sim / max(abs(PSD_sim));
