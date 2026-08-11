function [H_CTF] = H2ctf_uwb(H, fc, f, delay)
%H2CTF 此处显示有关此函数的摘要
%   input: H: no_rxAntenna * no_txAntenna * snaps * no_clusters
%   output: H_CTF: no_rxAntenna * no_txAntenna * snaps * no_carriers

    H_CTF = [];
    for find1 = 1: length(f)
        H_CTF = cat(4, H_CTF, (f(find1)/fc)^2 * sum(H.*exp(-1j*2*pi*f(find1)*delay),4));  % 大带宽的时候，(f(find1)/fc)^
    end
end