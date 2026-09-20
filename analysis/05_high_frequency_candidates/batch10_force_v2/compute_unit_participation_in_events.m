function Part = compute_unit_participation_in_events(UnitSpikes, eventPeakUs, halfWindowS)
    nUnits = numel(UnitSpikes);
    Part = repmat(struct('spikeCount',0,'participationFraction',NaN,'firingRateHz',NaN), nUnits, 1);

    if isempty(eventPeakUs)
        return;
    end

    starts = eventPeakUs(:) - halfWindowS * 1e6;
    ends = eventPeakUs(:) + halfWindowS * 1e6;
    totalWindowS = numel(eventPeakUs) * halfWindowS * 2;

    for u = 1:nUnits
        counts = count_spikes_in_intervals(UnitSpikes{u}, starts, ends);
        Part(u).spikeCount = sum(counts);
        Part(u).participationFraction = mean(counts > 0, 'omitnan');
        Part(u).firingRateHz = sum(counts) / max(totalWindowS, eps);
    end
end
