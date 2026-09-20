function r = spectralRoughnessMad(f, y, bandHz)
    idx = f >= bandHz(1) & f <= bandHz(2) & isfinite(y);
    if sum(idx) < 3
        r = NaN;
        return;
    end
    fb = f(idx);
    yb = y(idx);
    [fb, order] = sort(fb); %#ok<ASGLU>
    yb = yb(order);
    dy = diff(yb);
    r = median(abs(dy - median(dy, 'omitnan')), 'omitnan');
end
