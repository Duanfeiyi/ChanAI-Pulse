function [p_sur] = get_p_sur(clusters, delta_tx, delta_rx)
%GET_P_SUR 时域

    if clusters.corr_distance
        temp_tx_time = max(delta_tx / clusters.corr_distance, 0);
        temp_rx_time = max(delta_rx / clusters.corr_distance, 0);
    else
        temp_tx_time = 0; % Do not considering nonstationary in time domain.
        temp_rx_time = 0; % Do not considering nonstationary in time domain.
    end
        
    p_sur = exp( -clusters.recombination_rate * temp_tx_time) * exp( -clusters.recombination_rate * temp_rx_time); 
end

