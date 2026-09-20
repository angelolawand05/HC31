function B = standardiseBurstTable(Bin)
B = Bin;
vars = B.Properties.VariableNames;

B.animal = asCellstrColumn(B, vars, {'animal','Animal'});
B.band = asCellstrColumn(B, vars, {'band','Band','frequencyBand'});
B.burstPeakUs = asNumericColumn(B, vars, {'burstPeakUs','peakTimeUs','peakUs','BurstPeakUs'});

if any(strcmp(vars, 'excludedAsArtifact'))
    B.excludedAsArtifact = logical(B.excludedAsArtifact);
else
    B.excludedAsArtifact = false(height(B),1);
end

if any(strcmp(vars, 'includedInNovelFamiliarAnalysis'))
    inc = B.includedInNovelFamiliarAnalysis;
    if isnumeric(inc)
        B.excludedAsArtifact = B.excludedAsArtifact | inc == 0;
    end
end
end
