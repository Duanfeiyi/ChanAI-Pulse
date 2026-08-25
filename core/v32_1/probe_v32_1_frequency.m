function probe_v32_1_frequency(engineRoot)
%PROBE_V32_1_FREQUENCY Verify Frequency-axis CTF synthesis + missing pattern.

arguments
    engineRoot (1, 1) string = ""
end

if engineRoot == ""
    engineRoot = resolve_full_6gpcm_root().root;
end

patterns = ["uniform_half", "random_half", "block_8"];
for pattern = patterns
    spectrum = generate_v32_1_frequency_spectrum(engineRoot, ...
        ScenarioName="sub-6 GHz_UMa_LoS", Nf=64, ...
        MissingPattern=pattern, Seed=5500);
    ctf = spectrum.ctf_dataset;
    dims = ctf.dimensions;
    H = ctf.ctf.H;
    fprintf("[%s] Nf=%d Nt=%d N_sample=%d  H shape=[%d %d %d %d %d]\n", ...
        pattern, dims.Nf, dims.Nt, dims.N_sample, ...
        size(H, 1), size(H, 2), size(H, 3), size(H, 4), size(H, 5));

    assert(dims.Nf == 64, "Nf must be 64");
    assert(isfield(ctf.axes, "frequency_hz"), "frequency_hz axis missing");
    assert(numel(ctf.axes.frequency_hz) == 64, "frequency_hz must have 64 values");

    nf = dims.Nf;
    known = spectrum.known_subcarrier_index;
    target = spectrum.target_subcarrier_index;
    assert(isempty(intersect(known, target)), "known/target must not overlap");
    assert(numel(known) + numel(target) == nf, ...
        "known+target must cover all subcarriers");

    % Complex CTF values must be finite and non-degenerate.
    assert(all(isfinite(real(H(:)))) && all(isfinite(imag(H(:)))), ...
        "CTF must have finite complex values");
    assert(any(abs(H(:)) > 0), "CTF must have nonzero magnitude");

    fprintf("    known=%d target=%d  missing_ratio=%.2f\n", ...
        numel(known), numel(target), numel(target) / nf);
end

fprintf("PASS: Frequency-axis CTF synthesis + missing patterns work.\n");
end
