function p = exact_signflip_p(d)
    d = d(:);
    d = d(isfinite(d));
    d = d(d ~= 0);

    n = numel(d);
    if n == 0
        p = NaN;
        return;
    end

    observed = abs(mean(d));
    nPerm = 2^n;
    permMeans = zeros(nPerm,1);

    for mask = 0:(nPerm-1)
        signs = ones(n,1);
        for bit = 1:n
            if bitget(mask, bit)
                signs(bit) = -1;
            end
        end
        permMeans(mask+1) = mean(d .* signs);
    end

    p = mean(abs(permMeans) >= observed);
end
