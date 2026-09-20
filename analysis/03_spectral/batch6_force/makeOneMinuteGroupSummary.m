function groupSummary = makeOneMinuteGroupSummary(bandRows)
animals = unique(bandRows.animal, 'stable');
bands = unique(bandRows.band, 'stable');
maxMin = ceil(max(bandRows.timeMinFromRun1Start));
rows = table();
for b = 1:numel(bands)
    bandName = bands{b};
    for bin = 0:maxMin-1
        animalVals = nan(numel(animals),1);
        for a = 1:numel(animals)
            inRows = strcmp(bandRows.animal, animals{a}) & strcmp(bandRows.band, bandName) & ...
                bandRows.timeMinFromRun1Start >= bin & bandRows.timeMinFromRun1Start < bin+1;
            if any(inRows)
                animalVals(a) = mean(bandRows.meanZPower(inRows), 'omitnan');
            end
        end
        vals = animalVals(isfinite(animalVals));
        if isempty(vals)
            meanVal = NaN; semVal = NaN; nAnimals = 0;
        else
            meanVal = mean(vals);
            if numel(vals) > 1
                semVal = std(vals) ./ sqrt(numel(vals));
            else
                semVal = 0;
            end
            nAnimals = numel(vals);
        end
        row = table({bandName}, bin + 0.5, nAnimals, meanVal, semVal, ...
            'VariableNames', {'band','timeBinMidMin','nAnimals','meanZPower','semZPower'});
        rows = [rows; row]; %#ok<AGROW>
    end
end
groupSummary = rows;
end
