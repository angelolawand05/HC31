function v = findVar(T, candidates)
    v = '';
    names = T.Properties.VariableNames;
    lowerNames = lower(names);
    for c = 1:numel(candidates)
        idx = find(strcmp(lowerNames, lower(candidates{c})), 1);
        if ~isempty(idx)
            v = names{idx};
            return;
        end
    end
    % Fuzzy contains fallback.
    for c = 1:numel(candidates)
        idx = find(contains(lowerNames, lower(candidates{c})), 1);
        if ~isempty(idx)
            v = names{idx};
            return;
        end
    end
end
