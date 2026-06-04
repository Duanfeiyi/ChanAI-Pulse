function value = compute_nrmse(rmseValue, truth)
%COMPUTE_NRMSE Normalized RMSE percentage used by the App.

value = rmseValue / (max(truth(:)) - min(truth(:))) * 100;
end

