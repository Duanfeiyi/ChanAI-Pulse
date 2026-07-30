function publicConfig = sanitize_generator_config(config)
%SANITIZE_GENERATOR_CONFIG Remove local external paths from exported data.

publicConfig = config;
configured = isfield(publicConfig, "engine_root") && ...
    strlength(strtrim(string(publicConfig.engine_root))) > 0;
publicConfig.engine_root = "";
publicConfig.engine_root_configured = configured;
end
