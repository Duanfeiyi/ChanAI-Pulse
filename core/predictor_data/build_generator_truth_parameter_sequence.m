function sequence = build_generator_truth_parameter_sequence( ...
        values, parameterNames, options)
%BUILD_GENERATOR_TRUTH_PARAMETER_SEQUENCE Mark exact generator parameters.

arguments
    values double
    parameterNames
    options (1, 1) struct = struct()
end

options.label_source = "generator_truth";
options.fit_score = nan(size(values, 1), 1);
options.quality_status = "PASS";
if ~isfield(options, "provenance")
    options.provenance = struct();
end
options.provenance.label_meaning = ...
    "Exact parameters used by a deterministic channel generator.";
options.provenance.recommended_usage = ...
    "Generic pretraining and contract tests.";
sequence = create_parameter_sequence(values, parameterNames, options);
end
