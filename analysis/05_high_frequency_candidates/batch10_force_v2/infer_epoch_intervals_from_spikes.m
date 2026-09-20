function EpochInfo = infer_epoch_intervals_from_spikes(R, ri, animal, P)
    sp = R.spEpochSep;
    nEpochs = size(sp, 2);
    names = fieldnames(P.epochMap);

    EpochInfo = struct('epochName',{},'epochCol',{},'startUs',{},'endUs',{}, ...
        'durationS',{},'nPooledSpikes',{},'isUsable',{});

    for i = 1:numel(names)
        epochName = names{i};
        col = P.epochMap.(epochName);

        if col > nEpochs
            EpochInfo(end+1) = make_epoch_info(epochName, col, NaN, NaN, 0, false); %#ok<AGROW>
            continue;
        end

        pooled = [];
        for u = 1:size(sp,1)
            try
                st = double(sp(u,col).timeStamps(:));
            catch
                st = [];
            end
            st = st(isfinite(st));
            if ~isempty(st) && median(abs(st), 'omitnan') < 1e6
                st = st .* 1e6;
            end
            pooled = [pooled; st(:)]; %#ok<AGROW>
        end

        pooled = pooled(isfinite(pooled));
        if numel(pooled) >= P.minSpikesForEpochInterval
            startUs = min(pooled);
            endUs = max(pooled);
            usable = endUs > startUs;
        else
            startUs = NaN;
            endUs = NaN;
            usable = false;
        end

        EpochInfo(end+1) = make_epoch_info(epochName, col, startUs, endUs, numel(pooled), usable); %#ok<AGROW>
    end
end
