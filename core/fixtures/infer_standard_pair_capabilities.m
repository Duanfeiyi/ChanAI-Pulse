function report = infer_standard_pair_capabilities(pair)
%INFER_STANDARD_PAIR_CAPABILITIES Combine CIR and CTF plot capabilities.
%   Step 2 fixtures contain matching CIR and CTF views of one channel.
%   This function reports the union needed by the future shared
%   characteristic engine while keeping the standard 1/3/6/9 plot count
%   separate from the optional ordered-route heatmap.

arguments
    pair (1, 1) struct
end

if ~isfield(pair, "cir") || ~isfield(pair, "ctf")
    error("infer_standard_pair_capabilities:MissingDomain", ...
        "A standard fixture pair must contain cir and ctf datasets.");
end

cirCapabilities = infer_channel_capabilities(pair.cir);
ctfCapabilities = infer_channel_capabilities(pair.ctf);
dims = pair.ctf.dimensions;
isWideband = dims.Nf > 1;
isDynamic = dims.Nt > 1;
hasArray = dims.Tx > 1 || dims.Rx > 1;

if ~isWideband && ~isDynamic && ~hasArray
    classification = "narrowband_static_siso";
elseif isWideband && ~isDynamic && ~hasArray
    classification = "wideband_static_siso";
elseif isWideband && ~isDynamic && hasArray
    classification = "wideband_static_mimo";
elseif isWideband && isDynamic && hasArray
    classification = "wideband_dynamic_mimo";
else
    classification = "other_channel";
end

report = struct();
report.classification = classification;
report.power = true;
report.pdp = cirCapabilities.pdp || ctfCapabilities.pdp;
report.frequency_autocorrelation = ...
    ctfCapabilities.frequency_autocorrelation;
report.delay_spread_cdf = cirCapabilities.delay_spread_cdf;
report.angular_power_spectrum = ...
    cirCapabilities.angular_power_spectrum;
report.spatial_correlation = cirCapabilities.spatial_correlation;
report.angular_spread_cdf = cirCapabilities.angular_spread_cdf;
report.doppler_power_spectrum = ...
    cirCapabilities.doppler_power_spectrum;
report.time_autocorrelation = ctfCapabilities.time_autocorrelation;
report.doppler_spread_cdf = cirCapabilities.doppler_spread_cdf;
report.delay_sample_heatmap = ...
    cirCapabilities.delay_sample_heatmap;

if classification == "narrowband_static_siso"
    report.standard_plots = "power";
else
    orderedNames = ["pdp", "frequency_autocorrelation", ...
        "delay_spread_cdf", "angular_power_spectrum", ...
        "spatial_correlation", "angular_spread_cdf", ...
        "doppler_power_spectrum", "time_autocorrelation", ...
        "doppler_spread_cdf"];
    enabled = false(size(orderedNames));
    for index = 1:numel(orderedNames)
        enabled(index) = logical(report.(orderedNames(index)));
    end
    report.standard_plots = orderedNames(enabled);
end
report.standard_plot_count = numel(report.standard_plots);
report.heatmap_is_additional = true;
end
