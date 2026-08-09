function report = validate_mat_channel_mapping(mapping, variableInfo)
%VALIDATE_MAT_CHANNEL_MAPPING Validate explicit MAT variable/axis mapping.

arguments
    mapping (1, 1) struct
    variableInfo = struct([])
end

errors = strings(0, 1);
warnings = strings(0, 1);
required = ["domain", "complex_variable", "real_variable", ...
    "imag_variable", "source_dimension_order"];
for name = required
    if ~isfield(mapping, name)
        errors(end + 1, 1) = "Missing mapping field: " + name; %#ok<AGROW>
    end
end
if ~isempty(errors)
    report = finish(errors, warnings);
    return;
end

domain = lower(string(mapping.domain));
if ~ismember(domain, ["cir", "ctf"])
    errors(end + 1, 1) = "domain must be cir or ctf.";
end
hasComplex = strlength(string(mapping.complex_variable)) > 0;
hasPair = strlength(string(mapping.real_variable)) > 0 && ...
    strlength(string(mapping.imag_variable)) > 0;
if hasComplex == hasPair
    errors(end + 1, 1) = ...
        "Choose either one complex variable or one explicit real/imaginary pair.";
end

order = string(mapping.source_dimension_order(:)).';
axisName = "Npath";
if domain == "ctf", axisName = "Nf"; end
allowed = ["Tx", "Rx", axisName, "Nt", "N_sample"];
if isempty(order)
    errors(end + 1, 1) = "Confirm the source dimension order.";
elseif numel(unique(order)) ~= numel(order) || any(~ismember(order, allowed))
    errors(end + 1, 1) = "Dimension order must use each canonical axis at most once: " + ...
        strjoin(allowed, ", ") + ".";
end

if ~isempty(variableInfo)
    names = string({variableInfo.name});
    selected = string(mapping.complex_variable);
    if selected == "", selected = string(mapping.real_variable); end
    index = find(names == selected, 1);
    if isempty(index)
        errors(end + 1, 1) = "Selected channel variable does not exist: " + selected;
    elseif numel(variableInfo(index).size) ~= numel(order)
        errors(end + 1, 1) = sprintf( ...
            "Dimension order has %d labels but variable %s has %d stored dimensions.", ...
            numel(order), selected, numel(variableInfo(index).size));
    end
    if hasPair
        realIndex = find(names == string(mapping.real_variable), 1);
        imagIndex = find(names == string(mapping.imag_variable), 1);
        if isempty(realIndex) || isempty(imagIndex)
            errors(end + 1, 1) = "Selected real/imaginary variables do not both exist.";
        elseif ~isequal(variableInfo(realIndex).size, variableInfo(imagIndex).size)
            errors(end + 1, 1) = "Real and imaginary variable dimensions do not match.";
        end
    end
end

if domain == "cir"
    hasDelayVariable = isfield(mapping, "delay_variable") && ...
        strlength(string(mapping.delay_variable)) > 0;
    hasDelayStep = isfield(mapping, "delay_bin_spacing_s") && ...
        isPositiveScalar(mapping.delay_bin_spacing_s);
    if ~hasDelayVariable && ~hasDelayStep
        errors(end + 1, 1) = ...
            "CIR conversion requires a delay variable or delay_bin_spacing_s.";
    end
end

report = finish(errors, warnings);
end

function report = finish(errors, warnings)
report = struct("is_valid", isempty(errors), ...
    "status", "PASS", "errors", errors, "warnings", warnings);
if ~isempty(errors)
    report.status = "FAIL";
elseif ~isempty(warnings)
    report.status = "WARNING";
end
end

function tf = isPositiveScalar(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value) && value > 0;
end
