function gpu = has_gpu()
gpu = false;
try %#ok
    x = gpuArray(1);
    x = x + 1;
    y = gather( x );
    if y == 2
        gpu = true;
    end
end

end