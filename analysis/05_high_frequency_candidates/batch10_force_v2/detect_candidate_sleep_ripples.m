function ripples = detect_candidate_sleep_ripples(tUs, rippleFilt, envZ, epochName, P)
    above = envZ >= P.rippleEnvelopeLowZ & isfinite(envZ);
    starts = find(diff([false; above(:)]) == 1);
    ends = find(diff([above(:); false]) == -1);

    % Merge close events.
    sList = [];
    eList = [];
    if ~isempty(starts)
        curS = starts(1);
        curE = ends(1);
        for i = 2:numel(starts)
            gapS = (tUs(starts(i)) - tUs(curE)) / 1e6;
            if gapS <= P.rippleMergeGapS
                curE = ends(i);
            else
                sList(end+1,1) = curS; %#ok<AGROW>
                eList(end+1,1) = curE; %#ok<AGROW>
                curS = starts(i);
                curE = ends(i);
            end
        end
        sList(end+1,1) = curS;
        eList(end+1,1) = curE;
    end

    ripples = struct('epochName',{},'startUs',{},'endUs',{},'peakUs',{}, ...
        'durationS',{},'peakZ',{},'peakRippleAmp',{},'isArtifactLike',{});

    for i = 1:numel(sList)
        si = sList(i); ei = eList(i);
        durS = (tUs(ei) - tUs(si)) / 1e6;
        if durS < P.rippleMinDurationS || durS > P.rippleMaxDurationS
            continue;
        end
        [peakZ, localPeak] = max(envZ(si:ei));
        if peakZ < P.rippleEnvelopePeakZ
            continue;
        end
        pi = si + localPeak - 1;

        ripples(end+1).epochName = string(epochName); %#ok<AGROW>
        ripples(end).startUs = tUs(si);
        ripples(end).endUs = tUs(ei);
        ripples(end).peakUs = tUs(pi);
        ripples(end).durationS = durS;
        ripples(end).peakZ = peakZ;
        ripples(end).peakRippleAmp = abs(rippleFilt(pi));
        ripples(end).isArtifactLike = peakZ > P.rippleArtifactPeakZ;
    end
end
