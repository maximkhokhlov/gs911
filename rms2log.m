function out_files = rms2log(src, out_dir, overwrite)
%RMS2LOG Convert GS-911 Mobile (J2ME) *.rms record stores to GS-911 log files.
%
%   rms2log()                 converts all *.rms in the current folder
%   rms2log(folder)           converts all *.rms in FOLDER (output next to them)
%   rms2log(file)             converts a single *.rms file
%   rms2log(src, out_dir)     writes the converted files to OUT_DIR
%   rms2log(src, out_dir, true) overwrites existing output files
%
%   out_files - cell array with the paths of the files written
%
%   The old GS-911 Mobile app (Windows Mobile / J2ME) stored its data in
%   MIDP Record Management System (RMS) files:
%     GS911Mobile_m_logNNNNN.rms      -> "<date> - <model> - GS911 log.csv"
%     GS911Mobile_m_ecuinfoNNNN.rms   -> "<date> - <model> - ECUInfo.txt"
%     GS911Mobile_m_diagNNNN.rms      -> app settings (bluetooth, license) - skipped
%
%   RMS container (all integers big-endian):
%     0x00  'midp-rms' magic, 0x48 bytes of store header
%     0x48  chain of records: uint32 id, uint32 prevOffset, uint32 blockSize,
%           uint32 dataLength, then the data, padded to blockSize
%   Log store payload:
%     record 1 : int64 0, uint8 nDataCols, Java writeUTF (uint16 length +
%                UTF-8 bytes) with the complete text header of the log
%                ("##;##", "#date", "#app", "#model", "#ECU", column names)
%     records 2..N : packed samples of int64 time_ms + single(nDataCols)
%
%   The resulting csv is identical in layout to the logs written by the
%   GS-911 Android app, so extract_data / maxiGS911 read it directly.

if nargin < 1 || isempty(src),      src = pwd;        end
if nargin < 2,                      out_dir = '';     end
if nargin < 3 || isempty(overwrite), overwrite = false; end

% -------- collect the input files
if isfolder(src)
    d = dir(fullfile(src, '*.rms'));
    files = fullfile(src, {d.name});
    if isempty(out_dir), out_dir = src; end
elseif isfile(src)
    files = {src};
    if isempty(out_dir), out_dir = fileparts(src); end
else
    error('rms2log:notFound', '"%s" is neither a file nor a folder', src);
end
if isempty(out_dir), out_dir = pwd; end
if ~isfolder(out_dir), mkdir(out_dir); end

out_files = {};
for k = 1:numel(files)
    fn = files{k};
    [~, base] = fileparts(fn);
    try
        recs = read_rms_records(fn);
    catch ME
        warning('rms2log:badFile', 'Skipping "%s": %s', fn, ME.message);
        continue
    end

    if ~isempty(regexpi(base, '_log', 'once'))
        [txt, out_name] = decode_log(recs);
    elseif ~isempty(regexpi(base, '_ecuinfo', 'once'))
        [txt, out_name] = decode_ecuinfo(recs);
    else
        fprintf('Skipping "%s" (not a log or ECU info store)\n', base);
        continue
    end
    if isempty(txt)
        warning('rms2log:empty', 'Skipping "%s": no data records', fn);
        continue
    end

    out_fn = fullfile(out_dir, out_name);
    if isfile(out_fn) && ~overwrite
        fprintf('Exists, not overwritten: "%s"\n', out_name);
        continue
    end
    fid = fopen(out_fn, 'w', 'n', 'UTF-8');
    if fid < 0
        warning('rms2log:cantWrite', 'Cannot write "%s"', out_fn);
        continue
    end
    fwrite(fid, txt, 'char');
    fclose(fid);
    fprintf('%s  ->  %s\n', base, out_name);
    out_files{end+1} = out_fn; %#ok<AGROW>
end
end


% =====================================================================
function recs = read_rms_records(fn)
% Return a struct array (id, data) of the live records in an RMS file,
% sorted by record id. Data is uint8 row vector.

fid = fopen(fn, 'r', 'ieee-be');
if fid < 0, error('cannot open file'); end
c = onCleanup(@() fclose(fid));

magic = fread(fid, 8, 'uint8=>char')';
if ~strcmp(magic, 'midp-rms')
    error('not a MIDP RMS file (bad magic "%s")', magic);
end

fseek(fid, 0, 'eof'); fsize = ftell(fid);
off = hex2dec('48');
recs = struct('id', {}, 'data', {});

