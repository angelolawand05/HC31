function [row, p] = make_stat_row(testName, metric, band, subgroup, comparison, valsA, valsB)
    valsA = valsA(:);
    valsB = valsB(:);
    ok = isfinite(valsA) & isfinite(valsB);
    a = valsA(ok);
    b = valsB(ok);
    d = b - a;
    dNoZero = d(isfinite(d) & d ~= 0);

    p = exact_signflip_p(d);

    row = {char(testName), char(metric), char(band), char(subgroup), char(comparison), ...
        numel(d), numel(dNoZero), ...
        mean(a, 'omitnan'), mean(b, 'omitnan'), mean(d, 'omitnan'), median(d, 'omitnan'), ...
        nnz(d > 0), nnz(d < 0), p};
end
