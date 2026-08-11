%计算两条曲线的MSE，两条曲线的横纵坐标分别为下(x1,y1),(x2,y2)
%调用的时候通把测量结果值放在前面，仿真结果放在后面

function mse = cal_MSE(x1,y1,x2,y2) 
    
    % 确定横坐标最大值
    if x1(end)>x2(end)
        x1_ind = find(x1>(x2(end)));
        x1_ind = x1_ind(1);
        x1 = x1(1:x1_ind);
        y1 = y1(1:x1_ind);
    end

    %根据测量的输入对仿真结果进行插值
    y_interp = interp1(x2,y2,x1,'spline');

    %计算MSE
    mse = sum((y1-y_interp).^2)/length(y1);

end