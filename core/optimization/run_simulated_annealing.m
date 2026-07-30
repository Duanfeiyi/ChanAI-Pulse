function result = run_simulated_annealing(targetDataset, config, options)
%RUN_SIMULATED_ANNEALING Fit generator parameters with transparent SA.

arguments
    targetDataset (1, 1) struct
    config (1, 1) struct
    options (1, 1) struct = struct()
end

result = run_stochastic_optimizer(targetDataset, config, "sa", options);
end
