function config = step11abc_predictor_data_config(stepConfig)
%STEP11ABC_PREDICTOR_DATA_CONFIG Derive a validated predictor-data config.

arguments
    stepConfig (1, 1) struct = default_step11abc_config()
end

config = default_predictor_data_config();
% Existing Step 9 validators intentionally freeze this contract string.
% Step 11ABC records its own version in the corpus manifest instead.
config.schema_version = "v3.0-predictor-data-config.1";
config.supported_parameter_names = stepConfig.parameter_names;
config.standard_parameter_names = stepConfig.parameter_bundles.P2;
config.extrapolation.context_length = stepConfig.data.context_length;
config.extrapolation.target_length = stepConfig.data.target_length;
config.interpolation.left_context_length = stepConfig.data.context_length / 2;
config.interpolation.right_context_length = stepConfig.data.context_length / 2;
config.interpolation.target_length = stepConfig.data.target_length;
config.split.fractions = stepConfig.data.split_fractions;
end
