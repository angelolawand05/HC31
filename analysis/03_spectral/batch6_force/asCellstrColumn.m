function out = asCellstrColumn(T, vars, candidates)
out = repmat({''}, height(T), 1);
for c = 1:numel(candidates)
    idx = find(strcmp(vars, candidates{c}), 1);
    if ~isempty(idx)
        val = T.(vars{idx});
        if iscell(val)
            out = val;
        elseif isstring(val) || iscategorical(val)
            out = cellstr(val);
        else
            out = cellstr(string(val));
        end
        return;
    end
end
end
