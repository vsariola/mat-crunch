function compress(input,varargin)

SEVEN_ZIP = 'c:\Program Files\7-Zip\7z.exe';

expectedMfilename = {'none','filename','full'};

p = inputParser;
addRequired(p,'input',@(x) exist(x,'file'));
addOptional(p,'output','',@ischar);
addParameter(p,'remove_temp',true);   
addParameter(p,'seven_zip',[]); 
addParameter(p,'allow_move','full',@(x) any(validatestring(x,expectedMfilename)))
parse(p,input,varargin{:});
    
[inputpath,inputname,inputext] = fileparts(p.Results.input);
if isempty(inputext)
    inputext = '.m';
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

if ~exist(outputpath,'dir')
    mkdir(outputpath);
end

mainfilename = sprintf('%s%s',p.Results.main,inputext);
mainfilepath = sprintf('%s/%s',outputpath,mainfilename);
mainzip = sprintf('%s/main.zip',outputpath);
copyfile(inputfile,mainfilepath);
a = cd();
cd(outputpath);
if exist('main.zip','file')
    delete('main.zip');
end
if exist(SEVEN_ZIP,'file')
    command = ['"' SEVEN_ZIP '" a -mx=9 -mtc=off main.zip "' sprintf('%s',mainfilename) '"'];
    system(command);
else
    zip('main.zip',sprintf('%s',mainfilename));
end
cd(a);
if p.Results.cleanbuild
    delete(mainfilepath);
end

fin = fopen(mainzip);
d = fread(fin);
fclose(fin);

all_codes = (0:255);
valid_codes = all_codes(~ismember(all_codes,invalid_bytes));
counts = sum(d==valid_codes);
counts(valid_codes>=10) = counts(valid_codes>=10)+1;
counts(valid_codes>=100) = counts(valid_codes>=100)+1;
[~,code_ind] = min(counts);
code = valid_codes(code_ind);

specials = [invalid_bytes code];
for shift = -9:10
    shifted = specials+shift;
    if any(ismember(mod(shifted,256),specials)) || any(shifted<0) || any(shifted>255)
        continue;
    end
    break;
end

if shift == 10
    error('Cannot find single digit shift');
end

header = 'k=fread(fopen([mfilename(''fullpath'') ''.m'']));k=k(%d:end)';

header = [header sprintf(';i=k==%d',code)];

if shift > 0
    if any(specials+shift>255)
        header = [header sprintf(';s=mod(k-[i(2:end);0]*%d,256)',shift)];
    else
        header = [header sprintf(';s=k-[i(2:end);0]*%d',shift)];
    end
else
    if any(specials+shift<0)
        header = [header sprintf(';s=mod(k+[i(2:end);0]*%d,256)',-shift)];
    else
        header = [header sprintf(';s=k+[i(2:end);0]*%d',-shift)];
    end
end                          

header = [header ';Y=[tempname 47];mkdir(Y);t=[Y 65]']; % d=.../, t=.../A
header = [header ';fwrite(fopen(t,''w''),s(~i));fclose all'];
header = [header sprintf(';unzip(t,Y)')];
header = [header sprintf(';run([Y %d]);rmdir(Y,''s'')',uint8(p.Results.main))];
header = [header '%%'];

s = length(header)-3;
finalheader = '';
while s ~= length(finalheader)      
    s = s+1;
	finalheader = sprintf(header,s+1);    
end

if p.Results.cleanbuild
    delete(mainzip);
end
   
k = [];
for i = d'
    if ismember(i,specials)
        k = [k mod(i+shift,256) code];
    else
        k = [k i];
    end   
end

fout = fopen(outputfile,'w');
fwrite(fout,finalheader);
fwrite(fout,k);
fclose(fout);
