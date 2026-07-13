function dpsdDbm = generation_result_to_dpsd(result)
%GENERATION_RESULT_TO_DPSD Convert a generated CIR result to DPSD dBm.

if ~isstruct(result) || ~isfield(result, "cir")
    error("generation_result_to_dpsd:InvalidResult", "A generator result with a cir field is required.");
end

if ndims(result.cir) < 4
    error("generation_result_to_dpsd:InvalidCIR", ...
        "Generated CIR must use the [1, 1, snapshot, delay] tensor layout.");
end

snapshotCount = size(result.cir, 3);
delayBinCount = size(result.cir, 4);
cirMatrix = reshape(result.cir, snapshotCount, delayBinCount);
nfft = size(cirMatrix, 2);
ctf = fft(cirMatrix, nfft, 2);
dpsdDbm = 10 * log10(abs(ctf).^2.' / 1e-3 + 1e-20);
end
