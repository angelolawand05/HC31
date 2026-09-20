function tOut = downsampleEventTimes(tIn, maxDots)
tIn = tIn(:);
tIn = tIn(isfinite(tIn));
if numel(tIn) <= maxDots
    tOut = tIn;
else
    idx = round(linspace(1, numel(tIn), maxDots));
    tOut = tIn(idx);
end
end
