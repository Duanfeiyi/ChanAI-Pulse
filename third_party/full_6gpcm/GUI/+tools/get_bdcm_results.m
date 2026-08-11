function H_B_CTF = get_bdcm_results(cm, H_CTF)
%GET_BDCM_RESULTS 此处显示有关此函数的摘要
%% Beam domain channel transformation

%多频段
if length(cm.sim_params.carrier_frequency)>1
    H_CTF_temp = H_CTF;
    % 获取原始数组的尺寸
    [m, n, p, q] = size(H_CTF_temp);

    % 初始化新的 cell 数组
    H_CTF = cell(m, n, q);

    % 遍历并合并第三维
    for i = 1:m
        for j = 1:n
            for k = 1:q
                % 将第三维度的数据沿第三维合并为一个 5x5x(101*100) 的矩阵
                temp = cat(3, H_CTF_temp{i, j, :, k});
                % 自动计算 reshape 的第四维大小
                H_CTF{i, j, k} = reshape(temp, size(temp,1), size(temp,2), p, []);
            end
        end
    end
    H_B_CTF =  cell(size(H_CTF,1),size(H_CTF,2), q);
    for i_freq = 1: q

        for i_user_tx = 1 : m
            for i_user_rx = 1 : n

                if iscell(H_CTF)
                    H_CTF_sigleUser = H_CTF{i_user_tx, i_user_rx, i_freq};
                else
                    H_CTF_sigleUser = H_CTF;
                end

                tx_array = cm.tx_array(i_user_tx);
                rx_array = cm.rx_array(i_user_rx);

                array_type_tx = tx_array.type;
                array_type_rx = rx_array.type;

                CTF = squeeze(H_CTF_sigleUser(:,:,1,1));
                HorV = 1;%1:面阵配置下展示水平方向角度；0：面阵配置下展示垂直方向角度
                if strcmp(array_type_tx,'linear') && strcmp(array_type_rx,'linear')
                    P = tx_array.no_elements;%发端波束数=发端天线数
                    Q = rx_array.no_elements;%收端波束数=收端天线数
                    i = 1:P;
                    j = 1:Q;
                    tildeThetaT = (2*i-1)/(2*P)-0.5;%发端波束对应空间频率
                    tildeThetaR = (2*j-1)/(2*Q)-0.5;%收端波束对应空间频率
                    % CTF=squeeze(H_CTF(:,:,1,1));
                    UT = [];%发端转换矩阵
                    UR = [];%收端转换矩阵
                    for i = 1:P
                        UT = [UT, ResponseVector(P, tildeThetaT(i))];%发端转换矩阵采样
                    end
                    for j = 1:Q
                        UR = [UR, ResponseVector(Q, tildeThetaR(j))];%收端转换矩阵采样
                    end
                    % CTF = kron(ResponseVector(P, 0.2),ResponseVector(Q, 0.1).');
                    UR = 1/sqrt(Q)*UR;
                    UT = 1/sqrt(P)*UT;
                    H_B_CTF_full = UT'*CTF*conj(UR);%波束域转换
                    %                         [X,Y] = meshgrid(tildeThetaR, tildeThetaT);
                    %                         mesh(X,Y,10*log10(abs(H_B_CTF_full).^2));
                    %                         xlabel('Rx beam');
                    %                         ylabel('Tx beam');

                    H_B_CTF{i_user_tx,i_user_rx, i_freq} = H_B_CTF_full;

                elseif strcmp(array_type_tx,'linear') && strcmp(array_type_rx,'planar')
                    Ph = tx_array.no_elements;%发端波束数=发端天线数
                    Pv = 1;%发端波束仅一个维度，另一个维度置1
                    Qh = rx_array.no_elements_H;%收端水平波束数=收端水平天线数
                    Qv = rx_array.no_elements_V;%收端垂直波束数=收端垂直天线数
                    P = Ph*Pv;%发端天线&波束总数
                    Q = Qh*Qv;%收端天线&波束总数
                    ph = 1:Ph;
                    qh = 1:Qh;
                    pv = 1:Pv;
                    qv = 1:Qv;
                    tildeThetaTaz = (2*ph-1)/(2*Ph)-0.5;
                    tildeThetaTel = (2*pv-1)/(2*Pv)-0.5;
                    tildeThetaRaz = (2*qh-1)/(2*Qh)-0.5;
                    tildeThetaRel = (2*qv-1)/(2*Qv)-0.5;

                    UTaz = [];
                    URaz = [];
                    UTel = [];
                    URel = [];
                    for i = 1:Ph
                        UTaz = [UTaz, ResponseVector(Ph, tildeThetaTaz(i))];
                    end
                    for i = 1:Pv
                        UTel = [UTel, ResponseVector(Pv, tildeThetaTel(i))];
                    end
                    for i = 1:Qh
                        URaz = [URaz, ResponseVector(Qh, tildeThetaRaz(i))];
                    end
                    for i = 1:Qv
                        URel = [URel, ResponseVector(Qv, tildeThetaRel(i))];
                    end
                    UT = kron(UTaz,UTel);
                    UR = kron(URaz,URel);
                    % CTF = kron(ResponseVector(P, 0.2),ResponseVector(Q, 0.1).');
                    UR = 1/sqrt(Q)*UR;
                    UT = 1/sqrt(P)*UT;
                    H_B_CTF_temp = UT'*CTF*conj(UR);
                    H_B_CTF_full = reshape(H_B_CTF_temp,Pv,Ph,Qv,Qh);
                    if HorV == 1
                        H_B_CTF_full = sum(abs(H_B_CTF_full).^2,3);%求和消掉垂直维度
                        %                             [X,Y] = meshgrid(tildeThetaRaz, tildeThetaTaz);
                    else
                        H_B_CTF_full = sum(abs(H_B_CTF_full).^2,4);%求和消掉水平维度
                        %                             [X,Y] = meshgrid(tildeThetaTel, tildeThetaTaz);
                    end
                    H_B_CTF_full = squeeze(H_B_CTF_full);
                    %                         mesh(X,Y,10*log10(H_B_CTF_full));
                    %                         xlabel('Rx beam');
                    %                         ylabel('Tx beam');

                    H_B_CTF{i_user_tx,i_user_rx, i_freq} = H_B_CTF_full;

                elseif strcmp(array_type_tx,'planar') && strcmp(array_type_rx,'linear')
                    Ph = tx_array.no_elements_H;
                    Pv = tx_array.no_elements_V;
                    Qh = rx_array.no_elements;
                    Qv = 1;
                    P = Ph*Pv;
                    Q = Qh*Qv;
                    ph = 1:Ph;
                    qh = 1:Qh;
                    pv = 1:Pv;
                    qv = 1:Qv;
                    tildeThetaTaz = (2*ph-1)/(2*Ph)-0.5;
                    tildeThetaTel = (2*pv-1)/(2*Pv)-0.5;
                    tildeThetaRaz = (2*qh-1)/(2*Qh)-0.5;
                    tildeThetaRel = (2*qv-1)/(2*Qv)-0.5;

                    UTaz = [];
                    URaz = [];
                    UTel = [];
                    URel = [];
                    for i = 1:Ph
                        UTaz = [UTaz, ResponseVector(Ph, tildeThetaTaz(i))];
                    end
                    for i = 1:Pv
                        UTel = [UTel, ResponseVector(Pv, tildeThetaTel(i))];
                    end
                    for i = 1:Qh
                        URaz = [URaz, ResponseVector(Qh, tildeThetaRaz(i))];
                    end
                    for i = 1:Qv
                        URel = [URel, ResponseVector(Qv, tildeThetaRel(i))];
                    end
                    UT = kron(UTaz,UTel);
                    UR = kron(URaz,URel);
                    % CTF = kron(ResponseVector(P, 0.2),ResponseVector(Q, 0.1).');
                    UR = 1/sqrt(Q)*UR;
                    UT = 1/sqrt(P)*UT;
                    H_B_CTF_temp = UT'*CTF*conj(UR);
                    H_B_CTF_full = reshape(H_B_CTF_temp,Pv,Ph,Qv,Qh);
                    if HorV == 1
                        H_B_CTF_full = sum(abs(H_B_CTF_full).^2,1);
                        %                             [X,Y] = meshgrid(tildeThetaRaz, tildeThetaTaz);
                    else
                        H_B_CTF_full = sum(abs(H_B_CTF_full).^2,2);
                        %                             [X,Y] = meshgrid(tildeThetaRaz, tildeThetaTel);
                    end
                    H_B_CTF_full = squeeze(H_B_CTF_full);

                    %                         mesh(X,Y,10*log10(H_B_CTF_full));
                    %                         xlabel('Rx beam');
                    %                         ylabel('Tx beam');

                    H_B_CTF{i_user_tx,i_user_rx, i_freq} = H_B_CTF_full;

                elseif strcmp(array_type_tx,'planar') && strcmp(array_type_rx,'planar')
                    Ph = tx_array.no_elements_H;
                    Pv = tx_array.no_elements_V;
                    Qh = rx_array.no_elements_H;
                    Qv = rx_array.no_elements_V;
                    P = Ph*Pv;
                    Q = Qh*Qv;
                    ph = 1:Ph;
                    qh = 1:Qh;
                    pv = 1:Pv;
                    qv = 1:Qv;
                    tildeThetaTaz = (2*ph-1)/(2*Ph)-0.5;
                    tildeThetaTel = (2*pv-1)/(2*Pv)-0.5;
                    tildeThetaRaz = (2*qh-1)/(2*Qh)-0.5;
                    tildeThetaRel = (2*qv-1)/(2*Qv)-0.5;

                    UTaz = [];
                    URaz = [];
                    UTel = [];
                    URel = [];
                    for i = 1:Ph
                        UTaz = [UTaz, ResponseVector(Ph, tildeThetaTaz(i))];
                    end
                    for i = 1:Pv
                        UTel = [UTel, ResponseVector(Pv, tildeThetaTel(i))];
                    end
                    for i = 1:Qh
                        URaz = [URaz, ResponseVector(Qh, tildeThetaRaz(i))];
                    end
                    for i = 1:Qv
                        URel = [URel, ResponseVector(Qv, tildeThetaRel(i))];
                    end
                    UT = kron(UTaz,UTel);
                    UR = kron(URaz,URel);
                    % CTF = kron(ResponseVector(P, 0.2),ResponseVector(Q, 0.1).');
                    UR = 1/sqrt(Q)*UR;
                    UT = 1/sqrt(P)*UT;
                    H_B_CTF_temp = UT'*CTF*conj(UR);
                    H_B_CTF_full = reshape(H_B_CTF_temp,Pv,Ph,Qv,Qh);
                    if HorV == 1
                        H_B_CTF_full = sum(abs(H_B_CTF_full).^2,1);
                        H_B_CTF_full = sum(abs(H_B_CTF_full).^2,3);
                        %                             [X,Y] = meshgrid(tildeThetaRaz, tildeThetaTaz);
                    else
                        H_B_CTF_full = sum(abs(H_B_CTF_full).^2,2);
                        H_B_CTF_full = sum(abs(H_B_CTF_full).^2,4);
                        %                             [X,Y] = meshgrid(tildeThetaRel, tildeThetaTel);
                    end
                    H_B_CTF_full = squeeze(H_B_CTF_full);
                    %                         mesh(X,Y,10*log10(H_B_CTF_full));
                    %                         xlabel('Rx beam');
                    %                         ylabel('Tx beam');

                    H_B_CTF{i_user_tx,i_user_rx, i_freq} = H_B_CTF_full;
                else
                    %error('Array type not support! only support linear/planar antenna array')
                end
            end

        end
    end

else


    if iscell(H_CTF)
        num_user_tx = size(H_CTF,1);
        num_user_rx = size(H_CTF,2);
    else
        num_user_tx = 1;
        num_user_rx = 1;
    end
    H_B_CTF =  cell(num_user_tx, num_user_rx);
    for i_user_tx = 1 : num_user_tx
        for i_user_rx = 1 : num_user_rx

            if iscell(H_CTF)
                H_CTF_sigleUser = H_CTF{i_user_tx,i_user_rx};
            else
                H_CTF_sigleUser = H_CTF;
            end

            tx_array = cm.tx_array(i_user_tx);
            rx_array = cm.rx_array(i_user_rx);

            array_type_tx = tx_array.type;
            array_type_rx = rx_array.type;

            CTF = squeeze(H_CTF_sigleUser(:,:,1,1));
            HorV = 1;%1:面阵配置下展示水平方向角度；0：面阵配置下展示垂直方向角度
            if strcmp(array_type_tx,'linear') && strcmp(array_type_rx,'linear')
                P = tx_array.no_elements;%发端波束数=发端天线数
                Q = rx_array.no_elements;%收端波束数=收端天线数
                i = 1:P;
                j = 1:Q;
                tildeThetaT = (2*i-1)/(2*P)-0.5;%发端波束对应空间频率
                tildeThetaR = (2*j-1)/(2*Q)-0.5;%收端波束对应空间频率
                % CTF=squeeze(H_CTF(:,:,1,1));
                UT = [];%发端转换矩阵
                UR = [];%收端转换矩阵
                for i = 1:P
                    UT = [UT, ResponseVector(P, tildeThetaT(i))];%发端转换矩阵采样
                end
                for j = 1:Q
                    UR = [UR, ResponseVector(Q, tildeThetaR(j))];%收端转换矩阵采样
                end
                % CTF = kron(ResponseVector(P, 0.2),ResponseVector(Q, 0.1).');
                UR = 1/sqrt(Q)*UR;
                UT = 1/sqrt(P)*UT;
                H_B_CTF_full = UT'*CTF*conj(UR);%波束域转换
                %                         [X,Y] = meshgrid(tildeThetaR, tildeThetaT);
                %                         mesh(X,Y,10*log10(abs(H_B_CTF_full).^2));
                %                         xlabel('Rx beam');
                %                         ylabel('Tx beam');

                H_B_CTF{i_user_tx,i_user_rx} = H_B_CTF_full;

            elseif strcmp(array_type_tx,'linear') && strcmp(array_type_rx,'planar')
                Ph = tx_array.no_elements;%发端波束数=发端天线数
                Pv = 1;%发端波束仅一个维度，另一个维度置1
                Qh = rx_array.no_elements_H;%收端水平波束数=收端水平天线数
                Qv = rx_array.no_elements_V;%收端垂直波束数=收端垂直天线数
                P = Ph*Pv;%发端天线&波束总数
                Q = Qh*Qv;%收端天线&波束总数
                ph = 1:Ph;
                qh = 1:Qh;
                pv = 1:Pv;
                qv = 1:Qv;
                tildeThetaTaz = (2*ph-1)/(2*Ph)-0.5;
                tildeThetaTel = (2*pv-1)/(2*Pv)-0.5;
                tildeThetaRaz = (2*qh-1)/(2*Qh)-0.5;
                tildeThetaRel = (2*qv-1)/(2*Qv)-0.5;

                UTaz = [];
                URaz = [];
                UTel = [];
                URel = [];
                for i = 1:Ph
                    UTaz = [UTaz, ResponseVector(Ph, tildeThetaTaz(i))];
                end
                for i = 1:Pv
                    UTel = [UTel, ResponseVector(Pv, tildeThetaTel(i))];
                end
                for i = 1:Qh
                    URaz = [URaz, ResponseVector(Qh, tildeThetaRaz(i))];
                end
                for i = 1:Qv
                    URel = [URel, ResponseVector(Qv, tildeThetaRel(i))];
                end
                UT = kron(UTaz,UTel);
                UR = kron(URaz,URel);
                % CTF = kron(ResponseVector(P, 0.2),ResponseVector(Q, 0.1).');
                UR = 1/sqrt(Q)*UR;
                UT = 1/sqrt(P)*UT;
                H_B_CTF_temp = UT'*CTF*conj(UR);
                H_B_CTF_full = reshape(H_B_CTF_temp,Pv,Ph,Qv,Qh);
                if HorV == 1
                    H_B_CTF_full = sum(abs(H_B_CTF_full).^2,3);%求和消掉垂直维度
                    %                             [X,Y] = meshgrid(tildeThetaRaz, tildeThetaTaz);
                else
                    H_B_CTF_full = sum(abs(H_B_CTF_full).^2,4);%求和消掉水平维度
                    %                             [X,Y] = meshgrid(tildeThetaTel, tildeThetaTaz);
                end
                H_B_CTF_full = squeeze(H_B_CTF_full);
                %                         mesh(X,Y,10*log10(H_B_CTF_full));
                %                         xlabel('Rx beam');
                %                         ylabel('Tx beam');

                H_B_CTF{i_user_tx,i_user_rx} = H_B_CTF_full;

            elseif strcmp(array_type_tx,'planar') && strcmp(array_type_rx,'linear')
                Ph = tx_array.no_elements_H;
                Pv = tx_array.no_elements_V;
                Qh = rx_array.no_elements;
                Qv = 1;
                P = Ph*Pv;
                Q = Qh*Qv;
                ph = 1:Ph;
                qh = 1:Qh;
                pv = 1:Pv;
                qv = 1:Qv;
                tildeThetaTaz = (2*ph-1)/(2*Ph)-0.5;
                tildeThetaTel = (2*pv-1)/(2*Pv)-0.5;
                tildeThetaRaz = (2*qh-1)/(2*Qh)-0.5;
                tildeThetaRel = (2*qv-1)/(2*Qv)-0.5;

                UTaz = [];
                URaz = [];
                UTel = [];
                URel = [];
                for i = 1:Ph
                    UTaz = [UTaz, ResponseVector(Ph, tildeThetaTaz(i))];
                end
                for i = 1:Pv
                    UTel = [UTel, ResponseVector(Pv, tildeThetaTel(i))];
                end
                for i = 1:Qh
                    URaz = [URaz, ResponseVector(Qh, tildeThetaRaz(i))];
                end
                for i = 1:Qv
                    URel = [URel, ResponseVector(Qv, tildeThetaRel(i))];
                end
                UT = kron(UTaz,UTel);
                UR = kron(URaz,URel);
                % CTF = kron(ResponseVector(P, 0.2),ResponseVector(Q, 0.1).');
                UR = 1/sqrt(Q)*UR;
                UT = 1/sqrt(P)*UT;
                H_B_CTF_temp = UT'*CTF*conj(UR);
                H_B_CTF_full = reshape(H_B_CTF_temp,Pv,Ph,Qv,Qh);
                if HorV == 1
                    H_B_CTF_full = sum(abs(H_B_CTF_full).^2,1);
                    %                             [X,Y] = meshgrid(tildeThetaRaz, tildeThetaTaz);
                else
                    H_B_CTF_full = sum(abs(H_B_CTF_full).^2,2);
                    %                             [X,Y] = meshgrid(tildeThetaRaz, tildeThetaTel);
                end
                H_B_CTF_full = squeeze(H_B_CTF_full);

                %                         mesh(X,Y,10*log10(H_B_CTF_full));
                %                         xlabel('Rx beam');
                %                         ylabel('Tx beam');

                H_B_CTF{i_user_tx,i_user_rx} = H_B_CTF_full;

            elseif strcmp(array_type_tx,'planar') && strcmp(array_type_rx,'planar')
                Ph = tx_array.no_elements_H;
                Pv = tx_array.no_elements_V;
                Qh = rx_array.no_elements_H;
                Qv = rx_array.no_elements_V;
                P = Ph*Pv;
                Q = Qh*Qv;
                ph = 1:Ph;
                qh = 1:Qh;
                pv = 1:Pv;
                qv = 1:Qv;
                tildeThetaTaz = (2*ph-1)/(2*Ph)-0.5;
                tildeThetaTel = (2*pv-1)/(2*Pv)-0.5;
                tildeThetaRaz = (2*qh-1)/(2*Qh)-0.5;
                tildeThetaRel = (2*qv-1)/(2*Qv)-0.5;

                UTaz = [];
                URaz = [];
                UTel = [];
                URel = [];
                for i = 1:Ph
                    UTaz = [UTaz, ResponseVector(Ph, tildeThetaTaz(i))];
                end
                for i = 1:Pv
                    UTel = [UTel, ResponseVector(Pv, tildeThetaTel(i))];
                end
                for i = 1:Qh
                    URaz = [URaz, ResponseVector(Qh, tildeThetaRaz(i))];
                end
                for i = 1:Qv
                    URel = [URel, ResponseVector(Qv, tildeThetaRel(i))];
                end
                UT = kron(UTaz,UTel);
                UR = kron(URaz,URel);
                % CTF = kron(ResponseVector(P, 0.2),ResponseVector(Q, 0.1).');
                UR = 1/sqrt(Q)*UR;
                UT = 1/sqrt(P)*UT;
                H_B_CTF_temp = UT'*CTF*conj(UR);
                H_B_CTF_full = reshape(H_B_CTF_temp,Pv,Ph,Qv,Qh);
                if HorV == 1
                    H_B_CTF_full = sum(abs(H_B_CTF_full).^2,1);
                    H_B_CTF_full = sum(abs(H_B_CTF_full).^2,3);
                    %                             [X,Y] = meshgrid(tildeThetaRaz, tildeThetaTaz);
                else
                    H_B_CTF_full = sum(abs(H_B_CTF_full).^2,2);
                    H_B_CTF_full = sum(abs(H_B_CTF_full).^2,4);
                    %                             [X,Y] = meshgrid(tildeThetaRel, tildeThetaTel);
                end
                H_B_CTF_full = squeeze(H_B_CTF_full);
                %                         mesh(X,Y,10*log10(H_B_CTF_full));
                %                         xlabel('Rx beam');
                %                         ylabel('Tx beam');

                H_B_CTF{i_user_tx,i_user_rx} = H_B_CTF_full;
            else
                %error('Array type not support! only support linear/planar antenna array')
            end
        end

    end

end
end



function a = ResponseVector(P, tildeTheta)
a = zeros(P,1);
for i = 1:P
    %     a=[a (exp(1i*[0:N-1]*2*pi*d*sin(azimuth(i))/lamada)).'];
    a(i) = exp(1i*(i-1)*2*pi*tildeTheta);
end

end

