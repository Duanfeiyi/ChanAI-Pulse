function [H_CTF, f] = H2ctf(H, freq_sample, B, delay, use_gpu, d_waitbar)
%H2CTF 此处显示有关此函数的摘要
%   input: H: no_txAntenna * no_rxAntenna * snaps * no_clusters
%   output: H_CTF: no_txAntenna * no_rxAntenna * snaps * no_carriers

use_gpu = mf.has_gpu;

[no_txant, no_rxant, no_snap, no_clusters] = size(H);

f = linspace( - B/2,  B/2, freq_sample);

%判断是否使用单精度
if no_txant*no_rxant < 16384 %16*8 * 16*8
    H_CTF = zeros(no_txant, no_rxant, no_snap, freq_sample);
else
    %单精度
    H_CTF = zeros(no_txant, no_rxant, no_snap, freq_sample,'single');
    H = single( H );
    delay = single( delay );
    f = single( f );
end

%判断GPU运算矩阵是否分块
if use_gpu == 1
    [op_no_txant,op_no_rxant] = mf.split(no_snap,no_clusters,freq_sample);

    if no_txant*no_rxant > op_no_txant*op_no_rxant
        use_gpu = 2;
    else
        use_gpu = 1;
    end
    
end


% GPU算法
if use_gpu == 1 && all(isnumeric(H(:))) && all(isnumeric(delay(:)))


    H_CTF = gpuArray( H_CTF );
    f = gpuArray( f );
    H = gpuArray( H );
    delay = gpuArray( delay );

    for find1 = 1: freq_sample

        H_CTF(:,:,:,find1) = sum(H.*exp(-1j*2*pi*f(find1)*delay),4);
        if exist('d_waitbar')
            d_waitbar.Value = find1/freq_sample;
            if d_waitbar.CancelRequested
                close(d_waitbar);
                return;
            end
        end
    end
    H_CTF = (gather(H_CTF));
    H_CTF(isnan(H_CTF)) = 0;



elseif use_gpu == 2 && all(isnumeric(H(:))) && all(isnumeric(delay(:)))
    % GPU算法 矩阵分块
  
    H_CTF = gpuArray( H_CTF );
    f = gpuArray( f );
    

    num_row_parts = ceil(no_txant/op_no_txant);%tx天线的分块数
    num_col_parts = ceil(no_rxant/op_no_rxant);%rx天线的分块数

    
    for i = 1:num_row_parts
        for j = 1:num_col_parts
            %矩阵分块
         
            rowStart = (i - 1) * op_no_txant + 1;
            rowEnd = min(i * op_no_txant, no_txant);
            colStart = (j - 1) * op_no_rxant + 1;
            colEnd = min(j * op_no_rxant, no_rxant);

            H_gpu = gpuArray( H(rowStart:rowEnd, colStart:colEnd, :, :) );
            delay_gpu = gpuArray( delay(rowStart:rowEnd, colStart:colEnd, :, :) );

            for find1 = 1: freq_sample

                H_CTF(rowStart:rowEnd, colStart:colEnd, :, find1) = sum(H_gpu.*exp(-1j*2*pi*f(find1)*delay_gpu),4);

                if exist('d_waitbar')
                    d_waitbar.Value = find1/(freq_sample*num_col_parts*num_row_parts) + (i-1)/num_row_parts + (j-1)/(num_row_parts*num_col_parts);
                    if d_waitbar.CancelRequested
                        close(d_waitbar);
                        return;
                    end
                end

            end

            clear H_gpu delay_gpu
            
        end
    end
    H_CTF = (gather(H_CTF));
    H_CTF(isnan(H_CTF)) = 0;


else
    %  CPU算法
    for find1 = 1: freq_sample
       
        H_CTF(:,:,:,find1) = sum(H.*exp(-1j*2*pi*f(find1)*delay),4);
        if exist('d_waitbar')
            d_waitbar.Value = find1/freq_sample;
            if d_waitbar.CancelRequested
                close(d_waitbar);
                return;
            end
        end
    end
    H_CTF(isnan(H_CTF)) = 0;

end


end

