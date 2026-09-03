function [data, column_names]=extract_data(filename, data_column_names)
%Extract data from F800GS log files. It is based on column name
% fileToRead
% data_column_names - cell array of strings. each element represents column name
% to be extracted
%
% data - extracted data array. 1st column contains the time stamp. other
% columns contain the data
%
% Eliminate the characters inside the paranteses
% They differ from log file versions



% Import the file
try
    rawData = importdata(filename, ';', 6);
catch
    error(['Error occured during opening "' filename '" file']);
end


% read the date stamp. all other data points are related to this starting
% point
try
    start_date_str=char(rawData.textdata{2,1});
    start_date=datenum(start_date_str(2:end));
catch
    warning(['Error occured during reading timestamp in "' filename '" file']);
    data=[];
    column_names=[];
    return
end

% record the time stamp
data=rawData.data(:,1)/(3600*24*1000)+start_date;
column_names={'Time stamp'};

% output data counter
n=1;


% extaract the data
for m=1:length(data_column_names)

    %     Eliminate the characters inside the paranteses
    %     They differ from log file versions

    % Find the parantases. there are two types of paranteses: 1. with the
    % space before the par. 2. without the space
    pr_ind=strfind(data_column_names{m},' (');
    if pr_ind
        pr_ind=pr_ind(1)-1;    
    else
        pr_ind=strfind(data_column_names{m},'(');
        if pr_ind
            pr_ind=pr_ind(1)-1;
        else
            pr_ind=length(data_column_names{m});
        end
    end
    
    



    ind=find(strncmpi(rawData.colheaders,data_column_names{m},pr_ind));
    
    if ind
        n=n+1;
        data(:,n)=rawData.data(:,ind);
        column_names{n}=data_column_names{m};
    end
end