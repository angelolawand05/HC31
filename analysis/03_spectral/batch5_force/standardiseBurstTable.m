function B = standardiseBurstTable(Braw)
    animalVar = findVar(Braw, {'animal','animalName','subject'});
    bandVar = findVar(Braw, {'band','burstBand','frequencyBand'});
    artifactVar = findVar(Braw, {'artifact','isArtifact','artefact','isArtefact','artifactFlag','artefactFlag'});

    if isempty(animalVar) || isempty(bandVar)
        error('Burst table must contain animal and band/burstBand columns.');
    end

    B = table();
    B.animal = string(Braw.(animalVar));
    B.band = string(Braw.(bandVar));

    if isempty(artifactVar)
        B.isArtifact = false(height(Braw),1);
    else
        val = Braw.(artifactVar);
        if islogical(val)
            B.isArtifact = val;
        elseif isnumeric(val)
            B.isArtifact = val ~= 0;
        else
            B.isArtifact = strcmpi(string(val), 'true') | strcmpi(string(val), 'yes') | strcmpi(string(val), 'artifact') | strcmpi(string(val), 'artefact');
        end
    end
end
