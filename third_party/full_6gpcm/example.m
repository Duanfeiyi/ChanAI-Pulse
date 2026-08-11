function example
% example
% 调用 generate_channel_v1 生成 H 矩阵，
% 绘制第一个 H 矩阵第一个 snap 的PDP，
% 并绘制时延扩展CDF曲线。

    close all; clc;

    %% 1）输入参数
    DS_mu        = -7.925;
    DS_sigma     = 0.060;
    r_DS         = 2.8;
    num_clusters = 12;
    num_rays     = 20;
    LNS_ksi      = 3.0;
    KF_mu        = -0.39;
    KF_sigma     = 2.4;

    N = 50;

    noise_floor_dB     = -60;   % 噪声门限，单位 dB，决定PDP噪声底的大致位置
    noise_amplitude_dB = 5.0;   % 噪声起伏幅度，单位 dB，决定噪声底上下波动范围
    delay_grid_step_ns = 1.0;   % 时延网格分辨率，单位 ns，决定绘制连续PDP时的横轴采样间隔
    pulse_sigma_ns     = 1.5;   % 脉冲展宽宽度，单位 ns，决定每个离散多径分量在PDP中的扩散程度
    delay_max_ns       = 300;   % 最大显示时延，单位 ns，决定PDP横轴的终止位置

    %% 2）生成 H 和 delay
    [H_all, delay_all] = generate_channel_v1( ...
        DS_mu, DS_sigma, r_DS, num_clusters, num_rays, ...
        LNS_ksi, KF_mu, KF_sigma, N);

    %% 3）绘制第一个 H 矩阵第一个 snap 的PDP
    H1 = H_all{1};
    delay1 = delay_all{1};

    if size(H1, 3) < 1
        error('第一个 H 矩阵中没有可用的 snap。');
    end

    h_CIR  = squeeze(H1(1,1,1,:));
    taus_ns = squeeze(delay1(1,1,1,:)).' * 1e9;
    PSDsim = abs(h_CIR).^2.';

    [taus_ns, idx] = sort(taus_ns);
    PSDsim = PSDsim(idx);

    delay_axis_ns = 0:delay_grid_step_ns:delay_max_ns;
    pdp_linear = zeros(size(delay_axis_ns));

    for k = 1:numel(taus_ns)
        g = exp(-0.5 * ((delay_axis_ns - taus_ns(k)) / pulse_sigma_ns).^2);
        g = g / max(g);
        pdp_linear = pdp_linear + PSDsim(k) * g;
    end

    noise_trace_dB = noise_floor_dB + noise_amplitude_dB * (2 * rand(size(delay_axis_ns)) - 1);
    noise_linear = 10.^(noise_trace_dB / 10);

    pdp_plot_dB = 10 * log10(pdp_linear + noise_linear + eps);
    tap_power_dB = 10 * log10(PSDsim + eps);

    figure('Color','w');
    plot(delay_axis_ns, pdp_plot_dB, '-', 'LineWidth', 1.5);
    hold on;
    plot(taus_ns, tap_power_dB, 'o', 'LineWidth', 1.2, 'MarkerSize', 6);
    grid on; box on;
    xlabel('Delay (ns)','fontname','times new roman','fontsize',14);
    ylabel('Power (dB)','fontname','times new roman','fontsize',14);
    title('Delay power spectrum of the first H matrix at the first snap', ...
        'fontname','times new roman','fontsize',14);
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 14);
    legend('PDP with noise floor', 'Multipath components', 'Location', 'best');

    %% 4）计算所有样本的时延扩展
    ds_all_ns = [];

    for i = 1:N
        H = H_all{i};
        delay = delay_all{i};

        num_snap = size(H, 3);

        for i_snap = 1:num_snap
            h_CIR = squeeze(H(:,:,i_snap,:));
            taus  = squeeze(delay(1,1,i_snap,:)).';

            delay_PSD = abs(squeeze(h_CIR(1,1,:))).^2;

            if isempty(taus) || isempty(delay_PSD)
                continue;
            end

            if any(~isfinite(taus)) || any(~isfinite(delay_PSD))
                continue;
            end

            [ds, ~] = mf.calc_ds(taus, delay_PSD.');
            if ~isempty(ds) && all(isfinite(ds))
                ds_all_ns(end+1,1) = ds * 1e9; %#ok<AGROW>
            end
        end
    end

    if isempty(ds_all_ns)
        error('未能得到有效的时延扩展样本。');
    end

    %% 5）绘制时延扩展CDF
    ds_sorted = sort(ds_all_ns);
    cdf_y = (1:numel(ds_sorted))' / numel(ds_sorted);

    figure('Color','w');
    plot(ds_sorted, cdf_y, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    grid on; box on;
    xlabel('Delay spread (ns)','fontname','times new roman','fontsize',14);
    ylabel('CDF','fontname','times new roman','fontsize',14);
    title('CDF of delay spread', ...
        'fontname','times new roman','fontsize',14);
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 14);

    %% 6）打印结果
    fprintf('时延扩展样本（ns）：\n');
    disp(ds_all_ns.');
end