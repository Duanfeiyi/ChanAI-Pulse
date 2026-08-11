function maxDistance = findMaxDistance(points)
    % 输入 points 是一个 3xN 的矩阵，其中每列代表三维空间中的一个点
    
    % 检查矩阵是否符合要求
    [rows, cols] = size(points);
    if rows ~= 3
        error('The input matrix must have 3 rows representing 3D coordinates.');
    end
    
    % 初始化最大距离为0
    maxDistance = 0;
    
    % 计算所有点对之间的距离
    for i = 1:cols-1
        for j = i+1:cols
            distance = norm(points(:,i) - points(:,j));
            if distance > maxDistance
                maxDistance = distance; % 更新最大距离
            end
        end
    end
end
