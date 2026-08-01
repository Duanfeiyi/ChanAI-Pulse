function analysis = apply_prediction_continuity_policy(analysis, continuity)
%APPLY_PREDICTION_CONTINUITY_POLICY Disable unsupported cross-target plots.

arguments
    analysis (1, 1) struct
    continuity (1, 1) string
end

if continuity ~= "independent_targets" || ...
        string(analysis.status) == "FAIL"
    return;
end
blocked = ["doppler_power_spectrum", "time_autocorrelation", ...
    "doppler_spread_cdf", "delay_sample_heatmap"];
reason = "Predicted targets were generated independently; " + ...
    "cross-target time/route continuity is not scientifically available.";
for id = blocked
    if isfield(analysis.metrics, id)
        analysis.metrics.(id).available = false;
        analysis.metrics.(id).reason = reason;
        analysis.metrics.(id).x = [];
        analysis.metrics.(id).y = [];
        analysis.metrics.(id).z = [];
    end
end
analysis.registry = build_channel_plot_registry( ...
    analysis.classification, analysis.metrics);
analysis.continuity_policy = struct( ...
    "mode", continuity, ...
    "blocked_metric_ids", blocked, ...
    "reason", reason);
analysis.warnings = unique([analysis.warnings; reason], "stable");
if analysis.status == "PASS"
    analysis.status = "WARNING";
end
end
