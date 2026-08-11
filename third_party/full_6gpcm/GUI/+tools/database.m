function scen_para = database(app)

data = {
    % 空-时-频域簇的生灭过程相关变量
    'Corr_distance', 'Time-domain correlation distance [m], 0 indicates that the time-domain non-stationarity is not considered';
    'Corr_distance_A', 'Array-domain correlation distance [m], 0 indicates that space-domain non-stationarity is not considered';
    'Corr_distance_F', 'Frequency-domain correlation distance [Hz], 0 indicates that frequency-domain non-stationarity is not considered';
    'lambdaG', 'Cluster birth rate [/m]';
    'lambdaR', 'Cluster recombination (death) rate [/m]';
    
    % 新簇生成相关的变量
    'R', 'Radius of the tube [m]'; %UHST场景下才用到
    'd_Rx_mean', 'Average distance between the center of the last-bounce cluster and Rx [m]';
    'd_Rx_min', 'Minimum distance between the center of the last-bounce cluster and Rx [m]';
    'd_Tx_mean', 'Average distance between center point of the first-bounce cluster and Tx [m]';
    'd_Tx_min', 'Minimum distance between center point of the first-bounce cluster and Tx [m]';
    
    % 空-时-频簇内子径的功率计算相关的变量
    'uwb_frequency_factor', 'Ultra-wide band frequency dependent factor';  %大带宽场景下才用到
    
    %%%%%%%%% 具有空间一致性的8个大尺度参数(LSPs)
    % (DS, KF, SF, ASD, ASA, ESD, ESA ane XPR)生成相关的变量
    % 与DS相关
    'DS_mu', 'Expectation of delay spread (DS) [log10(s)]';  % [log10（s）] @ 1 GHz
    'DS_mu1', 'Expectation of DS, drone height-dependence [log10(s)/log10(m)]';
    'DS_sigma', 'Standard deviation (STD) of DS [log10(s)]';
    'DS_gamma', 'Dependence of DS [log10(s)/log10(GHz)]';
    'DS_sigma1', 'STD of DS, UAV height-dependence [log10(s)/log10(m)]';
    'DS_omega', 'Reference frequency offset of DS [GHz]';
    'DS_alpha', 'Tx elevation-dependence of DS [log10(s)/log10(rad)]';
    'DS_delta', 'Frequency-dependence of DS STD [log10(s)/log10(GHz)]';
    'DS_beta', 'Distance-dependence of DS STD [log10(s)/log10(m)]';
    
    'DS_epsilon', 'Distance-dependence of DS [log10(s)/log10(m)]';
    'DS_zeta', 'Tx height-dependence of DS [log10(s)/log10(m)]';
    'DS_kappa', 'Distance-dependence of DS STD [log10(s)/log10(m)]';
    'DS_tau', 'Tx height-dependence of DS STD [log10(s)/log10(m)]';
    
    % 与KF相关
    'KF_mu', 'Expectation of the Ricean K-factor (KF) [log10(s)]';
    'KF_mu1', 'Expectation of the KF, drone height-dependence [log10(s)/log10(m)]';
    'KF_sigma', 'STD of the KF [log10(s)]';
    'KF_sigma1', 'STD of the KF, drone height-dependence [log10(s)/log10(m)]';
    'KF_gamma', 'Frequency-dependence of the KF (satellite communication scenarios) [log10(s)/log10(GHz)]';
    'KF_alpha', 'Tx elevation-dependence of the KF STD (satellite communication scenarios) [log10(s)/log10(rad)]';
    'KF_delta', 'Frequency-dependence of the KF STD (satellite communication scenarios) [log10(s)/log10(GHz)]';
    'KF_beta', 'Tx elevation-dependence of the KF STD (satellite communication scenarios) [log10(s)/log10(rad)]';
    
    'KF_omega', 'Reference frequency offset of the KF [GHz]';
    'KF_epsilon', 'Distance-dependence of the KF [log10(s)/log10(m)]';
    'KF_zeta', 'Tx height-dependence of the KF [log10(s)/log10(m)]';
    'KF_kappa', 'Distance-dependence of the KF STD [log10(s)/log10(m)]';
    'KF_tau', 'Tx height-dependence of the KF STD [log10(s)/log10(m)]';
    
    % 与SF相关
    'SF_mu', 'Expectation of the shadow fading (SF) [log10(s)]';
    'SF_mu1', 'Expectation of the SF, drone height-dependence [log10(s)/log10(m)]';
    'SF_sigma', 'STD of the SF [log10(s)]';
    'SF_sigma1', 'drone height-dependence of the SF STD [log10(s)/log10(m)])';
    'SF_beta', 'Tx elevation-dependence of the SF STD (satellite communication scenarios) [log10(s)/log10(rad)]';
    'SF_delta', 'Frequency-dependence of the SF STD (satellite communication scenarios) [log10(s)/log10(GHz)]';
    
    'SF_omega', 'Reference frequency offset of the SF [GHz]';
    'SF_kappa', 'Distance-dependence of the SF STD [log10(s)/log10(m)]'
    'SF_tau', 'Tx height-dependence of the SF STD [log10(s)/log10(m)]';
    
    % 与ASD相关
    'AS_D_mu', 'Expectation of the azimuth spread of departure (ASD) [log10(deg)]';
    'AS_D_mu1', 'Expectation of the ASD, drone height-dependence [log10(deg)/log10(m)]';
    'AS_D_sigma', 'STD of the ASD [log10(deg)]';
    'AS_D_sigma1', 'STD of the ASD, drone height-dependence [log10(deg)/log10(m)]';
    'AS_D_gamma', 'Frequency-dependence of the ASD [log10(deg)/log10(GHz)]';
    'AS_D_omega', 'Reference frequency offset of the ASD [GHz]';
    'AS_D_epsilon', '2D distance-dependence of the ASD [log10(deg)/log10(m)]';
    'AS_D_alpha', 'Tx elevation-dependence of the ASD (satellite communication scenarios) [log10(deg)/log10(rad)]';
    'AS_D_beta', 'log10(deg)/log10(rad)](Tx elevation-dependence of the ASD STD (satellite communication scenarios) [log10(deg)/log10(rad)]';
    'AS_D_delta', 'Frequency-dependence of the ASD STD [log10(deg)/log10(GHz)]';
    
    'AS_D_zeta', 'Tx height-dependence of the ASD [log10(deg)/log10(m)]';
    'AS_D_kappa', 'Distance-dependence of the ASD STD [log10(deg)/log10(m)]'
    'AS_D_tau', 'Tx height-dependence of the ASD STD [log10(deg)/log10(m)]';
    
    % 与ASA相关
    'AS_A_mu', 'Expectation of the azimuth spread of arrival (ASA) [log10(deg)]';
    'AS_A_mu1', 'Expectation of the ASA, drone height-dependence [log10(deg)/log10(m)]';
    'AS_A_sigma', 'STD of the ASA [log10(deg)]';
    'AS_A_sigma1', 'Drone height-dependence of the ASA STD [log10(deg)/log10(m)]';
    'AS_A_omega', 'Reference frequency offset of the ASA [GHz]';
    'AS_A_gamma', 'Frequency-dependence of the ASA [log10(deg)/log10(GHz)]';
    'AS_A_delta', 'Frequency-dependence of the ASA STD [log10(deg)/log10(GHz)]';
    'AS_A_alpha', 'Tx elevation-dependence of the ASA STD (satellite communication scenarios) [log10(deg)/log10(rad)]';
    'AS_A_beta', 'Tx elevation-dependence of the ASA STD (satellite communication scenarios) [log10(deg)/log10(rad)]';
    
    'AS_A_epsilon', 'Distance-dependence of the ASA [log10(deg)/log10(m)]';
    'AS_A_zeta', 'Tx height-dependence of the ASA [log10(deg)/log10(m)]'
    'AS_A_kappa', 'Distance-dependence of the ASA STD [log10(deg)/log10(m)]';
    'AS_A_tau', 'Tx height-dependence of the ASA STD [log10(deg)/log10(m)]';
    
    % 与ESD相关
    'ES_D_mu', 'Expectation of the elevation spread of departure (ESD) [log10(deg)]';
    'ES_D_mu1', 'Expectation of the ESD, drone height-dependence  [log10(deg)/log10(m)]';
    'ES_D_mu_min', 'Minimum value of the ESD [log10(deg)]';
    'ES_D_mu_A', '2D distance-dependence of the ESD [log10(deg)/log10(m)]';
    'ES_D_sigma', 'STD of the ESD [log10(deg)]';
    'ES_D_sigma1', 'STD of the ESD, drone height-dependence [log10(deg)/log10(m)]';
    'ES_D_omega', 'Reference frequency offset of the ESD [GHz]';
    'ES_D_gamma', 'Frequency-dependence of the ESD [log10(deg)/log10(GHz)]';
    'ES_D_epsilon', '2D distance-dependence of the ESD [log10(deg)/log10(m)]';
    'ES_D_alpha', 'Tx elevation-dependence of the ESD (satellite communication scenarios) [log10(deg)/log10(rad)]';
    'ES_D_delta', 'Frequency-dependence of the ESD STD [log10(deg)/log10(GHz)]';
    'ES_D_beta', 'Tx elevation-dependence of the ESD STD (satellite communication scenarios) [log10(deg)/log10(rad)]';
    
    'ES_D_zeta', 'Tx height-dependence of the ESD [log10(deg)/log10(m)]';
    'ES_D_kappa', 'Distance-dependence of the ESD STD [log10(deg)/log10(m)]'
    'ES_D_tau', 'Tx height-dependence of the ESD STD [log10(deg)/log10(m)]';
    
    % 与ESA相关
    'ES_A_mu', 'Expectation of the elevation spread of arrival (ESA) [log10(deg)]';
    'ES_A_mu1', 'Expectation of the ESA, drone height-dependence [log10(deg)/log10(m)]';
    'ES_A_sigma', 'STD of the ESA [log10(deg)]';
    'ES_A_sigma1', 'STD of the ESA, drone height-dependence [log10(deg)/log10(m)]';
    'ES_A_gamma', 'Frequency-dependence of the ESA [log10(deg)/log10(GHz)]';
    'ES_A_omega', 'Reference frequency offset of the ESA [GHz]';
    'ES_A_alpha', 'Tx elevation-dependence of the ESD (satellite communication scenarios) [log10(deg)/log10(rad)]';
    'ES_A_beta', 'STD of the ESA, Tx elevation-dependence (satellite communication scenarios) [log10(deg)/log10(rad)]';
    'ES_A_delta', 'Frequency-dependence of the ESA STD [log10(deg)/log10(GHz)]';
    
    'ES_A_epsilon', 'Distance-dependence of the ESA [log10(deg)/log10(m)]';
    'ES_A_zeta', 'Tx height-dependence of the ESA [log10(deg)/log10(m)]'
    'ES_A_kappa', 'Distance-dependence of the ESA STD [log10(deg)/log10(m)]';
    'ES_A_tau', 'Tx height-dependence of the ESA STD [log10(deg)/log10(m)]';
    
    % 与XPR相关
    'XPR_mu', 'Expectation of the cross-polarization ratio (XPR)';
    'XPR_sigma', 'Expectation of the XPR [log10(s)]';
    'XPR_alpha', 'Tx elevation-dependence of the XPR (satellite communication scenarios) [log10(s)/log10(rad)]';
    'XPR_gamma', 'Frequency-dependence of the XPR  [log10(s)/log10(GHz)]';
    'XPR_beta', 'Tx elevation-dependence of the XPR STD (satellite communication scenarios) [log10(s)/log10(rad)]';
    'XPR_delta', 'Frequency-dependence of the XPR STD [log10(s)/log10(GHz)]';
    
    'XPR_omega', 'Reference frequency offset of the XPR [GHz]';
    'XPR_epsilon', 'Distance-dependence of the XPR [log10(s)/log10(m)]'
    'XPR_zeta', 'Tx height-dependence of the XPR [log10(s)/log10(m)]';
    'XPR_kappa', 'Distance-dependence of the XPR STD [log10(s)/log10(m)]';
    'XPR_tau', 'Tx height-dependence of the XPR STD [log10(s)/log10(m)]';
    
    % Large-Scale fading decorrelation distances 大尺度衰落去相关距离
    'DS_lambda', 'DS de-correlation distance [m]';
    'KF_lambda', 'KF de-correlation distance [m]';
    'SF_lambda', 'SF de-correlation distance [m]';
    'AS_D_lambda', 'ASD de-correlation distance [m]';
    'AS_A_lambda', 'ASA de-correlation distance [m]';
    'ES_D_lambda', 'ESD de-correlation distance [m]';
    'ES_A_lambda', 'ESA de-correlation distance [m]';
    'XPR_lambda', 'XPR de-correlation distance [m]';
    
    % Inter-parameter correlations
    'ds_kf', 'DS_KF correlation coefficient';
    'ds_sf', 'DS_SF correlation coefficient';
    'asD_ds', 'ASD_DS correlation coefficient';
    'asA_ds', 'ASA_DS correlation coefficient';
    'esA_ds', 'ESA_DS correlation coefficient';
    'sf_kf', 'SF_KF correlation coefficient';
    'asD_kf', 'ASD_KF correlation coefficient';
    'asA_kf', 'ASA_KF correlation coefficient';
    'asD_sf', 'ASD_SF correlation coefficient';
    'asA_sf', 'ASA_SF correlation coefficient';
    'asD_asA', 'ASD_ASA correlation coefficient';
    'esD_asD', 'ESD_ASD correlation coefficient';
    'esA_asD', 'ESA_ASD correlation coefficient';
    'esD_ds', 'ESD_DS correlation coefficient';
    'esA_asA', 'ESA_ASA correlation coefficient';
    'esD_esA', 'ESD_ESA correlation coefficient';
    'esA_sf', 'ESA_SF correlation coefficient';
    'esD_asA', 'ESD_ASA correlation coefficient';
    'esA_kf', 'ESA_KF correlation coefficient';
    'esD_sf', 'ESD_SF correlation coefficient';
    'xpr_ds', 'XPR_DS correlation coefficient';
    'esD_kf', 'ESD_KF correlation coefficient';
    'xpr_kf', 'XPR_KF correlation coefficient';
    'xpr_sf', 'XPR_SF correlation coefficient';
    'xpr_asd', 'XPR_ASD correlation coefficient';
    'xpr_esd', 'XPR_ESD correlation coefficient';
    'xpr_esa', 'XPR_ESA correlation coefficient';
    'xpr_asa', 'XPR_ASA correlation coefficient';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % 很多配置文件里都有
    'no_snaps_update', 'The time interval between the birth and death of the cluster';
    
    % Model parameters 模型参数
    'r_DS', 'Delay scaling factor (satellite communication scenario)';
    % Decorrelation distance for the small-scale fading spatial consistency
    'SC_lambda', 'De-correction distance [m]';
    
    % Path-loss model
    'PL_model', 'Path loss model';
    'A', 'Path loss factor A [dB/log10(m)]';
    'A1', 'Path loss factor A1 [dB/log10(m)]';
    'A2', 'Path loss factor A2 [dB/log10(m)]';
    'B', 'Path loss factor B [dB]';
    'C', 'Path loss factor C [dB/log(GHz)]';
    'D', 'Path loss factor D [dB/m]';
    'E', 'Path loss factor E [s/m]';
    'hE', 'Path loss factor hE [m]';
    'An', 'Path loss factor An [dB/log10(m)]';
    'Bn', 'Path loss factor Bn [dB]';
    'Cn', 'Path loss factor Cn [dB/log(GHz)]';
    'Dn', 'Path loss factor Dn [dB/log10(m)]';
    'D2n', 'Path loss factor D2n [dB/log10(m)/m^2]';
    'E3n', 'Path loss factor E3n [dB/m]';
    'Fn', 'Path loss factor Fn [dB/log10(m^{log10(GHz))]';
    'G1n', 'Path loss factor G1n [dB/log10^2(m)]';
    'G2n', 'Path loss factor G2n';
    'sig1', 'Path loss factor sig1 [dB]';
    'sig2', 'Path loss factor sig2 [dB]';
    'gwA', 'Path loss factor gwA [dB/log10(MHz)]';
    'gwB', 'Path loss factor gwB [dB/log10(m)]';
    'gwC', 'Path loss factor gwC [dB/log10(m)]';
    'gwD', 'Path loss factor gwD [dB/log10^2(m)]';
    'swA', 'Path loss factor swA [dB/log10(m)]';
    'swB', 'Path loss factor swB [dB]';
    'swC', 'Path loss factor swC [dB/log10(MHz)]';
    'CL', 'Clutter loss[dB]';
    %Satellite场景特有参数
    'rain_rate', 'Rainfall rate  [mm/h]';
    'PL_usePLa', 'Dedicated to satellite communication scenarios, whether to consider atmospheric attenuation when calculating PL [1 consideration, 0 not consideration]';
    'usePLa', 'Dedicated to satellite communication scenarios, whether to consider atmospheric attenuation when calculating PL [1 consideration, 0 not consideration]';
    
    %VHF特有
    'N','Mean radio-refraction decrement [km]';

    % unique parameters for UHST
    'roughness', 'Vacuum piping roughness coefficient in UHST scenario(Low vacuum tube: 0.5 Tunnel:0.7)';
    
    % AOA AOD仰角、方位角的方差  Satellite、UAV、UHST、OW场景出现
    'AAoA_variance', 'Azimuth angle of arrival expansion [rad]';
    'AAoD_variance', 'Azimuth angle of departure expansion [rad]';
    'EAoA_variance', 'Elevation angle of arrival expansion [rad]';
    'EAoD_variance', 'Elevation angle of departure expansion [rad]';
    
     %%%%%%%%%%%% RIS场景独有 %%%%%%%%%%%%%%%%
    % TX2RIS
    'lambdaG_B2RIS', 'The generaion rate of B2RIS channel cluster[/m]';
    'lambdaR_B2RIS', 'The recombination (disappearance) rate of B2RIS channel cluster [/m]';
    'DS_r_B2RIS', 'B-RIS channel delay spreasd parameters';
    'd_RIS_min_B2RIS', 'The minimum distance between the center of the B2RIS channel last-bounce cluster and the center of RIS [m]';
    'd_RIS_mean_B2RIS', 'The mean distance between the center of the B2RIS channel last-bounce cluster and the center of RIS [m]';
    'd_B_min_B2RIS', 'The minimum distance between the center of the B2RIS channel first-bounce cluster and Tx [m]';
    'd_B_mean_B2RIS', 'The mean distance between the center of the B2RIS channel first-bounce cluster and Tx [m]';
    'NumRay_B2RIS', 'The total number of B2RIS channel sub-paths';
    'Nc0_B2RIS', 'The number of clusters at initial time of the B2RIS channel';
    'tao', 'The amplitude gain of each unit of RIS';
    
    % RIS2RX
    'lambdaG_RIS2U', 'The generaion rate of RIS2U channel cluster[/m]';
    'lambdaR_RIS2U', 'The recombination (disappearance) rate of RIS2U channel cluster [/m]';
    'DS_r_RIS2U', 'RIS2U channel delay spreasd parameters';
    'd_U_min_RIS2U', 'The minimum distance between the center of the RIS2U channel last-bounce cluster and the Rx [m]';
    'd_U_mean_RIS2U', 'The mean distance between the center of the RIS2U channel last-bounce cluster and the Rx [m]';
    'd_RIS_min_RIS2U', 'The minimum distance between the center of the RIS2U channel first-bounce cluster and center of RIS';
    'd_RIS_mean_RIS2U', 'The mean distance between the center of the RIS2U channel first-bounce cluster and center of RIS [m]';
    'NumRay_RIS2U', 'The total number of RIS2U channel sub-paths';
    'Nc0_RIS2U', 'The number of clusters at initial time of the RIS2U channel';
    
    % TX2RX
    'lambdaG_B2U', 'The generaion rate of B2U channel cluster[/m]';
    'lambdaR_B2U', 'The recombination (disappearance) rate of B2U channel cluster [/m]';
    'DS_r_B2U', 'B2U channel delay spreasd parameters)';
    'd_U_min_B2U', 'The minimum distance between the center of the B2U channel last-bounce cluster and the Rx [m]';
    'd_U_mean_B2U', 'The mean distance between the center of the B2U channel last-bounce cluster and the Rx [m]';
    'd_B_min_B2U', 'The minimum distance between the center of the B2U channel first-bounce cluster and Tx [m]';
    'd_B_mean_B2U', 'The mean distance between the center of the B2U channel first-bounce cluster and Tx [m]';
    'NumRay_B2U', 'The total number of B2U channel sub-paths';
    'Nc0_B2U', 'The number of clusters at initial time of the B2U channel';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % OW场景特有参数
    'omegavR_A', 'The rotational azimuth angle velocity at the receiver [rad/s]';
    'omegavR_E', 'The rotational elevation angle velocity at the receiver [rad/s]';
    'Ar', 'The area of PD [m^2]';
    'nind', 'The refractive index of optical lens';
    'FoV', 'The visual Angle of PD';
    'T_gain', 'The optical filter gain at the receiver';
    'Ac_eff', 'The equivalent area of the cluster [m^2]';
    'Vc_eff', 'The equivalent volume of the cluster [m^3]';
    'ms', 'The directivity of specular reflection components';
    'p_particle', 'The probability that the direct path of ultraviolet light and the reflected path of an object are scattered by particles';
    'p_blockage', 'The probability that the LoS component is blocked';
    'eta_SB', 'The proportion of single-bounce clusters';
    'ke', 'Particle extinction coefficient in UV frequency band';
    'ksr', 'Scattering coefficient';
    'ksm', 'Absorption coefficient';
    'nu_A_T', 'The mean value of Tx azimuth angle';
    'nu_E_T', 'The mean value of Tx elevation angle';
    'nu_A_R', 'The mean value of Rx azimuth angle';
    'nu_E_R', 'The mean value of Rx elevation angle';
    'd_PS', 'The particle scattering clusters in ultraviolet light';
    'd_PS_mean', 'The average value of particle scattering cluster xx in ultraviolet light';
    'd_PS_min', 'The minimum value of particle scattering cluster xx in ultraviolet light';
    'PSsigmax', 'The mean value of the Gaussian distribution of particle scattering clusters in ultraviolet light along the x-axis [m]';
    'PSsigmay', 'The mean value of the Gaussian distribution of particle scattering clusters in ultraviolet light along the y-axis [m]';
    'PSsigmaz', 'The mean value of the Gaussian distribution of particle scattering clusters in ultraviolet light along the z-axis [m]';
    
    % 海洋通信场景特有参数
    'h_duct', 'The height of duct [m]';
    'wind_speed', 'The wind speed at 19.5 meters above sea level [m/s]';
    'grav_accel', 'Acceleration of gravity';
    'R_earth', 'Earth radius';
    % 海面上空波导
    'd_Rx_min_h', 'The minimum distance between the cluster and the receiver [m]'; % 
    'd_Rx_mean_h', 'The mean distance between the cluster and the receiver [m]' ;  %
    'd_Tx_min_h', 'The minimum distance between the cluster and the transmitter [m]' ;  % 
    'd_Tx_mean_h', 'The mean distance between the cluster and the transmitter [m]';   % 
    'distance_rx2coastline', 'distance between rx and coastline [m]';
    
    % ISAC特有参数
    'back', 'Not yet used, please ignore it';
    'back_no_clusetes', 'Not yet used, please ignore it';
    
    % IIOT场景特有参数
    'ka_aoa_mean', 'The average ASA value of DMCs >0';
    'ka_aod_mean', 'The average ASD value of DMCs >0';
    'ka_eoa_mean', 'The average ESA value of DMCs >0';
    'ka_eod_mean', 'The average ESD value of DMCs >0';
    'eta', 'The power ratio between SMCs and DMC'; 
    % Absolute time of arrival model parameters (optional feature)
    'absTOA_lambda', 'The offset decorrelation distance of absolute arrival time[m]';
    'absTOA_mu', 'The offset reference value of absolute arrival time [log10(s)]';
    'absTOA_sigma', 'The offset reference STD of absolute arrival time [log10(s)]';
    'no_DMC','The number of multipaths in the DMCs model';
    'PerClusterDS_D','Intra-clutser DS of DMCs';
    'power_decay_rate','Intra-clutser power decay rate of DMCs';

    
    % 阻挡损耗相关参数
    'BL_x_sb' ,	'The azimuth angle span of the self-occluding area [deg]';	            % 阻挡损耗_自阻挡区域的方位角跨度(单位：度)
    'BL_y_sb','The elevation angle span of the self-occluding area [deg]';		        % 阻挡损耗_自阻挡区域的俯仰角跨度(单位：度)
    'BL_theta_sb','The elevation angle of the self-occluding region in the local coordinate system [deg]'; 	% 阻挡损耗_局部坐标系中自阻挡区域的俯仰角(单位：度)
    'BL_phi_sb','The azimuth angle of the self-occluding region in the local coordinate system [deg]';		% 阻挡损耗_局部坐标系中自阻挡区域的方位角(单位：度)
    'BL_x_min','The minimum value of the azimuth angle span in the non-self-occluding area [deg]';		% 阻挡损耗_非自阻挡区域的方位角跨度的最小值(单位：度)
    'BL_x_max','The maximum value of the azimuth angle span in the non-self-occluding area [deg]';		% 阻挡损耗_非自阻挡区域的方位角跨度的最大值(单位：度)
    'BL_y_min','The minimum value of the elevation angle span in the non-self-occluding area [deg]';		% 阻挡损耗_非自阻挡区域的俯仰角跨度的最小值(单位：度)
    'BL_y_max','The maximum value of the elevation angle span in the non-self-occluding area [deg]';		% 阻挡损耗_非自阻挡区域的俯仰角跨度的最大值(单位：度)
    'BL_theta_min','The minimum value of the elevation angle in the non-occlusion area [deg]';	    % 阻挡损耗_非自阻挡区域俯仰角的最小值(单位：度)
    'BL_theta_max','The maximum value of the elevation angle in the non-occlusion area [deg]';	    % 阻挡损耗_非自阻挡区域俯仰角的最大值(单位：度)
    'BL_phi_min','The minimum value of the azimuth angle of the non-self-occluding area [deg]';        	% 阻挡损耗_非自阻挡区域方位角的最小值(单位：度)
    'BL_phi_max','The maximum value of the azimuth angle of the non-self-occluding area [deg]';	        % 阻挡损耗_非自阻挡区域方位角的最大值(单位：度)
    'BL_r','The distance between the receiver and the blocker [m]'; 		        % 阻挡损耗_接收机与阻挡物之间的距离(单位：米)
    %3GPP
    'SubpathMethod',' Subpath mapping method (legacy, Laplacian or mmMAGIC)';
    'LNS_ksi', 'Per cluster shadowing STD [dB]';
    'PerClusterDS',          'Cluster delay spread [ns]';
    'PerClusterDS_gamma', 'Freq.-dep. of cluster delay spread [ns/log10(GHz)]';
    'PerClusterDS_min', 'Minumum cluster delay spread [ns]';
    'PerClusterAS_D', 'Cluster azimuth of departure angle spread [deg]';
    'PerClusterAS_A' ,    'Cluster azimuth of arrival angle spread [deg]';
    'PerClusterES_D' , 'Cluster elevation of departure angle spread [deg]';
    'PerClusterES_A' , 'Cluster elevation of arrival angle spread [deg]';
    'per_cluster_shadowing', 'Per-cluster shadowing fading'

    % new
    'LOS_scatter_radius','Scattering around the LOS cluster';
    'GR_enabled','Enable (1) or disable (0) Ground Reflection';
    'GR_epsilon','Manual value for the relative permittivity, 0 = auto';
    'lambdaG_N','Generation rate in the birth-death process'
    'lambdaR_N','Recombination rate in the birth-death process'
    'lambdaG_F','Generation rate in the birth-death process'
    'lambdaR_F','Recombination rate in the birth-death process'
    'DS_mu_N','Delay spread [log10(s)] @ 1 GHz'
    'DS_sigma_N','Delay spread STD [log10(s)] '
    'DS_mu_F','Delay spread [log10(s)] @ 1 GHz'
    'DS_sigma_F','Delay spread STD [log10(s)]'
    'AS_D_sigma_F','Azimuth of departure angle spread STD [log10(deg)]'
    'AS_D_sigma_N','Azimuth of departure angle spread STD [log10(deg)]' 
    'AS_A_sigma_F','Azimuth of arrival angle spread STD [log10(deg)]' 
    'AS_A_sigma_N','Azimuth of arrival angle spread STD [log10(deg)]'
    'ES_D_sigma_F','Elevation of departure angle spread STD [log10(deg)]'
    'ES_D_sigma_N','Elevation of departure angle spread STD [log10(deg)]' 
    'ES_A_sigma_F','Elevation of arrival angle spread STD [log10(deg)]'
    'ES_A_sigma_N','Elevation of arrival angle spread STD [log10(deg)]'
    'tunnel_H','Height of cross-section'
    'tunnel_W','Width of cross-section'
    
    'garage_L','Length'
    'garage_W','Width' 
    'garage_H','Height'
    'dens','Scatter density'
    'delta','Interval'
    'R_lim','Radius of visual area'

    % UWA
    'height_water','Water height';
    'subpath_angle_sigma','Subpath angle sigma';
    };
variableNames = {'name', 'Chinese'};
scen_para = cell2table(data, 'VariableNames', variableNames);
end