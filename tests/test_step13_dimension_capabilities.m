% Step 13 metrics must follow the 1/3/6/9 input capability classes.
clearvars;
clc;
repoRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, "core")));
addpath(genpath(fullfile(repoRoot, "examples")));
temporaryRoot = string(tempname);
cleanup = onCleanup(@() removeTemporary(temporaryRoot));
names = [ ...
    "narrowband_static_siso_cir.h5", ...
    "wideband_static_siso_cir.h5", ...
    "wideband_static_mimo_cir.h5", ...
    "wideband_dynamic_mimo_cir.h5"];

for index = 1:numel(names)
    paths = prepare_step13_review_data( ...
        fullfile(temporaryRoot, "case_" + index), FixtureName=names(index));
    result = run_channel_benchmark(paths.original_file, paths.prediction_directory);
    metric = result.metrics.prediction;
    assert(result.comparability_status == "PASS");
    assert(isfinite(metric.complex_nmse));
    assert(isfinite(metric.magnitude_nrmse));
    assert(isfinite(metric.phase_mae_rad));
    assert(isfinite(metric.complex_correlation));
    if index == 1
        assert(isnan(metric.pdp_nrmse));
        assert(isnan(metric.spatial_correlation_nrmse));
        assert(isnan(metric.angular_spectrum_nrmse));
        assert(isnan(metric.time_autocorrelation_nrmse));
        assert(isnan(metric.doppler_spectrum_nrmse));
    else
        assert(isfinite(metric.pdp_nrmse));
        assert(isfinite(metric.rms_delay_spread_abs_error_s));
    end
    if index < 3
        assert(isnan(metric.spatial_correlation_nrmse));
        assert(isnan(metric.angular_spectrum_nrmse));
    else
        assert(isfinite(metric.spatial_correlation_nrmse));
        assert(isfinite(metric.angular_spectrum_nrmse));
    end
    if index < 4
        assert(isnan(metric.time_autocorrelation_nrmse));
        assert(isnan(metric.doppler_spectrum_nrmse));
    else
        assert(isfinite(metric.time_autocorrelation_nrmse));
        assert(isfinite(metric.doppler_spectrum_nrmse));
    end
end
fprintf("PASS: Step 13 metrics follow the 1/3/6/9 capability classes.\n");

function removeTemporary(path)
if isfolder(path), rmdir(path, "s"); end
end
