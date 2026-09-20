function rateRows = compute_ripple_rates(ripples, sectInt, posT, posLin, speedCmS, P)
    rateRows = {};
    categories = ["all"]; % novel/familiar is assigned below when possible.

    for se = 1:size(sectInt,1)
        inSe = posT >= sectInt(se,1) & posT <= sectInt(se,2);
        low = inSe & isfinite(speedCmS) & speedCmS <= P.lowSpeedThresholdCmS;
        lowS = nnz(low) / estimate_pos_fs(posT);

        rIdx = [ripples.subepoch] == se;
        nRip = nnz(rIdx);
        rate = nRip / max(lowS, eps) * 60;
        rateRows(end+1,:) = {se, 'all', lowS, nRip, rate}; %#ok<AGROW>
    end
end
