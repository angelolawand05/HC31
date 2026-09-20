function col = find_var(T, candidates)
    col = '';
    names = T.Properties.VariableNames;
    lowerNames = lower(names);
    for i = 1:numel(candidates)
        target = lower(candidates{i});
        hit = strcmp(lowerNames, target);
        if any(hit)
            col = names{find(hit,1)};
            return;
        end
    end
    for i = 1:numel(candidates)
        target = lower(candidates{i});
        hit = contains(lowerNames, target);
        if any(hit)
            col = names{find(hit,1)};
            return;
        end
    end
end
