function [x_ds,y_out] = calc_cdf(x_in,num)
x_ds = linspace(min(x_in), max(x_in),num);
y_ds = hist(x_in, x_ds)/length(x_in);
y_ds(end) = 0;
y_out = cumsum(y_ds);