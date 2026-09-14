function [n_hdr, hdr_lines] = count_header_lines(filename)
%COUNT_HEADER_LINES Number of header lines in a GS-911 log file.
%   GS-911 logs start with a block of lines beginning with '#' (date, app
%   version, model, ECU, and in newer Android versions also the VIN),
%   followed by the column-names line. The number of '#' lines differs
%   between GS-911 versions, so it must be counted rather than hardcoded.
%
%   n_hdr     - number of lines to skip for importdata (all '#' lines plus
%               the column-names line). 0 if the file is not a GS-911 log.
%   hdr_lines - cell array with the '#' lines (without the leading '#')

n_hdr = 0;
hdr_lines = {};

fid = fopen(filename, 'r');
if fid < 0
    return
end
c = onCleanup(@() fclose(fid));

while true
    ln = fgetl(fid);
    if ~ischar(ln)
        break
    end
    % strip a UTF-8 byte-order mark (some old GS-911 Mobile logs have one)
    ln = strrep(ln, char(65279), '');
    ln = strrep(ln, char([239 187 191]), '');
    ln = strtrim(ln);
    if isempty(ln) || ln(1) ~= '#'
        break
    end
    hdr_lines{end+1} = ln(2:end); %#ok<AGROW>
end

if isempty(hdr_lines)
    return
end

% '#' lines plus the column-names line
n_hdr = length(hdr_lines) + 1;
