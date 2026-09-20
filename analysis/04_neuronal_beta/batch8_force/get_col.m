function out = get_col(T, candidates)
    col = find_var(T, candidates);
    if isempty(col)
        out = strings(height(T), 1);
    else
        out = T.(col);
    end
end
