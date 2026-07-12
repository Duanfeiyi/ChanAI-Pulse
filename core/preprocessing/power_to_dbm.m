function powerDbm = power_to_dbm(powerW)
%POWER_TO_DBM Convert nonnegative power values in watts to dBm.

if ~isnumeric(powerW) || ~isreal(powerW)
    error("power_to_dbm:InvalidInput", "Power input must be a real numeric array.");
end

if any(powerW(:) < 0)
    error("power_to_dbm:NegativePower", "Power input must not contain negative values.");
end

powerDbm = 10 .* log10(max(double(powerW), realmin("double")) ./ 1e-3);
end

