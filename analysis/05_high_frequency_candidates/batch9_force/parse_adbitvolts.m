function scale = parse_adbitvolts(header)
    scale = 1;
    if isempty(header), return; end
    for i = 1:numel(header)
        line = string(header{i});
        if contains(line, 'ADBitVolts', 'IgnoreCase', true)
            nums = regexp(char(line), '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match');
            if ~isempty(nums)
                val = str2double(nums{end});
                if isfinite(val) && val > 0, scale = val; return; end
            end
        end
    end
end
