function [tall, vall, Fs] = makeContinuousLfp(t, v)
t = double(t(:));
v = double(v);
vallRaw = v(:);

tDiff = diff(t);
if isempty(tDiff)
    error('CSC file returned fewer than two timestamp records.');
end
mtDiff = mode(round(tDiff));
noSkip = abs(tDiff - mtDiff) < 2;

if all(noSkip)
    Fs = 1 / (mean(tDiff) / size(v,1) / 1e6);
    sampleStepUs = (1 / Fs) * 1e6;
    tall = t(1) + (0:(numel(vallRaw)-1))' .* sampleStepUs;
    vall = vallRaw;
else
    warning('Timestamp gaps detected. Inserting NaNs to preserve timing.');
    Fs = 1 / (mean(tDiff(noSkip)) / size(v,1) / 1e6);
    sampleStepUs = (1 / Fs) * 1e6;
    tVec = (t(1):sampleStepUs:(t(end) + (size(v,1)-1)*sampleStepUs))';
    vVec = nan(numel(tVec), 1);
    p = 1;
    for j = 1:size(v,2)
        while p <= numel(tVec) && abs(t(j) - tVec(p)) >= 2
            p = p + 1;
        end
        if p + size(v,1) - 1 <= numel(vVec)
            vVec(p:p+size(v,1)-1) = v(:,j);
        end
        p = p + size(v,1);
    end
    tall = tVec;
    vall = vVec;
end
end
