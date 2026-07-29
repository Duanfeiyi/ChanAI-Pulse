function H = cir_to_ctf(coefficient, delayS, frequencyOffsetsHz)
%CIR_TO_CTF Convert path-domain CIR coefficients to baseband CTF samples.
%   H = CIR_TO_CTF(COEFFICIENT, DELAYS, FREQUENCYOFFSETS) evaluates
%   sum_p alpha_p exp(-j*2*pi*f*tau_p). COEFFICIENT uses
%   [Tx, Rx, Npath, Nt, N_sample], DELAYS may broadcast across Tx/Rx, and
%   FREQUENCYOFFSETS is an Nf-vector in Hz.

arguments
    coefficient {mustBeNumeric}
    delayS {mustBeNumeric, mustBeReal}
    frequencyOffsetsHz (:, 1) double
end

coefficientShape = size5(coefficient);
delayShape = size5(delayS);
if ~all(delayShape == 1 | delayShape == coefficientShape)
    error("cir_to_ctf:IncompatibleDelayShape", ...
        "delayS must broadcast to coefficient dimensions.");
end
expandedDelay = repmat(reshape(delayS, delayShape), ...
    coefficientShape ./ delayShape);

frequencyCount = numel(frequencyOffsetsHz);
H = complex(zeros([coefficientShape(1:2), frequencyCount, ...
    coefficientShape(4:5)], "like", coefficient));
for frequency = 1:frequencyCount
    phase = exp(-1i * 2 * pi * ...
        cast(frequencyOffsetsHz(frequency), "like", expandedDelay) .* ...
        expandedDelay);
    H(:, :, frequency, :, :) = sum(coefficient .* phase, 3);
end
end

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
