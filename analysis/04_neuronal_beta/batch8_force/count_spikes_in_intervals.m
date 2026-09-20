function counts = count_spikes_in_intervals(spikeTimesUs, startUs, endUs)
    spikeTimesUs = spikeTimesUs(:);
    spikeTimesUs = spikeTimesUs(isfinite(spikeTimesUs));
    counts = zeros(numel(startUs), 1);
    if isempty(spikeTimesUs), return; end
    for k = 1:numel(startUs)
        if ~isfinite(startUs(k)) || ~isfinite(endUs(k)), continue; end
        counts(k) = nnz(spikeTimesUs >= startUs(k) & spikeTimesUs <= endUs(k));
    end
end
