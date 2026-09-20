function E = make_event_metric_summary(BT)
    animals = unique(BT.animal, 'stable');
    bands = unique(BT.band, 'stable');
    cats = ["familiar"; "novel"];

    rows = {};
    for a = 1:numel(animals)
        for b = 1:numel(bands)
            for c = 1:numel(cats)
                idx = BT.animal == animals(a) & BT.band == bands(b) & BT.category == cats(c);
                if ~any(idx), continue; end

                if ismember('peakZ', BT.Properties.VariableNames)
                    medZ = median(BT.peakZ(idx), 'omitnan');
                else
                    medZ = NaN;
                end
                if ismember('burstDurationS', BT.Properties.VariableNames)
                    medDur = median(BT.burstDurationS(idx), 'omitnan');
                else
                    medDur = NaN;
                end

                rows(end+1,:) = {char(animals(a)), char(bands(b)), char(cats(c)), nnz(idx), medZ, medDur}; %#ok<AGROW>
            end
        end
    end

    E = cell2table(rows, 'VariableNames', {'animal','band','category','nBursts','medianPeakZ','medianBurstDurationS'});
    E.animal = string(E.animal);
    E.band = string(E.band);
    E.category = string(E.category);
end
