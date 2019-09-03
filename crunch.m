function crunch(mfile,varargin)

    p = inputParser;
    addRequired(p,'input',@(x) exist(x,'file'));
    addParameter(p,'output','',@ischar);
    addParameter(p,'main','k',@ischar);
    addParameter(p,'sevenzip','7za.exe');
    addParameter(p,'advzip','advzip.exe');
    addParameter(p,'minify',true);
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
        
    if exist(p.Results.sevenzip,'file')
        command = ['"' which(p.Results.sevenzip) '" a -mx=9 -mtc=off "' archivefile '" ' mainfile];
        system(command);
    else
        zip(archivefile,sprintf('%s',mainfile));
    end
    cd(origdir);

    if exist(p.Results.advzip,'file')
        command = ['"' which(p.Results.advzip) '" --shrink-insane -i 100 "' archive '"'];
        % system(command);
    end

    sea(archive,'output',pfile);
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
    


