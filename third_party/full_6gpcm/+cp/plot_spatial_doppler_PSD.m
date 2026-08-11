function plot_spatial_doppler_PSD(costheta,PSD_sim)
figure;plot(costheta,10*log10(PSD_sim));
xlabel('Spatial-doppler frequency, \nu','fontname','times new roman','FontSize',12);
ylabel('Normalized spatial-doppler PSD (dB)','fontname','times new roman','FontSize',12);
xlim([-1 1]);grid on;box on;
