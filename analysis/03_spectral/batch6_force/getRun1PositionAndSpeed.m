function [posTimeUs, linPos, speedCmS] = getRun1PositionAndSpeed(R)
posU = R.posMazeLin(1);
posData = double(posU.data);
posTimeUs = posData(:,1);
linPos = posData(:,2);
if size(posData,2) >= 4
    speedCmS = posData(:,4);
else
    speedCmS = nan(size(linPos));
end
end
