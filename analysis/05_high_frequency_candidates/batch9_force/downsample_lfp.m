function [tDsUs, xDs, fsDs] = downsample_lfp(tUs, x, fsRaw, targetFs)
    factor = max(1, round(fsRaw / targetFs));
    fsDs = fsRaw / factor;
    x = double(x(:));
    tUs = double(tUs(:));
    x = x - median(x, 'omitnan');

    if factor > 1
        try
            xDs = decimate(x, factor);
            tDsUs = linspace(tUs(1), tUs(end), numel(xDs))';
        catch
            xDs = x(1:factor:end);
            tDsUs = tUs(1:factor:end);
        end
    else
        xDs = x;
        tDsUs = tUs;
    end
end
