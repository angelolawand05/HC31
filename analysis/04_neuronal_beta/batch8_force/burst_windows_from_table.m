function [startUs, endUs, durationS] = burst_windows_from_table(BB, P)
    durationS = BB.durationS;
    badDur = ~isfinite(durationS) | durationS <= 0;
    durationS(badDur) = P.defaultBurstWindowSec;

    startUs = BB.startUs;
    endUs = BB.endUs;

    badStartEnd = ~isfinite(startUs) | ~isfinite(endUs) | endUs <= startUs;
    startUs(badStartEnd) = BB.peakUs(badStartEnd) - durationS(badStartEnd) .* 1e6 ./ 2;
    endUs(badStartEnd)   = BB.peakUs(badStartEnd) + durationS(badStartEnd) .* 1e6 ./ 2;
end
