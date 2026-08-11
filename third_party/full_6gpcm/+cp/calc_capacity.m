function [CP,cp] = calc_capacity(cir1,SNR_dB,span,cir2,eta_dB)
% Input:
% cir_e1: reconstructed cir include delay,[MR*MT*L]
% SNR_dB: signal to noise ratio in dB
% cir_e2: cir of interfered link
% eta_dB: 
% Output: 
% CP: ergodic channel capacity of single link,[length(SNR_dB)*1]
%%
    % H1 = fft(cir1,[],3);
    H1 = fft(cir1(:,:,1,:),[],4); % L means samples in frequency domain   
    H1 = H1(:,:,1:span:end);

    H1 = permute(H1, [2,1,3]); % 转成[MR*MT*L]
    [no_rxant,no_txant,NumFreq] = size(H1);
    
    const = 1/no_txant/no_rxant/NumFreq;
    or = ones(1,no_rxant);
    IR = diag(or);
    SNR = 10.^((SNR_dB)/10);
    
    beta_sub = zeros(1,NumFreq);
    cp = zeros(length(SNR),NumFreq);
    % normalize H1
    for k = 1 : NumFreq
        beta_sub(1,k) = norm(H1(:,:,k),'fro').^2;
    end
    beta = const * sum(beta_sub);
    H1_norm = H1./sqrt(beta);
    
    if  nargin < 4
        R_int = IR;
    else
        eta = 10.^(eta_dB/10);
        H2 = fft(cir2,[],3);
        for k = 1 : NumFreq
            beta_sub(1,k) = norm(H2(:,:,k)).^2;
        end
        beta = sqrt(const * sum(beta_sub));
        H2_norm = H2./beta;
        R_int = eta * squeeze(H2_norm(:,:,k))*squeeze(H2_norm(:,:,k))'+IR;
    end  
    for n = 1:length(SNR)
        for k = 1 : NumFreq
            cp(n,k) = log2(det(IR + SNR(n)/no_txant*squeeze(H1_norm(:,:,k))*squeeze(H1_norm(:,:,k))'*R_int^(-1)));
        end
    end
    CP = 1/NumFreq*sum(abs(cp),2); % real_valued
end
