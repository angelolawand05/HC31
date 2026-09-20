function [animalsOut, valsA, valsB] = paired_values_by_band(T, valueField, bandA, bandB)
    T.animal = string(T.animal);
    T.band = normalise_band_labels(string(T.band));
    animals = unique(T.animal, 'stable');

    animalsOut = strings(0,1);
    valsA = [];
    valsB = [];

    for a = 1:numel(animals)
        rowA = T.animal == animals(a) & T.band == bandA;
        rowB = T.animal == animals(a) & T.band == bandB;

        if any(rowA) && any(rowB)
            va = T.(valueField)(find(rowA,1));
            vb = T.(valueField)(find(rowB,1));
            if isfinite(va) && isfinite(vb)
                animalsOut(end+1,1) = animals(a); %#ok<AGROW>
                valsA(end+1,1) = va; %#ok<AGROW>
                valsB(end+1,1) = vb; %#ok<AGROW>
            end
        end
    end
end
