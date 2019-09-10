function sea(archive,varargin)
    expected_rename = {'none','partial','full'};

    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p,'input');
    addParameter(p,'output','',@ischar);
    addParameter(p,'remove_temp',true);   
    addParameter(p,'use_tempdir',true);   
    addParameter(p,'var1','a'); 
    addParameter(p,'var2','r'); 
    addParameter(p,'main','z'); 
    addParameter(p,'cache',true); 
    addParameter(p,'rename_support','full',@(x) any(validatestring(x,expected_rename)))
    parse(p,archive,varargin{:});
    
    [inputpath,inputname,inputext] = fileparts(p.Results.input);
    if isempty(inputext)
        inputext = '.zip';
    end
    inputfile = fullfile(inputpath,[inputname inputext]);

    [outputpath,outputname,outputext] = fileparts(p.Results.output);
    if isempty(outputext)
        outputext = '.p';
    end
    if isempty(outputname)
        outputname = inputname;
    end
    if isempty(outputpath)
       outputpath = inputpath;
    end
    outputfile = fullfile(outputpath,[outputname outputext]);
    
    if p.Results.use_tempdir
        f = '%1$s=tempname,%2$s=unzip(%3$s,%1$s),run(%2$s{1})';
        if p.Results.remove_temp
            f = [f ',rmdir(%1$s,''s'')'];
        end
        if strcmp(p.Results.rename_support,'full')
            namecmd = 'which(mfilename)';
        elseif strcmp(p.Results.rename_support,'partial')
            namecmd = '[mfilename,''.p'']';
        else
            namecmd = ['''' outputname outputext ''''];
        end
    else
        f = 'unzip%3$s;run %4$s';
        if p.Results.remove_temp
            f = [f ';delete %4$s.m'];
        end
        if strcmp(p.Results.rename_support,'full')
            namecmd = '(which(mfilename))';
        elseif strcmp(p.Results.rename_support,'partial')
            namecmd = '([mfilename,''.p''])';
        else
            namecmd = [' ' outputname outputext ''];
        end
    end

    scr = sprintf(f,p.Results.var1,p.Results.var2,namecmd,p.Results.main);
    
    scriptfile = ['s' num2str(hash(scr))];
    
    if p.Results.cache
        scriptfile = ['cache/' scriptfile];
        if ~exist('cache','dir')
            mkdir('cache');
        end
    else
        scriptfile = [tempname '/' scriptfile];
    end
    
    if ~exist([scriptfile '.m'],'file')
        writefile([scriptfile '.m'],scr);
    end
    
    if ~exist([scriptfile '.p'],'file')
        pcode([scriptfile '.m'],'-inplace');
    end

    pscr = readfile([scriptfile '.p']);
    
    if ~p.Results.cache
        delete([scriptfile '.m']);
        delete([scriptfile '.p']);
    end
   
    data = readfile(inputfile);
    data = offset_pointers(data,length(pscr));
    
    if ~isempty(outputpath) && ~exist(outputpath,'dir')
        mkdir(outputpath);
    end
    
    writefile(outputfile,[pscr data]);
end

function ret = hash(str)
    ret = 5381*ones(size(str,1),1); 
    for i=1:size(str,2)
        ret = mod(ret * 33 + str(:,i), 2^32-1); 
    end
end

function data = offset_pointers(data,offset)
    signature = hex2dec('06054b50');
    for i = length(data)-3:-1:1
        if from_le(data(i:i+3)) == signature
            dirpos = from_le(data(i+16:i+19));
            numrecords = from_le(data(i+10:i+11));
            data(i+16:i+19) = to_le(dirpos+offset,4);
            j = dirpos+1;
            for n = 1:numrecords
                filenamelen = from_le(data(j+28:j+29));
                extralen = from_le(data(j+30:j+31));
                comlen = from_le(data(j+32:j+33));
                filepos = from_le(data(j+42:j+45));
                data(j+42:j+45) = to_le(filepos+offset,4);
                j = j + filenamelen + extralen + comlen;
            end
        end
    end
   
end

function ret = from_le(bytes)
    ret = sum(bytes .* 2.^(0:8:length(bytes)*8-8));
end

function bytes = to_le(value,numbytes)    
    bytes = arrayfun(@(x)mod(bitshift(value,-x),256),0:8:numbytes*8-8);
end

function writefile(filename,str)
    f = fopen(filename,'w');
    fwrite(f,str);
    fclose(f);
end

function str = readfile(filename)
    f = fopen(filename);
    str = fread(f)';
    fclose(f);
end