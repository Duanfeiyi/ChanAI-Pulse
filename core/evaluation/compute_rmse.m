function value = compute_rmse(predicted, truth)
%COMPUTE_RMSE Root mean squared error.

value = sqrt(mean((predicted(:) - truth(:)).^2));
end

