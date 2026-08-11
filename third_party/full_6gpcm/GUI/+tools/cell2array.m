function array_data = cell2array(ori_cell)
%CELL2ARRAY 此处显示有关此函数的摘要
array_data = [];

% 遍历cell数组
for i = 1:size(ori_cell, 1)
    % 获取当前行的元素
    row = ori_cell(i, :);
    row_data = [];
    for j = 1:size(ori_cell, 2)
        row_data = [row_data; row{j}];   
    end
    array_data = [array_data; row_data'];
end
end

