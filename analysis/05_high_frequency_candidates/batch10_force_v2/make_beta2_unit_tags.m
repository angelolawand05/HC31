function TagInfo = make_beta2_unit_tags(UnitSpikes, startUs, endUs, cat, P)
    nUnits = numel(UnitSpikes);
    TagInfo = repmat(struct('allSpikeCount',0,'allParticipation',0,'isBeta2Tagged',false, ...
        'novelSpikeCount',0,'novelParticipation',0,'isNovelBeta2Tagged',false, ...
        'familiarSpikeCount',0,'familiarParticipation',0,'isFamiliarBeta2Tagged',false), nUnits, 1);

    allIdx = isfinite(startUs) & isfinite(endUs) & endUs > startUs;
    novelIdx = allIdx & cat == "novel";
    famIdx = allIdx & cat == "familiar";

    for u = 1:nUnits
        st = UnitSpikes{u};

        allCounts = count_spikes_in_intervals(st, startUs(allIdx), endUs(allIdx));
        novCounts = count_spikes_in_intervals(st, startUs(novelIdx), endUs(novelIdx));
        famCounts = count_spikes_in_intervals(st, startUs(famIdx), endUs(famIdx));

        TagInfo(u).allSpikeCount = sum(allCounts);
        TagInfo(u).allParticipation = mean(allCounts > 0, 'omitnan');
        TagInfo(u).isBeta2Tagged = TagInfo(u).allParticipation >= P.beta2TagMinParticipation || ...
            TagInfo(u).allSpikeCount >= P.beta2TagMinSpikesDuringBursts;

        TagInfo(u).novelSpikeCount = sum(novCounts);
        if isempty(novCounts), TagInfo(u).novelParticipation = NaN;
        else, TagInfo(u).novelParticipation = mean(novCounts > 0, 'omitnan'); end
        TagInfo(u).isNovelBeta2Tagged = isfinite(TagInfo(u).novelParticipation) && ...
            (TagInfo(u).novelParticipation >= P.beta2TagMinParticipation || ...
             TagInfo(u).novelSpikeCount >= P.beta2TagMinSpikesDuringBursts);

        TagInfo(u).familiarSpikeCount = sum(famCounts);
        if isempty(famCounts), TagInfo(u).familiarParticipation = NaN;
        else, TagInfo(u).familiarParticipation = mean(famCounts > 0, 'omitnan'); end
        TagInfo(u).isFamiliarBeta2Tagged = isfinite(TagInfo(u).familiarParticipation) && ...
            (TagInfo(u).familiarParticipation >= P.beta2TagMinParticipation || ...
             TagInfo(u).familiarSpikeCount >= P.beta2TagMinSpikesDuringBursts);
    end
end
