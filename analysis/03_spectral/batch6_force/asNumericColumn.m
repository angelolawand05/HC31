function out = asNumericColumn(T, vars, candidates)
out = nan(height(T), 1);
for c = 1:numel(candidates)
    idx = find(strcmp(vars, candidates{c}), 1);
    if ~isempty(idx)
        out = double(T.(vars{idx}));
        return;
    end
end
end
