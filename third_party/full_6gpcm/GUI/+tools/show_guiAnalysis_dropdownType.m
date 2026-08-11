function show_guiAnalysis_dropdownType(app)
%确定多用户
users_tx = app.CallingApp.UITable_tx.Data{:,1};
users_rx = app.CallingApp.UITable_rx.Data{:,1};

if strfind(app.DropDown_type.Value, 'Large scale fadings')
    app.Panel_timeDomain.Position = [-347,-1579,1260,741];
    app.Panel_freqDomain.Position = [-347,-808,1260,741];
    app.Panel_spaceDomain.Position = [955,-808,1260,741];
    app.Panel_lsfs.Position = [2, 1, app.UIFigure.Position(1,3:4)];
    app.Panel_systemLevel.Position = [955,-1579,1260,741];
    app.DropDown_txUserIndex_lsfs.Items = users_tx;
    app.DropDown_rxUserIndex_lsfs.Items = users_rx;

elseif strfind(app.DropDown_type.Value, 'Time domain')
    app.Panel_timeDomain.Position = [2, 1, app.UIFigure.Position(1,3:4)];
    app.Panel_freqDomain.Position = [-347,-808,1260,741];
    app.Panel_spaceDomain.Position = [955,-808,1260,741];
    app.Panel_lsfs.Position = [-347,-1579,1260,741];
    app.Panel_systemLevel.Position = [955,-1579,1260,741];
    app.DropDown_txUserIndex.Items = users_tx;
    app.DropDown_rxUserIndex.Items = users_rx;

    if tools.is_owc_band(app.CallingApp.scenarios, app.CallingApp)
        app.DropDown_txAntennaIndex.Items = strsplit(num2str(1));
        app.DropDown_rxAntennaIndex.Items = strsplit(num2str(1));
        app.DropDown_txAntennaIndex.Enable = 'off';
        app.DropDown_rxAntennaIndex.Enable = 'off';
        app.Label_12.Text = "行，      ";
        app.Label_10.Text = "列LED";
        app.TransmittingAntennaIndexLabel.Text = 'LED row index';
        app.ReceivingAntennaIndexLabel.Text = 'LED column index';
    else
        if strcmp(app.CallingApp.Tree.SelectedNodes.Text,app.CallingApp.acousticNode.Text)
            app.Label_12.Text = "根发射声呐 ";
            app.Label_10.Text = "根接收声呐 ";
            app.TransmittingAntennaIndexLabel.Text = 'Transmitting Sonar Index';
            app.ReceivingAntennaIndexLabel.Text = 'Receiving Sonar Index';
        else
            app.Label_12.Text = "根发射天线 ";
            app.Label_10.Text = "根接收天线 ";
            app.TransmittingAntennaIndexLabel.Text = 'Transmitting Antenna Index';
            app.ReceivingAntennaIndexLabel.Text = 'Receiving Antenna Index';
            % app.DropDown_txAntennaIndex.Items = strsplit(num2str(1:app.CallingApp.noAntennaTx.Value)); % TODO OWC频段没用到
            % app.DropDown_rxAntennaIndex.Items = strsplit(num2str(1:app.CallingApp.noAntennaRx.Value));
        end
        app.DropDown_txAntennaIndex.Enable = 'on';
        app.DropDown_rxAntennaIndex.Enable = 'on';
    end
