function allSettings = app2settings(app, scenario)
    if tools.is_owc_band(scenario, app)
        allSettings{1} = app.scenarios;
        allSettings{2} = app.LEDColor.Value; % LED 颜色
        allSettings{3} = app.LEDType.Value; % LED type
        allSettings{4} = app.EditField.Value;
        allSettings{5} = num2str(app.noCluster_6.Value);
        allSettings{6} = num2str(app.noRaysEachCluster_6.Value);
        allSettings{7} = num2str(app.noLEDRow.Value);
        allSettings{8} = num2str(app.noLEDColumn.Value);
        allSettings{9} = num2str(app.spacingLEDRow.Value);
        allSettings{10} = num2str(app.spacingLEDColumn.Value);
        allSettings{11} = num2str(app.azimuthAnglePD.Value);
        allSettings{12} = num2str(app.elevationAnglePD.Value);
        allSettings{13} = num2str(app.azimuthAngleLEDRow.Value);
        allSettings{14} = num2str(app.elevationAngleLEDRow.Value);
        allSettings{15} = num2str(app.azimuthAngleLEDColumn.Value);
        allSettings{16} = num2str(app.elevationAngleLEDColumn.Value);
        allSettings{17} = num2str(app.PD_omegavR_A.Value);
        allSettings{18} = num2str(app.PD_omegavR_E.Value);
        allSettings{19} = ' ';
        allSettings{20} = ' ';
        allSettings{21} = ' ';
        allSettings{22} = ' ';
        allSettings{23} = ' ';
        allSettings{24} = ' ';
        allSettings{25} = ' ';
        allSettings{26} = ' ';
        allSettings{27} = ' ';
    else
        if strfind(scenario, app.sps.scenario_RIS)
            allSettings{1} = app.scenarios;
            allSettings{2} = num2str(app.EditField_RISx.Value);
            allSettings{3} = num2str(app.EditField_RISy.Value);
            allSettings{4} = num2str(app.EditField_RISwidth.Value);
            allSettings{5} = num2str(app.EditField_RISheight.Value);
            allSettings{6} = num2str(app.EditField_RISdelta_x.Value);
            allSettings{7} = num2str(app.EditField_RISdelta_y.Value);
            allSettings{8} = num2str(app.EditField_RISposx.Value);
            allSettings{9} = num2str(app.EditField_RISposy.Value);
            allSettings{10} = num2str(app.EditField_RISposz.Value);
            allSettings{11} = num2str(app.vectorEditField_0.Value);
            allSettings{12} = num2str(app.vectorEditField_1.Value);
            allSettings{13} = num2str(app.vectorEditField_2.Value);
            allSettings{14} = num2str(app.vectorEditField_3.Value);
            allSettings{15} = num2str(app.vectorEditField_4.Value);
            allSettings{16} = num2str(app.vectorEditField_5.Value);
            allSettings{17} = num2str(app.vectorEditField_6.Value);
            allSettings{18} = num2str(app.vectorEditField_7.Value);
            allSettings{19} = num2str(app.vectorEditField_8.Value);
            allSettings{20} = num2str(app.noCluster_RIS1.Value);
            allSettings{21} = num2str(app.noRaysEachCluster_RIS1.Value);
            allSettings{22} = num2str(app.noCluster_RIS3.Value);
            allSettings{23} = num2str(app.noRaysEachCluster_RIS3.Value);
            allSettings{24} = num2str(app.ButtonGroup_RIS.SelectedObject.Text);
            allSettings{25} = app.DropDown_7.Value;
        elseif strfind(scenario, app.sps.scenario_MARITIME)
            allSettings{1} = app.scenarios;
            allSettings{2} = num2str(app.noCluster_2.Value);
            allSettings{3} = num2str(app.noRaysEachCluster_2.Value);
            allSettings{4} = num2str(app.noCluster_3.Value);
            allSettings{5} = num2str(app.noRaysEachCluster_3.Value);
            allSettings{6} = num2str(app.EditField_7.Value);
            allSettings{7} = num2str(app.wind_speed.Value);
            allSettings{8} = ' ';
            allSettings{9} = ' ';
            allSettings{10} = ' ';
            allSettings{11} = ' ';
            allSettings{12} = ' ';
            allSettings{13} = ' ';
            allSettings{14} = ' ';
            allSettings{15} = ' ';
            allSettings{16} = ' ';
            allSettings{17} = ' ';
            allSettings{18} = ' ';
            allSettings{19} = ' ';
            allSettings{20} = ' ';
            allSettings{21} = ' ';
            allSettings{22} = ' ';
            allSettings{23} = ' ';
            allSettings{24} = ' ';
            allSettings{25} = ' ';
            allSettings{26} = ' ';
            allSettings{27} = ' ';
        elseif strfind(scenario, app.sps.scenario_SATELLITE)
            allSettings{1} = app.scenarios;
            allSettings{2} = num2str(app.noCluster_4.Value);
            allSettings{3} = num2str(app.noRaysEachCluster_4.Value);
            allSettings{4} = app.DropDown_7.Value;
            % 新增加部分
            allSettings{5} = num2str(app.satHeight.Value);
            allSettings{6} = num2str(app.BinEditField.Value);
            allSettings{7} = num2str(app.DinEditField.Value);
            allSettings{8} = num2str(app.CinEditField.Value);
            allSettings{9} = num2str(app.EinEditField.Value);
            allSettings{10} = num2str(app.FinEditField.Value);
            allSettings{11} = app.DropDown_8.Value;
            allSettings{12} = num2str(app.rainRate.Value);
            allSettings{13} = ' ';
            allSettings{14} = ' ';
            allSettings{15} = ' ';
            allSettings{16} = ' ';
            allSettings{17} = ' ';
            allSettings{18} = ' ';
            allSettings{19} = ' ';
            allSettings{20} = ' ';
            allSettings{21} = ' ';
            allSettings{22} = ' ';
            allSettings{23} = ' ';
            allSettings{24} = ' ';
            allSettings{25} = ' ';
            allSettings{26} = ' ';
            allSettings{27} = ' ';
        elseif strfind(scenario, app.sps.scenario_SKYWAVE)
            allSettings{1} = app.scenarios;
            allSettings{2} = '';
            allSettings{3} = num2str(app.noRaysEachCluster_7.Value);
            allSettings{4} = app.DropDown_7.Value;
            allSettings{5} = app.Day.Value;
            allSettings{6} = app.Bx.Value;
            allSettings{7} = app.R12.Value;
            allSettings{8} = app.Hour.Value;
            allSettings{9} = app.Latitude.Value;
        
        elseif strfind(scenario, app.sps.scenario_UWA)
            allSettings{1} = app.scenarios;
            allSettings{2} = num2str(app.noCluster_7.Value);
            allSettings{3} = num2str(app.noRaysEachCluster_8.Value);
            allSettings{4} = app.DropDown_7.Value;
            allSettings{5} = num2str(app.acousticSpeed.Value);
            allSettings{6} = num2str(app.txDepth.Value);
            allSettings{7} = num2str(app.wind_speed_uwa.Value);
            allSettings{8} = num2str(app.rxDepth.Value);
            allSettings{9} = num2str(app.height_water_uwa.Value);
            allSettings{10} = num2str(app.Distance_tx_rx.Value);

        elseif strfind(scenario, app.sps.scenario_ISAC)
            allSettings{1} = app.scenarios;
            allSettings{2} = app.SensingmodelDropDown.Value;
            allSettings{3} = app.TargettypeDropDown.Value;
            allSettings{4} = app.noCluster_9.Value;
            allSettings{5} = app.noCluster_10.Value;
            allSettings{6} = app.ButtonGroup_2.SelectedObject.Text;
            allSettings{7} = app.EditField_59.Value;
            allSettings{8} = app.bandwidth_2.Value;
            allSettings{9} = app.noCluster_8.Value;
            allSettings{10} = app.noRaysEachCluster_9.Value;
            allSettings{11} = app.noRaysEachCluster_10.Value;
            allSettings{12} = app.txInitialPos.Value;
            allSettings{13} = app.txInitialPos_2.Value;
            allSettings{14} = app.txInitialPos_3.Value;
            allSettings{15} = app.txTrackType.Value;
            allSettings{16} = app.txSpeed.Value;
            allSettings{17} = app.txAcceleration.Value;
            allSettings{18} = app.txTrackOri.Value;

      
        else
            allSettings{1} = app.scenarios;
            allSettings{2} = num2str(app.noCluster_5.Value);
            allSettings{3} = num2str(app.noRaysEachCluster_5.Value);
            allSettings{4} = app.DropDown_7.Value;
            allSettings{5} = ' ';
            allSettings{6} = ' ';
            allSettings{7} = ' ';
            allSettings{8} = ' ';
            allSettings{9} = ' ';
            allSettings{10} = ' ';
            allSettings{11} = ' ';
            allSettings{12} = ' ';
            allSettings{13} = ' ';
            allSettings{14} = ' ';
            allSettings{15} = ' ';
            allSettings{16} = ' ';
            allSettings{17} = ' ';
            allSettings{18} = ' ';
            allSettings{19} = ' ';
            allSettings{20} = ' ';
            allSettings{21} = ' ';
            allSettings{22} = ' ';
            allSettings{23} = ' ';
            allSettings{24} = ' ';
            allSettings{25} = ' ';
            allSettings{26} = ' ';
            allSettings{27} = ' ';
        end

        allSettings{28} = num2str(app.EditField.Value);
        allSettings{29} = num2str(app.bandwidth.Value);
        allSettings{30} = num2str(app.freqSamples.Value);
        allSettings{31} = app.UITable_antenna.Data;
       
    end

    allSettings{32} = num2str(app.trackLength.Value);
    allSettings{33} = num2str(app.sampleRate.Value);

    allSettings{34} = app.UITable_tx.Data;
    allSettings{35} = app.UITable_rx.Data;

    allSettings{36} = num2str(app.anSpeed.Value);
    allSettings{37} = app.anOri.Value;
    allSettings{38} = num2str(app.znSpeed.Value);
    allSettings{39} = app.znOri.Value;
end