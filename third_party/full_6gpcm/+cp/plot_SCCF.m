function plot_SCCF(ccf,deltad)
no_ant = length(ccf);
x = (0 : no_ant - 1) * deltad;
figure;plot(x,ccf);
xlabel('Space interval, \Delta d (m)','fontname','times new roman','FontSize',12);
ylabel('SCCF','fontname','times new roman','FontSize',12);
xlim([0 (no_ant-1)*deltad]);grid on;box on;
