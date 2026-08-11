function check_ant_traj_chosen(app, scenario)
% 检查天线、运动轨迹等是否已经设置

% 发射端运动轨迹不能为空, 请在运动轨迹页面进行设置
if isempty(app.UITable_tx.Data) || any(ismissing(app.UITable_tx.Data{:,5}))
    error('The trajectory of the transmitter can not be empty, please set these parameters on the Track page');
end

%接收端运动轨迹不能为空, 请在运动轨迹页面进行设置
if isempty(app.UITable_rx.Data) ||  any(ismissing(app.UITable_rx.Data{:,5}))
    error('The trajectory of the receiver can not be empty, please set these parameters on the Track page');
end

%天线配置不能为空, 请在天线配置页面进行设置
if isempty(app.UITable_antenna.Data) || any(ismissing(app.UITable_antenna.Data{:,5}))
    if tools.is_owc_band(scenario, app)
        return;
    else
        error('The antenna configuration can not be empty, please set these parameters on the Antenna settings page');
    end
end
end

