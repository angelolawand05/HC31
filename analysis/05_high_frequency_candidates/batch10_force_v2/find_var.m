function col = find_var(T, candidates)
    col = '';
    names = T.Properties.VariableNames;
    lowerNames = lower(names);
    for i = 1:numel(candidates)
        hit = strcmp(lowerNames, lower(candidates{i}));
        if any(hit), col = names{find(hit,1)}; return; end
    end
    for i = 1:numel(candidates)
        hit = contains(lowerNames, lower(candidates{i}));
        if any(hit), col = names{find(hit,1)}; return; end
    end
end
