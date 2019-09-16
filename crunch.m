function crunch(mfile,varargin)
    expected_compressor = {'java','7zip','advzip','zopfli'};

    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p,'input',@(x) exist(x,'file'));
    addParameter(p,'output','',@ischar);
    addParameter(p,'main','z',@ischar);
    addParameter(p,'exe',[]);
    addParameter(p,'verbose',true);
    addParameter(p,'compressor','zopfli',@(x) any(validatestring(x,expected_compressor)))
    parse(p,mfile,varargin{:});

    [inputpath,inputname,inputext] = fileparts(p.Results.input);
    if isempty(inputext)
        inputext = '.m';
    end
    inputfile = fullfile(inputpath,[inputname inputext]);

    [outputpath,outputname] = fileparts(p.Results.output);
    if isempty(outputname)
        outputname = inputname;
    end
    if isempty(outputpath)
       outputpath = inputpath;
    end

    mainfile = [p.Results.main '.m'];
    mainpath = fullfile(outputpath,mainfile);
    archivefile = [outputname '.zip'];
    archive = fullfile(outputpath,archivefile);
    pfile = fullfile(outputpath,[outputname '.p']);

    if ~isempty(outputpath) && ~exist(outputpath,'dir')
        mkdir(outputpath);
    end
    
    copyfile(inputfile,mainpath);
    
    if exist(archive,'file')
        delete(archive);
    end

    origdir = cd;
    if ~isempty(outputpath)
        cd(outputpath);
    end
        
    header_len = -1;
    data_len = -1;
    if strcmp(p.Results.compressor,'zopfli')
        [header_len,data_len] = zopfli_zip(archivefile,mainfile,'exe',p.Results.exe,varargin{:});
    elseif strcmp(p.Results.compressor,'advzip')
        zip(archivefile,mainfile);
        exe = p.Results.exe;
        if isempty(exe)
            exe = 'advzip';
        end
        cmd_f = '%s --shrink-insane -i 100 %s';
        cmd = sprintf(cmd_f,exe,archivefile);
        system(cmd);
    elseif strcmp(p.Results.compressor,'7zip')
        exe = p.Results.exe;
        if isempty(exe)
            exe = '7za';
        end
        cmd_f = '%s a -mx=9 -mtc=off "%s" %s';
        cmd = sprintf(cmd_f,exe,archivefile,mainfile);
        if system(cmd) > 0
            [~,exename,~] = fileparts(exe);    
            cmd = sprintf(cmd_f,which([exename '.exe']),archivefile,mainfile);
            system(cmd);
        end
    else
        zip(archivefile,mainfile);
    end
    
    cd(origdir);
    
    [final_len,pcode_len] = sea(archive,'output',pfile,'main',p.Results.main,varargin{:});
    
    fprintf('Crunched size: %d bytes (pcode: %d, zip-headers: %d, deflated-data: %d)\n',final_len,pcode_len,header_len,data_len);
end


