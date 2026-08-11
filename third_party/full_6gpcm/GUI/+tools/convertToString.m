function outStr = convertToString(value)
if isnumeric(value) || islogical(value)
    outStr = num2str(value);
elseif ischar(value) || isstring(value)
    outStr = value;
else
    outStr = 'Invalid Data';
end

end