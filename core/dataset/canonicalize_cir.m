function [cir, info] = canonicalize_cir(cirInput)
%CANONICALIZE_CIR Normalize CIR arrays to antenna-by-delay-by-snapshot.
%   [cir, info] = canonicalize_cir(cirInput) preserves numeric values and
%   complex values while removing singleton dimensions. The returned CIR is
%   always three-dimensional: [antenna, delay_or_frequency, snapshot].

if ~isnumeric(cirInput)
    error("canonicalize_cir:InvalidType", "CIR input must be numeric.");
end

if isempty(cirInput)
    error("canonicalize_cir:EmptyInput", "CIR input must not be empty.");
end

originalSize = size(cirInput);
reduced = squeeze(cirInput);

if isscalar(reduced)
    cir = reshape(reduced, 1, 1, 1);
elseif isvector(reduced)
    cir = reshape(reduced, 1, numel(reduced), 1);
elseif ndims(reduced) == 2
    cir = reshape(reduced, size(reduced, 1), size(reduced, 2), 1);
elseif ndims(reduced) == 3
    cir = reduced;
else
    error("canonicalize_cir:UnsupportedDimensions", ...
        "CIR input has %d non-singleton dimensions; expected at most 3.", ndims(reduced));
end

info = struct();
info.original_size = originalSize;
info.canonical_size = [size(cir, 1), size(cir, 2), size(cir, 3)];
info.is_complex = ~isreal(cir);
info.layout = "antenna_by_delay_or_frequency_by_snapshot";
end
