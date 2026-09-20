function ripples = detect_ripples_from_envelope(tUs, rippleFilt, envZ, speed, posLin, lowSpeed, sectInt, P)
    above = envZ >= P.rippleEnvelopeLowZ & lowSpeed & isfinite(envZ);
    starts = find(diff([false; above(:)]) == 1);
    ends = find(diff([above(:); false]) == -1);

    % Merge close events.
    if ~isempty(starts)
        mergedS = starts(1);
        mergedE = ends(1);
        sList = [];
        eList = [];
        for i = 2:numel(starts)
            gapS = (tUs(starts(i)) - tUs(mergedE)) / 1e6;
            if gapS <= P.rippleMergeGapS
                mergedE = ends(i);
            else
                sList(end+1,1) = mergedS; %#ok<AGROW>
                eList(end+1,1) = mergedE; %#ok<AGROW>
                mergedS = starts(i);
                mergedE = ends(i);
            end
        end
        sList(end+1,1) = mergedS;
        eList(end+1,1) = mergedE;
    else
        sList = [];
        eList = [];
    end

    ripples = struct('startUs',{},'endUs',{},'peakUs',{},'durationS',{}, ...
        'peakZ',{},'peakRippleAmp',{},'peakSpeedCmS',{},'peakLinearPosition',{}, ...
        'subepoch',{},'category',{},'isArtifactLike',{});

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

        se = find(tUs(pi) >= sectInt(:,1) & tUs(pi) <= sectInt(:,2), 1);
        cat = "unknown";
        if ~isempty(se)
            cat = "all";
        else
            se = NaN;
        end

        ripples(end+1).startUs = tUs(si); %#ok<AGROW>
        ripples(end).endUs = tUs(ei);
        ripples(end).peakUs = tUs(pi);
        ripples(end).durationS = durS;
        ripples(end).peakZ = peakZ;
        ripples(end).peakRippleAmp = abs(rippleFilt(pi));
        ripples(end).peakSpeedCmS = speed(pi);
        ripples(end).peakLinearPosition = posLin(pi);
        ripples(end).subepoch = se;
        ripples(end).category = cat;
        ripples(end).isArtifactLike = peakZ > P.rippleArtifactPeakZ;
    end
end
