function SortCopyImportedLogs(basePath)
% Copy-sort logs from "imported folder
% The program will create sub folders according to motorcycle model
% Only new files will be copied

% input parameter(optional) the folder which contains "Imported" folder
% if not provided, the UI will promt for the base folder



impFld='Imported';


if nargin>0
    pathstr=basePath;
else
    if exist('SortCopyImportedLogs.mat','file')
        load('SortCopyImportedLogs.mat');
        if ~exist(pathstr,'file') %#ok<NODEF>
            pathstr=uigetdir(pathstr,'Select Base Folder. The folder that contains "Imported" folder');
            if ~pathstr % exit if cancel clicked
                return
            end
            
        end
        
    else
        pathstr=cd;
    end
    
    save('SortCopyImportedLogs.mat','pathstr');
    
    % pathstr='D:\Temp\gs911 - logs sorting try';
end


if ~exist([pathstr '\' impFld],'file')
    error(['Folder "' impFld '" was not found in "' pathstr '"'])
end

disp(['Loaded base path: "' pathstr '"'])


files=dir([pathstr '\' impFld '\*.csv']);
files=[files; dir([pathstr '\' impFld '\*.txt'])];

disp(['Found ' num2str(length(files)) ' files'])


for m=1:length(files)
    
    % Import the file
    try
        rawData = importdata([pathstr '\' impFld '\' files(m).name], ';', 6);
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
        
        %         % if the new name equals to old name, skip the rename
        %         if strcmpi(files(m).name,new_name)
        %             disp(['***Skipping file(filename is ok) :' files(m).name])
        %             continue
        %         end
        
        newPathStr=[pathstr '\' motorcycle_model];
        
        
        %         % check if this file name already exists
        %         counter=0;
        %         while ~isempty(dir([pathstr '\' new_name]))
        %             counter=counter+1;
        %             new_name=[start_date_str ' - ' motorcycle_model ' - GS911 log_' num2str(counter) files(m).name(end-3:end)];
        %         end
        %
        
        
        if ~exist(newPathStr,'file')
            mkdir(newPathStr);
        end
        
        
        if ~exist([newPathStr '\' new_name],'file')
            disp([num2str(m) '. Copying "' files(m).name '" -> "' motorcycle_model '\' new_name '"'])
            copyfile([pathstr '\' impFld '\' files(m).name],[newPathStr '\' new_name]);
        else
            disp([num2str(m) '. ***Skipping - File exists in Destination "' files(m).name '" -> "' motorcycle_model '\' new_name '"'])
        end
        
    else
        disp([num2str(m) '. ***Skipping file :' files(m).name])
    end
end


