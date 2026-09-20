function info = try_get_csc_bounds(cscPath, defaultInfo, runStartUs, runEndUs)
    info = defaultInfo;
    try
        % FieldSelection [1 0 0 0 0] selects timestamps only, so request one output.
        ts = Nlx2MatCSC(cscPath, [1 0 0 0 0], 0, 1, []);
        if ~isempty(ts)
            info.startUs = double(min(ts));
            info.endUs = double(max(ts));
            overlapUs = max(0, min(info.endUs, runEndUs) - max(info.startUs, runStartUs));
            info.overlapS = overlapUs / 1e6;
        end
    catch
        % Timestamp probing can fail in some Neuralynx import builds. This is not fatal;
        % the exact animal-to-CSC mapping can still choose the correct file.
    end
end
