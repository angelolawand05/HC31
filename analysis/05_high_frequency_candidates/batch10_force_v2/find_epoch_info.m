function E = find_epoch_info(EpochInfo, epochName)
    E = [];
    for i = 1:numel(EpochInfo)
        if strcmpi(EpochInfo(i).epochName, char(epochName))
            E = EpochInfo(i);
            return;
        end
    end
end
