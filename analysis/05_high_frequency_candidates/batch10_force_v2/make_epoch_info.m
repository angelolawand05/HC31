function E = make_epoch_info(name, col, startUs, endUs, nSpikes, usable)
    E = struct();
    E.epochName = char(name);
    E.epochCol = col;
    E.startUs = startUs;
    E.endUs = endUs;
    if isfinite(startUs) && isfinite(endUs)
        E.durationS = (endUs - startUs) / 1e6;
    else
        E.durationS = NaN;
    end
    E.nPooledSpikes = nSpikes;
    E.isUsable = logical(usable);
end
