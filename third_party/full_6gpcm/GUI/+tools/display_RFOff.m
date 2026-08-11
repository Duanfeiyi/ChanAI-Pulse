function display_RFOff(app)
% 光无线场景，禁用带宽、子载波数量、天线配置相关
    app.EditField.Enable = 'on';
    app.bandwidth.Enable = 'off';
    app.freqSamples.Enable = 'off';
    app.delete_antenna.Enable = 'off';
    app.add_antenna.Enable = 'off';
    app.edit_antenna.Enable = 'off';
    app.UITable_antenna.Enable = 'off';
end

