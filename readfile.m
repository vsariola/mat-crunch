function str = readfile(filename)
    f = fopen(filename);
    str = fread(f)';
    fclose(f);
end
    