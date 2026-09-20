function p = exact_sign_flip_p(vals)
    vals = vals(:);
    vals = vals(isfinite(vals) & vals ~= 0);
    n = numel(vals);
    if n == 0
        p = NaN;
        return;
    end
    k = sum(vals > 0);
    lo = min(k, n-k);
    % Exact two-sided sign-flip/binomial p without requiring Statistics Toolbox.
    probs = arrayfun(@(j) nchoosek(n,j), 0:lo) ./ (2^n);
    p = min(1, 2 * sum(probs));
end
