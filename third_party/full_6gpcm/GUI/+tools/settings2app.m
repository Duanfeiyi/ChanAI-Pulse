function settings2app(app, allSettings)
    tempTree = app.Node_2.Children;
    tempTree.delete;

    tools.set_ori_scenariosTree(app);
    if tools.is_owc_band(allSettings{1}, app)
        app.scenarios = allSettings{1};
        app.Tree_2.SelectedNodes = app.IndoorNode;
        app.Tree.SelectedNodes = app.VLNode;
        app.LEDColor.Value = allSettings{2};
        app.LEDType.Value = allSettings{3};

        app.noCluster_6.Value = str2double(allSettings{5});
        app.noRaysEachCluster_6.Value = str2double(allSettings{6});
        app.noLEDRow.Value = str2double(allSettings{7});
        app.noLEDColumn.Value = str2double(allSettings{8});
        app.spacingLEDRow.Value = str2double(allSettings{9});
        app.spacingLEDColumn.Value = str2double(allSettings{10});
        app.azimuthAnglePD.Value = str2double(allSettings{11});
        app.elevationAnglePD.Value = str2double(allSettings{12});
        app.azimuthAngleLEDRow.Value = str2double(allSettings{13});
        app.elevationAngleLEDRow.Value = str2double(allSettings{14});
        app.azimuthAngleLEDColumn.Value = str2double(allSettings{15});
        app.elevationAngleLEDColumn.Value = str2double(allSettings{16});
        app.PD_omegavR_A.Value = str2double(allSettings{17});
        app.PD_omegavR_E.Value = str2double(allSettings{18});

        tools.display_RFOff(app);
        tools.setFreqAndScensTree(app, app.scenarios);
        tools.check_display_scenarioTreeSelected(app);
        tools.check_display_freqTreeSelected(app);
        % 频率最后载入
        app.EditField.Value = allSettings{4};

    else
        tools.display_RFOn(app);
        if strfind(allSettings{1}, app.sps.scenario_RIS)
            app.scenarios = allSettings{1};

            % 先设置频段场景 后赋值
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_freqTreeSelected(app);
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_scenarioTreeSelected(app);

            app.EditField_RISx.Value = str2double(allSettings{2});
            app.EditField_RISy.Value = str2double(allSettings{3});
            app.EditField_RISwidth.Value = str2double(allSettings{4});
            app.EditField_RISheight.Value = str2double(allSettings{5});
            app.EditField_RISdelta_x.Value = str2double(allSettings{6});
            app.EditField_RISdelta_y.Value = str2double(allSettings{7});
            app.EditField_RISposx.Value = str2double(allSettings{8});
            app.EditField_RISposy.Value = str2double(allSettings{9});
            app.EditField_RISposz.Value = str2double(allSettings{10});
            app.vectorEditField_0.Value = str2double(allSettings{11});
            app.vectorEditField_1.Value = str2double(allSettings{12});
            app.vectorEditField_2.Value = str2double(allSettings{13});
            app.vectorEditField_3.Value = str2double(allSettings{14});
            app.vectorEditField_4.Value = str2double(allSettings{15});
            app.vectorEditField_5.Value = str2double(allSettings{16});
            app.vectorEditField_6.Value = str2double(allSettings{17});
            app.vectorEditField_7.Value = str2double(allSettings{18});
            app.vectorEditField_8.Value = str2double(allSettings{19});
            app.noCluster_RIS1.Value = str2double(allSettings{20});
            app.noRaysEachCluster_RIS1.Value = str2double(allSettings{21});
            app.noCluster_RIS3.Value = str2double(allSettings{22});
            app.noRaysEachCluster_RIS3.Value = str2double(allSettings{23});

            if ~isempty(strfind(allSettings{24}, app.LoSButton_RIS.Text))
                app.ButtonGroup_RIS.SelectedObject = app.LoSButton_RIS;
            else
                app.ButtonGroup_RIS.SelectedObject = app.NLoSButton_RIS;
            end
            app.DropDown_7.Value = allSettings{25};


        elseif strfind(allSettings{1}, app.sps.scenario_MARITIME)
            app.scenarios = allSettings{1};

            % 先设置频段场景 后赋值
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_freqTreeSelected(app);
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_scenarioTreeSelected(app);

            app.noCluster_2.Value = str2double(allSettings{2});
            app.noRaysEachCluster_2.Value = str2double(allSettings{3});
            app.noCluster_3.Value = str2double(allSettings{4});
            app.noRaysEachCluster_3.Value = str2double(allSettings{5});
            app.EditField_7.Value = str2double(allSettings{6});
            app.wind_speed.Value = str2double(allSettings{7});

        elseif strfind(allSettings{1},app.sps.scenario_SATELLITE)
            app.scenarios = allSettings{1};

            % 先设置频段场景 后赋值
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_freqTreeSelected(app);
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_scenarioTreeSelected(app);

            app.noCluster_4.Value = str2double(allSettings{2});
            app.noRaysEachCluster_4.Value = str2double(allSettings{3});
            app.DropDown_7.Value = allSettings{4};
            app.satHeight.Value = str2double(allSettings{5});
            app.BinEditField.Value = str2double(allSettings{6});
            app.DinEditField.Value = str2double(allSettings{7});
            app.CinEditField.Value = str2double(allSettings{8});
            app.EinEditField.Value = str2double(allSettings{9});
            app.FinEditField.Value = str2double(allSettings{10});
            app.DropDown_8.Value = allSettings{11};
            app.rainRate.Value = str2double(allSettings{12});

        elseif strfind(allSettings{1}, app.sps.scenario_SKYWAVE)
            app.scenarios = allSettings{1};

            % 先设置频段场景 后赋值
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_freqTreeSelected(app);
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_scenarioTreeSelected(app);

            app.noRaysEachCluster_7.Value = str2double(allSettings{3});
            app.DropDown_7.Value = allSettings{4};
            app.Day.Value = allSettings{5};
            app.Bx.Value = allSettings{6};
            app.R12.Value = allSettings{7};
            app.Hour.Value = allSettings{8};
            app.Latitude.Value = allSettings{9};

        elseif strfind(allSettings{1}, app.sps.scenario_UWA)
            app.scenarios = allSettings{1};

            % 先设置频段场景 后赋值
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_freqTreeSelected(app);
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_scenarioTreeSelected(app);

            app.noCluster_7.Value = str2double(allSettings{2});
            app.noRaysEachCluster_8.Value = str2double(allSettings{3});
            app.DropDown_7.Value = allSettings{4};
            app.acousticSpeed.Value = str2double(allSettings{5});
            app.txDepth.Value = str2double(allSettings{6});
            app.wind_speed_uwa.Value = str2double(allSettings{7});
            app.rxDepth.Value = str2double(allSettings{8});
            app.height_water_uwa.Value = str2double(allSettings{9});
            app.Distance_tx_rx.Value = str2double(allSettings{10});

        elseif strfind(allSettings{1}, app.sps.scenario_ISAC)
            app.scenarios = allSettings{1};
             % 先设置频段场景 后赋值
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_freqTreeSelected(app);
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_scenarioTreeSelected(app);

            app.scenarios = allSettings{1};
            app.SensingmodelDropDown.Value = allSettings{2};
            app.TargettypeDropDown.Value = allSettings{3};
            app.noCluster_9.Value = allSettings{4}  ;
            app.noCluster_10.Value = allSettings{5};
            if ~isempty(strfind(allSettings{6}, app.NLoSNLoSButton.Text))
                app.ButtonGroup_2.SelectedObject = app.NLoSNLoSButton;
            else
                app.ButtonGroup_2.SelectedObject = app.LoSLoSButton;
            end
            app.EditField_59.Value = allSettings{7};
            app.bandwidth_2.Value = allSettings{8};
            app.noCluster_8.Value = allSettings{9};
            app.noRaysEachCluster_9.Value = allSettings{10};
            app.noRaysEachCluster_10.Value = allSettings{11};
            app.txInitialPos.Value = allSettings{12};
            app.txInitialPos_2.Value = allSettings{13};
            app.txInitialPos_3.Value = allSettings{14};
            app.txTrackType.Value = allSettings{15};
            app.txSpeed.Value = allSettings{16};
            app.txAcceleration.Value = allSettings{17};
            app.txTrackOri.Value = allSettings{18};

        else
            app.scenarios = allSettings{1};

            % 先设置频段场景 后赋值
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_freqTreeSelected(app);
            tools.setFreqAndScensTree(app, app.scenarios);
            tools.check_display_scenarioTreeSelected(app);

            app.noCluster_5.Value = str2double(allSettings{2});
            app.noRaysEachCluster_5.Value = str2double(allSettings{3});
            app.DropDown_7.Value = allSettings{4};
        end

        app.EditField.Value = allSettings{28}; % 为了支持多频段
        app.bandwidth.Value = (allSettings{29});
        app.freqSamples.Value = (allSettings{30});
        app.UITable_antenna.Data = allSettings{31};
    end

    app.trackLength.Value = str2double(allSettings{32});
    app.sampleRate.Value = str2double(allSettings{33});
    % TODO
    app.UITable_tx.Data = allSettings{34};
    app.UITable_rx.Data = allSettings{35};

    app.anSpeed.Value = str2double(allSettings{36});
    app.anOri.Value = allSettings{37};
    app.znSpeed.Value = str2double(allSettings{38});
    app.znOri.Value = allSettings{39};
end
