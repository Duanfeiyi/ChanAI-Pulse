function flag = is_owc_band(scenario, app)
% IS_OWC_BAND 此处显示有关此函数的摘要
%   此处显示详细说明
    flag = ~isempty(strcat(strfind(scenario, app.sps.freqband_IR), strfind(scenario, app.sps.freqband_VL), strfind(scenario, app.sps.freqband_UV)));
end

