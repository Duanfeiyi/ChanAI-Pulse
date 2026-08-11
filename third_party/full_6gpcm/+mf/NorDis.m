%-------------------------------------------------------------------------------------------------------------------------
% This program is used to generate discrete Gaussian random variables
% 
% Input: Num: number of the random variables, mu: mean value, sigma: standard deviation
% Output: discrete Gaussian random variables
%--------------------------------------------------------------------------------------------------------------------------
function out  = NorDis(Num, mu, sigma)
    ran = linspace(0,1,Num);
    if Num > 1
        out = norminv(ran, mu, sigma);
        out(1) = mu-5*sigma;
        out(end) = mu+5*sigma;
    else
        out = mu+5*sigma;
    end
end
% plot(out); figure; hist(out,100);