elseif strfind(app.DropDown_type.Value, 'Frequency domain')
    [~,~,samples] = mf.str2frequencys(app.CallingApp.EditField.Value,app.CallingApp.bandwidth.Value,app.CallingApp.freqSamples.Value);
    app.EditField_simPoints_freq.Value = samples(1);

    app.Panel_timeDomain.Position = [-347,-808,1260,741];
    app.Panel_freqDomain.Position = [2, 1, app.UIFigure.Position(1,3:4)];
    app.Panel_spaceDomain.Position = [955,-808,1260,741];
    app.Panel_lsfs.Position = [-347,-1579,1260,741];
    app.Panel_systemLevel.Position = [955,-1579,1260,741];
    
    app.DropDown_txUserIndex_freq.Items = users_tx;
    app.DropDown_rxUserIndex_freq.Items = users_rx;

    if tools.is_owc_band(app.CallingApp.scenarios, app.CallingApp)
        app.DropDown_txAntennaIndex_freq.Items = strsplit(num2str(1));
        app.DropDown_rxAntennaIndex_freq.Items = strsplit(num2str(1));
        app.DropDown_txAntennaIndex_freq.Enable = 'off';
        app.DropDown_rxAntennaIndex_freq.Enable = 'off';
        app.Label_17.Text = "行，      ";
        app.Label_15.Text = "列LED";
        app.TransmittingAntennaIndexLabel.Text = 'LED row index';
        app.ReceivingAntennaIndexLabel.Text = 'LED column index';
    else
        app.DropDown_txAntennaIndex_freq.Enable = 'on';
        app.DropDown_rxAntennaIndex_freq.Enable = 'on';
        if strcmp(app.CallingApp.Tree.SelectedNodes.Text,app.CallingApp.acousticNode.Text)
            app.Label_17.Text = "根发射声呐 ";
            app.Label_15.Text = "根接收声呐 ";
            app.TransmittingAntennaIndexLabel_2.Text = 'Transmitting Sonar Index';
            app.ReceivingAntennaIndexLabel_2.Text = 'Receiving Sonar Index';

        else
            app.Label_17.Text = "根发射天线 ";
            app.Label_15.Text = "根接收天线 ";
            app.TransmittingAntennaIndexLabel_2.Text = 'Transmitting Antenna Index';
            app.ReceivingAntennaIndexLabel_2.Text = 'Receiving Antenna Index';
            % app.DropDown_txAntennaIndex_freq.Items = strsplit(num2str(1:app.CallingApp.noAntennaTx.Value)); % TODO OWC频段没用到
            % app.DropDown_rxAntennaIndex_freq.Items = strsplit(num2str(1:app.CallingApp.noAntennaRx.Value));
        end
    end
elseif strfind(app.DropDown_type.Value, 'Space domain')
    app.Panel_timeDomain.Position = [955,-808,1260,741];
    app.Panel_freqDomain.Position = [-347,-808,1260,741];
    app.Panel_spaceDomain.Position = [2, 1, app.UIFigure.Position(1,3:4)];
    app.Panel_lsfs.Position = [-347,-1579,1260,741];
    app.Panel_systemLevel.Position = [955,-1579,1260,741];
    app.DropDown_txUserIndex_space.Items = users_tx;
    app.DropDown_rxUserIndex_space.Items = users_rx;
    
else
    if strcmp(app.CallingApp.Tree.SelectedNodes.Text,app.CallingApp.acousticNode.Text)
        app.Label_48.Text = "根发射声呐 ";
        app.Label_46.Text = "根接收声呐 ";
        app.TransmittingAntennaIndexLabel_3.Text = 'Transmitting Sonar Index';
        app.ReceivingAntennaIndexLabel_3.Text = 'Receiving Sonar Index';
    else
        app.Label_48.Text = "根发射天线 ";
        app.Label_46.Text = "根接收天线 ";
        app.TransmittingAntennaIndexLabel_3.Text = 'Transmitting Antenna Index';
        app.ReceivingAntennaIndexLabel_3.Text = 'Receiving Antenna Index';
    end

    app.Panel_systemLevel.Position = [2, 1, app.UIFigure.Position(1,3:4)];
    app.Panel_timeDomain.Position = [955,-808,1260,741];
    app.Panel_freqDomain.Position = [-347,-808,1260,741];
    app.Panel_spaceDomain.Position = [955,-1579,1260,741];
    app.Panel_lsfs.Position = [-347,-1579,1260,741];
    app.DropDown_txUserIndex_system.Items = users_tx;
    app.DropDown_rxUserIndex_system.Items = users_rx;
end
end

