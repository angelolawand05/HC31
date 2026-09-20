function [centers, counts, eventsPerRipple] = event_crosscorr(ripplePeaks, betaPeaks, winS, binS)
    edges = -winS:binS:winS;
    centers = edges(1:end-1) + binS/2;
    counts = zeros(size(centers));
    for i = 1:numel(ripplePeaks)
        dS = (betaPeaks - ripplePeaks(i)) ./ 1e6;
        counts = counts + histcounts(dS, edges);
    end
    eventsPerRipple = counts ./ max(numel(ripplePeaks), 1);
end
