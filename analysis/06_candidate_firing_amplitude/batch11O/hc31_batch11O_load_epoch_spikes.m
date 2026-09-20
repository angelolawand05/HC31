function [spikeCell, usableMask, nUnits, epochColumn] = ...
    hc31_batch11O_load_epoch_spikes(R, epochName)
% Load epoch-compatible spike timestamps from one resSave animal.
%
% Correct HC-31 spEpochSep mapping:
% PRE = 1, Run1 = 2, REST = 3, POST = 4.

epochName = upper(strtrim(string(epochName)));

if epochName == "PRE"
    epochColumn = 1;
elseif epochName == "RUN1AWAKE" || epochName == "RUN1"
    epochColumn = 2;
elseif epochName == "REST"
    epochColumn = 3;
elseif epochName == "POST"
    epochColumn = 4;
else
    epochColumn = NaN;
end

nUnits = 0;

if isfield(R,'spEpochSep')
    try
        nUnits = size(R.spEpochSep,1);
    catch
        nUnits = 0;
    end
end

if nUnits == 0 && isfield(R,'spAll')
    try
        nUnits = numel(R.spAll);
    catch
        nUnits = 0;
    end
end

spikeCell = cell(nUnits,1);
usableMask = false(nUnits,1);

for unitIndex = 1:nUnits
    spikeTimes = [];

    try
        if isfinite(epochColumn) && ...
                isfield(R,'spEpochSep') && ...
                size(R.spEpochSep,1) >= unitIndex && ...
                size(R.spEpochSep,2) >= epochColumn

            source = R.spEpochSep(unitIndex,epochColumn);

            if isfield(source,'timeStamps')
                spikeTimes = double(source.timeStamps(:));
            elseif isfield(source,'timestamps')
                spikeTimes = double(source.timestamps(:));
            elseif isfield(source,'times')
                spikeTimes = double(source.times(:));
            elseif isfield(source,'time')
                spikeTimes = double(source.time(:));
            end
        end
    catch
        spikeTimes = [];
    end

    if isempty(spikeTimes)
        try
            if isfield(R,'spAll') && numel(R.spAll) >= unitIndex
                source = R.spAll(unitIndex);

                if isfield(source,'timeStamps')
                    spikeTimes = double(source.timeStamps(:));
                elseif isfield(source,'timestamps')
                    spikeTimes = double(source.timestamps(:));
                elseif isfield(source,'times')
                    spikeTimes = double(source.times(:));
                elseif isfield(source,'time')
                    spikeTimes = double(source.time(:));
                end
            end
        catch
            spikeTimes = [];
        end
    end

    spikeTimes = spikeTimes(isfinite(spikeTimes));

    if ~isempty(spikeTimes) && ...
            median(abs(spikeTimes),'omitnan') < 1e6
        spikeTimes = spikeTimes*1e6;
    end

    spikeTimes = sort(spikeTimes(:));
    spikeCell{unitIndex} = spikeTimes;
    usableMask(unitIndex) = ~isempty(spikeTimes);
end

end
