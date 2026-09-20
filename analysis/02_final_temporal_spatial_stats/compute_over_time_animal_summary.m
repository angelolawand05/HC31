function S = compute_over_time_animal_summary(T, bandsWanted)
    T.animal = string(T.animal);
    T.band = normalise_band_labels(string(T.band));

    animals = unique(T.animal, 'stable');
    rows = {};

    for a = 1:numel(animals)
        animal = animals(a);
        for b = 1:numel(bandsWanted)
            band = bandsWanted(b);
            take = T.animal == animal & T.band == band;
            if ~any(take), continue; end

            validSeconds = T.validSecondsInBin(take);
            burstCounts = T.burstCount(take);
            rates = T.burstRatePerMinute(take);
            times = T.binMidMinutesFromRun1Start(take);

            ok = isfinite(rates) & isfinite(times) & validSeconds > 0;

            totalValidSeconds = sum(validSeconds(ok), 'omitnan');
            totalBurstCount = sum(burstCounts(ok), 'omitnan');

            if totalValidSeconds > 0
                overallRate = totalBurstCount / totalValidSeconds * 60;
            else
                overallRate = NaN;
            end

            if nnz(ok) >= 2
                pfit = polyfit(times(ok), rates(ok), 1);
                slope = pfit(1);
            else
                slope = NaN;
            end

            if any(ok)
                midTime = median(times(ok), 'omitnan');
                firstMask = ok & times <= midTime;
                secondMask = ok & times > midTime;

                firstValidSeconds = sum(validSeconds(firstMask), 'omitnan');
                firstBurstCount = sum(burstCounts(firstMask), 'omitnan');
                secondValidSeconds = sum(validSeconds(secondMask), 'omitnan');
                secondBurstCount = sum(burstCounts(secondMask), 'omitnan');

                if firstValidSeconds > 0
                    firstRate = firstBurstCount / firstValidSeconds * 60;
                else
                    firstRate = NaN;
                end

                if secondValidSeconds > 0
                    secondRate = secondBurstCount / secondValidSeconds * 60;
                else
                    secondRate = NaN;
                end
            else
                firstRate = NaN;
                secondRate = NaN;
            end

            rows(end+1,:) = {char(animal), char(band), totalValidSeconds, totalBurstCount, ...
                overallRate, slope, firstRate, secondRate, secondRate - firstRate}; %#ok<AGROW>
        end
    end

    S = cell2table(rows, 'VariableNames', { ...
        'animal','band','totalValidSeconds','totalBurstCount', ...
        'overallBurstRatePerMinute','slopeBurstRatePerMinutePerMinute', ...
        'firstHalfRatePerMinute','secondHalfRatePerMinute','secondMinusFirstHalfRate'});
    S.animal = string(S.animal);
    S.band = string(S.band);
end
