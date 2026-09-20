function info = try_get_csc_bounds(cscPath, defaultInfo, startUs, endUs)
    info = defaultInfo;
    try
        % FieldSelection [1 0 0 0 0] selects timestamps only, so request one output.
        ts = Nlx2MatCSC(cscPath, [1 0 0 0 0], 0, 1, []);
        if ~isempty(ts)
            info.startUs = double(min(ts));
            info.endUs = double(max(ts));
            overlapUs = max(0, min(info.endUs, endUs) - max(info.startUs, startUs));
            info.overlapS = overlapUs / 1e6;
        end
    catch
        % Timestamp probing can fail in some Neuralynx import builds. This is not fatal;
        % interval reads can still be attempted from the mapped animal CSC file.
    end
end
