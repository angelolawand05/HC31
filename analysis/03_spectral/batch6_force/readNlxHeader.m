function H = readNlxHeader(header)
H = struct();
if isempty(header); return; end
if ischar(header)
    header = cellstr(header);
end
for i = 1:numel(header)
    line = char(header{i});
    if contains(line, 'ADBitVolts')
        nums = regexp(line, '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match');
        if ~isempty(nums)
            H.ADBitVolts = str2double(nums{end});
        end
    end
end
end
