function [posT, posLin, speedCmS] = extract_position_speed(posU)
    data = double(posU.data);
    posT = data(:,1);
    posLin = data(:,2);
    if size(data,2) >= 4
        speedRaw = data(:,4);
    else
        speedRaw = nan(size(posT));
    end
    if isfield(posU, 'unitsPerCm') && isfield(posU, 'unitsPerSecond')
        speedCmS = speedRaw .* (1 / posU.unitsPerCm) .* posU.unitsPerSecond;
    else
        speedCmS = speedRaw;
    end
end
