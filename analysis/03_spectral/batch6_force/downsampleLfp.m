function [lfpDs, tDsUs, FsDs, validMaskDs] = downsampleLfp(v, tUs, Fs, targetFs)
v = double(v(:));
tUs = double(tUs(:));
factor = max(1, round(Fs / targetFs));
FsDs = Fs / factor;
validRaw = isfinite(v);

vFilled = v;
if any(validRaw)
    fillValue = median(v(validRaw));
else
    fillValue = 0;
end
vFilled(~validRaw) = fillValue;

if factor > 1
    try
        lfpDs = decimate(vFilled, factor);
    catch
        warning('decimate unavailable/failed; falling back to simple downsampling after median fill.');
        lfpDs = vFilled(1:factor:end);
    end
    tDsUs = tUs(1:factor:end);
    validMaskDs = validRaw(1:factor:end);
else
    lfpDs = vFilled;
    tDsUs = tUs;
    validMaskDs = validRaw;
end

n = min([numel(lfpDs), numel(tDsUs), numel(validMaskDs)]);
lfpDs = lfpDs(1:n);
tDsUs = tDsUs(1:n);
validMaskDs = validMaskDs(1:n);
end
