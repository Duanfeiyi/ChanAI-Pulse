function [psiS] = set_no_contribution(psiS)
%------------------------------------------------------------------------------
% SET_NO_CONTRIBUTION: Set the contributions of invalid rays as zero
%------------------------------------------------------------------------------
Num = length(psiS);
for k=1:Num
    if psiS(k) > pi/2
        psiS(k) = pi/2;
    end
end
end

