function Z = zscoreRows(Y)
mu = mean(Y, 2, 'omitnan');
sd = std(Y, 0, 2, 'omitnan');
sd(sd == 0 | ~isfinite(sd)) = NaN;
Z = (Y - mu) ./ sd;
Z(~isfinite(Z)) = 0;
end
