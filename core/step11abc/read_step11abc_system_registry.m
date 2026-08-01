function registry = read_step11abc_system_registry(registryPath, options)
%READ_STEP11ABC_SYSTEM_REGISTRY Validate a frozen Step 11ABC system choice.
%   The loader rejects selections that used test truth and verifies the
%   selected model-registry hashes before a product can consume the choice.

arguments
    registryPath (1, 1) string
    options.RequireFinalTest (1, 1) logical = true
end
if ~isfile(registryPath)
    error("read_step11abc_system_registry:MissingFile", ...
        "Registry does not exist: %s", registryPath);
end
registry = jsondecode(fileread(registryPath));
schema = string(registry.schema_version);
supported = ["v3.0-step11abc-bundle-selection.2", ...
    "v3.0-step11abc-system-registry.1"];
if ~any(schema == supported)
    error("read_step11abc_system_registry:UnsupportedSchema", ...
        "Unsupported system-registry schema: %s", schema);
end
if ~isfield(registry, "test_truth_used_for_selection") || ...
        logical(registry.test_truth_used_for_selection)
    error("read_step11abc_system_registry:TestLeakage", ...
        "The registry does not prove validation-only selection.");
end
if ~isfield(registry, "decisions") || ...
        ~all(isfield(registry.decisions, ...
        {'interpolation', 'extrapolation'}))
    error("read_step11abc_system_registry:MissingDecision", ...
        "Both interpolation and extrapolation decisions are required.");
end
if ~isfield(registry, "delay_grid") || ...
        string(registry.delay_grid.frozen_from_partition) ~= ...
        "validation_truth_only" || ...
        ~logical(registry.delay_grid.overflow_bin_enabled) || ...
        numel(registry.delay_grid.finite_edges_s) < 2 || ...
        any(~isfinite(registry.delay_grid.finite_edges_s)) || ...
        any(diff(double(registry.delay_grid.finite_edges_s)) <= 0)
    error("read_step11abc_system_registry:UnsafeDelayGrid", ...
        "The PDP delay grid must be frozen from validation truth only.");
end
if options.RequireFinalTest && schema ~= ...
        "v3.0-step11abc-system-registry.1"
    error("read_step11abc_system_registry:FinalTestRequired", ...
        "A selection-only manifest cannot be used as a final registry.");
end
if schema == "v3.0-step11abc-system-registry.1"
    if string(registry.selection_partition) ~= "validation" || ...
            string(registry.final_evaluation_partition) ~= "test" || ...
            string(registry.status) ~= "frozen_and_tested"
        error("read_step11abc_system_registry:InvalidLifecycle", ...
            "System registry lifecycle fields are inconsistent.");
    end
end
verifySelectedRegistries(registry.selected_model_registries);
end

function verifySelectedRegistries(records)
for index = 1:numel(records)
    path = string(records(index).path);
    if ~isfile(path)
        error("read_step11abc_system_registry:ModelRegistryMissing", ...
            "Selected model registry is missing: %s", path);
    end
    actual = sha256File(path);
    if ~strcmpi(actual, string(records(index).sha256))
        error("read_step11abc_system_registry:HashMismatch", ...
            "Selected model registry changed after bundle selection: %s", path);
    end
end
end

function value = sha256File(path)
fid = fopen(path, "rb");
if fid < 0
    error("read_step11abc_system_registry:CannotHash", ...
        "Cannot read %s", path);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
digest = javaMethod("getInstance", ...
    "java.security.MessageDigest", "SHA-256");
while ~feof(fid)
    bytes = fread(fid, 1024 * 1024, "*uint8");
    if ~isempty(bytes)
        digest.update(typecast(uint8(bytes(:)), "int8"));
    end
end
raw = typecast(int8(digest.digest()), "uint8");
value = lower(string(reshape(dec2hex(raw, 2).', 1, [])));
end
