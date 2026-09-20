function [startUs, endUs, cat] = beta2_windows_from_table(BB, P)
    cat = lower(string(BB.category));
    cat(cat ~= "novel" & cat ~= "familiar") = "all";

    startUs = BB.startUs;
    endUs = BB.endUs;

    durationS = BB.durationS;
    badDur = ~isfinite(durationS) | durationS <= 0;
    durationS(badDur) = P.beta2UnitWindowS * 2;

    bad = ~isfinite(startUs) | ~isfinite(endUs) | endUs <= startUs;
    startUs(bad) = BB.peakUs(bad) - durationS(bad) .* 1e6 ./ 2;
    endUs(bad)   = BB.peakUs(bad) + durationS(bad) .* 1e6 ./ 2;

    bad = ~isfinite(startUs) | ~isfinite(endUs) | endUs <= startUs;
    startUs(bad) = BB.peakUs(bad) - P.beta2UnitWindowS * 1e6;
    endUs(bad)   = BB.peakUs(bad) + P.beta2UnitWindowS * 1e6;
end
