function antenna2sonar(app)
%当使用水声通信时，主界面所有"天线"改为"声呐"
    if strcmp(app.Tree.SelectedNodes.Text,app.acousticNode.Text)
        app.GHzEditFieldLabel.Text = '载波频率（KHz）';
        app.MHzEditFieldLabel.Text = '带宽（KHz）';
        app.AntennasettingsTab.Title = '声呐配置(Sonar settings)';
        app.add_antenna.Text = '添加声呐 (Add sonar array)';
        app.edit_antenna.Text = '编辑声呐 (Edit selected sonar array)';
        app.delete_antenna.Text = '删除声呐 (Delete sonar array)';
        app.UITable_antenna.ColumnName{1} = 'Sonar array id';
        app.ConfiguremodifyantennaarrayidMenu.Text = '为所选用户配置/修改声呐阵列(Configure/modify sonar array id)';
        app.ConfiguremodifyantennaarrayidMenu_2.Text = '为所选用户配置/修改声呐阵列(Configure/modify sonar array id)';
        app.EditselectedantennaarrayMenu.Text = '编辑声呐 (Edit selected sonar array)';
        app.DeleteselectedantennaarrayMenu.Text = '删除声呐 (Delete selected sonar array)';
        app.UITable_tx.ColumnName{4} = 'Sonar array id';
        app.UITable_rx.ColumnName{4} = 'Sonar array id';
    else
        app.GHzEditFieldLabel.Text = '载波频率（GHz）';
        app.MHzEditFieldLabel.Text = '带宽（MHz）';
        app.AntennasettingsTab.Title = '天线配置(Antenna settings)';
        app.add_antenna.Text = '添加天线 (Add antenna array)';
        app.edit_antenna.Text = '编辑天线 (Edit selected antenna array)';
        app.delete_antenna.Text = '删除天线 (Delete antenna array)';
        app.UITable_antenna.ColumnName{1} = 'Antenna array id';
        app.ConfiguremodifyantennaarrayidMenu.Text = '为所选用户配置/修改天线阵列(Configure/modify antenna array id)';
        app.ConfiguremodifyantennaarrayidMenu_2.Text = '为所选用户配置/修改天线阵列(Configure/modify antenna array id)';
        app.EditselectedantennaarrayMenu.Text = '编辑天线 (Edit selected antenna array)';
        app.DeleteselectedantennaarrayMenu.Text = '删除天线 (Delete selected antenna array)';
        app.UITable_tx.ColumnName{4} = 'Antenna array id';
        app.UITable_rx.ColumnName{4} = 'Antenna array id';
    end
end 