function col = get_epoch_col(P, epochName, nEpochs)
    col = NaN;
    epochName = char(epochName);
    if isfield(P.epochMap, epochName)
        c = P.epochMap.(epochName);
        if c <= nEpochs
            col = c;
        end
    end
end
