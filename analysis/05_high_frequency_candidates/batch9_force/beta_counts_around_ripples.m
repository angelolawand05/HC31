function [preCounts, postCounts, overlapCounts, nearestDeltaS] = beta_counts_around_ripples(ripplePeaks, betaPeaks, P)
    n = numel(ripplePeaks);
    preCounts = zeros(n,1);
    postCounts = zeros(n,1);
    overlapCounts = zeros(n,1);
    nearestDeltaS = nan(n,1);
    for i = 1:n
        dS = (betaPeaks - ripplePeaks(i)) ./ 1e6;
        preCounts(i) = nnz(dS >= -P.prePostWindowS & dS < 0);
        postCounts(i) = nnz(dS > 0 & dS <= P.prePostWindowS);
        overlapCounts(i) = nnz(abs(dS) <= P.betaRippleOverlapWindowS);
        if ~isempty(dS)
            [~, j] = min(abs(dS));
            nearestDeltaS(i) = dS(j);
        end
    end
end
