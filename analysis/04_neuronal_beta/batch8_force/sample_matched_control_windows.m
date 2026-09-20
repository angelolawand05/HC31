function [ctrlStartUs, ctrlEndUs, ctrlCenterUs, ctrlSpeedCmS] = sample_matched_control_windows( ...
    peakUs, durationS, subepoch, peakSpeedCmS, sectInt, posT, speedCmS, validMove, allBurstPeakUs, P)

    n = numel(peakUs);
    ctrlCenterUs = nan(n,1);
    ctrlStartUs = nan(n,1);
    ctrlEndUs = nan(n,1);
    ctrlSpeedCmS = nan(n,1);

    allBurstPeakUs = allBurstPeakUs(isfinite(allBurstPeakUs));

    for k = 1:n
        durUs = durationS(k) * 1e6;
        se = subepoch(k);
        if ~isfinite(se) || se < 1 || se > size(sectInt,1)
            se = find(peakUs(k) >= sectInt(:,1) & peakUs(k) <= sectInt(:,2), 1);
        end
        if isempty(se), continue; end

        inSe = posT >= sectInt(se,1) & posT <= sectInt(se,2);
        cand = find(validMove & inSe & isfinite(posT));

        if isempty(cand), continue; end

        % Speed matching, if burst speed is known.
        if isfinite(peakSpeedCmS(k))
            tol = max(P.speedToleranceCmS, abs(peakSpeedCmS(k)) * P.speedToleranceFraction);
            candSpeed = cand(abs(speedCmS(cand) - peakSpeedCmS(k)) <= tol);
            if ~isempty(candSpeed)
                cand = candSpeed;
            end
        end

        candT = posT(cand);

        % Avoid controls too close to detected bursts from same animal/band.
        if ~isempty(allBurstPeakUs)
            nearAnyBurst = false(size(candT));
            chunk = 2000;
            for a = 1:chunk:numel(candT)
                b = min(numel(candT), a+chunk-1);
                D = abs(candT(a:b) - allBurstPeakUs(:)');
                nearAnyBurst(a:b) = min(D, [], 2) < P.controlExcludeAroundBurstSec * 1e6;
            end
            cand = cand(~nearAnyBurst);
            candT = posT(cand);
        end

        if isempty(cand), continue; end

        pick = cand(randi(numel(cand)));
        c = posT(pick);
        ctrlCenterUs(k) = c;
        ctrlStartUs(k) = c - durUs/2;
        ctrlEndUs(k) = c + durUs/2;
        ctrlSpeedCmS(k) = speedCmS(pick);
    end
end
