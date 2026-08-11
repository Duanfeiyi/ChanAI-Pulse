function scen_para = set_scen_para(simu_para, scenario)
%READ_SCEN_PARA read scenaro-dependent parameters from config files
% %   % check if the input argument "scenario" belongs to one of the simulation scenarios
%     load_scen_names;
%     scen_names = scen_name_lists;
%     if ~ismember(scenario, scen_names)
%         error('The input argument "Scenario" is illegal');
%     end
    
    file_dir = ['scen_', scenario, '.conf'];     
        scen_para = struct( ...
        'DS_lambda' , 20 , ...             % Decorrelation distance [m]
        'DS_omega' , 0 , ...               % Reference frequency offset [GHz]
        'DS_gamma' , 0 , ...               % Freq.-dep. [log10(s)/log10(GHz)]
        'DS_epsilon' , 0 , ...             % Dist.-dep. [log10(s)/log10(m)]
        'DS_zeta' , 0 , ...                % BS-height-dep. [log10(s)/log10(m)]
        'DS_alpha' , 0 , ...               % TX-elevation-dep. [log10(s)/log10(rad)]
        'DS_delta' , 0 , ...               % Freq.-dep. of STD [log10(s)/log10(GHz)]
        'DS_kappa' , 0 , ...               % Dist.-dep. of STD [log10(s)/log10(m)]
        'DS_tau' , 0 , ...                 % BS-height-dep. of STD [log10(s)/log10(m)]
        'DS_beta' , 0 , ...                % TX-elevation-dep. of STD [log10(s)/log10(rad)]
        'AS_D_mu' , 1 , ...                % Reference value [log10(deg)]
        'AS_D_sigma' , 0.2 , ...           % Referenece STD [log10(deg)]
        'AS_D_lambda' , 20 , ...           % Decorrelation distance [m]
        'AS_D_omega' , 0 , ...             % Reference frequency offset [GHz]
        'AS_D_gamma' , 0 , ...             % Freq.-dep. [log10(deg)/log10(GHz)]
        'AS_D_epsilon' , 0 , ...           % Dist.-dep. [log10(deg)/log10(m)]
        'AS_D_zeta' , 0 , ...              % BS-height-dep. [log10(deg)/log10(m)]
        'AS_D_alpha' , 0 , ...             % TX-elevation-dep. [log10(deg)/log10(rad)]
        'AS_D_delta' , 0 , ...             % Freq.-dep. of STD [log10(deg)/log10(GHz)]
        'AS_D_kappa' , 0 , ...             % Dist.-dep. of STD [log10(deg)/log10(m)]
        'AS_D_tau' , 0 , ...               % BS-height-dep. of STD [log10(deg)/log10(m)]
        'AS_D_beta' , 0 , ...              % TX-elevation-dep. of STD [log10(deg)/log10(rad)]
        'AS_A_mu' , 1 , ...                % Reference value [log10(deg)]
        'AS_A_sigma' , 0.2 , ...           % Referenece STD [log10(deg)]
        'AS_A_lambda' , 20 , ...           % Decorrelation distance [m]
        'AS_A_omega' , 0 , ...             % Reference frequency offset [GHz]
        'AS_A_gamma' , 0 , ...             % Freq.-dep. [log10(deg)/log10(GHz)]
        'AS_A_epsilon' , 0 , ...           % Dist.-dep. [log10(deg)/log10(m)]
        'AS_A_zeta' , 0 , ...              % BS-height-dep. [log10(deg)/log10(m)]
        'AS_A_alpha' , 0 , ...             % TX-elevation-dep. [log10(deg)/log10(rad)]
        'AS_A_delta' , 0 , ...             % Freq.-dep. of STD [log10(deg)/log10(GHz)]
        'AS_A_kappa' , 0 , ...             % Dist.-dep. of STD [log10(deg)/log10(m)]
        'AS_A_tau' , 0 , ...               % BS-height-dep. of STD [log10(deg)/log10(m)]
        'AS_A_beta' , 0 , ...              % TX-elevation-dep. of STD [log10(deg)/log10(rad)]
        'ES_D_mu' , 0.3 , ...              % Reference value [log10(deg)]
        'ES_D_sigma' , 0.2 , ...           % Referenece STD [log10(deg)]
        'ES_D_lambda' , 20 , ...           % Decorrelation distance [m]
        'ES_D_omega' , 0 , ...             % Reference frequency offset [GHz]
        'ES_D_gamma' , 0 , ...             % Freq.-dep. [log10(deg)/log10(GHz)]
        'ES_D_epsilon' , 0 , ...           % Dist.-dep. [log10(deg)/log10(m)]
        'ES_D_zeta' , 0 , ...              % BS-height-dep. [log10(deg)/log10(m)]
        'ES_D_alpha' , 0 , ...             % TX-elevation-dep. [log10(deg)/log10(rad)]
        'ES_D_delta' , 0 , ...             % Freq.-dep. of STD [log10(deg)/log10(GHz)]
        'ES_D_kappa' , 0 , ...             % Dist.-dep. of STD [log10(deg)/log10(m)]
        'ES_D_tau' , 0 , ...               % BS-height-dep. of STD [log10(deg)/log10(m)]
        'ES_D_beta' , 0 , ...              % TX-elevation-dep. of STD [log10(deg)/log10(rad)]
        'ES_D_mu_A' , 0 , ...              % departure elevation spread distance dependency (legacy)
        'ES_D_mu_min' , -Inf , ...         % departure elevation spread minimum value
        'ES_A_mu' , 0.3 , ...              % Reference value [log10(deg)]
        'ES_A_sigma' , 0.2 , ...           % Referenece STD [log10(deg)]
        'ES_A_lambda' , 20 , ...           % Decorrelation distance [m]
        'ES_A_omega' , 0 , ...             % Reference frequency offset [GHz]
        'ES_A_gamma' , 0 , ...             % Freq.-dep. [log10(deg)/log10(GHz)]
        'ES_A_epsilon' , 0 , ...           % Dist.-dep. [log10(deg)/log10(m)]
        'ES_A_zeta' , 0 , ...              % BS-height-dep. [log10(deg)/log10(m)]
        'ES_A_alpha' , 0 , ...             % TX-elevation-dep. [log10(deg)/log10(rad)]
        'ES_A_delta' , 0 , ...             % Freq.-dep. of STD [log10(deg)/log10(GHz)]
        'ES_A_kappa' , 0 , ...             % Dist.-dep. of STD [log10(deg)/log10(m)]
        'ES_A_tau' , 0 , ...               % BS-height-dep. of STD [log10(deg)/log10(m)]
        'ES_A_beta' , 0 , ...              % TX-elevation-dep. of STD [log10(deg)/log10(rad)]
        'SF_sigma' , 8 , ...               % Referenece STD [log10(s)]
        'SF_lambda' , 20 , ...             % Decorrelation distance [m]
        'SF_omega' , 0 , ...               % Reference frequency offset [GHz]
        'SF_delta' , 0 , ...               % Freq.-dep. of STD [log10(s)/log10(GHz)]
        'SF_kappa' , 0 , ...               % Dist.-dep. of STD [log10(s)/log10(m)]
        'SF_tau' , 0 , ...                 % BS-height-dep. of STD [log10(s)/log10(m)]
        'SF_beta' , 0 , ...                % TX-elevation-dep. of STD [log10(s)/log10(rad)]
        'KF_mu' , 0 , ...                  % Reference value [log10(s)]
        'KF_sigma' , 0 , ...               % Referenece STD [log10(s)]
        'KF_lambda' , 20 , ...             % Decorrelation distance [m]
        'KF_omega' , 0 , ...               % Reference frequency offset [GHz]
        'KF_gamma' , 0 , ...               % Freq.-dep. [log10(s)/log10(GHz)]
        'KF_epsilon' , 0 , ...             % Dist.-dep. [log10(s)/log10(m)]
        'KF_zeta' , 0 , ...                % BS-height-dep. [log10(s)/log10(m)]
        'KF_alpha' , 0 , ...               % TX-elevation-dep. [log10(s)/log10(rad)]
        'KF_delta' , 0 , ...               % Freq.-dep. of STD [log10(s)/log10(GHz)]
        'KF_kappa' , 0 , ...               % Dist.-dep. of STD [log10(s)/log10(m)]
        'KF_tau' , 0 , ...                 % BS-height-dep. of STD [log10(s)/log10(m)]
        'KF_beta' , 0 , ...                % TX-elevation-dep. of STD [log10(s)/log10(rad)]
        'XPR_mu' , 0 , ...                 % Reference value [log10(s)]
        'XPR_sigma' , 10 , ...             % Referenece STD [log10(s)]
        'XPR_lambda' , 20 , ...            % Decorrelation distance [m]
        'XPR_omega' , 0 , ...              % Reference frequency offset [GHz]
        'XPR_gamma' , 0 , ...              % Freq.-dep. [log10(s)/log10(GHz)]
        'XPR_epsilon' , 0 , ...            % Dist.-dep. [log10(s)/log10(m)]
        'XPR_zeta' , 0 , ...               % BS-height-dep. [log10(s)/log10(m)]
        'XPR_alpha' , 0 , ...              % TX-elevation-dep. [log10(s)/log10(rad)]
        'XPR_delta' , 0 , ...              % Freq.-dep. of STD [log10(s)/log10(GHz)]
        'XPR_kappa' , 0 , ...              % Dist.-dep. of STD [log10(s)/log10(m)]
        'XPR_tau' , 0 , ...                % BS-height-dep. of STD [log10(s)/log10(m)]
        'XPR_beta' , 0 , ...               % TX-elevation-dep. of STD [log10(s)/log10(rad)]
        'PerClusterDS', 0 , ...            % Cluster Delay Spread factor cDS in [ns]
        'PerClusterDS_gamma', 0 , ...      % Freq.-dep. of Cluster DS [ns/log10(GHz)]
        'PerClusterDS_min', 0 , ...        % Minimum Cluster Delay Spread in [ns]
        'absTOA_mu' , -100 , ...           % Absolute time of azRival offset reference value [log10(s)]
        'absTOA_sigma' , 0 , ...           % Absolute time of azRival offset referenece STD [log10(s)]
        'absTOA_lambda' , 0 , ...          % Absolute time of azRival offset decorrelation distance [m]
        'SubpathMethod', 'legacy', ...     % Subpath-generation method
        'LOS_scatter_radius', 0, ...       % Scattering around the LOS cluster
        'SC_lambda', 0 ,...                % Decorrelation distance [m] for spatial consistency
        'GR_enabled' , 0 , ...             % Enable (1) or disable (0) Ground Reflection
        'GR_epsilon' , 0 , ...             % Manual value for the relative permittivity, 0 = auto
        'asD_ds' , 0 , ...                 % departure AS vs delay spread
        'asA_ds' , 0 , ...                 % azRival AS vs delay spread
        'asA_sf' , 0 , ...                 % azRival AS vs shadowing std
        'asD_sf' , 0 , ...                 % departure AS vs shadowing std
        'ds_sf' , 0 , ...                  % delay spread vs shadowing std
        'asD_asA' , 0 , ...                % departure AS vs azRival AS
        'asD_kf' , 0 , ...                 % departure AS vs k-factor
        'asA_kf' , 0 , ...                 % azRival AS vs k-factor
        'ds_kf' , 0 , ...                  % delay spread vs k-factor
        'sf_kf' , 0 , ...                  % shadowing std vs k-factor
        'esD_ds' , 0 , ...                 % departure ES vs delay spread
        'esA_ds' , 0 , ...                 % azRival ES vs delay spread
        'esA_sf' , 0 , ...                 % azRival ES vs shadowing std
        'esD_sf' , 0 , ...                 % departure ES vs shadowing std
        'esD_esA' , 0 , ...                % departure ES vs azRival ES
        'esD_asD' , 0 , ...                % departure ES vs departure AS
        'esD_asA' , 0 , ...                % departure ES vs azRival AS
        'esA_asD' , 0 , ...                % azRival ES vs departure AS
        'esA_asA' , 0 , ...                % azRival ES vs azRival AS
        'esD_kf' , 0 , ...                 % departure ES vs k-factor
        'esA_kf' , 0 , ...                 % azRival ES vs k-factor
        'xpr_ds' , 0 , ...                 % XPR vs. DS
        'xpr_kf' , 0 , ...                 % XPR vs. DS
        'xpr_sf' , 0 , ...                 % XPR vs. DS
        'xpr_asd' , 0 , ...                % XPR vs. DS
        'xpr_asa' , 0 , ...                % XPR vs. DS
        'xpr_esd' , 0 , ...                % XPR vs. DS
        'xpr_esa' , 0 );                   % XPR vs. DS

        configFilePath = fullfile('config', file_dir);

        if ~exist(configFilePath, 'file')
            configFilePath = file_dir;
        end

        mf.add_logs('set_scen_para', configFilePath);
        scen_para = mf.read_scen_para(configFilePath, scenario, scen_para);
    simu_para.scen_para = scen_para;
end

