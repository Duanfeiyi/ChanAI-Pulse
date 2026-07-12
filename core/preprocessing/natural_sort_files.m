function [sortedNames, order] = natural_sort_files(names)
%NATURAL_SORT_FILES Sort file names by embedded numeric values.

names = string(names(:));
keys = strings(size(names));

for idx = 1:numel(names)
    keys(idx) = makeNaturalKey(names(idx));
end

[~, order] = sort(keys);
sortedNames = names(order);
end

function key = makeNaturalKey(name)
parts = regexp(char(name), '(\d+)', 'split');
numbers = regexp(char(name), '(\d+)', 'match');
key = lower(string(parts{1}));

for idx = 1:numel(numbers)
    key = key + sprintf('%012d', str2double(numbers{idx})) + lower(string(parts{idx + 1}));
end
end

