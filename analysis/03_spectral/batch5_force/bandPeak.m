function [peakHz, peakDb] = bandPeak(f, y, bandHz)
    idx = f >= bandHz(1) & f <= bandHz(2) & isfinite(y);
    if any(idx)
        fb = f(idx);
        yb = y(idx);
        [peakDb, mx] = max(yb);
        peakHz = fb(mx);
    else
        peakHz = NaN;
        peakDb = NaN;
    end
end
