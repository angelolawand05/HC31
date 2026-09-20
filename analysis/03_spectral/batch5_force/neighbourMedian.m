function nm = neighbourMedian(f, y, neighbourHz)
    idx = false(size(f));
    for k = 1:size(neighbourHz,1)
        idx = idx | (f >= neighbourHz(k,1) & f <= neighbourHz(k,2));
    end
    idx = idx & isfinite(y);
    if any(idx)
        nm = median(y(idx), 'omitnan');
    else
        nm = NaN;
    end
end
