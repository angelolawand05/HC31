function sur = circular_shift_surrogate_prepost(ripplePeaks, betaPeaks, runStartUs, runEndUs, P)
    runDurUs = runEndUs - runStartUs;
    sur = nan(P.nSurrogates, 1);
    betaRel = betaPeaks - runStartUs;
    for s = 1:P.nSurrogates
        shiftS = P.minShiftS + rand * ((runDurUs/1e6) - 2*P.minShiftS);
        if rand < 0.5, shiftS = -shiftS; end
        shifted = mod(betaRel + shiftS*1e6, runDurUs) + runStartUs;
        [pre, post] = beta_counts_around_ripples(ripplePeaks, shifted, P);
        sur(s) = mean(post - pre, 'omitnan');
    end
end
