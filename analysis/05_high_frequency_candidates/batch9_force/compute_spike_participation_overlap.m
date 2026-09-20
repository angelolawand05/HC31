function spikeRows = compute_spike_participation_overlap(R, ri, animal, betaPeaks, ripplePeaks, P)
    spikeRows = {};
    if ~isfield(R, 'spEpochSep') || isempty(R.spEpochSep), return; end
    sp = R.spEpochSep;
    nUnits = size(sp,1);
    epoch = P.run1SpikeEpoch;
    if size(sp,2) < epoch, epoch = 1; end

    betaStart = betaPeaks - P.spikeParticipationWindowS * 1e6;
    betaEnd   = betaPeaks + P.spikeParticipationWindowS * 1e6;
    ripStart  = ripplePeaks - P.spikeParticipationWindowS * 1e6;
    ripEnd    = ripplePeaks + P.spikeParticipationWindowS * 1e6;

    for u = 1:nUnits
        try
            st = double(sp(u,epoch).timeStamps(:));
        catch
            st = [];
        end
        if isempty(st), continue; end
        if median(abs(st), 'omitnan') < 1e6, st = st .* 1e6; end
        st = st(isfinite(st));

        bCounts = count_spikes_in_intervals(st, betaStart, betaEnd);
        rCounts = count_spikes_in_intervals(st, ripStart, ripEnd);
        spikeRows(end+1,:) = {animal, ri, u, numel(st), ...
            sum(bCounts), sum(rCounts), mean(bCounts > 0), mean(rCounts > 0), ...
            mean(bCounts > 0) > 0 && mean(rCounts > 0) > 0}; %#ok<AGROW>
    end
end
