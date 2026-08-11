function save_bdcm_results(H_B_CTF_all, savePath)
%GET_BDCM_RESULTS 此处显示有关此函数的摘要
%% Beam domain channel transformation
answer = questdlg('Save the results in the beam domain or not?', 'Option', 'Save', 'Do not save', 'Do not save');

switch answer
    case 'Save'
        if ~exist(savePath, 'dir')
            mkdir(savePath);
        end
        save(strcat(savePath, filesep, 'h_B_CTF.mat'),  'H_B_CTF_all');
        msgbox(["The results in the beam domain have been saved in the directory : ", savePath], "modal");

    case 'Do not save'
        msgbox("The results in the beam domain are not saved", "modal");
end

end





