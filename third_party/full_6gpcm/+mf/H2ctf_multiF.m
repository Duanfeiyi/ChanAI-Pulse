function H_CTF = H2ctf_multiF(result, delay, B, freq_sample)
%H2CTF 此处显示有关此函数的摘要
%   input: H: no_txAntenna * no_rxAntenna * snaps * no_clusters
H_CTF = cell(size(result));

if length(freq_sample) == 1
    freq_sample = repmat(freq_sample,1,size(result,4));
end
if length(B) == 1
    B = repmat(B,1,size(result,4));
end
f = cell(1,size(result,4));
for i_freq = 1:size(result,4)
    f{i_freq} = linspace(-B(i_freq)/2,B(i_freq)/2,freq_sample(i_freq));
end



for i_user_tx = 1:size(result,1)
    for i_user_rx = 1:size(result,2)
        no_txAntenna = size(result{i_user_tx,i_user_rx,1,1},1);
        no_rxAntenna = size(result{i_user_tx,i_user_rx,1,1},2);
        for i_snap = 1:size(result,3)
            for i_freq = 1:size(result,4)
                temp_h = result{i_user_tx,i_user_rx,i_snap,i_freq};
                temp_h = reshape(temp_h,1,[]);
                temp_delay = delay{i_user_tx,i_user_rx,i_snap,i_freq};
                temp_delay = reshape(temp_delay,1,[]);
                dir = exp(-1i*2*pi*f{i_freq}.'*temp_delay);
                temp_H = repmat(temp_h,freq_sample(i_freq),1).*dir;
                temp_H = reshape(temp_H,freq_sample(i_freq),no_txAntenna,no_rxAntenna,[]);
                temp_H = squeeze(sum(temp_H,4));
                H_CTF{i_user_tx,i_user_rx,i_snap,i_freq} = permute(temp_H,[2 3 1]);
            end
        end
    end
end

end

