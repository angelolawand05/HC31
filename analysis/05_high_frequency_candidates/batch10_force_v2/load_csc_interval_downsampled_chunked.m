function [tDsUs, xDsAll, fsDs] = load_csc_interval_downsampled_chunked(cscPath, startUs, endUs, targetFs, chunkLengthS)
    tDsUs = [];
    xDsAll = [];
    fsDs = NaN;

    chunkUs = chunkLengthS * 1e6;
    currentStart = startUs;

    while currentStart < endUs
        currentEnd = min(endUs, currentStart + chunkUs);

        [tUs, xRaw, fsRaw] = load_csc_interval_raw(cscPath, currentStart, currentEnd);
        if ~isempty(tUs)
            [tds, xds, fsd] = downsample_lfp(tUs, xRaw, fsRaw, targetFs);
            fsDs = fsd;
            if isempty(tDsUs)
                tDsUs = tds(:);
                xDsAll = xds(:);
            else
                keep = tds(:) > tDsUs(end);
                tDsUs = [tDsUs; tds(keep)]; %#ok<AGROW>
                xDsAll = [xDsAll; xds(keep)]; %#ok<AGROW>
            end
        end

        currentStart = currentEnd;
    end
end
