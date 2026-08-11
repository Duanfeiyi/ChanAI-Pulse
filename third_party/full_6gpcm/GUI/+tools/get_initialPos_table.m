function [initialPosTx, initialPosRx] = get_initialPos_table(app)

    tx_track_list = table2array(app.UITable_tx.Data);
    rx_track_list = table2array(app.UITable_rx.Data);
    initial_str_tx = tx_track_list(:,3).';
    initial_str_rx = rx_track_list(:,3).';

    % 初始化矩阵
    initialPosTx = zeros(numel(initial_str_tx), 3);
    initialPosRx = zeros(numel(initial_str_rx), 3);

    % 遍历Tx字符串数组，将每个字符串转换为double类型，并存入矩阵
    for i = 1 : numel(initial_str_tx)
        % 使用正则表达式提取字符串中的数字部分
        numbers = str2double(regexp(initial_str_tx{i}, '-?\d+(\.\d*)?([eE][-+]?\d+)?', 'match'));

        % 将提取的数字存入矩阵对应的行
        initialPosTx(i, :) = numbers;
    end

    % 遍历Rx字符串数组，将每个字符串转换为double类型，并存入矩阵
    for i = 1 : numel(initial_str_rx)
        % 使用正则表达式提取字符串中的数字部分
        numbers = str2double(regexp(initial_str_rx{i}, '-?\d+(\.\d*)?([eE][-+]?\d+)?', 'match'));

        % 将提取的数字存入矩阵对应的行
        initialPosRx(i, :) = numbers;
    end
