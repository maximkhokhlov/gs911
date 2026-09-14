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



% Count the header lines. Their number differs between GS-911 versions
% (e.g. GS-911 Android V1.31 adds a VIN line), so it cannot be hardcoded.
[n_hdr, hdr_lines] = count_header_lines(filename);

% not a GS-911 log (e.g. Codes*.txt, ECUInfo*.txt, data exports) - skip quietly
if n_hdr < 3 || isempty(regexp(hdr_lines{2}, '^\s*\d', 'once'))
    disp(['Not a GS-911 log file, skipping: "' filename '"'])
    data=[];
    column_names=[];
    return
end

% Import the file
try
    rawData = importdata(filename, ';', n_hdr);
catch
    error(['Error occured during opening "' filename '" file']);
end


% read the date stamp. all other data points are related to this starting
% point. It is the 2nd header line: e.g. "#2026-09-02 08:39:03"
try
    start_date=datenum(strtrim(hdr_lines{2}));
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
    
    



    % 1. exact (case-insensitive) match on the full column name
    ind=find(strcmpi(strtrim(rawData.colheaders),strtrim(data_column_names{m})));

    % 2. fall back to matching the name without the unit, e.g. 'Speed'
    %    matches 'Speed (km/h)' and 'Speed( km/h)'
    if isempty(ind)
        ind=find(strncmpi(rawData.colheaders,data_column_names{m},pr_ind));
    end

    % several columns can share a prefix (e.g. 'Time (ms)', 'Time(s)',
    % 'Time(min)') - take the first one only
    if ~isempty(ind)
        if numel(ind)>1
            warning(['Several columns match "' data_column_names{m} '" in "' ...
                filename '": ' strjoin(rawData.colheaders(ind),', ') ...
                '. Using the first one.']);
            ind=ind(1);
        end
        n=n+1;
        data(:,n)=rawData.data(:,ind);
        column_names{n}=data_column_names{m};
    end
end

% Remove invalid sensor readings.
% During starter cranking / engine shut-off the ECU reports the wheel speed
% sensors as 4095 (saturated 12-bit value) and the derived speed as 318 km/h.
% Anything above MAX_SPEED is physically impossible for the bike -> NaN
% (plot() draws NaN as a gap).
MAX_SPEED = 250; % km/h
for n=2:size(data,2)
    if ~isempty(regexpi(column_names{n}, '^(speed|front wheel speed|rear wheel speed)', 'once'))
        bad = data(:,n) > MAX_SPEED;
        data(bad,n) = NaN;
    end
end
end
