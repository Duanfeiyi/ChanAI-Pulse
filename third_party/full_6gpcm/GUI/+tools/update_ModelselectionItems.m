function update_ModelselectionItems(app)
%更新模式下拉框选项
      tools.check_freqAndScensChosen(app);
      tag_scen = app.Tree_2.SelectedNodes.Tag;
      tag_freq = app.Tree.SelectedNodes.Tag;
      if strfind (tag_scen, app.sps.scenario_SATELLITE)
           app.Model_Selection.Items =  {'6GPCS', '3GPP TR 38.811'};
      elseif strfind (tag_scen, app.sps.scenario_UAV)
           app.Model_Selection.Items =  {'6GPCS', '3GPP TR 36.777'};
      elseif strfind (tag_scen, app.sps.scenario_IIOT)
           app.Model_Selection.Items = {'6GPCS','3GPP TR 38.901'};
      elseif strfind (tag_scen, app.sps.scenario_V2V)
          app.Model_Selection.Items = {'6GPCS','3GPP TR 37.885'};
      elseif contains(tag_scen, {app.sps.scenario_UWA, app.sps.scenario_ISAC, app.sps.scenario_RIS, app.sps.scenario_GROUNDWAVE, app.sps.scenario_MARITIME,...
              app.sps.scenario_SKYWAVE, app.sps.scenario_UHST, 'Corridor', 'Expressway', 'Office', app.sps.scenario_US, 'RMi'}) || contains(tag_freq, {app.sps.freqband_UV, ...
           app.sps.freqband_IR, app.sps.freqband_VL, app.sps.freqband_THZ, app.sps.freqband_VHF})
       app.Model_Selection.Items = {'6GPCS'};
      else
           app.Model_Selection.Items = {'6GPCS','3GPP TR 38.901','IMT2020'};
      end
end

