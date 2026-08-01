function defaults = step11abc_versioned_generator_defaults(engineRoot)
%STEP11ABC_VERSIONED_GENERATOR_DEFAULTS One source for offline P8 fallback.
%   Values are read from the existing Full-6GPCM probe adapter rather than
%   duplicated in Python or Step 11ABC scripts.

arguments
    engineRoot (1, 1) string = ""
end
names = default_step11abc_config().parameter_names;
probe = default_full_6gpcm_probe_config(engineRoot);
values = zeros(1, numel(names));
model = struct();
for index = 1:numel(names)
    values(index) = double(probe.(names(index)));
    model.(names(index)) = values(index);
end
model.doppler_hz = 0;
defaults = struct( ...
    "schema_version", "v3.0-step11abc-generator-defaults.1", ...
    "parameter_names", names, ...
    "values", values, ...
    "model", model, ...
    "source", "default_full_6gpcm_probe_config");
end
