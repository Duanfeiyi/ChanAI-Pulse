function [result_tar, delay_tar, lsps, ssps] = get_CIR_ISAC(channel_model, tx_track, rx_track, tar_track, ori_scp, use_gpu)
channel_model.rx_track = rx_track;
channel_model.tx_track = tx_track;
channel_model.tar_track = tar_track; %new

no_users_tx = length(channel_model.tx_array);
no_users_rx = length(channel_model.rx_array);
no_tar = channel_model.tar_num; %new

%% Generate parameters for tx-target
for i_user_tx = 1:no_users_tx
    for i_tar = 1:no_tar
        % Generate LSP, SSP
        SoS = channel_model.get_lsf_SOS(channel_model.decorr_dist);
        LSP_tx_tar = channel_model.gen_LSP(channel_model.tx_track(i_user_tx).positions(1,:), channel_model.tar_track(i_tar).positions(1,:),SoS, 0, ori_scp);
        SSP_tx_tar = get_ssf_parameters_3GPP( channel_model, LSP_tx_tar, i_user_tx, i_tar );

        % Check the use of gpu
        if ~exist( 'use_gpu','var' ) || isempty( use_gpu )
            use_gpu = channel_model.sim_params.use_gpu;
        elseif logical( use_gpu ) && ~channel_model.sim_params.use_gpu
            use_gpu = 0;
        end

        % Check if we have a single-frequency builder
        if numel( channel_model.sim_params.carrier_frequency ) > 1
            error('get_CIR_3GPP only works for single-freqeuncy simulations.');
        end
        % Set initial parameters
        n_mobiles = 1;
        % These variables are often needed. Pre-computing them saves a lot of time
        scen_para = channel_model.sim_params.scen_para;
        use_ground_reflection_3GPP = channel_model.sim_params.use_ground_reflection_3GPP; % logical
        use_large_bandwidth_3GPP = channel_model.sim_params.use_large_bandwidth_3GPP;
        use_absolute_delays_3GPP = channel_model.sim_params.use_absolute_delays_3GPP;