while off + 16 <= fsize
    fseek(fid, off, 'bof');
    hdr = fread(fid, 4, 'uint32=>double');       % id, prev, blockSize, dataLen
    if numel(hdr) < 4, break; end
    id = hdr(1); blk = hdr(3); dlen = hdr(4);
    if blk < 16, break; end                       % corrupt / end of chain
    if id > 0 && dlen > 0
        data = fread(fid, dlen, 'uint8=>uint8')';
        recs(end+1) = struct('id', id, 'data', data); %#ok<AGROW>
    end
    off = off + blk;
end
[~, order] = sort([recs.id]);
recs = recs(order);
end


% =====================================================================
function [txt, out_name] = decode_log(recs)
txt = ''; out_name = '';
if isempty(recs), return; end

% ---- record 1: int64 0, uint8 nCols, writeUTF(header)
d = recs(1).data;
ncol  = double(d(9));
ulen  = double(d(10)) * 256 + double(d(11));
hdr   = native2unicode(d(12:11+ulen), 'UTF-8');
hdr   = regexprep(hdr, '\r?\n', char([13 10]));   % normalise line endings
hdr_lines = regexp(hdr, '\r\n', 'split');

% ---- records 2..N: samples of int64 t + single(ncol)
step = 8 + 4 * ncol;
rows = {};
for r = 2:numel(recs)
    d = recs(r).data;
    n = floor(numel(d) / step);
    for i = 0:n-1
        s = d(i*step + (1:step));
        t = double(typecast(uint8(s(8:-1:1)), 'int64'));                 % big-endian int64
        v = zeros(1, ncol);
        for j = 1:ncol
            b = s(8 + (j-1)*4 + (4:-1:1));                               % big-endian single
            v(j) = double(typecast(uint8(b), 'single'));
        end
        nums = fmt_num(v);
        rows{end+1} = [sprintf('%d', t) sprintf(';%s', nums{:})]; %#ok<AGROW>
    end
end
if isempty(rows), return; end

txt = [hdr sprintf('\r\n') strjoin(rows, sprintf('\r\n')) sprintf('\r\n')];

% ---- output name: "<yyyy-mm-dd HH-MM-SS> - <model> - GS911 log.csv"
[date_str, model] = header_date_model(hdr_lines);
out_name = [date_str ' - ' model ' - GS911 log.csv'];
end


% =====================================================================
function [txt, out_name] = decode_ecuinfo(recs)
txt = ''; out_name = '';
if isempty(recs), return; end
% payload: int64 timestamp, writeUTF(text)
d = recs(1).data;
ulen = double(d(9)) * 256 + double(d(10));
body = native2unicode(d(11:10+ulen), 'UTF-8');
body = regexprep(body, '\r?\n', char([13 10]));
lines = regexp(body, '\r\n', 'split');
txt = [body sprintf('\r\n')];
[date_str, model] = header_date_model(lines);
out_name = [date_str ' - ' model ' - ECUInfo.txt'];
end


% =====================================================================
function [date_str, model] = header_date_model(lines)
% Find "#yyyy-mm-dd HH:MM:SS" and "#<model>" (3rd '#' line) in header lines
date_str = 'unknown-date'; model = 'unknown';
hashes = lines(strncmp(strtrim(lines), '#', 1));
for k = 1:numel(hashes)
    m = regexp(hashes{k}, '^#\s*(\d{4}-\d{2}-\d{2}) (\d{2}):(\d{2}):(\d{2})', 'tokens', 'once');
    if ~isempty(m)
        date_str = sprintf('%s %s-%s-%s', m{1}, m{2}, m{3}, m{4});
        break
    end
end
% lines are: ##;## (optional), #date, #app, #model, #ECU
model_idx = find(~cellfun(@isempty, regexp(hashes, '^#\s*\d{4}-\d{2}-\d{2}', 'once')), 1) + 2;
if ~isempty(model_idx) && model_idx <= numel(hashes)
    model = strtrim(hashes{model_idx}(2:end));
end
model = regexprep(model, '[\\/:*?"<>|]', '_');
end


% =====================================================================
function s = fmt_num(v)
% Format numbers like the GS-911 logs: up to 4 decimals, trailing zeros
% removed but at least one decimal kept (1310 -> "1310.0", 12.595 -> "12.595")
s = cell(1, numel(v));
for k = 1:numel(v)
    t = sprintf('%.4f', v(k));
    t = regexprep(t, '0+$', '');
    if t(end) == '.', t = [t '0']; end
    s{k} = t;
end
end
