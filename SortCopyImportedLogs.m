function SortCopyImportedLogs(importFolderPath, moveFiles, repoBasePath)
% Copy/move-sort logs from importFolderPath folder
% The program will create sub folders according to motorcycle model
% Only new files will be copied/moved

% input parameters are optional. In case one of the folders doesn't exist,
% the script will call GetFolderUI

% It is possible to enter relative paths (ex. '..\..\D8141\GS911 Logs')

%% process input parameters
if exist('SortCopyImportedLogs.mat','file')
    load('SortCopyImportedLogs.mat');
end

if nargin < 3
    if exist('repoBasePathSaved','var')
        repoBasePath = repoBasePathSaved; %#ok<NODEF>
    else
        repoBasePath = cd;
    end
end

%check whether the repo folder exist
if ~exist(repoBasePath,'file')
    repoBasePath=uigetdir(cd,'Select Repo Base Folder');
    if ~repoBasePath % exit if cancel clicked
        return
    end
end

if nargin < 2
    if exist('inputParamsSaved','var')
        moveFiles = moveFilesSaved; %#ok<NODEF>
    else
        moveFiles = false;
    end
end

if nargin < 1
    if exist('importFolderPathSaved','var')
        importFolderPath = importFolderPathSaved; %#ok<NODEF>
    else
        importFolderPath = fullfile(repoBasePath,'Imported');
    end
end
%check whether the import folder exist
if ~exist(importFolderPath,'file')
    importFolderPath=uigetdir(cd,'Select folder with logs to import');
    if ~importFolderPath % exit if cancel clicked
        return
    end
end

%% save the paths and other parameters for future use (without input parameters)
importFolderPathSaved = importFolderPath; %#ok<NASGU>
repoBasePathSaved = repoBasePath; %#ok<NASGU>
moveFilesSaved = moveFiles; %#ok<NASGU>
save('SortCopyImportedLogs.mat','importFolderPathSaved','repoBasePathSaved','moveFilesSaved');


%% the body of the script
disp(['Logs repo base path: "' repoBasePath '"'])
disp(['Logs folder to import: "' importFolderPath '"'])
if moveFiles
    disp('Move files: True')
else
    disp('Move files: False')
end



files=dir(fullfile(importFolderPath,'\*.csv'));
files=[files; dir(fullfile(importFolderPath,'\*.txt'))];

disp(['Found ' num2str(length(files)) ' files'])


for m=1:length(files)
    
    % Import the file
    try
        rawData = importdata(fullfile(importFolderPath, files(m).name), ';', 6);
    catch
        error(['Error occured during opening "' files(m).name '" file']);
    end
    
    
    % read the date stamp.
    start_date_str=[]; %#ok<NASGU>
    start_date=[];
    
    try
        start_date_str=char(rawData.textdata{2,1});
        start_date_str=start_date_str(2:end);
        start_date=datenum(start_date_str);
        
        
        motorcycle_model=char(rawData.textdata{4,1});
        motorcycle_model=motorcycle_model(2:end);
    catch
        warning(['Error occured during reading timestamp/motorcycle model in "' files(m).name '" file']);
    end
    
    
    % if data extract was successful
    if ~isempty(start_date)
        
        % check date range to eliminate corrupted data
        
        if (start_date>now) || (start_date<733408)
            disp(['Date was out of range [2008->' datestr(now) '] in "' files(m).name '"'])
            disp(['Skipping "'  files(m).name '"'])
            continue
        end
        
        % at this point the date extract is succesfull. continue with
        % renaming
        start_date_str=datestr(start_date,'yyyy-mm-dd HH-MM-SS');
        new_name=[start_date_str ' - ' motorcycle_model ' - GS911 log' files(m).name(end-3:end)];
        newPathStr=fullfile(repoBasePath, motorcycle_model);
        
        if ~exist(newPathStr,'file')
            mkdir(newPathStr);
        end
        
        if ~exist(fullfile(newPathStr, new_name),'file')
            if ~moveFiles
                disp([num2str(m) '. Copying "' files(m).name '" -> "' fullfile(motorcycle_model, new_name) '"'])
                copyfile(fullfile(importFolderPath, files(m).name),fullfile(newPathStr, new_name));
            else
                disp([num2str(m) '. Moving "' files(m).name '" -> "' fullfile(motorcycle_model, new_name) '"'])
                movefile(fullfile(importFolderPath, files(m).name),fullfile(newPathStr, new_name));
                
            end
        else
            disp([num2str(m) '. ***Skipping - File exists in Destination "' files(m).name '" -> "' fullfile(motorcycle_model, new_name) '"'])
        end
        
    else
        disp([num2str(m) '. ***Skipping file:' files(m).name])
    end
end


