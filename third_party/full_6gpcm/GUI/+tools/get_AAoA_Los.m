function AoAs = get_AAoA_Los(tx_pos, rx_pos, tx_array, rx_array)
%GET_AAOA 此处显示有关此函数的摘要
%   此处显示详细说明
tmp_p_loc = tx_array.element_position_gcs;
tmp_q_loc = rx_array.element_position_gcs;

p_loc = tmp_p_loc + tx_pos';
q_loc = tmp_q_loc + rx_pos';

AoAs = zeros(1, size(q_loc, 2));
for i_q = 1:size(q_loc, 2)
    tmp_tx2rx = p_loc(:,1) - q_loc(:,i_q);
    [aoa,~,~] = cart2sph(tmp_tx2rx(1), tmp_tx2rx(2), tmp_tx2rx(3));
    AoAs(i_q) = aoa/pi*180;
end
end

