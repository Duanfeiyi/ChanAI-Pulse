function selection = select_generator_backend(requestedBackend, dimensions, options)
%SELECT_GENERATOR_BACKEND Resolve a production generator before execution.
%   Automatic mode tries every registered production backend in priority
%   order. Test doubles are deliberately excluded. A backend is eligible
%   only when it is both available and able to preserve Tx, Rx and Nt.

arguments
    requestedBackend (1, 1) string
    dimensions (1, 1) struct
    options.FullEngineRoot (1, 1) string = ""
end

requestedBackend = canonicalRequestedBackend(requestedBackend);
required = ["Tx", "Rx", "Nt"];
for name = required
    if ~isfield(dimensions, name) || ~isscalar(dimensions.(name)) || ...
            ~isfinite(dimensions.(name)) || dimensions.(name) < 1
        error("select_generator_backend:InvalidDimensions", ...
            "dimensions.%s must be a positive finite scalar.", name);
    end
end

if requestedBackend == "auto"
    backends = ["lite_6gpcm", "full_6gpcm"];
    source = "automatic";
else
    backends = requestedBackend;
    source = "manual";
end

emptyCandidate = struct( ...
    "backend", "", "compatible", false, "available", false, ...
    "adapter_variant", "", ...
    "selected", false, "reason_code", "", "reason", "", ...
    "errors", strings(0, 1), "warnings", strings(0, 1));
candidates = repmat(emptyCandidate, numel(backends), 1);
selectedIndex = 0;

for index = 1:numel(backends)
    backend = backends(index);
    candidate = emptyCandidate;
    candidate.backend = backend;
    [candidate.compatible, candidate.adapter_variant, ...
        candidate.reason_code, candidate.reason] = ...
        checkDimensions(backend, dimensions);

    config = default_generator_config(backend);
    config.dimensions.Tx = double(dimensions.Tx);
    config.dimensions.Rx = double(dimensions.Rx);
    config.dimensions.Nt = double(dimensions.Nt);
    config.dimensions.Npath = 0;
    if isfield(dimensions, "N_sample") && dimensions.N_sample >= 1
        config.dimensions.N_sample = double(dimensions.N_sample);
    end
    if backend == "full_6gpcm"
        config.engine_root = options.FullEngineRoot;
        config.backend_options.full_interface = candidate.adapter_variant;
    end

    if candidate.compatible
        probe = probe_generator_backend(config);
        candidate.available = logical(probe.available);
        candidate.errors = string(probe.errors(:));
        candidate.warnings = string(probe.warnings(:));
        if candidate.available
            candidate.reason_code = "compatible_and_available";
            candidate.reason = backendLabel(backend) + ...
                " supports the requested Tx/Rx/Nt dimensions and is available.";
        else
            candidate.reason_code = "backend_unavailable";
            candidate.reason = backendLabel(backend) + ...
                " matches the requested dimensions but is unavailable: " + ...
                strjoin(candidate.errors, " | ");
        end
    end

    candidates(index) = candidate;
    if selectedIndex == 0 && candidate.compatible && candidate.available
        selectedIndex = index;
        candidates(index).selected = true;
    end
end

selection = struct( ...
    "schema_version", "v3.0-generator-selection.1", ...
    "success", selectedIndex > 0, ...
    "requested_backend", requestedBackend, ...
    "selected_backend", "", ...
    "selected_adapter_variant", "", ...
    "source", source, ...
    "reason_code", "no_eligible_backend", ...
    "reason", "", ...
    "registered_production_backends", ["lite_6gpcm", "full_6gpcm"], ...
    "candidates", candidates);
if selectedIndex > 0
    selection.selected_backend = candidates(selectedIndex).backend;
    selection.selected_adapter_variant = candidates(selectedIndex).adapter_variant;
    selection.reason_code = candidates(selectedIndex).reason_code;
    selection.reason = candidates(selectedIndex).reason;
else
    selection.reason = "No registered production generator is both " + ...
        "dimension-compatible and available.";
end
end

function [compatible, variant, code, reason] = checkDimensions(backend, dimensions)
switch backend
    case "lite_6gpcm"
        variant = "lite_native";
        compatible = dimensions.Tx == 1 && dimensions.Rx == 1;
        code = "lite_requires_siso";
        reason = "Lite requires Tx=1 and Rx=1; requested Tx=" + ...
            dimensions.Tx + ", Rx=" + dimensions.Rx + ".";
    case "full_6gpcm"
        if dimensions.Tx == 2 && dimensions.Rx == 2 && dimensions.Nt == 2
            variant = "fixed_entrypoint";
        else
            variant = "public_api";
        end
        defaults = default_generator_config("full_6gpcm");
        options = defaults.backend_options;
        compatible = dimensions.Tx * dimensions.Rx <= ...
            options.full_max_antenna_pairs && ...
            dimensions.Nt <= options.full_max_nt && ...
            dimensions.Tx * dimensions.Rx * dimensions.Nt <= ...
            options.full_max_tensor_slices;
        code = "full_resource_limit_exceeded";
        reason = "Requested Tx/Rx/Nt exceeds the configured Full 6GPCM resource budget.";
    otherwise
        variant = "";
        compatible = false;
        code = "unregistered_backend";
        reason = "The backend is not registered for production use.";
end
if compatible
    code = "dimension_compatible";
    reason = backendLabel(backend) + " preserves the requested Tx/Rx/Nt dimensions.";
end
end

function value = canonicalRequestedBackend(value)
value = lower(strtrim(string(value)));
switch value
    case {"auto", "automatic"}
        value = "auto";
    case {"lite", "6gpcm-lite", "lite_6gpcm"}
        value = "lite_6gpcm";
    case {"full", "6gpcm", "full_6gpcm", "full_6gpcm_external"}
        value = "full_6gpcm";
    otherwise
        error("select_generator_backend:UnsupportedBackend", ...
            "Unsupported generator backend selection: %s", value);
end
end

function label = backendLabel(backend)
if backend == "lite_6gpcm"
    label = "6GPCM-Lite";
else
    label = "Full 6GPCM";
end
end
