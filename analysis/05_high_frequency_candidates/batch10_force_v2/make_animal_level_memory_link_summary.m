function Summary = make_animal_level_memory_link_summary(RP)
    if isempty(RP), Summary = table(); return; end

    RP.animal = string(RP.animal);
    RP.epochName = string(RP.epochName);
    animals = unique(RP.animal, 'stable');
    epochs = unique(RP.epochName, 'stable');

    rows = {};
    for ai = 1:numel(animals)
        for ei = 1:numel(epochs)
            idx = RP.animal == animals(ai) & RP.epochName == epochs(ei);
            if ~any(idx), continue; end

            tagged = idx & logical(RP.isBeta2Tagged);
            untagged = idx & ~logical(RP.isBeta2Tagged);
            novelTagged = idx & logical(RP.isNovelBeta2Tagged);
            nonNovelTagged = idx & ~logical(RP.isNovelBeta2Tagged);

            meanTagged = mean(RP.rippleParticipationFraction(tagged), 'omitnan');
            meanUntagged = mean(RP.rippleParticipationFraction(untagged), 'omitnan');
            meanNovelTagged = mean(RP.rippleParticipationFraction(novelTagged), 'omitnan');
            meanNonNovelTagged = mean(RP.rippleParticipationFraction(nonNovelTagged), 'omitnan');

            rows(end+1,:) = {char(animals(ai)), char(epochs(ei)), ...
                nnz(idx), nnz(tagged), nnz(untagged), ...
                meanTagged, meanUntagged, meanTagged - meanUntagged, ...
                meanNovelTagged, meanNonNovelTagged, meanNovelTagged - meanNonNovelTagged, ...
                mean(RP.rippleWindowFiringRateHz(tagged), 'omitnan'), ...
                mean(RP.rippleWindowFiringRateHz(untagged), 'omitnan')}; %#ok<AGROW>
        end
    end

    Summary = cell2table(rows, 'VariableNames', { ...
        'animal','epochName','nUnits','nBeta2TaggedUnits','nUntaggedUnits', ...
        'meanRippleParticipationBeta2Tagged','meanRippleParticipationUntagged', ...
        'beta2TaggedMinusUntaggedParticipation', ...
        'meanRippleParticipationNovelBeta2Tagged','meanRippleParticipationNonNovelBeta2Tagged', ...
        'novelBeta2TaggedMinusNonNovelParticipation', ...
        'meanRippleWindowFiringRateBeta2TaggedHz','meanRippleWindowFiringRateUntaggedHz'});
end