%         use_dual_mobility_3GPP = channel_model.sim_params.use_dual_mobility_3GPP;
        use_dual_mobility_3GPP = channel_model.sim_params.use_dual_mobility_3GPP;
        if use_dual_mobility_3GPP
            use_absolute_delays_3GPP = 1;
            use_ground_reflection_3GPP = 0;
        end
        lambda  = channel_model.sim_params.wavelength;
        wave_no = 2*pi/lambda;

        % If Laplacian PAS is used, the intra-cluster angles are increased by a factor of sqrt(2). To
        % compensate, the intra-cluster powers must be adjusted. This is done by a weighting the path
        % amplitudes, depending on the number of subpath per cluster. The weigths are set here.
        if strcmp( scen_para.SubpathMethod, 'Laplacian' )
            use_laplacian_pas = true;
            laplacian_weights = {1, [1.18 0.78], ...
                [0.60 1.05 1.24], ...
                [0.86 0.40 1.71 0.42], ...
                [1.05 0.45 0.85 0.85 1.50], ...
                [0.65 0.59 1.87 0.39 1.17 0.46], ...
                [0.77 0.75 1.06 0.61 1.02 0.53 1.74], ...
                [0.74 0.79 1.07 0.51 0.94 0.57 1.52 1.38], ...
                [0.96 0.62 0.92 0.75 1.08 0.51 1.71 1.24 0.63], ...
                [0.90 0.71 0.96 0.78 1.04 0.51 1.52 1.14 0.57 1.37], ...
                [0.92 0.66 0.89 0.79 1.03 0.52 1.47 1.13 0.60 1.36 1.15], ...
                [0.84 0.71 0.91 0.69 1.03 0.54 1.53 1.17 0.50 1.37 1.13 1.01], ...
                [0.79 0.67 1.01 0.61 0.96 0.49 1.61 1.24 0.54 1.33 1.08 1.13 0.86], ...
                [0.98 0.71 0.91 0.84 1.15 0.53 1.45 1.12 0.71 1.43 1.25 1.01 0.83 0.47], ...
                [0.99 0.70 0.89 0.83 1.09 0.57 1.32 1.11 0.64 1.37 1.16 1.01 0.80 0.53 1.41], ...
                [0.96 0.75 0.93 0.82 1.02 0.59 1.35 1.07 0.70 1.30 1.16 0.99 0.82 0.45 1.36 1.18], ...
                [0.95 0.70 0.92 0.80 1.04 0.58 1.28 1.07 0.71 1.28 1.10 1.01 0.79 0.50 1.32 1.17 1.25], ...
                [0.89 0.83 0.97 0.82 1.02 0.67 1.30 1.16 0.69 1.17 1.05 1.10 0.89 0.58 1.26 1.25 1.29 0.53], ...
                [0.91 0.79 1.01 0.85 0.99 0.66 1.29 1.14 0.70 1.20 1.04 1.03 0.92 0.56 1.23 1.21 1.27 0.53 1.15], ...
                [0.89 0.79 0.98 0.83 0.97 0.71 1.27 1.11 0.67 1.15 1.08 1.05 0.89 0.50 1.21 1.24 1.27 0.59 1.13 1.15]};
        else
            use_laplacian_pas = false;
        end
        % The loop for each user position
        for i_mobile = 1 : n_mobiles

            % Get the list of zero-power paths - we do not return paths with zero-power
            iClst       = SSP_tx_tar.pow(i_mobile,:) ~= 0;
            iClst(1)    = true;
            if use_ground_reflection_3GPP
                iClst(2) = true;
            end
            iPath       = clst_expand( iClst, SSP_tx_tar.NumSubPaths );
            n_clusters  = sum( iClst );

            n_paths     = sum( iPath );
            n_subpaths  = SSP_tx_tar.NumSubPaths( iClst );
            n_txant     = channel_model.tx_array(i_user_tx).no_elements;
            n_tarant     = channel_model.tar_array(i_tar).no_elements;

            % Read some commonly needed variables in order to save time.
            n_links_tx_tar     = n_tarant*n_txant;
            o_links_tx_tar     = ones(1,n_links_tx_tar,'uint8');
            n_snapshots = size(channel_model.tar_track(i_tar).positions,1);
            SSP_tx_tar.n_snapshots = n_snapshots;

            % Extract the random initial phases
            pin_tx_tar = SSP_tx_tar.pin(i_mobile,iPath); % double

            %     % Travel directions
            %     rx_orientation = channel_model.rx_track.move_dir.';
            %     tx_orientation = channel_model.tx_track.move_dir.';
            %     if size( tx_orientation,2 ) == 1
            %         tx_orientation = tx_orientation(:,o_snapshots);
            %     end

            if use_gpu == 2 % Single precision GPU Acceleration
                gM_tx_tar = single( SSP_tx_tar.xprmat(:,iPath,i_mobile) );     	% The NLOS polarization transfer matrix
                gM_tx_tar(1) = gM_tx_tar(1) + 1j*1e-45;                               % Make sure it is complex-valued

            else % Double precision (CPU or GPU)
                gM_tx_tar = SSP_tx_tar.xprmat(:,iPath,i_mobile);               	% The NLOS polarization transfer matrix
                gM_tx_tar(1) = gM_tx_tar(1) + 1j*4e-324;                              % Make sure it is complex-valued
            end
            gM_tx_tar = permute( gM_tx_tar,[3,4,2,1] );                               % Convert to [ 1 x 1 x n_paths x 4 ]

            % Transfer to GPU
            if use_gpu
                try
                    gM_tx_tar = gpuArray( gM_tx_tar );
                catch
                    use_gpu = false;
                end
            end
            if use_absolute_delays_3GPP
                r       = channel_model.tar_track(i_tar).positions(1,:) - channel_model.tx_track(i_user_tx).positions(1,:);
                norm_r  = sqrt(sum(r.^2)).';
                delay_tx_tar   = norm_r / channel_model.sim_params.speed_of_light + SSP_tx_tar.taus;
                SSP_tx_tar.taus(i_mobile,:) = delay_tx_tar;
            end

            if use_large_bandwidth_3GPP
                cn_tx_tar    = zeros( n_links_tx_tar , n_paths , n_snapshots );
            else
                cn_tx_tar    = zeros( n_links_tx_tar , n_clusters , n_snapshots );
            end

            % Placeholder for the radiated power
            ppat_tx_tar  = zeros( n_links_tx_tar , n_clusters , n_snapshots );

            if ~use_dual_mobility_3GPP
                % Get the angles of the subpaths and perform random coupling.
                [ aod,eod,aoa,eoa] = get_subpath_angles_3GPP( channel_model,SSP_tx_tar, i_mobile, use_laplacian_pas );
                aod = aod(:,iPath);
                eod = eod(:,iPath);
                aoa = aoa(:,iPath);
                eoa = eoa(:,iPath);

                % Calculate the distance-dependent phases
                d_lms_tx_tar   = channel_model.sim_params.speed_of_light * SSP_tx_tar.taus;
                phase   = 2*pi/lambda * mod(d_lms_tx_tar, lambda);
                phase   = clst_expand( phase, n_subpaths );

                % Doppler component
                % Without drifting, the Doppler component is calculated by plane wave approximation
                % using the distance from the initial position.
                tmp_tx_tar = channel_model.rx_track(i_tar).positions.';
                dist_tx_tar = sqrt( sum([ tmp_tx_tar(1,:) - tmp_tx_tar(1,1) ; tmp_tx_tar(2,:) - tmp_tx_tar(2,1) ; tmp_tx_tar(3,:) - tmp_tx_tar(3,1)   ].^2 ) );   %YANGR

                % Calculate the Doppler profile.
                doppler_tx_tar = cos(aoa+pi).*cos(eoa); %YANGR

                dir_rx = [cos(eoa).*cos(aoa);cos(eoa).*sin(aoa);sin(eoa)];
                rx_array_pos = channel_model.tar_array(i_tar).element_position;
                P_tar = reshape(rx_array_pos.'*dir_rx,n_tarant,1,n_paths);

                % generate CPM of TX array YANGR
                gVt = ones(1,n_txant,n_paths );
                gHt = zeros(1,n_txant,n_paths );
                % CPM of RX id no need here
                dir_tx = [cos(eod).*cos(aod);cos(eod).*sin(aod);sin(eod)];
                tx_array_pos = channel_model.tx_array(i_user_tx).element_position;
                P_tx = reshape(tx_array_pos.'*dir_tx,1,n_txant,n_paths);

                if ~ use_large_bandwidth_3GPP
                    taus_tx_tar = repmat(SSP_tx_tar.taus(i_mobile,:),n_snapshots,1).';
                else
                    tau_mn = clst_expand( SSP_tx_tar.taus, n_subpaths );
                    if isfield(scen_para,'PerClusterDS')
                        tau_mn(2:end) = tau_mn(2:end) + scen_para.PerClusterDS*rand(1,n_paths-1);
                    end
                    taus_tx_tar = (P_tx(ones(1,n_tarant),:,:)+P_tar(:,ones(1,n_txant),:))/...
                        channel_model.sim_params.speed_of_light + repmat(reshape(tau_mn,1,1,[]),n_tarant,n_txant,1);
                    taus_tx_tar = repmat(taus_tx_tar,1,1,1,n_snapshots);
                end

                % Calculate the NLOS channel coefficients YANGR
                gG_tx_tar = repmat( gM_tx_tar(:,:,:,1),[n_tarant,n_txant,1] ) .* repmat(gVt,[n_tarant,1,1]) + ...
                    repmat( gM_tx_tar(:,:,:,3),[n_tarant,n_txant,1] ) .* repmat(gHt,[n_tarant,1,1]) + ...
                    repmat( gM_tx_tar(:,:,:,2),[n_tarant,n_txant,1] ) .* repmat(gVt,[n_tarant,1,1]) + ...
                    repmat( gM_tx_tar(:,:,:,4),[n_tarant,n_txant,1] ) .* repmat(gHt,[n_tarant,1,1]);

                % The phases
                % In drifting mode, we have to update the coefficient matrix with the time-variant
                % Doppler profile.
                phase_tx_tar = exp( -1j*( repmat(permute(pin_tx_tar,[1,3,2]),n_tarant,n_txant) + ...
                    wave_no*( repmat(P_tx,[n_tarant,1,1]) + repmat(P_tar,[1,n_txant,1]) ) + ...
                    repmat(permute(phase(1,:),[1,3,2]),n_tarant,n_txant) ) );

            else
                % Do for each snapshot
                for i_snapshot = 1 : n_snapshots          % Track positions
                    tar_pos = channel_model.tar_track(i_tar).positions(i_snapshot,:).';
                    tx_pos = channel_model.tx_track(i_user_tx).positions(i_snapshot,:).';

                    %             % distances between BS and MT
                    %             d_2d = hypot( tx_pos(1,:) - rx_pos(1,:), tx_pos(2,:) - rx_pos(2,:) );
                    %             d_2d( d_2d<1e-5 ) = 1e-5;
                    %
                    %             % Calculate angles between BS and MT
                    %             aod(1) = atan2( rx_pos(2,:) - tx_pos(2,:) , rx_pos(1,:) - tx_pos(1,:) );           % Azimuth at BS
                    %             aoa(1) = mod( pi + aod(1) + 3.141592653589792, 2*pi ) - 3.141592653589792;    % Azimuth at MT
                    %             eod(1) = atan( ( rx_pos(3,:) - tx_pos(3,:) ) ./ d_2d );                            % Elevation at BS
                    %             eoa(1) = -eod(1);                                                % Elevation at MT

                    if i_snapshot == 1
                        [SSP_tx_tar,relative_speed] = update_3GPP(channel_model,SSP_tx_tar,[],i_snapshot,i_user_tx,i_tar);
                    else
                        [SSP_tx_tar,relative_speed] = update_3GPP(channel_model,SSP_tx_tar,relative_speed,i_snapshot,i_user_tx,i_tar);
                        if use_absolute_delays_3GPP
                            r       = tar_pos - tx_pos;
                            norm_r  = sqrt(sum(r.^2)).';
                            delay_tx_tar   = norm_r / channel_model.sim_params.speed_of_light + SSP_tx_tar.taus(i_mobile,:);
                            SSP_tx_tar.taus(i_mobile,:) = delay_tx_tar;
                        end
                    end
                    % Get the angles of the subpaths and perform random coupling.
                    [ aod,eod,aoa,eoa] = get_subpath_angles_3GPP( channel_model,SSP_tx_tar, i_mobile, use_laplacian_pas );
                    aod = aod(:,iPath);
                    eod = eod(:,iPath);
                    aoa = aoa(:,iPath);
                    eoa = eoa(:,iPath);
                    % Calculate the distance-dependent phases
                    d_lms_tx_tar   = channel_model.sim_params.speed_of_light * SSP_tx_tar.taus;
                    phase   = 2*pi/lambda * mod(d_lms_tx_tar, lambda);
                    phase   = clst_expand( phase, n_subpaths );

                    dir_tar = [sin(eoa).*cos(aoa);sin(eoa).*sin(aoa);cos(eoa)];
                    tar_array_pos = channel_model.tar_array(i_tar).element_position;
                    P_tar = reshape(tar_array_pos.'*dir_tar,n_tarant,1,n_paths);

                    dir_tx = [sin(eod).*cos(aod);sin(eod).*sin(aod);cos(eod)];
                    tx_array_pos = channel_model.tx_array(i_user_tx).element_position;
                    P_tx = reshape(tx_array_pos.'*dir_tx,1,n_txant,n_paths);

                    if ~ use_large_bandwidth_3GPP
                        taus_tx_tar(:,i_snapshot) = SSP_tx_tar.taus;
                    else
                        tau_mn = clst_expand( SSP_tx_tar.taus, n_subpaths );
                        if isfield(scen_para,'PerClusterDS')
                            tau_mn(2:end) = tau_mn(2:end) + scen_para.PerClusterDS*rand(1,n_paths-1);
                        end
                        taus_tx_tar(:,:,:,i_snapshot) = (P_tx(ones(1,n_tarant),:,:)+P_tar(:,ones(1,n_txant),:))/...
                            channel_model.sim_params.speed_of_light + repmat(reshape(tau_mn,1,1,[]),n_tarant,n_txant,1);
                    end
                    gVt = ones(1,n_txant,n_paths );
                    gHt = zeros(1,n_txant,n_paths );

                    doppler_tx_tar = cos(aoa+pi).*cos(eoa); %YANGR

                    gG_tx_tar = repmat( gM_tx_tar(:,:,:,1),[n_tarant,n_txant,1] ) .* repmat(gVt,[n_tarant,1,1]) + ...
                        repmat( gM_tx_tar(:,:,:,3),[n_tarant,n_txant,1] ) .* repmat(gHt,[n_tarant,1,1]) + ...
                        repmat( gM_tx_tar(:,:,:,2),[n_tarant,n_txant,1] ) .* repmat(gVt,[n_tarant,1,1]) + ...
                        repmat( gM_tx_tar(:,:,:,4),[n_tarant,n_txant,1] ) .* repmat(gHt,[n_tarant,1,1]);

                    % The phases
                    % In drifting mode, we have to update the coefficient matrix with the time-variant
                    % Doppler profile.


                    % The phases
                    % In drifting mode, we have to update the coefficient matrix with the time-variant
                    % Doppler profile.
                    phase_tx_tar = exp( -1j*( repmat(permute(pin_tx_tar,[1,3,2]),n_tarant,n_txant) + ...
                        wave_no*( repmat(P_tx,[n_tarant,1,1]) + repmat(P_tar,[1,n_txant,1]) ) + ...
                        repmat(permute(phase(1,:),[1,3,2]),n_tarant,n_txant) ) );
                end
            end
        end
    end
end

%% Generate parameters for target-rx
for i_tar = 1:no_tar
    for i_user_rx = 1:no_users_rx
        % Generate LSP, SSP
        SoS = channel_model.get_lsf_SOS(channel_model.decorr_dist);
        LSP_tar_rx = channel_model.gen_LSP( channel_model.rx_track(i_user_rx).positions(1,:),channel_model.tar_track(i_tar).positions(1,:), SoS, 0, ori_scp);
        SSP_tar_rx = get_ssf_parameters_3GPP( channel_model, LSP_tar_rx, i_tar, i_user_rx );

        % Check the use of gpu
        if ~exist( 'use_gpu','var' ) || isempty( use_gpu )
            use_gpu = channel_model.sim_params.use_gpu;
        elseif logical( use_gpu ) && ~channel_model.sim_params.use_gpu
            use_gpu = 0;
        end

        % Check if we have a single-frequency builder
        if numel( channel_model.sim_params.carrier_frequency ) > 1
            error('get_CIR_3GPP only works for single-freqeuncy simulations.');
        end
        % Set initial parameters
        n_mobiles = 1;
        % These variables are often needed. Pre-computing them saves a lot of time
        scen_para = channel_model.sim_params.scen_para;
        use_ground_reflection_3GPP = channel_model.sim_params.use_ground_reflection_3GPP; % logical
        use_large_bandwidth_3GPP = channel_model.sim_params.use_large_bandwidth_3GPP;
        use_absolute_delays_3GPP = channel_model.sim_params.use_absolute_delays_3GPP;
        use_dual_mobility_3GPP = channel_model.sim_params.use_dual_mobility_3GPP;
        if use_dual_mobility_3GPP
            use_absolute_delays_3GPP = 1;
            use_ground_reflection_3GPP = 0;
        end
        lambda  = channel_model.sim_params.wavelength;
        wave_no = 2*pi/lambda;

    end
    % The loop for each user position
    for i_mobile = 1 : n_mobiles

        % Get the list of zero-power paths - we do not return paths with zero-power
        iClst       = SSP_tar_rx.pow(i_mobile,:) ~= 0;
        iClst(1)    = true;
        if use_ground_reflection_3GPP
            iClst(2) = true;
        end
        iPath       = clst_expand( iClst, SSP_tar_rx.NumSubPaths );
        n_clusters  = sum( iClst );

        n_paths     = sum( iPath );
        n_subpaths  = SSP_tar_rx.NumSubPaths( iClst );
        n_tarant     = channel_model.tar_array(i_tar).no_elements;
        n_rxant     = channel_model.rx_array(i_user_rx).no_elements;

        % Read some commonly needed variables in order to save time.
        n_links_tar_rx     = n_tarant*n_rxant;
        o_links_tar_rx     = ones(1,n_links_tar_rx,'uint8');
        n_snapshots = size(channel_model.rx_track(i_user_rx).positions,1);
        SSP_tar_rx.n_snapshots = n_snapshots;

        % Extract the random initial phases
        pin_tar_rx = SSP_tar_rx.pin(i_mobile,iPath); % double

        %     % Travel directions
        %     rx_orientation = channel_model.rx_track.move_dir.';
        %     tx_orientation = channel_model.tx_track.move_dir.';
        %     if size( tx_orientation,2 ) == 1
        %         tx_orientation = tx_orientation(:,o_snapshots);
        %     end

        if use_gpu == 2 % Single precision GPU Acceleration
            gM_tar_rx = single( SSP_tar_rx.xprmat(:,iPath,i_mobile) );     	% The NLOS polarization transfer matrix
            gM_tar_rx(1) = gM_tar_rx(1) + 1j*1e-45;                               % Make sure it is complex-valued

        else % Double precision (CPU or GPU)
            gM_tar_rx = SSP_tar_rx.xprmat(:,iPath,i_mobile);               	% The NLOS polarization transfer matrix
            gM_tar_rx(1) = gM_tar_rx(1) + 1j*4e-324;                              % Make sure it is complex-valued
        end
        gM_tar_rx = permute( gM_tar_rx,[3,4,2,1] );                               % Convert to [ 1 x 1 x n_paths x 4 ]

        % Transfer to GPU
        if use_gpu
            try
                gM_tar_rx = gpuArray( gM_tar_rx );
            catch
                use_gpu = false;
            end
        end
        if use_absolute_delays_3GPP
            r       = channel_model.rx_track(i_user_rx).positions(1,:) - channel_model.tx_track(i_tar).positions(1,:);
            norm_r  = sqrt(sum(r.^2)).';
            delay_tar_rx   = norm_r / channel_model.sim_params.speed_of_light + SSP_tar_rx.taus;
            SSP_tar_rx.taus(i_mobile,:) = delay_tar_rx;
        end

        if use_large_bandwidth_3GPP
            cn_tar_rx    = zeros( n_links_tar_rx , n_paths , n_snapshots );
        else
            cn_tar_rx    = zeros( n_links_tar_rx , n_clusters , n_snapshots );
        end

        % Placeholder for the radiated power
        ppat_tar_rx  = zeros( n_links_tar_rx , n_clusters , n_snapshots );

        if ~use_dual_mobility_3GPP
            % Get the angles of the subpaths and perform random coupling.
            [ aod,eod,aoa,eoa] = get_subpath_angles_3GPP( channel_model,SSP_tar_rx, i_mobile, use_laplacian_pas );
            aod = aod(:,iPath);
            eod = eod(:,iPath);
            aoa = aoa(:,iPath);
            eoa = eoa(:,iPath);

            aod_deg = rad2deg(aod);
            rcs = mf.get_RCS('bistatic','person',aod_deg,1,1);

            % Calculate the distance-dependent phases
            d_lms_tar_rx   = channel_model.sim_params.speed_of_light * SSP_tar_rx.taus;
            phase   = 2*pi/lambda * mod(d_lms_tar_rx, lambda);
            phase   = clst_expand( phase, n_subpaths );

            % Doppler component
            % Without drifting, the Doppler component is calculated by plane wave approximation
            % using the distance from the initial position.
            tmp_tx_tar = channel_model.rx_track(i_user_rx).positions.';
            dist_tar_rx = sqrt( sum([ tmp_tx_tar(1,:) - tmp_tx_tar(1,1) ; tmp_tx_tar(2,:) - tmp_tx_tar(2,1) ; tmp_tx_tar(3,:) - tmp_tx_tar(3,1)   ].^2 ) );

            % Calculate the Doppler profile.
            doppler_tar_rx = cos(aoa+pi).*cos(eoa);
            % Yangr
            gVr = ones(  n_rxant,1,n_paths );
            gHr = zeros(  n_rxant,1,n_paths );

            dir_rx = [sin(eoa).*cos(aoa);sin(eoa).*sin(aoa);cos(eoa)];
            rx_array_pos = channel_model.rx_array(i_user_rx).element_position;
            P_rx = reshape(rx_array_pos.'*dir_rx,n_rxant,1,n_paths);

            dir_tar = [sin(eod).*cos(aod);sin(eod).*sin(aod);cos(eod)];
            tar_array_pos = channel_model.tar_array(i_tar).element_position;
            P_tar = reshape(tar_array_pos.'*dir_tar,1,n_tarant,n_paths);

            if ~ use_large_bandwidth_3GPP
                taus_tar_rx = repmat(SSP_tar_rx.taus(i_mobile,:),n_snapshots,1).';
            else
                tau_mn = clst_expand( SSP_tar_rx.taus, n_subpaths );
                if isfield(scen_para,'PerClusterDS')
                    tau_mn(2:end) = tau_mn(2:end) + scen_para.PerClusterDS*rand(1,n_paths-1);
                end
                taus_tar_rx = (P_tar(ones(1,n_rxant),:,:)+P_rx(:,ones(1,n_tarant),:))/...
                    channel_model.sim_params.speed_of_light + repmat(reshape(tau_mn,1,1,[]),n_rxant,n_tarant,1);
                taus_tar_rx = repmat(taus_tar_rx,1,1,1,n_snapshots);
            end

            gG_tar_rx = repmat(gVr,[1,n_tarant,1]) .* repmat( gM_tar_rx(:,:,:,1),[n_rxant,n_tarant,1] ) + ...
                repmat(gVr,[1,n_tarant,1]) .* repmat( gM_tar_rx(:,:,:,3),[n_rxant,n_tarant,1] ) +...
                repmat(gHr,[1,n_tarant,1]) .* repmat( gM_tar_rx(:,:,:,2),[n_rxant,n_tarant,1] ) + ...
                repmat(gHr,[1,n_tarant,1]) .* repmat( gM_tar_rx(:,:,:,4),[n_rxant,n_tarant,1] ) ;

            % The phases
            % In drifting mode, we have to update the coefficient matrix with the time-variant
            % Doppler profile.
            phase_tar_rx = exp( -1j*( repmat(permute(pin_tar_rx,[1,3,2]),n_rxant,n_tarant) + ...
                wave_no*( repmat(P_tar,[n_rxant,1,1]) + repmat(P_rx,[1,n_tarant,1]) ) + ...
                repmat(permute(phase(1,:),[1,3,2]),n_rxant,n_tarant) ) );

        else
            % Do for each snapshot
            for i_snapshot = 1 : n_snapshots          % Track positions
                tar_pos = channel_model.tar_track(i_tar).positions(i_snapshot,:).';
                rx_pos = channel_model.rx_track(i_user_rx).positions(i_snapshot,:).';

                %             % distances between BS and MT
                %             d_2d = hypot( tx_pos(1,:) - rx_pos(1,:), tx_pos(2,:) - rx_pos(2,:) );
                %             d_2d( d_2d<1e-5 ) = 1e-5;
                %
                %             % Calculate angles between BS and MT
                %             aod(1) = atan2( rx_pos(2,:) - tx_pos(2,:) , rx_pos(1,:) - tx_pos(1,:) );           % Azimuth at BS
                %             aoa(1) = mod( pi + aod(1) + 3.141592653589792, 2*pi ) - 3.141592653589792;    % Azimuth at MT
                %             eod(1) = atan( ( rx_pos(3,:) - tx_pos(3,:) ) ./ d_2d );                            % Elevation at BS
                %             eoa(1) = -eod(1);                                                % Elevation at MT

                if i_snapshot == 1
                    [SSP_tar_rx,relative_speed] = update_3GPP(channel_model,SSP_tar_rx,[],i_snapshot,i_tar,i_user_rx);
                else
                    [SSP_tar_rx,relative_speed] = update_3GPP(channel_model,SSP_tar_rx,relative_speed,i_snapshot,i_tar,i_user_rx);
                    if use_absolute_delays_3GPP
                        r       = tar_pos - rx_pos;
                        norm_r  = sqrt(sum(r.^2)).';
                        delay_tar_rx   = norm_r / channel_model.sim_params.speed_of_light + SSP_tar_rx.taus(i_mobile,:);
                        SSP_tar_rx.taus(i_mobile,:) = delay_tar_rx;
                    end
                end
                % Get the angles of the subpaths and perform random coupling.
                [ aod,eod,aoa,eoa] = get_subpath_angles_3GPP( channel_model,SSP_tar_rx, i_mobile, use_laplacian_pas );
                aod = aod(:,iPath);
                eod = eod(:,iPath);
                aoa = aoa(:,iPath);
                eoa = eoa(:,iPath);

                % Calculate the RCS of sub-paths
                aod_deg = rad2deg(aod);
                rcs = mf.get_RCS('bistatic','vehicle',aod_deg,1,1);
                % Calculate the distance-dependent phases
                d_lms_tar_rx   = channel_model.sim_params.speed_of_light * SSP_tar_rx.taus;
                phase   = 2*pi/lambda * mod(d_lms_tar_rx, lambda);
                phase   = clst_expand( phase, n_subpaths );

                dir_rx = [sin(eoa).*cos(aoa);sin(eoa).*sin(aoa);cos(eoa)];
                rx_array_pos = channel_model.rx_array(i_user_rx).element_position;
                P_rx = reshape(rx_array_pos.'*dir_rx,n_rxant,1,n_paths);

                dir_tar = [sin(eod).*cos(aod);sin(eod).*sin(aod);cos(eod)];
                tar_array_pos = channel_model.tar_array(i_tar).element_position;
                P_tar = reshape(tar_array_pos.'*dir_tar,1,n_tarant,n_paths);

                if ~ use_large_bandwidth_3GPP
                    taus_tar_rx(:,i_snapshot) = SSP_tar_rx.taus;
                else
                    tau_mn = clst_expand( SSP_tar_rx.taus, n_subpaths );
                    if isfield(scen_para,'PerClusterDS')
                        tau_mn(2:end) = tau_mn(2:end) + scen_para.PerClusterDS*rand(1,n_paths-1);
                    end
                    taus_tar_rx(:,:,:,i_snapshot) = (P_tar(ones(1,n_tarant),:,:)+P_rx(:,ones(1,n_rxant),:))/...
                        channel_model.sim_params.speed_of_light + repmat(reshape(tau_mn,1,1,[]),n_rxant,n_tarant,1);
                end
                gVr = ones(  n_rxant,1,n_paths );
                gHr = zeros(  n_rxant,1,n_paths );


                gG_tar_rx = repmat(gVr,[1,n_tarant,1]) .* repmat( gM_tar_rx(:,:,:,1),[n_rxant,n_tarant,1] ) + ...
                    repmat(gVr,[1,n_tarant,1]) .* repmat( gM_tar_rx(:,:,:,3),[n_rxant,n_tarant,1] ) +...
                    repmat(gHr,[1,n_tarant,1]) .* repmat( gM_tar_rx(:,:,:,2),[n_rxant,n_tarant,1] ) + ...
                    repmat(gHr,[1,n_tarant,1]) .* repmat( gM_tar_rx(:,:,:,4),[n_rxant,n_tarant,1] ) ;

                % The phases
                % In drifting mode, we have to update the coefficient matrix with the time-variant
                % Doppler profile.
                doppler_tar_rx = cos(aoa+pi).*cos(eoa);

                phase_tar_rx = exp( -1j*( repmat(permute(pin_tar_rx,[1,3,2]),n_rxant,n_tarant) + ...
                    wave_no*( repmat(P_tar,[n_rxant,1,1]) + repmat(P_rx,[1,n_tarant,1]) ) + ...
                    repmat(permute(phase(1,:),[1,3,2]),n_rxant,n_tarant) ) );
            end
        end
    end
end



%% Generate CIR for tx-rx
for i_user_tx = 1:no_users_tx
    for i_user_rx = 1:no_users_rx
        if ~use_dual_mobility_3GPP
            ccp_tx_tar = reshape( gG_tx_tar.*phase_tx_tar, n_tarant*n_txant,n_paths );
            c_tx_tar = ccp_tx_tar;
            for i_snapshot = 1 : n_snapshots
                % Generate rotating Dopplers for the sucessive snapshots
                cp_tx_tar = exp( -1j * wave_no * doppler_tx_tar * dist_tx_tar(i_snapshot) );
                cp_tx_tar = cp_tx_tar( ones(1,n_links_tx_tar) , : );

                % Combine antenna patterns and phases
                ccp_tx_tar = c_tx_tar.*cp_tx_tar;
                if use_large_bandwidth_3GPP
                    cn_tx_tar(:,:,i_snapshot) = ccp_tx_tar;
                else
                    % Sum over the sub-paths in a cluster. This changes the cluster power due to the random
                    % phases. This is corrected later.
                    ls_tx_tar = 1;
                    for l = 1 : n_clusters
                        le_tx_tar = ls_tx_tar + n_subpaths(l) - 1;
                        if le_tx_tar ~= ls_tx_tar
                            if use_laplacian_pas
                                tmp_tx_tar = ccp_tx_tar(:,ls_tx_tar:le_tx_tar) .* (ones(n_tarant*n_txant,1) * laplacian_weights{n_subpaths(l)});
                                ppat_tx_tar(:,l,i_snapshot) = sum( abs(tmp_tx_tar).^2,2 );
                                cn_tx_tar(:,l,i_snapshot)   = sum( tmp_tx_tar,2 );
                            else
                                ppat_tx_tar(:,l,i_snapshot) = sum( abs(ccp_tx_tar(:,ls_tx_tar:le_tx_tar)).^2,2 );
                                cn_tx_tar(:,l,i_snapshot)   = sum( ccp_tx_tar(:,ls_tx_tar:le_tx_tar),2 );
                            end
                        else
                            ppat_tx_tar(:,l,i_snapshot) = abs(ccp_tx_tar(:,ls_tx_tar)).^2;
                            cn_tx_tar(:,l,i_snapshot)   = ccp_tx_tar(:,ls_tx_tar);
                        end
                        ls_tx_tar = le_tx_tar + 1;
                    end
                end
            end

            ccp_tar_rx = reshape( gG_tar_rx.*phase_tar_rx, n_tarant*n_rxant,n_paths );
            c_tar_rx = ccp_tar_rx;
            for i_snapshot = 1 : n_snapshots
                % Generate rotating Dopplers for the sucessive snapshots
                cp_tar_rx = exp( -1j * wave_no * doppler_tar_rx * dist_tar_rx(i_snapshot) );
                cp_tar_rx = cp_tar_rx( ones(1,n_links_tar_rx) , : );

                % Combine antenna patterns and phases
                ccp_tar_rx = c_tar_rx.*cp_tar_rx;
                if use_large_bandwidth_3GPP
                    cn_tar_rx(:,:,i_snapshot) = ccp_tar_rx;
                else
                    % Sum over the sub-paths in a cluster. This changes the cluster power due to the random
                    % phases. This is corrected later.
                    ls_tar_rx = 1;
                    for l = 1 : n_clusters
                        le_tar_rx = ls_tar_rx + n_subpaths(l) - 1;
                        if le_tar_rx ~= ls_tar_rx
                            if use_laplacian_pas
                                tmp_tar_rx = ccp_tar_rx(:,ls_tar_rx:le_tar_rx) .* (ones(n_tarant*n_rxant,1) * laplacian_weights{n_subpaths(l)});
                                ppat_tar_rx(:,l,i_snapshot) = sum( abs(tmp_tar_rx).^2,2 );
                                cn_tar_rx(:,l,i_snapshot)   = sum( tmp_tar_rx,2 );
                            else
                                ppat_tar_rx(:,l,i_snapshot) = sum( abs(ccp_tar_rx(:,ls_tar_rx:le_tar_rx)).^2,2 );
                                cn_tar_rx(:,l,i_snapshot)   = sum( ccp_tar_rx(:,ls_tar_rx:le_tar_rx),2 );
                            end
                        else
                            ppat_tar_rx(:,l,i_snapshot) = abs(ccp_tar_rx(:,ls_tar_rx)).^2;
                            cn_tar_rx(:,l,i_snapshot)   = ccp_tar_rx(:,ls_tar_rx);
                        end
                        ls_tar_rx = le_tar_rx + 1;
                    end
                end
            end
        else
            for i_snapshot = 1 : n_snapshots          % Track positions
                ccp_tx_tar = reshape( gG_tx_tar.*phase_tx_tar, n_tarant*n_txant,n_paths );

                % Sum over the sub-paths in a cluster. This changes the cluster power due to the random
                % phases. This is corrected later.
                if use_large_bandwidth_3GPP
                    cn_tx_tar(:,:,i_snapshot) = ccp_tx_tar;
                else
                    ls_tx_tar = 1;
                    for l = 1 : n_clusters
                        le_tx_tar = ls_tx_tar + n_subpaths(l) - 1;
                        if le_tx_tar ~= ls_tx_tar
                            if use_laplacian_pas
                                tmp_tx_tar = ccp_tx_tar(:,ls_tx_tar:le_tx_tar) .* (ones(n_tarant*n_txant,1) * laplacian_weights{n_subpaths(l)});
                                ppat_tx_tar(:,l,i_snapshot) = sum( abs(tmp_tx_tar).^2,2 );
                                cn_tx_tar(:,l,i_snapshot)   = sum( tmp_tx_tar,2 );
                            else
                                ppat_tx_tar(:,l,i_snapshot) = sum( abs(ccp_tx_tar(:,ls_tx_tar:le_tx_tar)).^2,2 );
                                cn_tx_tar(:,l,i_snapshot)   = sum( ccp_tx_tar(:,ls_tx_tar:le_tx_tar),2 );
                            end
                        else
                            ppat_tx_tar(:,l,i_snapshot) = abs(ccp_tx_tar(:,ls_tx_tar)).^2;
                            cn_tx_tar(:,l,i_snapshot)   = ccp_tx_tar(:,ls_tx_tar);
                        end
                        ls_tx_tar = le_tx_tar + 1;
                    end
                end
            end

            for i_snapshot = 1 : n_snapshots          % Track positions
                ccp_tar_rx = reshape( gG_tar_rx.*phase_tar_rx, n_tarant*n_rxant,n_paths ).*repmat(sqrt(rcs),[n_links_tar_rx,1]);

                % Sum over the sub-paths in a cluster. This changes the cluster power due to the random
                % phases. This is corrected later.
                if use_large_bandwidth_3GPP
                    cn_tar_rx(:,:,i_snapshot) = ccp_tar_rx;
                else
                    ls_tar_rx = 1;
                    for l = 1 : n_clusters
                        le_tar_rx = ls_tar_rx + n_subpaths(l) - 1;
                        if le_tar_rx ~= ls_tar_rx
                            if use_laplacian_pas
                                tmp_tar_rx = ccp_tar_rx(:,ls_tar_rx:le_tar_rx) .* (ones(n_tarant*n_rxant,1) * laplacian_weights{n_subpaths(l)});
                                ppat_tar_rx(:,l,i_snapshot) = sum( abs(tmp_tar_rx).^2,2 );
                                cn_tar_rx(:,l,i_snapshot)   = sum( tmp_tar_rx,2 );
                            else
                                ppat_tar_rx(:,l,i_snapshot) = sum( abs(ccp_tar_rx(:,ls_tar_rx:le_tar_rx)).^2,2 );
                                cn_tar_rx(:,l,i_snapshot)   = sum( ccp_tar_rx(:,ls_tar_rx:le_tar_rx),2 );
                            end
                        else
                            ppat_tar_rx(:,l,i_snapshot) = abs(ccp_tar_rx(:,ls_tar_rx)).^2;
                            cn_tar_rx(:,l,i_snapshot)   = ccp_tar_rx(:,ls_tar_rx);
                        end
                        ls_tar_rx = le_tar_rx + 1;
                    end
                end
            end
        end
        % The path powers
        p_cl_tx_tar = SSP_tx_tar.pow(i_mobile*ones(1,n_links_tx_tar),iClst )./n_subpaths(i_mobile*ones(1,n_links_tx_tar),iClst);
        if use_large_bandwidth_3GPP
            p_correct_tx_tar = clst_expand( p_cl_tx_tar, n_subpaths );
        else

            % The powers of the antenna patterns at the given angles (power-sum)
            p_pat_tx_tar = sum( ppat_tx_tar,3 ) ./ size(ppat_tx_tar,3);

            % The powers in the current channel coefficients (complex sum)
            p_coeff_tx_tar = sum( abs(cn_tx_tar).^2, 3 ) ./ size(cn_tx_tar,3);

            % Correct the powers
            p_correct_tx_tar = sqrt( p_cl_tx_tar .* p_pat_tx_tar ./ p_coeff_tx_tar ./ n_subpaths(o_links_tx_tar,:) );
            p_correct_tx_tar( p_pat_tx_tar < 1e-30 ) = 0; % Fix NaN caused by 0/0
        end
        cn_tx_tar = p_correct_tx_tar(:,:,ones(1,n_snapshots)) .* cn_tx_tar;
        %
        p_cl_tar_rx = SSP_tar_rx.pow(i_mobile*ones(1,n_links_tar_rx),iClst )./n_subpaths(i_mobile*ones(1,n_links_tar_rx),iClst);
        if use_large_bandwidth_3GPP
            p_correct_tar_rx = clst_expand( p_cl_tar_rx, n_subpaths );
        else

            % The powers of the antenna patterns at the given angles (power-sum)
            p_pat_tar_rx = sum( ppat_tar_rx,3 ) ./ size(ppat_tar_rx,3);

            % The powers in the current channel coefficients (complex sum)
            p_coeff_tar_rx = sum( abs(cn_tar_rx).^2, 3 ) ./ size(cn_tar_rx,3);

            % Correct the powers
            p_correct_tar_rx = sqrt( p_cl_tar_rx .* p_pat_tar_rx ./ p_coeff_tar_rx ./ n_subpaths(o_links_tar_rx,:) );
            p_correct_tar_rx( p_pat_tar_rx < 1e-30 ) = 0; % Fix NaN caused by 0/0
        end
        cn_tar_rx = p_correct_tar_rx(:,:,ones(1,n_snapshots)) .* cn_tar_rx;

        % rashape matrix
        if use_large_bandwidth_3GPP
            cn_tx_tar = reshape(cn_tx_tar,[n_tarant,n_txant,n_paths,n_snapshots]);
            cn_tar_rx = reshape(cn_tar_rx,[n_rxant,n_tarant,n_paths,n_snapshots]);
        else
            cn_tx_tar = reshape(cn_tx_tar,[n_tarant,n_txant,n_clusters,n_snapshots]);
            cn_tar_rx = reshape(cn_tar_rx,[n_rxant,n_tarant,n_clusters,n_snapshots]);
        end
        % cascade 2 parts
        cn = pagemtimes(cn_tar_rx,cn_tx_tar);

        c = reshape( cn , n_rxant , n_txant , [] , n_snapshots );
        c = permute(c,[2 1 4 3]);

        %Calculate delay
        % 初始化 delay 矩阵，维度为 (n_txant, n_rxant, n_snapshots, n_paths)


        if use_large_bandwidth_3GPP
            delay = zeros(n_txant, n_rxant, n_snapshots, n_paths);
            for no_txant = 1:n_txant
                for no_rxant = 1:n_rxant
                    for no_snapshots = 1:n_snapshots
                        for no_paths = 1:n_paths
                            for no_tarant = 1:n_tarant
                                delay_tx_tar = taus_tx_tar(no_tarant, no_txant, no_paths, no_snapshots);
                                delay_tar_rx = taus_tar_rx(no_rxant, no_tarant, no_paths, no_snapshots);
                                delay(no_txant, no_rxant, no_snapshots, no_paths) = delay(no_txant, no_rxant, no_snapshots, no_paths) + delay_tx_tar + delay_tar_rx;
                            end
                        end
                    end
                end
            end
        else
            delay = repmat(reshape(taus_tar_rx + taus_tar_rx,1,1,[],n_snapshots),[n_txant,n_rxant,1,1]);
            delay = permute(delay,[ 1 2 4 3]);
        end
    end
    result_tar = c;
    delay_tar = delay;

    % Combine SSP and LSP
    fields_SSP = fieldnames(SSP_tar_rx);
    for i = 1:length(fields_SSP)
        fieldName = fields_SSP{i};
        ssps.(fieldName) = [SSP_tar_rx.(fieldName), SSP_tx_tar.(fieldName)];
    end
    fields_LSP = fieldnames(SSP_tar_rx);
    for i = 1:length(fields_LSP)
        fieldName = fields_LSP{i};
        lsps.(fieldName) = [SSP_tar_rx.(fieldName), SSP_tx_tar.(fieldName)];
    end
    % Combine Tx track and Tar track
    fields = properties(tx_track);
    track_merged = track();
    % 遍历每个属性并合并
    for i = 1:length(fields)
        fieldName = fields{i};
        track_merged.(fieldName) = [tx_track.(fieldName), tar_track.(fieldName)];
    end
    tx_track = track_merged;
end

end

