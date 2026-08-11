function [Capacity_mea,xcdf,ycdf] = cal_Mea_capacity(cir_mea,span,SNR_dB)
    xcdf = cell(1,length(SNR_dB));
    ycdf = cell(1,length(SNR_dB));
    [RxNum,TxNum,fNum,pointNum] = size(cir_mea);
    Capacity_mea = zeros(size(cir_mea,4),length(SNR_dB));

    for mea_no = 1:pointNum
        [Capacity_mea(mea_no,:),~] = calc_capacity(cir_mea(:,:,:,mea_no),SNR_dB,span);
    end

    for snr = 1:length(SNR_dB)
        [ycdf{snr},xcdf{snr}] = cdfcalc(Capacity_mea(:,snr));
    end

end

