function [animalsOut, famVals, novVals] = paired_values_novel_familiar(T, band, familiarField, novelField)
    T.animal = string(T.animal);
    if ismember('band', T.Properties.VariableNames)
        T.band = normalise_band_labels(string(T.band));
        T = T(T.band == band, :);
    end
    animals = unique(T.animal, 'stable');

    animalsOut = strings(0,1);
    famVals = [];
    novVals = [];

    for a = 1:numel(animals)
        row = T.animal == animals(a);
        if any(row)
            f = T.(familiarField)(find(row,1));
            n = T.(novelField)(find(row,1));
            if isfinite(f) && isfinite(n)
                animalsOut(end+1,1) = animals(a); %#ok<AGROW>
                famVals(end+1,1) = f; %#ok<AGROW>
                novVals(end+1,1) = n; %#ok<AGROW>
            end
        end
    end
end
