function zopfli_zip(output,input,varargin)
    p = inputParser;
    addRequired(p,'output');
    addRequired(p,'input');
    addParameter(p,'iter',100);
    addParameter(p,'exe',[]);
    parse(p,output,input,varargin{:});
    
    exe = p.Results.exe;
    if isempty(exe)
        exe = 'zopfli';
    end

    cmd_f = '%s -i %d --deflate "%s"';
    cmd = sprintf(cmd_f,exe,p.Results.iter,p.Results.input);
    status = system(cmd);
    if status > 0
        error('Zopfli failed');
    end
    compressed_data = readfile([input '.deflate']);
    delete([input '.deflate']);
    uncompressed_data = readfile(input);
    [~,inputname,inputext] = fileparts(p.Results.input);
    inputfile = [inputname inputext];
    
    c32 = crc32(uncompressed_data);
    
    fh_start = fromhex('504b0304140002000800');

     % no need to repeat the filename in local header - matlab unzip seems
     % to use only the filename from central directory
    fh = zeros(1,30);
    fh(1:length(fh_start)) = fh_start;
    fh(15:18) = to_le(c32,4);
    fh(19:22) = to_le(length(compressed_data),4);
    fh(23:26) = to_le(length(uncompressed_data),4);        
    
    cdfh_start = fromhex('504b01023f00140002000800');
    
    cdfh = zeros(1,46+length(inputfile));
    cdfh(1:length(cdfh_start)) = cdfh_start;
    cdfh(17:20) = to_le(crc32(uncompressed_data),4);
    cdfh(21:24) = to_le(length(compressed_data),4);
    cdfh(25:28) = to_le(length(uncompressed_data),4);
    cdfh(29:30) = to_le(length(inputfile),2);
    cdfh(47:end) = inputfile;
    
    eocd_start = fromhex('504b05060000000001000100');
    eocd = zeros(1,22);
    eocd(1:length(eocd_start)) = eocd_start;
    eocd(13:14) = to_le(length(cdfh),2);
    eocd(17:20) = to_le(length(fh)+length(compressed_data),4);

    data = [fh compressed_data cdfh eocd];
    
    writefile(output,data);
end

function bytes = fromhex(str)
    bytes = hex2dec(reshape(str,2,[])');
end

