function capabilities = build_capability_profile(dataset, validationResult)
%BUILD_CAPABILITY_PROFILE Generate capability profile for Complex-H data.
%   capabilities = build_capability_profile(dataset, validationResult) evaluates
%   the validated dataset and determines its computational boundaries.

disp('::');

capabilities = struct();
capabilities.has_complex_h = false;
capabilities.has_magnitude = false;
capabilities.has_phase = false;
capabilities.phase_coherent = false;
capabilities.has_time_axis = false;
capabilities.has_frequency_axis = false;
capabilities.temporal = false;
capabilities.frequency_domain = false;
capabilities.siso = false;
capabilities.mimo = false;
capabilities.can_compute_pdp = false;
capabilities.can_compute_doppler = false;
capabilities.can_enter_generation = false;
capabilities.can_enter_complex_h_prediction = false;
capabilities.reasons = strings(0, 1);

% If validation failed, downgrade all capabilities
if string(validationResult.status) == "FAIL"
    capabilities.reasons(end+1, 1) = "Validation failed. Capabilities degraded.";
    return;
end

capabilities.has_complex_h = true;
capabilities.has_magnitude = true;

% Enforce phase rules (Legacy Power cannot have phase)
if isfield(dataset, 'representation') && contains(string(dataset.representation), "Legacy Power")
    capabilities.has_phase = false;
    capabilities.reasons(end+1, 1) = "Legacy Power data does not contain valid phase.";
else
    capabilities.has_phase = true;
    capabilities.phase_coherent = true; 
end

% Check physical axes
if isfield(dataset, 'axes')
    if isfield(dataset.axes, 'time_s') && ~isempty(dataset.axes.time_s)
        capabilities.has_time_axis = true;
        capabilities.temporal = true;
    end
    if isfield(dataset.axes, 'frequency_hz') && ~isempty(dataset.axes.frequency_hz)
        capabilities.has_frequency_axis = true;
        capabilities.frequency_domain = true;
    end
end

% Determine SISO vs MIMO
if isfield(dataset, 'antenna')
    if dataset.antenna.num_rx == 1 && dataset.antenna.num_tx == 1
        capabilities.siso = true;
    else
        capabilities.mimo = true;
    end
end

% Derived capabilities based on physical axes
if capabilities.has_frequency_axis
    capabilities.can_compute_pdp = true;
else
    capabilities.reasons(end+1, 1) = "Missing frequency axis; cannot compute PDP with physical units.";
end

if capabilities.has_time_axis
    capabilities.can_compute_doppler = true;
else
    capabilities.reasons(end+1, 1) = "Missing time axis; cannot compute Doppler Hz.";
end

if capabilities.has_complex_h && capabilities.has_time_axis && capabilities.has_frequency_axis
    capabilities.can_enter_generation = true;
    capabilities.can_enter_complex_h_prediction = true;
end
end
