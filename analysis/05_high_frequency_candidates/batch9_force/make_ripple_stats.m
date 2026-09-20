function Stats = make_ripple_stats(A)
    if isempty(A), Stats = table(); return; end
    vals = A.rippleRatePerMinute;
    Stats = table("ripple_rate_vs_zero", numel(vals), mean(vals,'omitnan'), median(vals,'omitnan'), nnz(vals>0), exact_sign_flip_p(vals), ...
        'VariableNames', {'comparison','nAnimals','meanValue','medianValue','nPositive','twoSidedExactSignFlipP'});
end
