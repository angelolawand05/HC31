function Stats = make_timing_stats(T)
    if isempty(T), Stats = table(); return; end
    bands = unique(string(T.betaBand), 'stable');
    rows = {};
    for bi = 1:numel(bands)
        idx = string(T.betaBand) == bands(bi);
        vals = T.meanPostMinusPre(idx);
        rows(end+1,:) = {char(bands(bi)), numel(vals), mean(vals,'omitnan'), median(vals,'omitnan'), nnz(vals>0), nnz(vals<0), exact_sign_flip_p(vals)}; %#ok<AGROW>
    end
    Stats = cell2table(rows, 'VariableNames', {'betaBand','nAnimals','meanPostMinusPre','medianPostMinusPre','nPositive','nNegative','twoSidedExactSignFlipP'});
end
