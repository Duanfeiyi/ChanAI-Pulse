function write_savingconf(app,tempFileName,newFileName)
    % 打开临时文件以进行读取
    tempFileID = fopen(tempFileName, 'r');

    % 检查文件是否成功打开
    if tempFileID == -1
        error(['Unable to open temporary file "', tempFileName, '"']);
    end

    % 读取临时文件的内容
    tempContent = fread(tempFileID, Inf, 'char=>char');

    % 关闭临时文件
    fclose(tempFileID);

    % 打开新文件以进行写入
    newFileID = fopen(newFileName, 'w');

    % 检查文件是否成功打开
    if newFileID == -1
        error(['Unable to open new file "', newFileName, '"']);
    end

    % 将临时文件的内容写入新文件
    fwrite(newFileID, tempContent, 'char');

    % 关闭新文件
    fclose(newFileID);
end
