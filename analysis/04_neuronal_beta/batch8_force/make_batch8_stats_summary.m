function Stats = make_batch8_stats_summary(A)
    if isempty(A)
        Stats = table();
        return;
    end
    A.band = string(A.band);
    A.category = string(A.category);

    rows = {};
    bands = unique(A.band, 'stable');
    cats = unique(A.category, 'stable');

    for bi = 1:numel(bands)
        for ci = 1:numel(cats)
            idx = A.band == bands(bi) & A.category == cats(ci);
            if nnz(idx) < 2, continue; end

            vals = A.meanBurstMinusControlFiringRateHz(idx);
            p = exact_sign_flip_p(vals);
            rows(end+1,:) = {char(bands(bi)), char(cats(ci)), ...
                'mean_unit_burst_minus_control_firing_rate', nnz(isfinite(vals)), ...
                mean(vals, 'omitnan'), median(vals, 'omitnan'), ...
                nnz(vals > 0), nnz(vals < 0), p}; %#ok<SAGROW>

            vals2 = A.meanBurstMinusControlParticipationFraction(idx);
            p2 = exact_sign_flip_p(vals2);
            rows(end+1,:) = {char(bands(bi)), char(cats(ci)), ...
                'mean_unit_burst_minus_control_participation', nnz(isfinite(vals2)), ...
                mean(vals2, 'omitnan'), median(vals2, 'omitnan'), ...
                nnz(vals2 > 0), nnz(vals2 < 0), p2}; %#ok<SAGROW>
        end
    end

    Stats = cell2table(rows, 'VariableNames', { ...
        'band','category','metric','nAnimals','meanValue','medianValue', ...
        'nPositive','nNegative','twoSidedExactSignFlipP'});
end
