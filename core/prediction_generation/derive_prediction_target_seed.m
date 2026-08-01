function seed = derive_prediction_target_seed(masterSeed, targetNumber, targetValue)
%DERIVE_PREDICTION_TARGET_SEED Deterministic per-target random seed.

arguments
    masterSeed (1, 1) double {mustBeInteger, mustBeNonnegative}
    targetNumber (1, 1) double {mustBeInteger, mustBePositive}
    targetValue (1, 1) double {mustBeFinite}
end

modulus = 2^31 - 1;
coordinateTerm = mod(round(abs(targetValue) * 1e6), modulus);
seed = mod(masterSeed + 104729 * targetNumber + ...
    1009 * coordinateTerm, modulus);
seed = double(seed);
end
