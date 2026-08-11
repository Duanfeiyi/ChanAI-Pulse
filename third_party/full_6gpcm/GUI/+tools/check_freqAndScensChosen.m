function check_freqAndScensChosen(app)
%CHECK_FREQANDSCENSCHOSEN 所设置的频段或场景不能为空, 请在系统配置页面进行设置
    if isempty(app.Tree.SelectedNodes.Tag) || isempty(app.Tree_2.SelectedNodes.Tag)
        error('The frequency band or scenario can not be empty, please set these parameters on the system configuration page');
    end    
end