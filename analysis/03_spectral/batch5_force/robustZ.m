function z = robustZ(x)
    x = double(x);
    med = median(x, 'omitnan');
    madVal = median(abs(x - med), 'omitnan');
    if ~isfinite(madVal) || madVal == 0
        sd = std(x, 'omitnan');
        if ~isfinite(sd) || sd == 0
            z = zeros(size(x));
        else
            z = (x - mean(x, 'omitnan')) ./ sd;
        end
    else
        z = 0.6745 .* (x - med) ./ madVal;
    end
end
