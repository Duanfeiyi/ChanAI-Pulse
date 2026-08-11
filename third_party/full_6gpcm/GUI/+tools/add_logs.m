function add_logs(funcName, logStr)
%ADDLOGS 此处显示有关此函数的摘要
%   此处显示详细说明
    disp(strcat(datestr(now,'yyyy-mm-dd HH:MM:ss'), ' [', funcName, '] - ', logStr));
end