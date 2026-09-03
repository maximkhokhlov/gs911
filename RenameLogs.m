% rename log files according to the date/time stamp found in the file
% program will serach for *.txt and *.csv

% this program will not overwrite existing filenames. therefore, it is a
% good practice to rename all files to some temporary filenames before
% renaming


pathstr=uigetdir;

files=dir([pathstr '\*.csv']);
files=[files; dir([pathstr '\*.txt'])];

disp(['Found ' num2str(length(files)) ' files'])


for m=1:length(files)
    
    % Import the file
    try
        rawData = importdata([pathstr '\' files(m).name], ';', 6);
    catch
        error(['Error occured during opening "' files(m).name '" file']);
    end
    
    
    % read the date stamp.
    start_date_str=[];
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
        
        % if the new name equals to old name, skip the rename
        if strcmpi(files(m).name,new_name)
            disp(['***Skipping file(filename is ok) :' files(m).name])
            continue
        end
        
        
        % check if this file name already exists
        counter=0;
        while ~isempty(dir(new_name))
            counter=counter+1;
            new_name=[start_date_str ' - ' motorcycle_model ' - GS911 log_' num2str(counter) files(m).name(end-3:end)];
        end
        
        
        
        disp([num2str(m) '. "' files(m).name '" -> "' new_name])
        
        movefile([pathstr '\' files(m).name],[pathstr '\' new_name]);
        
        
    else
        disp(['***Skipping file :' files(m).name])
    end
end


