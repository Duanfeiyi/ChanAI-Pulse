function [freqs,bands,samples] = str2frequencys(freqStrs,bandStrs,sampleStrs)
    pat = '(\d+(\.\d+){0,1})';
    freqs = str2double(regexp(freqStrs, pat, 'match'));
    bands = str2double(regexp(bandStrs, pat, 'match'));
    samples = str2double(regexp(sampleStrs, pat, 'match'));

    mf.add_logs('str2frequencys', ['Freqs: [', num2str(freqs), '], bandwidths: [', num2str(bands), '], sub-freqs: [', num2str(samples), ']']);
    if (length(bands) > 1 && length(freqs) ~= length(bands) ) || (length(samples) > 1 && length(freqs) ~= length(samples)) 
        error(['The number of carrier frequencies and bandwidths (frequency samples) must be same or ' ...
            'different carrier frequencies share the bandwidths and frequency samples']);
    end

    max_freq = 5;
    if length(freqs) > max_freq
        error(['The maximum supported carrier frequencies is ',num2str(max_freq),'. Please reduce the number '...
            'of simulated carrier frequencies']);
    end

%     % 校验
%     for i = 1:length(freqs)
%         if freqs(i) < 0.003 || freqs(i) > 1000
%             error('Invalid carrier frequency. \n The value must be > 0.45 and < 1000');
%         end
%     end
end

