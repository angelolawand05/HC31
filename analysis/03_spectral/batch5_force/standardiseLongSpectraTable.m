function T = standardiseLongSpectraTable(Traw)
    animalVar = findVar(Traw, {'animal','animalName','subject'});
    conditionVar = findVar(Traw, {'condition','category','state'});
    freqVar = findVar(Traw, {'frequencyHz','freqHz','frequency','freq'});
    powerDbVar = findVar(Traw, {'powerDb','powerDB','dbPower','power_dB'});
    powerVar = findVar(Traw, {'power','rawPower','spectrumPower'});

    if isempty(animalVar) || isempty(conditionVar) || isempty(freqVar)
        error('Spectra table must contain animal, condition and frequencyHz columns.');
    end
    if isempty(powerDbVar) && isempty(powerVar)
        error('Spectra table must contain either powerDb or power columns.');
    end

    T = table();
    T.animal = string(Traw.(animalVar));
    T.condition = string(Traw.(conditionVar));
    T.frequencyHz = double(Traw.(freqVar));
    if ~isempty(powerDbVar)
        T.powerDb = double(Traw.(powerDbVar));
    else
        p = double(Traw.(powerVar));
        p(p <= 0) = NaN;
        T.powerDb = 10 .* log10(p);
    end
    if ~isempty(powerVar)
        T.power = double(Traw.(powerVar));
    else
        T.power = 10 .^ (T.powerDb ./ 10);
    end
end
