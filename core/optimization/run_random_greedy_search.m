function result = run_random_greedy_search(targetDataset, config, options)
%RUN_RANDOM_GREEDY_SEARCH Step 8 comparison baseline; never accepts worse.

arguments
    targetDataset (1, 1) struct
    config (1, 1) struct
    options (1, 1) struct = struct()
end

result = run_stochastic_optimizer( ...
    targetDataset, config, "random_greedy", options);
end
