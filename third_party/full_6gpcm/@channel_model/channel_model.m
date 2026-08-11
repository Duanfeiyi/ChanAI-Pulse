classdef channel_model < handle    
    properties
        name = '';                  % Name of the parameter set object
        sim_params = simulation_parameters;       
        tx_array = []; %第一个维度是用户，第二个维度是频段
        rx_array = [];
        tx_track = [];
        rx_track = [];
        tar_track = [];%目标轨迹（Zixuan Chen）
        tar_array = [];
        tar_num = [];
        clusters = clusters();
        gr_epsilon_r = [];          % The relative permittivity for the ground reflection
        absTOA_offset = [];         % The absolute time-of-arrival offset in [s]
        ris = [];                   % ris相关信息
    end
    
    properties(Hidden) % properties used for scenario 'MF' [Zhou zihao]
        lambda_s = [];
        pstable = [];
        freq_cluster_evolution = [];
        nSPL = [];
    end

    properties(Dependent,SetAccess=protected)
        lsp_vals                    % The distribution values of the LSPs
    end

    properties(Dependent)
        lsp_xcorr                   % The cross-correlation matrix for the LSPs
    end
    properties(SetAccess = private)
        decorr_dist                   % decorr_dist
    end

    methods
        % Constructor
        function h_channel_model = channel_model( sim_params, tx_array, rx_array )
            h_channel_model.name = '6GPCM-GBSM';
            
            if exist( 'tx_array','var' ) && ~isempty(tx_array)
               h_channel_model.tx_array = tx_array;
            else
                h_channel_model.tx_array = antenna_array();
            end
            
            if exist( 'rx_array','var' ) && ~isempty(rx_array)
               h_channel_model.rx_array = rx_array;
            else
                h_channel_model.rx_array = antenna_array();
            end
            
            h_channel_model.clusters = clusters();
            
            if exist( 'sim_params','var' ) && ~isempty(sim_params)
                h_channel_model.sim_params = sim_params;
            else
                h_channel_model.sim_params = simulation_parameters;
            end
            obj = h_channel_model.sim_params;
            if isfield( obj.scen_para, 'lambdaG' ) && ~isempty(obj.scen_para.lambdaG)
                h_channel_model.clusters.generation_rate = obj.scen_para.lambdaG;
            end
             if isfield( obj.scen_para, 'lambdaR' ) && ~isempty(obj.scen_para.lambdaR)
                h_channel_model.clusters.recombination_rate = obj.scen_para.lambdaR;
             end
             if  isfield( obj.scen_para, 'Corr_distance' ) && ~isempty(obj.scen_para.Corr_distance)
                  h_channel_model.clusters.corr_distance = obj.scen_para.Corr_distance;
             end
             if  isfield( obj.scen_para, 'Corr_distance_A' ) && ~isempty(obj.scen_para.Corr_distance_A)
                  h_channel_model.clusters.corr_distance_array = obj.scen_para.Corr_distance_A;
             end
             if  isfield( obj.scen_para, 'Corr_distance_F' ) && ~isempty(obj.scen_para.Corr_distance_F)
                  h_channel_model.clusters.corr_distance_frequency = obj.scen_para.Corr_distance_F;
             end
        end

        % Get functions
        function out = get.tx_array(h_channel_model)
            out = h_channel_model.tx_array;
        end
        function out = get.tx_track(h_channel_model)
            out = h_channel_model.tx_track;
        end
        function out = get.rx_array(h_channel_model)
            out = h_channel_model.rx_array;
        end
        function out = get.rx_track(h_channel_model)
            out = h_channel_model.rx_track;
        end
        function out = get.clusters(h_channel_model)
            out = h_channel_model.clusters;
        end

        function out = get.lsp_vals(h_channel_model)
            if isempty( h_channel_model.sim_params )
                out = [];
            else
                % carrier frequency in GHz
                f_GHz = h_channel_model.sim_params.carrier_frequency / 1e9;
                oF = ones( 1,numel( f_GHz ));
                o8 = ones( 8,1 );

                    % Initialize the structs with default values
                scp = h_channel_model.sim_params.scen_para;

                % Reference frequency offset (omega)
                omega = [ scp.DS_omega; scp.KF_omega; scp.SF_omega; scp.AS_D_omega; ...
                    scp.AS_A_omega; scp.ES_D_omega; scp.ES_A_omega; scp.XPR_omega ];

                % Reference values (mu) including the frequency scaling
                mu = [ scp.DS_mu; scp.KF_mu; 0; scp.AS_D_mu; scp.AS_A_mu;...
                    scp.ES_D_mu; scp.ES_A_mu; scp.XPR_mu ];
                gammap = [ scp.DS_gamma; scp.KF_gamma;0; scp.AS_D_gamma; ...
                    scp.AS_A_gamma ;scp.ES_D_gamma ;scp.ES_A_gamma; scp.XPR_gamma]; % scp.KF_gamma �第二项
                mu = mu( :,oF ) + gammap(:,oF) .* log10( omega(:,oF) + f_GHz(o8,:) );

                % STD of the LSPs (sigma) including the frequency scaling
                sigma = [ scp.DS_sigma;scp.KF_sigma;scp.SF_sigma; scp.AS_D_sigma;...
                    scp.AS_A_sigma;scp.ES_D_sigma;scp.ES_A_sigma; scp.XPR_sigma ];
                delta = [ scp.DS_delta;scp.KF_delta;scp.SF_delta; scp.AS_D_delta;...
                    scp.AS_A_delta;scp.ES_D_delta;scp.ES_A_delta; scp.XPR_delta ];
                sigma = sigma( :,oF ) + delta(:,oF) .* log10( omega(:,oF) + f_GHz(o8,:) );
                sigma( sigma<0 ) = 0;

                % Decorr dist (lambda)
                lambda = h_channel_model.decorr_dist;
                lambda = lambda( :,oF );

                % Distance-dependence (epsilon) of the reference value
                epsilon = [ scp.DS_epsilon; scp.KF_epsilon; 0;...
                    scp.AS_D_epsilon; scp.AS_A_epsilon; scp.ES_D_epsilon;...
                    scp.ES_A_epsilon; scp.XPR_epsilon ];
                epsilon = epsilon( :,oF );

                % Height-dependence (zeta) of the reference value
                zeta = [ scp.DS_zeta; scp.KF_zeta; 0;...
                    scp.AS_D_zeta; scp.AS_A_zeta; scp.ES_D_zeta;...
                    scp.ES_A_zeta; scp.XPR_zeta ];
                zeta = zeta( :,oF );

                % Elevation-dependence (alpha) of the reference value
                alpha = [ scp.DS_alpha; scp.KF_alpha; 0;...
                    scp.AS_D_alpha; scp.AS_A_alpha; scp.ES_D_alpha;...
                    scp.ES_A_alpha; scp.XPR_alpha ];
                alpha = alpha( :,oF );

                % Distance-dependence (kappa) of the reference STD
                kappap = [ scp.DS_kappa; scp.KF_kappa; scp.SF_kappa;...
                    scp.AS_D_kappa; scp.AS_A_kappa; scp.ES_D_kappa;...
                    scp.ES_A_kappa; scp.XPR_kappa ];
                kappap = kappap( :,oF );

                % Height-dependence (tau) of the reference STD
                tau = [ scp.DS_tau; scp.KF_tau; scp.SF_tau;...
                    scp.AS_D_tau; scp.AS_A_tau; scp.ES_D_tau;...
                    scp.ES_A_tau; scp.XPR_tau ];
                tau = tau( :,oF );

                % Elevation-dependence (beta) of the reference STD
                beta = [ scp.DS_beta; scp.KF_beta; scp.SF_beta;...
                    scp.AS_D_beta; scp.AS_A_beta; scp.ES_D_beta;...
                    scp.ES_A_beta; scp.XPR_beta ];
                beta = beta( :,oF );

                % Assemble output
                out = [mu(:), sigma(:), lambda(:), epsilon(:), zeta(:), alpha(:), kappap(:), tau(:), beta(:)];
                out = permute( reshape( out, [],numel( f_GHz ),9 ),[1,3,2] );
            end
        end
        function out = get.decorr_dist(h_channel_model)
            scp = h_channel_model.sim_params.scen_para;
            out = [ scp.DS_lambda;scp.KF_lambda;scp.SF_lambda;...
                    scp.AS_D_lambda;scp.AS_A_lambda;scp.ES_D_lambda;...
                    scp.ES_A_lambda; scp.XPR_lambda ];
        end
    function out = get.lsp_xcorr(h_channel_model)
        if isempty( h_channel_model.sim_params.scen_para )
            out = [];
        else
            value = h_channel_model.sim_params.scen_para;
            a = value.ds_kf;          % delay spread vs k-factor
            b = value.ds_sf;          % delay spread vs shadowing std
            c = value.asD_ds;         % departure AS vs delay spread
            d = value.asA_ds;         % azRival AS vs delay spread
            e = value.esD_ds;         % departure ES vs delay spread
            f = value.esA_ds;         % azRival ES vs delay spread
            g = value.sf_kf;          % shadowing std vs k-factor
            h = value.asD_kf;         % departure AS vs k-factor
            k = value.asA_kf;         % azRival AS vs k-factor
            l = value.esD_kf;         % departure DS vs k-factor
            m = value.esA_kf;         % azRival DS vs k-factor
            n = value.asD_sf;         % departure AS vs shadowing std
            o = value.asA_sf;         % azRival AS vs shadowing std
            p = value.esD_sf;         % departure ES vs shadowing std
            q = value.esA_sf;         % azRival ES vs shadowing std
            r = value.asD_asA;        % departure AS vs azRival AS
            s = value.esD_asD;        % departure ES vs departure AS
            t = value.esA_asD;        % azRival ES vs departure AS
            u = value.esD_asA;        % departure ES vs azRival AS
            v = value.esA_asA;        % azRival ES vs azRival AS
            w = value.esD_esA;        % departure ES vs azRival ES
            x1 = value.xpr_ds;        % xpr vs delay spread
            x2 = value.xpr_kf;        % xpr vs k-factor
            x3 = value.xpr_sf;        % xpr vs shadowing
            x4 = value.xpr_asd;       % xpr vs departure AS
            x5 = value.xpr_asa;       % xpr vs azRival AS
            x6 = value.xpr_esd;       % xpr vs departure ES
            x7 = value.xpr_esa;       % xpr vs azRival ES

            out = [ 1  a  b  c  d  e  f x1;...
                a  1  g  h  k  l  m x2;...
                b  g  1  n  o  p  q x3;...
                c  h  n  1  r  s  t x4;...
                d  k  o  r  1  u  v x5;...
                e  l  p  s  u  1  w x6;...
                f  m  q  t  v  w  1 x7;...
                x1  x2  x3  x4  x5  x6  x7 1];
        end
    end
    
        % Set functions
        function set.name(h_channel_model,value)
            if ~( ischar(value) )
                error('error:qd_layout:WrongInput','??? "name" must be a string.')
            end
            h_channel_model.name = value;
        end
        function set.sim_params(h_channel_model, value)
            if ~( isa(value, 'simulation_parameters') )
                error('error:WrongInput','??? "h_channel_model" must be object of the class "simulation_parameters".')
            elseif ~all( size(value) == [1,1]  )
                error('error:WrongInput','??? "h_channel_model" must be scalar.')
            end
            h_channel_model.sim_params = value;
        end

        function set.tx_array(h_channel_model, value)
            if ~( isa(value, 'antenna_array') )
                error('channel_model:WrongInput','??? "tx_array" must be objects of the class antenna_array')
            end
            h_channel_model.tx_array = value;
        end
        
        function set.rx_array(h_channel_model,value)
            if ~( isa(value, 'antenna_array') )
                error('channel_model:WrongInput','??? "tx_array" must be objects of the class antenna_array')
            end
            h_channel_model.rx_array = value;
        end
        function set.clusters(h_channel_model,value)
            if ~( isa(value, 'clusters') )
                error('channel_model:WrongInput','??? "clusters" must be objects of the class clusters')
            end
            h_channel_model.clusters = value;
       end
        
    end
    
    methods
        H = get_CIR_total( channel_model, tx_track, rx_track, h_ris);
        [xT, yT, zT, xR, yR, zR, SSP] = get_clusters_new(channel_model, SSP,scen_para, rx_pos_t, tx_pos_t, num_rays_each_cluster);
        [xT, yT, zT, xR, yR, zR, SSP] = append_clusters_new( channel_model, num_new_clusters, clusters, SSP, LSP, xT, yT, zT, xR, yR, zR,tx_pos, rx_pos,condition);        
        [Dmn] = get_distance_ca2cz(channel_model, loc_tx0,loc_rx0,x1,y1,z1,a_an1,e_an1,v1,x2,y2,z2,a_zn1,e_zn1,v2,deltat);
        delays = get_delays(channel_model, DptT, DqtR, Dlink, virtual_delays, clusters);
        powers = get_powers(channel_model, delays, scen_para, DS, SSP);
        Dpq = get_distance_LOS(channel_model, tx_pos, rx_pos, tx_antenna_angle, rx_antenna_angle, tx_array, rx_array);
        [ result, delay, LSP, clusterPos] = get_CIR_Satellite( channel_model, tx_track, rx_track, ori_scp, consider_p_sur, condition );
        [xT, yT, zT, xR, yR, zR, SSP] = get_clusters_new_uhst(channel_model, scen_para, aod, eod, aoa, eoa, SSP, rx_pos_t, tx_pos_t);
        [result_total, delay_total, H_tx2RIS, H_RIS2rx, G_RIS_diag, delay_tx2RIS, delay_RIS2rx] = get_CIR_totalRIS(channel_model, h_RIS);
        [ result, delay ] = get_CIR_OWC(cm, owc, tx_track, rx_track);
        [ aod, eod, aoa, eoa, SSP ] = get_subpath_angles( channel_model, SSP, num, false );
        [ result, res_Delays, LSPs_h, SSP] = get_CIR_maritime_blos(channel_model_h, fc, tx_track);
    end
end