function [initialPosTx, initialPosRx] = get_initialPos_trans(app)
%GET_INITIALPOS_TRANS 此处显示有关此函数的摘要
%   此处显示详细说明
    initialPosTx(1) = app.txInitialPos_1.Value;
    initialPosTx(2) = app.txInitialPos_2.Value;
    initialPosTx(3) = app.txInitialPos_3.Value;
    initialPosRx(1) = app.rxInitialPos_1.Value;
    initialPosRx(2) = app.rxInitialPos_2.Value;
    initialPosRx(3) = app.rxInitialPos_3.Value;
end

