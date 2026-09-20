function [tUs, lfp, fsRaw] = load_csc_interval_raw(cscPath, startUs, endUs)
    tUs = [];
    lfp = [];
    fsRaw = NaN;

    try
        % FieldSelection [1 0 1 1 1] selects:
        % timestamps, sample frequencies, nValidSamples, samples, plus header = 5 outputs.
        [ts, fs, nValid, samples, header] = Nlx2MatCSC(cscPath, [1 0 1 1 1], 1, 4, [startUs endUs]);
    catch
        return;
    end

    if isempty(ts) || isempty(samples), return; end

    fsRaw = median(double(fs(:)), 'omitnan');
    if ~isfinite(fsRaw) || fsRaw <= 0, fsRaw = 32551.34; end
    scale = parse_adbitvolts(header);
    dtUs = 1e6 / fsRaw;

    tCell = cell(numel(ts), 1);
    xCell = cell(numel(ts), 1);

    for r = 1:numel(ts)
        nv = 512;
        if ~isempty(nValid), nv = min(512, double(nValid(r))); end
        if nv <= 0, continue; end
        tCell{r} = double(ts(r)) + (0:nv-1)' * dtUs;
        xCell{r} = double(samples(1:nv, r)) * scale;
    end

    if all(cellfun(@isempty, tCell))
        return;
    end

    tUs = vertcat(tCell{:});
    lfp = vertcat(xCell{:});
    keep = tUs >= startUs & tUs <= endUs & isfinite(lfp);
    tUs = tUs(keep);
    lfp = lfp(keep);
    if isempty(tUs), return; end
    [tUs, ord] = sort(tUs);
    lfp = lfp(ord);
    [tUs, uniq] = unique(tUs, 'stable');
    lfp = lfp(uniq);
end
