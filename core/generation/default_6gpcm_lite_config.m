function config = default_6gpcm_lite_config()
%DEFAULT_6GPCM_LITE_CONFIG Return public defaults for the lite generator.
%   The model is an independent, compact clustered channel generator. It
%   uses 6GPCM-inspired delay, cluster, ray, Rician, and Doppler concepts
%   without depending on an external 6GPCM software package.

config = struct();
config.bandwidth_hz = 100e6;
config.delay_grid_step_ns = 1.0;
config.delay_max_ns = 300;
config.ds_mu = -7.925;
config.ds_sigma = 0.06;
config.r_ds = 2.8;
config.clusters = 12;
config.rays = 20;
config.lns_ksi_db = 3.0;
config.kf_mu_db = -0.39;
config.kf_sigma_db = 2.4;
config.snapshots = 50;
config.doppler_hz = 50;
config.sample_interval_s = 1e-3;
config.random_seed = [];
end
