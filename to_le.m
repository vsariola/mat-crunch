function bytes = to_le(value,numbytes)    
    bytes = arrayfun(@(x)mod(bitshift(value,-x),256),0:8:numbytes*8-8);
end