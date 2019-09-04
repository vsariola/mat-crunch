function ret = from_le(bytes)
    ret = sum(bytes .* 2.^(0:8:length(bytes)*8-8));
end