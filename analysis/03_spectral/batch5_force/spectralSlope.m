function s = spectralSlope(f, y, bandHz)
    idx = f >= bandHz(1) & f <= bandHz(2) & isfinite(y);
    if sum(idx) < 3
        s = NaN;
        return;
    end
    coeff = polyfit(f(idx), y(idx), 1);
    s = coeff(1);
end
