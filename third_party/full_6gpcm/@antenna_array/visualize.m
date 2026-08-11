function visualize(antenna_array)
    % 单个天线阵列，单位为lambda 波长
    scatter3(antenna_array.element_position(1,:), antenna_array.element_position(2,:), antenna_array.element_position(3,:))
end

