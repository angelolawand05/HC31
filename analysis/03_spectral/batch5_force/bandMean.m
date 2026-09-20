function m = bandMean(f, y, bandHz)
    idx = f >= bandHz(1) & f <= bandHz(2) & isfinite(y);
    if any(idx)
        m = mean(y(idx), 'omitnan');
    else
        m = NaN;
    end
end
