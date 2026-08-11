function owc = gen_owc_gui(app)
%GEN_OWC_GUI 此处显示有关此函数的摘要
    owc = OWC(app.noLEDRow.Value, app.noLEDColumn.Value);                   
    owc.LED_element_spacing_H = app.spacingLEDRow.Value;
    owc.LED_element_spacing_V = app.spacingLEDColumn.Value;
    owc.LED_azimuth_angle_H = app.azimuthAngleLEDRow.Value/180*pi;
    owc.LED_azimuth_angle_V = app.azimuthAngleLEDColumn.Value/180*pi;
    owc.LED_elevation_angle_H = app.elevationAngleLEDRow.Value/180*pi;
    owc.LED_elevation_angle_V = app.elevationAngleLEDColumn.Value/180*pi;

    owc.PD_azimuth_angle = app.azimuthAnglePD.Value/180*pi;
    owc.PD_elevation_angle = app.elevationAnglePD.Value/180*pi;
    owc.PD_omegavR_A = app.PD_omegavR_A.Value;
    owc.PD_omegavR_E = app.PD_omegavR_E.Value;

    owc.band = app.Tree.SelectedNodes.Tag;
    owc.LED_color = app.LEDColor.Value;
end

