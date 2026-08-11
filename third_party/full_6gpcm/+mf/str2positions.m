function positions = str2positions(posStrs)
    pat = '(\-?\d+(\.\d+){0,1})';
    pos = str2double(regexp(posStrs, pat, 'match'));
    posMatrix = reshape(pos, 3, length(pos)/3);
    
    positions = posMatrix';
end

