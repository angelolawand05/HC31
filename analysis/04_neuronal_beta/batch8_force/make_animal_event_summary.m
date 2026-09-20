function AnimalEventSummary = make_animal_event_summary(E)
    E.band = string(E.band);
    E.category = string(E.category);
    animals = unique(string(E.animal), 'stable');
    bands = unique(E.band, 'stable');
    cats = unique(E.category, 'stable');

    rows = {};
    for ai = 1:numel(animals)
        for bi = 1:numel(bands)
            for ci = 1:numel(cats)
                idx = string(E.animal) == animals(ai) & E.band == bands(bi) & E.category == cats(ci);
                if ~any(idx), continue; end
                diffActive = E.nActiveUnitsBurst(idx) - E.nActiveUnitsControl(idx);
                diffSpikes = E.nSpikesBurst(idx) - E.nSpikesControl(idx);
                rows(end+1,:) = {char(animals(ai)), char(bands(bi)), char(cats(ci)), ...
                    nnz(idx), mean(E.nActiveUnitsBurst(idx), 'omitnan'), ...
                    mean(E.nActiveUnitsControl(idx), 'omitnan'), ...
                    mean(diffActive, 'omitnan'), ...
                    mean(E.nSpikesBurst(idx), 'omitnan'), ...
                    mean(E.nSpikesControl(idx), 'omitnan'), ...
                    mean(diffSpikes, 'omitnan')}; %#ok<SAGROW>
            end
        end
    end
    AnimalEventSummary = cell2table(rows, 'VariableNames', { ...
        'animal','band','category','nEvents','meanActiveUnitsBurst', ...
        'meanActiveUnitsControl','meanActiveUnitsBurstMinusControl', ...
        'meanSpikesBurst','meanSpikesControl','meanSpikesBurstMinusControl'});
end
