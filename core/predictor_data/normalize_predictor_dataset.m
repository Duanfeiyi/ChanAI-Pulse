function normalized = normalize_predictor_dataset( ...
        dataset, sequence, split, config)
%NORMALIZE_PREDICTOR_DATASET Attach train-only normalization to tensors.

arguments
    dataset (1, 1) struct
    sequence (1, 1) struct
    split (1, 1) struct
    config (1, 1) struct = default_predictor_data_config()
end

manifest = fit_parameter_normalization( ...
    sequence, split.train_group_id, config);
normalized = dataset;
normalized.inputs = apply_parameter_normalization( ...
    dataset.inputs, manifest);
normalized.targets = apply_parameter_normalization( ...
    dataset.targets, manifest);
normalized.normalization = manifest;
normalized.provenance.normalization_fit_scope = ...
    manifest.fit_scope;
end
