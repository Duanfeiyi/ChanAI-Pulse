function publicConfig = sanitize_grid_search_config(config)
%SANITIZE_GRID_SEARCH_CONFIG Remove local-only paths from public records.

publicConfig = config;
if isfield(publicConfig, "generator_config") && ...
        isstruct(publicConfig.generator_config)
    publicConfig.generator_config = ...
        sanitize_generator_config(publicConfig.generator_config);
end
end
