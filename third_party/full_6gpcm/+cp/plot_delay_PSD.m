function plot_delay_PSD(pdp, t_ind, bandwidth)
% Input: 
% pdp: delay PSD
% t_ind: scalar-- one time instant, vector--drifting 
% bandwidth: calculate the delay resolution
if length(t_ind) == 1
    x = (0:size(pdp,4)-1)/bandwidth*1e9;
    figure;
    plot(x, squeeze(10*log10(sum(pdp(:,:,t_ind,:),[1 2]))))
    xlabel('Delay, \tau (ns)','fontname','times new roman','FontSize',12);
    ylabel('Power, \itP \rm(dBm)','fontname','times new roman','FontSize',12);
    xlim([0 1000]);grid on;box on;
else
    figure;
    imagesc(squeeze(10*log10(sum(pdp(:,:,t_ind,:),[1 2]))))
    xlabel('Delay, \tau (ns)','fontname','times new roman','FontSize',12);
    ylabel('Snapshot index','fontname','times new roman','FontSize',12);
    colormap jet;colorbar;axis xy;
end