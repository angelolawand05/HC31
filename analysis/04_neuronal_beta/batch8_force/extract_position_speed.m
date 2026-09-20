function [t, linPos, speedCmS] = extract_position_speed(posU)
    data = double(posU.data);
    t = data(:,1);
    linPos = data(:,2);

    if size(data,2) >= 4
        speedRaw = data(:,4);
    else
        speedRaw = nan(size(t));
    end

    if isfield(posU, 'unitsPerCm') && isfield(posU, 'unitsPerSecond')
        speedCmS = speedRaw .* (1 / posU.unitsPerCm) .* posU.unitsPerSecond;
    else
        speedCmS = speedRaw;
    end
end
