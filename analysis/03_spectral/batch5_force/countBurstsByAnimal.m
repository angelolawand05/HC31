function burstCounts = countBurstsByAnimal(B, animals)
    rows = {};
    for a = 1:numel(animals)
        animalName = char(animals(a));
        validRows = B.animal == animals(a) & ~B.isArtifact;
        bands = B.band(validRows);
        betaCount = sum(contains(lower(bands), '13') | contains(lower(bands), 'beta_13') | strcmpi(bands, 'beta'));
        beta2Count = sum(contains(lower(bands), 'beta2') | contains(lower(bands), '23_30') | contains(lower(bands), '23-30'));
        totalCount = sum(validRows);
        rows(end+1,:) = {animalName, betaCount, beta2Count, totalCount}; %#ok<AGROW>
    end
    burstCounts = cell2table(rows, 'VariableNames', {'animal','beta13_30ValidBurstCount','beta2ValidBurstCount','totalValidBurstCount'});
end
