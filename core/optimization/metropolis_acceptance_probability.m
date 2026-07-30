function probability = metropolis_acceptance_probability(delta, temperature)
%METROPOLIS_ACCEPTANCE_PROBABILITY Standard Step 8 SA acceptance rule.

arguments
    delta (1, 1) double {mustBeFinite}
    temperature (1, 1) double {mustBePositive, mustBeFinite}
end

if delta <= 0
    probability = 1;
else
    probability = exp(-delta / temperature);
end
end
