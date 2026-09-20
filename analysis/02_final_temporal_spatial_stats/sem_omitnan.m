function s = sem_omitnan(x)
    x = x(:);
    x = x(isfinite(x));
    if numel(x) <= 1
        s = NaN;
    else
        s = std(x, 0, 'omitnan') ./ sqrt(numel(x));
    end
end
