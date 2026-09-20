function x = fillMissingForSpectrogram(x)
x = double(x(:));
if all(~isfinite(x))
    x(:) = 0;
    return;
end
medVal = median(x(isfinite(x)));
x(~isfinite(x)) = medVal;
end
